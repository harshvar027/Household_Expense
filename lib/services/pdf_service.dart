import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/expense.dart';
import '../models/income.dart';
import '../services/auth_service.dart';
import '../utils/money_format.dart';

class PdfService {
  Future<pw.Document> generateMonthlyReport({
    required String month,
    required double income,
    required double manualIncome,
    required double importedIncome,
    required double broughtForwardIncome,
    required double budget,
    required double expenses,
    required double investmentTotal,
    required double netBalance,
    required Map<String, double> categoryTotals,
    required Map<String, double> investmentTotals,
    required List<Expense> expenseList,
    required List<Income> incomeList,
    required List<Expense> investmentList,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          pw.Text(
            'Household Expense Tracker',
            style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Monthly Report',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            month,
            style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
          ),
          pw.Divider(),
          pw.SizedBox(height: 16),
          sectionTitle('Month summary'),
          pw.SizedBox(height: 8),
          summaryTable([
            summaryRow('Month', month),
            summaryRow('Total income', formatMoneyWithCurrency(income)),
            summaryRow('  Manual income', formatMoneyWithCurrency(manualIncome)),
            summaryRow('  Imported income', formatMoneyWithCurrency(importedIncome)),
            summaryRow(
              '  Balance brought forward',
              formatMoneyWithCurrency(broughtForwardIncome),
            ),
            summaryRow('Monthly budget', formatMoneyWithCurrency(budget)),
            summaryRow('Total expenses', formatMoneyWithCurrency(expenses)),
            summaryRow(
              'Savings & investments',
              formatMoneyWithCurrency(investmentTotal),
            ),
            summaryRow('Net balance', formatMoneyWithCurrency(netBalance)),
          ]),
          pw.SizedBox(height: 22),
          sectionTitle('Expense categories'),
          pw.SizedBox(height: 8),
          keyValueTable(
            categoryTotals.entries
                .map((entry) => MapEntry(entry.key, formatMoneyWithCurrency(entry.value)))
                .toList(),
            emptyLabel: 'No expenses recorded this month.',
          ),
          if (investmentTotals.isNotEmpty) ...[
            pw.SizedBox(height: 22),
            sectionTitle('Savings & investment categories'),
            pw.SizedBox(height: 8),
            keyValueTable(
              investmentTotals.entries
                  .map(
                    (entry) =>
                        MapEntry(entry.key, formatMoneyWithCurrency(entry.value)),
                  )
                  .toList(),
            ),
          ],
          pw.SizedBox(height: 22),
          sectionTitle('Income history'),
          pw.SizedBox(height: 8),
          dataTable(
            headers: const ['Date', 'Source', 'Category', 'Payment', 'Amount'],
            rows: incomeList.isEmpty
                ? const []
                : incomeList
                    .map(
                      (income) => [
                        _formatIncomeDate(income),
                        income.source,
                        income.category,
                        income.paymentMethod,
                        formatMoneyWithCurrency(income.amount),
                      ],
                    )
                    .toList(),
            emptyLabel: 'No income entries this month.',
          ),
          pw.SizedBox(height: 22),
          sectionTitle('Expense history'),
          pw.SizedBox(height: 8),
          dataTable(
            headers: const ['Date', 'Item', 'Category', 'Payment', 'Amount'],
            rows: expenseList.isEmpty
                ? const []
                : expenseList
                    .map(
                      (expense) => [
                        _formatExpenseDate(expense.expenseDate),
                        expense.item,
                        expense.category,
                        expense.paymentMethod,
                        formatMoneyWithCurrency(expense.amount),
                      ],
                    )
                    .toList(),
            emptyLabel: 'No expenses recorded this month.',
          ),
          pw.SizedBox(height: 22),
          sectionTitle('Savings & investment history'),
          pw.SizedBox(height: 8),
          dataTable(
            headers: const ['Date', 'Item', 'Category', 'Payment', 'Amount'],
            rows: investmentList.isEmpty
                ? const []
                : investmentList
                    .map(
                      (expense) => [
                        _formatExpenseDate(expense.expenseDate),
                        expense.item,
                        expense.category,
                        expense.paymentMethod,
                        formatMoneyWithCurrency(expense.amount),
                      ],
                    )
                    .toList(),
            emptyLabel: 'No savings or investment entries this month.',
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Generated by Household Expense Tracker',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return pdf;
  }

  Future<void> previewPdf({
    required String month,
    required double income,
    required double manualIncome,
    required double importedIncome,
    required double broughtForwardIncome,
    required double budget,
    required double expenses,
    required double investmentTotal,
    required double netBalance,
    required Map<String, double> categoryTotals,
    required Map<String, double> investmentTotals,
    required List<Expense> expenseList,
    required List<Income> incomeList,
    required List<Expense> investmentList,
  }) async {
    final pdf = await generateMonthlyReport(
      month: month,
      income: income,
      manualIncome: manualIncome,
      importedIncome: importedIncome,
      broughtForwardIncome: broughtForwardIncome,
      budget: budget,
      expenses: expenses,
      investmentTotal: investmentTotal,
      netBalance: netBalance,
      categoryTotals: categoryTotals,
      investmentTotals: investmentTotals,
      expenseList: expenseList,
      incomeList: incomeList,
      investmentList: investmentList,
    );

    await AuthService.instance.runWithNativeSheetGuard(() async {
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    });
  }

  pw.Widget sectionTitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
    );
  }

  pw.Widget summaryTable(List<pw.TableRow> rows) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.2),
      },
      children: rows,
    );
  }

  pw.TableRow summaryRow(String label, String value) {
    return pw.TableRow(
      children: [
        tableCell(label),
        tableCell(value, align: pw.TextAlign.right),
      ],
    );
  }

  pw.Widget keyValueTable(
    List<MapEntry<String, String>> entries, {
    String emptyLabel = 'No records.',
  }) {
    if (entries.isEmpty) {
      return pw.Text(emptyLabel, style: const pw.TextStyle(color: PdfColors.grey700));
    }

    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          children: [
            headerCell('Category'),
            headerCell('Amount'),
          ],
        ),
        ...entries.map(
          (entry) => pw.TableRow(
            children: [
              tableCell(entry.key),
              tableCell(entry.value, align: pw.TextAlign.right),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget dataTable({
    required List<String> headers,
    required List<List<String>> rows,
    required String emptyLabel,
  }) {
    if (rows.isEmpty) {
      return pw.Text(emptyLabel, style: const pw.TextStyle(color: PdfColors.grey700));
    }

    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          children: headers.map(headerCell).toList(),
        ),
        ...rows.map(
          (row) => pw.TableRow(
            children: row
                .map(
                  (cell) => tableCell(
                    cell,
                    align: cell == row.last ? pw.TextAlign.right : pw.TextAlign.left,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  String _formatExpenseDate(String dbDate) {
    if (dbDate.isEmpty) return '-';
    final parts = dbDate.split('-');
    if (parts.length < 3) return dbDate;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  String _formatIncomeDate(Income income) {
    if (income.incomeDate.isNotEmpty) {
      return _formatExpenseDate(income.incomeDate);
    }
    if (income.month != null && income.month!.isNotEmpty) {
      return 'Monthly';
    }
    return '-';
  }

  pw.Widget headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    );
  }

  pw.Widget tableCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, textAlign: align),
    );
  }
}

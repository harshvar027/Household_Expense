import '../database/database_helper.dart';
import '../models/bank_transaction.dart';
import '../models/expense.dart';
import 'category_detector.dart';
import 'merchant_rule_service.dart';
import '../models/income.dart';
import '../models/bank_profile.dart';
import '../utils/account_label.dart';

class ImportService {
  final db = DatabaseHelper.instance;

  Future<int> importTransactions(
    List<BankTransaction> transactions, {
    BankId? bankId,
  }) async {
    int importedCount = 0;
    final explicitBankName = bankId == null || bankId == BankId.generic
        ? null
        : BankProfile.fromId(bankId).displayName;

    for (final t in transactions) {
      if (!t.selected || t.duplicate) {
        continue;
      }

      final accountName = await _resolveAccountName(t);
      final bankName = explicitBankName ?? await _resolveBankName(t);

      if (t.isDebit) {
        await MerchantRuleService.instance.learnFromCategoryChange(
          t.description,
          t.category,
        );

        final expense = Expense(
          expenseDate: formatDate(t.date),
          category: t.category,
          item: t.item.isEmpty ? t.description : t.item,
          amount: t.amount,
          paymentMethod: 'Bank',
          accountId: t.accountId,
          notes: buildImportNotes(
            accountName: accountName,
            bankName: bankName,
          ),
        );

        await db.insertExpense(expense);
      } else {
        final incomeDate = formatDate(t.date);
        final income = Income(
          incomeDate: incomeDate,
          month: incomeDate.substring(0, 7),
          category: CategoryDetector.detectIncome(t),
          source: t.item.isEmpty ? t.description : t.item,
          amount: t.amount,
          paymentMethod: 'Bank',
          accountId: t.accountId,
        );

        await db.insertIncome(income);
      }

      importedCount++;
    }

    return importedCount;
  }

  Future<String?> _resolveAccountName(BankTransaction t) async {
    final cached = t.accountName?.trim();
    if (cached != null && cached.isNotEmpty) return cached;
    if (t.accountId == null) return null;

    final accounts = await db.getAccounts();
    for (final account in accounts) {
      if (account.id == t.accountId) return account.name;
    }
    return null;
  }

  Future<String?> _resolveBankName(BankTransaction t) async {
    if (t.accountId == null) return null;
    final accounts = await db.getAccounts();
    for (final account in accounts) {
      if (account.id == t.accountId) {
        final label = BankProfile.labelForId(account.bankId);
        return label.isEmpty ? null : label;
      }
    }
    return null;
  }

  String formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }
}

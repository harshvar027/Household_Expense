import '../models/expense.dart';
import '../utils/category_utils.dart';
import '../utils/money_format.dart';

class Insight {
  final String message;
  final String type; // info, warning, success

  Insight({required this.message, this.type = 'info'});
}

class InsightsService {
  List<Insight> generate({
    required String selectedMonth,
    required List<Expense> allExpenses,
    required Map<String, double> categoryTotals,
    required double totalExpenses,
    required double monthlyBudget,
    required Map<String, double> categoryBudgets,
  }) {
    final insights = <Insight>[];

    final prevMonth = _previousMonth(selectedMonth);
    final thisMonthExpenses = _monthSpending(allExpenses, selectedMonth);
    final prevMonthExpenses = _monthSpending(allExpenses, prevMonth);

    if (prevMonthExpenses > 0) {
      final change =
          ((thisMonthExpenses - prevMonthExpenses) / prevMonthExpenses * 100);
      if (change.abs() >= 10) {
        final dir = change > 0 ? 'up' : 'down';
        insights.add(Insight(
          message:
              'Total spending is ${change.abs().toStringAsFixed(0)}% $dir vs last month (${formatMoneyWithCurrency(prevMonthExpenses)} → ${formatMoneyWithCurrency(thisMonthExpenses)}).',
          type: change > 15 ? 'warning' : 'info',
        ));
      }
    }

    // Category month-over-month
    final prevCategoryTotals = _categoryTotalsForMonth(allExpenses, prevMonth);
    for (final entry in categoryTotals.entries) {
      final prev = prevCategoryTotals[entry.key] ?? 0;
      if (prev > 0) {
        final pct = ((entry.value - prev) / prev * 100);
        if (pct >= 20) {
          insights.add(Insight(
            message:
                '${entry.key} spending up ${pct.toStringAsFixed(0)}% vs last month.',
            type: 'warning',
          ));
        }
      }
    }

    // Top merchants
    final merchants = <String, double>{};
    for (final e in allExpenses) {
      if (e.expenseDate.substring(0, 7) != selectedMonth) continue;
      if (CategoryUtils.isSavingsCategory(e.category) || e.isTransfer) continue;
      merchants[e.item] = (merchants[e.item] ?? 0) + e.amount;
    }
    if (merchants.isNotEmpty) {
      final top = merchants.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top5 = top.take(5).map((e) => '${e.key} (${formatMoneyWithCurrency(e.value)})').join(', ');
      insights.add(Insight(
        message: 'Top merchants: $top5',
        type: 'info',
      ));
    }

    // Subscriptions
    final subTotal = categoryTotals['Subscriptions'] ?? 0;
    if (subTotal > 0) {
      insights.add(Insight(
        message:
            'You spent ${formatMoneyWithCurrency(subTotal)} on subscriptions this month.',
        type: 'info',
      ));
    }

    // Unusual transaction (>2x average)
    final monthlyList = allExpenses
        .where((e) =>
            e.expenseDate.substring(0, 7) == selectedMonth &&
            !CategoryUtils.isSavingsCategory(e.category) &&
            !e.isTransfer)
        .toList();
    if (monthlyList.length >= 3) {
      final avg = monthlyList.map((e) => e.amount).reduce((a, b) => a + b) /
          monthlyList.length;
      final unusual = monthlyList.where((e) => e.amount > avg * 2).toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));
      for (final u in unusual.take(2)) {
        insights.add(Insight(
          message:
              'Unusual transaction: ${formatMoneyWithCurrency(u.amount)} at ${u.item}.',
          type: 'warning',
        ));
      }
    }

    // Budget alerts
    if (monthlyBudget > 0) {
      final used = totalExpenses / monthlyBudget;
      if (used >= 1) {
        insights.add(Insight(
          message: 'Monthly budget exceeded by ${formatMoneyWithCurrency(totalExpenses - monthlyBudget)}.',
          type: 'warning',
        ));
      } else if (used >= 0.8) {
        insights.add(Insight(
          message:
              'You have used ${(used * 100).toStringAsFixed(0)}% of your monthly budget.',
          type: 'warning',
        ));
      }
    }

    for (final entry in categoryBudgets.entries) {
      final spent = categoryTotals[entry.key] ?? 0;
      if (entry.value <= 0) continue;
      final ratio = spent / entry.value;
      if (ratio >= 1) {
        insights.add(Insight(
          message:
              '${entry.key} budget exceeded (${formatMoneyWithCurrency(spent)} / ${formatMoneyWithCurrency(entry.value)}).',
          type: 'warning',
        ));
      } else if (ratio >= 0.8) {
        insights.add(Insight(
          message:
              '${entry.key} budget at ${(ratio * 100).toStringAsFixed(0)}%.',
          type: 'info',
        ));
      }
    }

    if (insights.isEmpty) {
      insights.add(Insight(
        message: 'Spending looks steady this month. Keep tracking!',
        type: 'success',
      ));
    }

    return insights.take(8).toList();
  }

  String _previousMonth(String month) {
    final parts = month.split('-');
    var y = int.parse(parts[0]);
    var m = int.parse(parts[1]);
    m--;
    if (m < 1) {
      m = 12;
      y--;
    }
    return '$y-${m.toString().padLeft(2, '0')}';
  }

  double _monthSpending(List<Expense> expenses, String month) {
    return expenses
        .where((e) =>
            e.expenseDate.substring(0, 7) == month &&
            !CategoryUtils.isSavingsCategory(e.category) &&
            !e.isTransfer)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  Map<String, double> _categoryTotalsForMonth(
    List<Expense> expenses,
    String month,
  ) {
    final totals = <String, double>{};
    for (final e in expenses) {
      if (e.expenseDate.substring(0, 7) != month) continue;
      if (CategoryUtils.isSavingsCategory(e.category) || e.isTransfer) continue;
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }
}

import '../models/expense.dart';
import '../models/income.dart';
import '../services/balance_service.dart';
import '../utils/category_utils.dart';
import '../widgets/expense_filter_bar.dart';

List<Expense> applyExpenseFilters(
  List<Expense> expenses,
  String selectedMonth,
  ExpenseFilterState filter, {
  bool investmentsOnly = false,
}) {
  var list = expenses.where((expense) {
    final expenseMonth = expense.expenseDate.substring(0, 7);
    if (expenseMonth != selectedMonth) return false;

    final isInvestment = CategoryUtils.isSavingsCategory(expense.category);
    if (investmentsOnly) return isInvestment;
    if (!investmentsOnly && isInvestment) return false;

    if (!filter.showTransfers && expense.isTransfer) return false;

    if (filter.categoryFilter != null &&
        expense.category != filter.categoryFilter) {
      return false;
    }

    if (filter.paymentFilter != null &&
        expense.paymentMethod != filter.paymentFilter) {
      return false;
    }

    if (filter.minAmount != null && expense.amount < filter.minAmount!) {
      return false;
    }

    if (filter.maxAmount != null && expense.amount > filter.maxAmount!) {
      return false;
    }

    if (filter.searchQuery.isNotEmpty) {
      final q = filter.searchQuery.toLowerCase();
      if (!expense.item.toLowerCase().contains(q) &&
          !expense.category.toLowerCase().contains(q) &&
          !expense.notes.toLowerCase().contains(q)) {
        return false;
      }
    }

    return true;
  }).toList();

  switch (filter.sort) {
    case ExpenseSort.dateDesc:
      list.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    case ExpenseSort.dateAsc:
      list.sort((a, b) => a.expenseDate.compareTo(b.expenseDate));
    case ExpenseSort.amountDesc:
      list.sort((a, b) => b.amount.compareTo(a.amount));
    case ExpenseSort.amountAsc:
      list.sort((a, b) => a.amount.compareTo(b.amount));
  }

  return list;
}

List<Income> applyIncomeFilters(
  List<Income> incomes,
  String selectedMonth,
  ExpenseFilterState filter,
) {
  var list = incomes.where((income) {
    if (income.paymentMethod == 'Manual') {
      if (income.month != selectedMonth) return false;
      if (income.amount <= 0) return false;
    } else if (income.source == BalanceService.broughtForwardSource) {
      if (income.month != selectedMonth) return false;
    } else {
      if (income.incomeDate.isEmpty) return false;
      if (income.incomeDate.substring(0, 7) != selectedMonth) return false;
    }

    if (filter.categoryFilter != null &&
        income.category != filter.categoryFilter) {
      return false;
    }

    if (filter.paymentFilter != null &&
        income.paymentMethod != filter.paymentFilter) {
      return false;
    }

    if (filter.minAmount != null && income.amount < filter.minAmount!) {
      return false;
    }

    if (filter.maxAmount != null && income.amount > filter.maxAmount!) {
      return false;
    }

    if (filter.searchQuery.isNotEmpty) {
      final q = filter.searchQuery.toLowerCase();
      if (!income.source.toLowerCase().contains(q) &&
          !income.category.toLowerCase().contains(q) &&
          !income.paymentMethod.toLowerCase().contains(q)) {
        return false;
      }
    }

    return true;
  }).toList();

  list.sort((a, b) {
    if (a.source == BalanceService.broughtForwardSource) return -1;
    if (b.source == BalanceService.broughtForwardSource) return 1;
    switch (filter.sort) {
      case ExpenseSort.dateDesc:
        return b.incomeDate.compareTo(a.incomeDate);
      case ExpenseSort.dateAsc:
        return a.incomeDate.compareTo(b.incomeDate);
      case ExpenseSort.amountDesc:
        return b.amount.compareTo(a.amount);
      case ExpenseSort.amountAsc:
        return a.amount.compareTo(b.amount);
    }
  });

  return list;
}

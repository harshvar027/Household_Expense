import 'package:flutter_test/flutter_test.dart';
import 'package:household_expense/models/income.dart';
import 'package:household_expense/services/balance_service.dart';
import 'package:household_expense/utils/expense_filter_utils.dart';
import 'package:household_expense/widgets/expense_filter_bar.dart';

Income _income({
  int? id,
  String incomeDate = '',
  String? month,
  String source = 'Manual',
  double amount = 1000,
}) {
  return Income(
    id: id,
    incomeDate: incomeDate,
    month: month,
    category: 'Income',
    source: source,
    amount: amount,
    paymentMethod: 'Manual',
  );
}

void main() {
  group('applyIncomeFilters', () {
    const month = '2026-07';
    final filter = ExpenseFilterState();

    test('includes manual income for the selected month', () {
      final result = applyIncomeFilters(
        [
          _income(month: month, amount: 50000, source: 'Salary'),
          _income(month: '2026-06', amount: 40000),
        ],
        month,
        filter,
      );

      expect(result.length, 1);
      expect(result.first.amount, 50000);
      expect(result.first.source, 'Salary');
    });

    test('excludes zero manual income', () {
      final result = applyIncomeFilters(
        [_income(month: month, amount: 0)],
        month,
        filter,
      );
      expect(result, isEmpty);
    });

    test('still includes dated bank income', () {
      final result = applyIncomeFilters(
        [
          Income(
            incomeDate: '2026-07-15',
            month: month,
            category: 'Income',
            source: 'Salary credit',
            amount: 12000,
            paymentMethod: 'Bank',
          ),
        ],
        month,
        filter,
      );

      expect(result.length, 1);
      expect(result.first.source, 'Salary credit');
    });

    test('includes balance brought forward for month', () {
      final result = applyIncomeFilters(
        [
          _income(
            month: month,
            incomeDate: '2026-07-01',
            source: BalanceService.broughtForwardSource,
            amount: 2500,
          ),
        ],
        month,
        filter,
      );

      expect(result.length, 1);
      expect(result.first.source, BalanceService.broughtForwardSource);
    });
  });
}

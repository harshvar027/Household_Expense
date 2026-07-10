import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:household_expense/widgets/money_amount.dart';

/// Mirrors the balance rule used on the dashboard:
/// balance = income - expenses - investments.
double _balance({
  required double income,
  required double expenses,
  required double investments,
}) =>
    income - expenses - investments;

/// Mirrors budget-used percentage guard from main.dart.
double _budgetUsedPct(double totalExpenses, double monthlyBudget) {
  if (monthlyBudget == 0) return 0;
  return (totalExpenses / monthlyBudget) * 100;
}

void main() {
  group('MoneyAmount.format', () {
    test('credit and debit prefixes with rupee symbol', () {
      expect(MoneyAmount.format(1200, MoneyFlow.credit), '+₹1200.00');
      expect(MoneyAmount.format(1200, MoneyFlow.debit), '-₹1200.00');
    });

    test('handles zero and rounding', () {
      expect(MoneyAmount.format(0, MoneyFlow.credit), '+₹0.00');
      expect(MoneyAmount.format(1234.6, MoneyFlow.debit), '-₹1234.60');
    });

    test('no rupee symbol variant', () {
      expect(MoneyAmount.format(50, MoneyFlow.credit, showCurrency: false), '+50.00');
    });

    test('negative input is shown via abs value', () {
      // format uses amount.abs(), so sign comes from flow only.
      expect(MoneyAmount.format(-500, MoneyFlow.debit), '-₹500.00');
    });
  });

  group('Balance math with random figures', () {
    test('10000 random income/expense/investment combos stay consistent', () {
      final rng = Random(42);
      for (var i = 0; i < 10000; i++) {
        final income = rng.nextDouble() * 500000;
        final expenses = rng.nextDouble() * 500000;
        final investments = rng.nextDouble() * 200000;

        final balance = _balance(
          income: income,
          expenses: expenses,
          investments: investments,
        );

        // Reconstruct income from the balance identity.
        expect(
          balance + expenses + investments,
          closeTo(income, 1e-6),
        );

        // Balance is negative only when outflow exceeds income.
        expect(balance < 0, (expenses + investments) > income);
      }
    });

    test('budget used percentage never divides by zero', () {
      final rng = Random(7);
      expect(_budgetUsedPct(1000, 0), 0);
      for (var i = 0; i < 5000; i++) {
        final expenses = rng.nextDouble() * 100000;
        final budget = rng.nextDouble() * 100000;
        final pct = _budgetUsedPct(expenses, budget);
        expect(pct.isFinite, isTrue);
        expect(pct, greaterThanOrEqualTo(0));
        if (budget > 0) {
          expect(pct, closeTo(expenses / budget * 100, 1e-6));
        }
      }
    });
  });
}

import '../database/database_helper.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/recurring_transaction.dart';

class RecurringService {
  static final RecurringService instance = RecurringService._();
  RecurringService._();

  final _db = DatabaseHelper.instance;

  Future<List<RecurringTransaction>> processMonth(String month) async {
    final recurring = await _db.getActiveRecurring();
    final missing = <RecurringTransaction>[];

    for (final r in recurring) {
      if (r.lastGeneratedMonth == month) continue;

      final exists = await _db.recurringExistsForMonth(r, month);
      if (exists) {
        await _db.markRecurringGenerated(r.id!, month);
        continue;
      }

      final parts = month.split('-');
      final year = int.parse(parts[0]);
      final mon = int.parse(parts[1]);
      final day = r.dayOfMonth.clamp(1, 28);
      final date =
          '${year.toString().padLeft(4, '0')}-${mon.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

      if (r.isIncome) {
        await _db.insertIncome(
          Income(
            incomeDate: date,
            month: month,
            category: r.category,
            source: r.item,
            amount: r.amount,
            paymentMethod: r.paymentMethod,
          ),
        );
      } else {
        await _db.insertExpense(
          Expense(
            expenseDate: date,
            category: r.category,
            item: r.item,
            amount: r.amount,
            paymentMethod: r.paymentMethod,
            memberId: r.memberId,
            accountId: r.accountId,
            notes: 'recurring',
          ),
        );
      }

      await _db.markRecurringGenerated(r.id!, month);
    }

    for (final r in recurring) {
      if (r.isIncome) continue;
      final today = DateTime.now();
      final parts = month.split('-');
      final monthDate = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      final isPastDue = today.isAfter(
        DateTime(monthDate.year, monthDate.month, r.dayOfMonth),
      );
      if (!isPastDue) continue;

      final hasReal = await _db.hasRealMatchForRecurring(r, month);
      if (!hasReal) missing.add(r);
    }

    return missing;
  }
}

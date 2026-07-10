import '../database/database_helper.dart';

class BalanceService {
  static const broughtForwardSource = DatabaseHelper.balanceBroughtForwardSource;

  static Future<void> ensureBroughtForward(String month) async {
    final previous = previousMonthKey(month);
    if (previous == null) return;

    final closingBalance =
        await DatabaseHelper.instance.calculateMonthBalance(previous);

    if (closingBalance == 0) {
      await DatabaseHelper.instance.deleteBalanceBroughtForward(month);
      return;
    }

    await DatabaseHelper.instance.upsertBalanceBroughtForward(
      month: month,
      amount: closingBalance,
      incomeDate: lastDayOfMonth(previous),
    );
  }

  static Future<void> syncAdjacentMonths(String month) async {
    await ensureBroughtForward(month);
    final next = nextMonthKey(month);
    if (next != null) {
      await ensureBroughtForward(next);
    }
  }

  /// After deleting a month's records, rebuild B/F for that month and the next ones
  /// that depend on its closing balance.
  static Future<void> resyncAfterMonthDelete(String month) async {
    await ensureBroughtForward(month);
    var cursor = nextMonthKey(month);
    // A couple of following months is enough for normal navigation; chain stays consistent.
    for (var i = 0; i < 3 && cursor != null; i++) {
      await ensureBroughtForward(cursor);
      cursor = nextMonthKey(cursor);
    }
  }

  static String? previousMonthKey(String month) {
    final parts = month.split('-');
    if (parts.length != 2) return null;

    var year = int.tryParse(parts[0]);
    var monthNum = int.tryParse(parts[1]);
    if (year == null || monthNum == null) return null;

    monthNum--;
    if (monthNum < 1) {
      monthNum = 12;
      year--;
    }

    return '$year-${monthNum.toString().padLeft(2, '0')}';
  }

  static String? nextMonthKey(String month) {
    final parts = month.split('-');
    if (parts.length != 2) return null;

    var year = int.tryParse(parts[0]);
    var monthNum = int.tryParse(parts[1]);
    if (year == null || monthNum == null) return null;

    monthNum++;
    if (monthNum > 12) {
      monthNum = 1;
      year++;
    }

    return '$year-${monthNum.toString().padLeft(2, '0')}';
  }

  static String lastDayOfMonth(String month) {
    final parts = month.split('-');
    final year = int.parse(parts[0]);
    final monthNum = int.parse(parts[1]);
    final last = DateTime(year, monthNum + 1, 0);
    return '${last.year.toString().padLeft(4, '0')}-'
        '${last.month.toString().padLeft(2, '0')}-'
        '${last.day.toString().padLeft(2, '0')}';
  }
}

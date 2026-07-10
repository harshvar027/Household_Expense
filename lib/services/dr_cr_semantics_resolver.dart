import 'amount_parser.dart';
import 'header_detector.dart';

/// Chooses standard vs inverted DR/CR semantics by matching balance deltas.
class DrCrSemanticsResolver {
  /// Returns `true` when inverted semantics fit better, `false` for standard,
  /// or `null` when balance data is insufficient.
  static bool? resolveFromBalances({
    required List<List<dynamic>> rows,
    required int headerIndex,
    required HeaderDetector detector,
  }) {
    if (detector.balanceColumn == -1) return null;
    if (detector.debitColumn == -1 && detector.creditColumn == -1) {
      return null;
    }

    var standardMatches = 0;
    var invertedMatches = 0;
    double? previousBalance;

    for (var i = headerIndex + 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length <= detector.balanceColumn) continue;

      final balance = AmountParser.parse(row[detector.balanceColumn]);
      if (balance == null) continue;

      final dr = detector.debitColumn != -1 && row.length > detector.debitColumn
          ? AmountParser.parse(row[detector.debitColumn])
          : null;
      final cr = detector.creditColumn != -1 && row.length > detector.creditColumn
          ? AmountParser.parse(row[detector.creditColumn])
          : null;

      final drVal = dr ?? 0;
      final crVal = cr ?? 0;
      if (drVal == 0 && crVal == 0) {
        previousBalance = balance;
        continue;
      }

      if (previousBalance == null) {
        previousBalance = balance;
        continue;
      }

      final standardDelta = crVal - drVal;
      final invertedDelta = drVal - crVal;

      if ((previousBalance + standardDelta - balance).abs() < 0.02) {
        standardMatches++;
      }
      if ((previousBalance + invertedDelta - balance).abs() < 0.02) {
        invertedMatches++;
      }

      previousBalance = balance;
    }

    if (standardMatches == 0 && invertedMatches == 0) return null;
    if (standardMatches == invertedMatches) return null;
    return invertedMatches > standardMatches;
  }
}

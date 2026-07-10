import 'amount_parser.dart';
import 'header_detector.dart';
import 'statement_amount_inferrer.dart';
import 'transaction_parser.dart';

/// Scores candidate statement tables so the best layout wins across banks.
class StatementLayoutScorer {
  StatementLayoutScore? score(List<List<dynamic>> rows) {
    if (rows.length < 2) return null;

    final headerIndex = HeaderDetector.findHeaderRowIndex(rows);
    if (headerIndex == null) return null;

    final detector = HeaderDetector()..detect(rows[headerIndex]);
    if (!detector.isValid()) return null;

    var transactionCount = 0;
    var balanceMatches = 0;
    var amountColumnHits = 0;
    double? previousBalance;

    for (var i = headerIndex + 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      final firstCell = row.first.toString().trim().toLowerCase();
      if (_isSummaryRow(firstCell)) continue;

      if (row.length <= detector.dateColumn ||
          row.length <=
              detector.descriptionColumn + detector.descriptionSpan - 1) {
        continue;
      }

      final date = TransactionParser().parseDate(
        row[detector.dateColumn].toString().trim(),
      );
      if (date == null) continue;

      final description = _readDescription(row, detector);
      if (description.isEmpty || description == '-') continue;

      final inferred = StatementAmountInferrer.infer(
        row: row,
        detector: detector,
        previousBalance: previousBalance,
        description: description,
      );
      if (inferred == null) continue;

      transactionCount++;
      if (inferred.usedExplicitColumn) amountColumnHits++;

      if (detector.balanceColumn != -1 && row.length > detector.balanceColumn) {
        final balance = AmountParser.parse(row[detector.balanceColumn]);
        if (balance != null && previousBalance != null) {
          final delta = inferred.isDebit ? -inferred.amount : inferred.amount;
          if ((previousBalance + delta - balance).abs() < 0.02) {
            balanceMatches++;
          }
        }
        if (balance != null && balance > 0) {
          previousBalance = balance;
        }
      } else if (inferred.balanceAfter != null) {
        if (previousBalance != null) {
          final delta = inferred.isDebit ? -inferred.amount : inferred.amount;
          if ((previousBalance + delta - inferred.balanceAfter!).abs() < 0.02) {
            balanceMatches++;
          }
        }
        previousBalance = inferred.balanceAfter;
      }
    }

    if (transactionCount == 0) return null;

    final balanceRatio = transactionCount <= 1
        ? 0.0
        : balanceMatches / (transactionCount - 1);
    final explicitRatio = amountColumnHits / transactionCount;
    final headerBonus = detector.balanceColumn != -1 ? 4.0 : 0.0;
    final dualAmountBonus =
        detector.debitColumn != -1 && detector.creditColumn != -1 ? 3.0 : 0.0;

    final score = (transactionCount * 10) +
        (balanceMatches * 8) +
        (balanceRatio * 20) +
        (explicitRatio * 6) +
        headerBonus +
        dualAmountBonus;

    return StatementLayoutScore(
      rows: rows,
      headerIndex: headerIndex,
      transactionCount: transactionCount,
      balanceMatches: balanceMatches,
      score: score,
    );
  }

  String _readDescription(List<dynamic> row, HeaderDetector detector) {
    final parts = <String>[];
    for (var c = 0; c < detector.descriptionSpan; c++) {
      final idx = detector.descriptionColumn + c;
      if (idx >= row.length) break;
      final part = row[idx].toString().trim();
      if (part.isNotEmpty && part != '-') parts.add(part);
    }
    return parts.join(' ');
  }

  bool _isSummaryRow(String firstCell) {
    return firstCell.contains('opening') ||
        firstCell.contains('closing') ||
        firstCell.contains('generated') ||
        firstCell.contains('total') ||
        firstCell.contains('statement') ||
        firstCell.contains('brought forward') ||
        firstCell.contains('carried forward');
  }
}

class StatementLayoutScore {
  final List<List<dynamic>> rows;
  final int headerIndex;
  final int transactionCount;
  final int balanceMatches;
  final double score;

  const StatementLayoutScore({
    required this.rows,
    required this.headerIndex,
    required this.transactionCount,
    required this.balanceMatches,
    required this.score,
  });
}

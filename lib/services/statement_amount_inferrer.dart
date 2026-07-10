import 'amount_parser.dart';
import 'header_detector.dart';

class InferredTransactionAmount {
  final double amount;
  final bool isDebit;
  final bool usedExplicitColumn;
  final double? balanceAfter;

  const InferredTransactionAmount({
    required this.amount,
    required this.isDebit,
    required this.usedExplicitColumn,
    this.balanceAfter,
  });
}

/// Reads debit/credit from named columns, then falls back to trailing amounts
/// and running-balance reconciliation.
class StatementAmountInferrer {
  static InferredTransactionAmount? infer({
    required List<dynamic> row,
    required HeaderDetector detector,
    required double? previousBalance,
    required String description,
  }) {
    final explicit = _readExplicitAmount(row, detector);
    if (explicit != null) return explicit;

    final trailing = _readTrailingAmounts(row, detector);
    if (trailing.isEmpty) return null;

    if (trailing.length >= 2) {
      final txnAmount = trailing[trailing.length - 2];
      final balanceAfter = trailing.last;
      final isDebit = _inferDebitFromBalance(
        amount: txnAmount,
        balanceAfter: balanceAfter,
        previousBalance: previousBalance,
        description: description,
      );
      if (isDebit == null) return null;
      return InferredTransactionAmount(
        amount: txnAmount,
        isDebit: isDebit,
        usedExplicitColumn: false,
        balanceAfter: balanceAfter,
      );
    }

    final only = trailing.first;
    return InferredTransactionAmount(
      amount: only,
      isDebit: !_looksLikeCredit(description),
      usedExplicitColumn: false,
    );
  }

  static InferredTransactionAmount? _readExplicitAmount(
    List<dynamic> row,
    HeaderDetector detector,
  ) {
    if (detector.invertedDrCrSemantics) {
      final credit = _columnAmount(row, detector.creditColumn);
      if (credit != null) {
        return InferredTransactionAmount(
          amount: credit,
          isDebit: true,
          usedExplicitColumn: true,
        );
      }

      final debit = _columnAmount(row, detector.debitColumn);
      if (debit != null) {
        return InferredTransactionAmount(
          amount: debit,
          isDebit: false,
          usedExplicitColumn: true,
        );
      }
      return null;
    }

    final debit = _columnAmount(row, detector.debitColumn);
    if (debit != null) {
      return InferredTransactionAmount(
        amount: debit,
        isDebit: true,
        usedExplicitColumn: true,
      );
    }

    final credit = _columnAmount(row, detector.creditColumn);
    if (credit != null) {
      return InferredTransactionAmount(
        amount: credit,
        isDebit: false,
        usedExplicitColumn: true,
      );
    }

    if (detector.amountColumn != -1 && row.length > detector.amountColumn) {
      final amount = AmountParser.parse(row[detector.amountColumn]);
      if (amount != null && amount > 0) {
        final typeText = row.length > detector.amountColumn + 1
            ? row[detector.amountColumn + 1].toString().toLowerCase()
            : '';
        final isDebit = typeText.contains('dr') || typeText.contains('debit');
        return InferredTransactionAmount(
          amount: amount,
          isDebit: isDebit,
          usedExplicitColumn: true,
        );
      }
    }

    return null;
  }

  static double? _columnAmount(List<dynamic> row, int column) {
    if (column == -1 || row.length <= column) return null;
    final value = AmountParser.parse(row[column]);
    if (value == null || value <= 0) return null;
    return value;
  }

  static List<double> _readTrailingAmounts(
    List<dynamic> row,
    HeaderDetector detector,
  ) {
    final start = detector.descriptionColumn + detector.descriptionSpan;
    final amounts = <double>[];
    for (var i = start; i < row.length; i++) {
      if (i == detector.debitColumn || i == detector.creditColumn) continue;
      final value = AmountParser.parse(row[i]);
      if (value != null && value > 0) amounts.add(value);
    }
    return amounts;
  }

  static bool? _inferDebitFromBalance({
    required double amount,
    required double balanceAfter,
    required double? previousBalance,
    required String description,
  }) {
    if (previousBalance != null) {
      if ((previousBalance + amount - balanceAfter).abs() < 0.02) return false;
      if ((previousBalance - amount - balanceAfter).abs() < 0.02) return true;
    }
    if (_looksLikeCredit(description)) return false;
    return true;
  }

  static bool _looksLikeCredit(String description) {
    final lower = description.toLowerCase();
    return lower.contains('salary') ||
        lower.contains('credit') ||
        lower.contains('deposit') ||
        lower.contains('refund') ||
        lower.contains('int.pd') ||
        lower.contains('interest') ||
        lower.contains('credited') ||
        lower.contains('neft cr') ||
        lower.contains('imps-in') ||
        lower.contains('upi/in/');
  }
}

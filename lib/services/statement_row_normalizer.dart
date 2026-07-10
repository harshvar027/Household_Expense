import 'amount_parser.dart';
import 'header_detector.dart';

/// Normalizes ragged statement rows once the header layout is known.
class StatementRowNormalizer {
  static List<List<String>> normalize(List<List<dynamic>> rows) {
    final headerIndex = HeaderDetector.findHeaderRowIndex(rows);
    if (headerIndex == null) {
      return rows.map((row) => row.map((c) => c.toString()).toList()).toList();
    }

    var normalized =
        rows.map((row) => row.map((c) => c.toString()).toList()).toList();
    normalized = _mergeSplitDescriptionColumns(normalized, headerIndex);
    normalized = _padSparseAmountColumns(normalized, headerIndex);
    return normalized;
  }

  static List<List<String>> _mergeSplitDescriptionColumns(
    List<List<String>> rows,
    int headerIdx,
  ) {
    final header =
        rows[headerIdx].map((cell) => cell.toLowerCase().trim()).toList();
    final transactionIdx = header.indexWhere((h) => h == 'transaction');
    if (transactionIdx == -1 ||
        transactionIdx + 1 >= header.length ||
        header[transactionIdx + 1] != 'reference') {
      return rows;
    }

    final merged = <List<String>>[];
    for (final row in rows) {
      if (row.length <= transactionIdx + 1) {
        merged.add(row);
        continue;
      }
      merged.add([
        ...row.take(transactionIdx),
        '${row[transactionIdx]} ${row[transactionIdx + 1]}'.trim(),
        ...row.skip(transactionIdx + 2),
      ]);
    }
    return merged;
  }

  static List<List<String>> _padSparseAmountColumns(
    List<List<String>> rows,
    int headerIdx,
  ) {
    final header = rows[headerIdx];
    final detector = HeaderDetector()..detect(header);
    if (detector.creditColumn == -1 || detector.debitColumn == -1) {
      return rows;
    }

    final expectedLen = header.length;
    final padded = <List<String>>[];
    double? previousBalance;

    for (var i = 0; i < rows.length; i++) {
      var row = List<String>.from(rows[i]);
      if (i > headerIdx && row.length == expectedLen - 1) {
        final prefix = row.take(detector.creditColumn).toList();
        final tail = row.skip(detector.creditColumn).toList();
        if (tail.length == 2) {
          final amount = AmountParser.parse(tail[0]);
          final balance = AmountParser.parse(tail[1]);
          if (amount != null &&
              amount > 0 &&
              balance != null &&
              balance > 0) {
            var isCredit = false;
            if (previousBalance != null) {
              isCredit =
                  (previousBalance + amount - balance).abs() < 0.02;
            }
            row = isCredit
                ? [...prefix, tail[0], '', tail[1]]
                : [...prefix, '', tail[0], tail[1]];
          }
        }
      }

      if (i > headerIdx &&
          detector.balanceColumn != -1 &&
          row.length > detector.balanceColumn) {
        final balance = AmountParser.parse(row[detector.balanceColumn]);
        if (balance != null && balance > 0) previousBalance = balance;
      }

      padded.add(row);
    }

    return padded;
  }
}

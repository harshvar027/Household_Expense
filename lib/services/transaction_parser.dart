import '../config/region_config.dart';
import '../models/bank_profile.dart';
import '../models/bank_transaction.dart';
import '../services/app_locale_service.dart';
import 'amount_parser.dart';
import 'dr_cr_semantics_resolver.dart';
import 'header_detector.dart';
import 'statement_amount_inferrer.dart';
import 'statement_row_normalizer.dart';

class TransactionParser {
  final BankProfile? bankProfile;

  TransactionParser({this.bankProfile});

  static final RegExp _datePattern = RegExp(
    r'^(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})$',
  );
  static final RegExp _monthNameDatePattern = RegExp(
    r'^(\d{1,2})[-/\s]([A-Za-z]{3})[-/\s](\d{2,4})$',
    caseSensitive: false,
  );
  static final RegExp _isoDatePattern = RegExp(
    r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})$',
  );

  List<BankTransaction> parse(List<List<dynamic>> csvRows) {
    final normalized = StatementRowNormalizer.normalize(csvRows);
    final headerIndex = HeaderDetector.findHeaderRowIndex(normalized);
    if (headerIndex == null) {
      throw Exception('Could not find statement header row.');
    }

    final detector = HeaderDetector()
      ..detect(normalized[headerIndex]);

    final balanceSemantics = DrCrSemanticsResolver.resolveFromBalances(
      rows: normalized,
      headerIndex: headerIndex,
      detector: detector,
    );
    if (balanceSemantics != null) {
      detector.invertedDrCrSemantics = balanceSemantics;
    }

    final transactions = <BankTransaction>[];
    double? previousBalance;

    for (int i = headerIndex + 1; i < normalized.length; i++) {
      final row = normalized[i];
      if (row.isEmpty) continue;

      final firstCell = row.first.toString().trim().toLowerCase();
      if (_isSummaryRow(firstCell)) continue;

      if (row.length <= detector.dateColumn ||
          row.length <=
              detector.descriptionColumn + detector.descriptionSpan - 1) {
        continue;
      }

      final dateText = row[detector.dateColumn].toString().trim();
      final date = parseDate(dateText);
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

      if (detector.balanceColumn != -1 && row.length > detector.balanceColumn) {
        final balance = AmountParser.parse(row[detector.balanceColumn]);
        if (balance != null && balance > 0) previousBalance = balance;
      } else if (inferred.balanceAfter != null) {
        previousBalance = inferred.balanceAfter;
      }

      transactions.add(
        BankTransaction(
          date: date,
          description: description,
          amount: inferred.amount,
          isDebit: inferred.isDebit,
        ),
      );
    }

    if (transactions.isEmpty) {
      throw Exception('No transactions found in the statement.');
    }

    return transactions;
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

  DateTime? parseDate(String value) {
    value = value.trim();

    final monthMatch = _monthNameDatePattern.firstMatch(value);
    if (monthMatch != null) {
      final day = int.parse(monthMatch.group(1)!);
      final month = _monthFromAbbrev(monthMatch.group(2)!);
      var year = int.parse(monthMatch.group(3)!);
      if (year < 100) year += 2000;
      if (month == null || day < 1 || day > 31) return null;
      return DateTime(year, month, day);
    }

    final isoMatch = _isoDatePattern.firstMatch(value);
    if (isoMatch != null) {
      final year = int.parse(isoMatch.group(1)!);
      final month = int.parse(isoMatch.group(2)!);
      final day = int.parse(isoMatch.group(3)!);
      if (month < 1 || month > 12 || day < 1 || day > 31) return null;
      return DateTime(year, month, day);
    }

    final match = _datePattern.firstMatch(value);
    if (match == null) return null;

    final order = AppLocaleService.instance.config.dateOrder;
    int day;
    int month;
    if (order == DateOrder.mdy) {
      month = int.parse(match.group(1)!);
      day = int.parse(match.group(2)!);
    } else {
      day = int.parse(match.group(1)!);
      month = int.parse(match.group(2)!);
    }
    var year = int.parse(match.group(3)!);
    if (year < 100) {
      year += 2000;
    }

    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }

    return DateTime(year, month, day);
  }

  int? _monthFromAbbrev(String abbrev) {
    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    return months[abbrev.toLowerCase().substring(0, 3)];
  }
}

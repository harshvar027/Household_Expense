import 'package:csv/csv.dart';

import '../models/bank_profile.dart';
import 'header_detector.dart';
import 'statement_layout_scorer.dart';
import 'statement_row_normalizer.dart';

/// Converts extracted PDF text into tabular rows for the shared parser.
class PdfStatementParser {
  static final RegExp _dateStart = RegExp(
    r'^(\d{1,2}[/\-.]\d{1,2}[/\-.]\d{2,4}|\d{4}[/\-.]\d{1,2}[/\-.]\d{1,2}|\d{1,2}[/\-.][A-Za-z]{3}[/\-.]\d{2,4}|\d{1,2}\s+[A-Za-z]{3}\s+\d{2,4})\s*(.*)$',
    caseSensitive: false,
  );
  static final RegExp _dateOnly = RegExp(
    r'^(\d{1,2}[/\-.]\d{1,2}[/\-.]\d{2,4}|\d{4}[/\-.]\d{1,2}[/\-.]\d{1,2}|\d{1,2}[/\-.][A-Za-z]{3}[/\-.]\d{2,4}|\d{1,2}\s+[A-Za-z]{3}\s+\d{2,4})$',
    caseSensitive: false,
  );
  static final RegExp _amountToken = RegExp(
    r'([\d,]+\.\d{2}|[\d,]+\.[\d]{1,2})(?:\s*(?:Dr|DR|Cr|CR))?',
  );
  static final RegExp _globalTxnPattern = RegExp(
    r'(\d{1,2}[/\-.]\d{1,2}[/\-.]\d{2,4}|\d{4}[/\-.]\d{1,2}[/\-.]\d{1,2}|\d{1,2}[/\-.][A-Za-z]{3}[/\-.]\d{2,4})'
    r'\s+'
    r'(.{3,200}?)'
    r'\s+'
    r'([\d,]+\.\d{2})'
    r'(?:\s+([\d,]+\.\d{2}))?',
    caseSensitive: false,
    dotAll: true,
  );

  List<List<String>> toRows(String text, {BankId? bankId}) {
    final normalized = _normalizeText(text);
    final rawLines = _toLines(normalized);
    final isVertical = _looksVertical(rawLines);
    final lines =
        isVertical ? rawLines : _mergeMultilineTransactions(rawLines);

    StatementLayoutScore? best;
    final scorer = StatementLayoutScorer();

    for (final strategy in _allStrategies(lines, normalized)) {
      try {
        final rows = StatementRowNormalizer.normalize(strategy());
        final result = scorer.score(rows);
        if (result == null) continue;
        if (best == null || result.score > best.score) {
          best = result;
        }
      } catch (_) {
        continue;
      }
    }

    if (best != null) {
      return best.rows
          .map((row) => row.map((cell) => cell.toString()).toList())
          .toList();
    }

    throw Exception(
      'Could not parse transactions from PDF text. '
      'Try exporting CSV or Excel from net banking, or ensure the PDF has '
      'selectable text (not a scanned image).',
    );
  }

  List<List<List<String>> Function()> _allStrategies(
    List<String> lines,
    String normalized,
  ) {
    return [
      () => _tryVerticalTableLayout(lines),
      () => _tryDelimitedRows(lines, ','),
      () => _tryDelimitedRows(lines, '\t'),
      () => _tryDelimitedRows(lines, '|'),
      () => _trySpacedColumns(lines),
      () => _trySingleSpaceColumns(lines),
      () => _parseLooseTransactionLines(lines),
      () => _tryGlobalExtraction(normalized),
    ];
  }

  String _normalizeText(String text) {
    var result = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    result = result.replaceAll(RegExp(r'[\u00A0\t]+'), ' ');
    result = result.replaceAllMapped(
      RegExp(r'(\d{2}[/\-.]\d{2}[/\-.]\d{4})([A-Za-z/])'),
      (m) => '${m[1]} ${m[2]}',
    );
    result = result.replaceAllMapped(
      RegExp(r'(\d{4}[/\-.]\d{2}[/\-.]\d{2})([A-Za-z/])'),
      (m) => '${m[1]} ${m[2]}',
    );
    result = result.replaceAllMapped(
      RegExp(r'([A-Za-z])(\d{2}[/\-.]\d{2})'),
      (m) => '${m[1]} ${m[2]}',
    );
    return result;
  }

  List<String> _toLines(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  List<String> _mergeMultilineTransactions(List<String> lines) {
    final merged = <String>[];
    final buffer = StringBuffer();

    void flush() {
      final value = buffer.toString().trim();
      buffer.clear();
      if (value.isNotEmpty) merged.add(value);
    }

    for (final line in lines) {
      final startsNewTxn = _dateStart.hasMatch(line) || _dateOnly.hasMatch(line);
      if (startsNewTxn && buffer.isNotEmpty) {
        flush();
      }

      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(line);

      if (_dateStart.hasMatch(buffer.toString()) &&
          _amountToken.allMatches(buffer.toString()).length >= 1) {
        flush();
      }
    }

    flush();

    final fixed = <String>[];
    for (final line in merged) {
      if (_isBalanceOnlyLine(line) && fixed.isNotEmpty) {
        fixed[fixed.length - 1] = '${fixed.last} $line';
      } else {
        fixed.add(line);
      }
    }

    return fixed.isNotEmpty ? fixed : lines;
  }

  bool _isBalanceOnlyLine(String line) {
    final trimmed = line.trim();
    final match = _amountToken.firstMatch(trimmed);
    if (match == null) return false;
    return match.group(0)!.trim() == trimmed;
  }

  List<List<String>> _tryDelimitedRows(List<String> lines, String delimiter) {
    const converter = CsvToListConverter(
      fieldDelimiter: ',',
      eol: '\n',
      shouldParseNumbers: false,
      allowInvalid: true,
    );

    if (delimiter == ',') {
      final rows = lines
          .map((line) {
            final parsed = converter.convert('$line\n');
            if (parsed.isEmpty) return <String>[];
            return parsed.first.map((c) => c.toString().trim()).toList();
          })
          .where((row) => row.any((cell) => cell.isNotEmpty))
          .toList();
      if (HeaderDetector.findHeaderRowIndex(rows) != null) return rows;
      throw Exception('no header');
    }

    final rows = lines
        .map((line) => line.split(delimiter).map((c) => c.trim()).toList())
        .where((row) => row.any((cell) => cell.isNotEmpty))
        .toList();
    if (HeaderDetector.findHeaderRowIndex(rows) != null) return rows;
    throw Exception('no header');
  }

  List<List<String>> _trySpacedColumns(List<String> lines) {
    final rows = <List<String>>[];
    for (final line in lines) {
      final parts = line.split(RegExp(r'\s{2,}')).map((p) => p.trim()).toList();
      if (parts.length >= 4) rows.add(parts);
    }
    final headerIdx = HeaderDetector.findHeaderRowIndex(rows);
    if (headerIdx != null) return rows;
    throw Exception('no header');
  }

  List<List<String>> _trySingleSpaceColumns(List<String> lines) {
    final rows = <List<String>>[];
    for (final line in lines) {
      final parts = line.split(RegExp(r'\s+')).map((p) => p.trim()).toList();
      if (parts.length < 4) continue;
      if (!_dateStart.hasMatch(line) && !_dateOnly.hasMatch(parts.first)) {
        continue;
      }
      rows.add(parts);
    }
    if (HeaderDetector.findHeaderRowIndex(rows) != null) return rows;
    throw Exception('no header');
  }

  /// Handles PDFs that export each table cell on its own line.
  List<List<String>> _tryVerticalTableLayout(List<String> lines) {
    if (!_looksVertical(lines)) throw Exception('not vertical');

    final rows = <List<String>>[
      ['Date', 'Description', 'Debit', 'Credit', 'Balance'],
    ];

    double? previousBalance;
    var i = 0;
    while (i < lines.length) {
      final lower = lines[i].toLowerCase();
      if (_isNoiseLine(lower) ||
          _isHeaderFragment(lower) ||
          _isEmptyCellMarker(lines[i])) {
        i++;
        continue;
      }

      final dateMatch = _dateOnly.firstMatch(lines[i]) ??
          _dateStart.firstMatch(lines[i]);
      if (dateMatch == null) {
        i++;
        continue;
      }

      final date = dateMatch.group(1)!;
      i++;

      if (i < lines.length &&
          (_dateOnly.hasMatch(lines[i]) || _dateStart.hasMatch(lines[i]))) {
        i++;
      }

      final description = StringBuffer();
      final amounts = <String>[];

      while (i < lines.length) {
        final line = lines[i];
        final lineLower = line.toLowerCase();
        if (_isNoiseLine(lineLower) ||
            _isHeaderFragment(lineLower) ||
            _isEmptyCellMarker(line)) {
          i++;
          continue;
        }

        if (_dateOnly.hasMatch(line) || _dateStart.hasMatch(line)) break;

        final lineAmounts = _amountToken
            .allMatches(line)
            .map((m) => m.group(1)!)
            .where((a) => _parseAmount(a) > 0)
            .toList();

        if (lineAmounts.isNotEmpty) {
          amounts.addAll(lineAmounts);
          i++;
          if (amounts.length >= 2) break;
          continue;
        }

        if (_isBranchOrMetaLine(line)) {
          i++;
          continue;
        }

        if (line != '-' && line.isNotEmpty && !_isEmptyCellMarker(line)) {
          if (description.isNotEmpty) description.write(' ');
          description.write(line);
        }
        i++;
      }

      if (amounts.isEmpty) continue;

      final parsed = _splitAmounts(
        description: description.toString(),
        amounts: amounts,
        fullLine: '$date ${description.toString()} ${amounts.join(' ')}',
        previousBalance: previousBalance,
      );
      if (parsed == null) continue;

      rows.add([
        date,
        parsed.$1,
        parsed.$2 ?? '',
        parsed.$3 ?? '',
        parsed.$4 ?? '',
      ]);

      if (parsed.$4 != null) {
        previousBalance = _parseAmount(parsed.$4!);
      }
    }

    if (rows.length <= 1) throw Exception('no vertical rows');
    return rows;
  }

  bool _looksVertical(List<String> lines) {
    if (_hasVerticalColumnHeader(lines)) return true;

    var dateOnlyLines = 0;
    var dateAndAmountLines = 0;

    for (final line in lines) {
      final hasDate = _dateOnly.hasMatch(line) || _dateStart.hasMatch(line);
      final amountCount = _amountToken.allMatches(line).length;
      if (!hasDate) continue;
      if (amountCount == 0) {
        dateOnlyLines++;
      } else {
        dateAndAmountLines++;
      }
    }

    return dateOnlyLines >= 3 && dateOnlyLines > dateAndAmountLines;
  }

  bool _hasVerticalColumnHeader(List<String> lines) {
    final lowerLines =
        lines.map((line) => line.toLowerCase().trim()).toList();
    final hasDebit = lowerLines.any(
      (line) =>
          line == 'debit' ||
          line == 'dr' ||
          line == 'withdrawal' ||
          line.contains('withdrawal(dr)'),
    );
    final hasCredit = lowerLines.any(
      (line) =>
          line == 'credit' ||
          line == 'cr' ||
          line == 'deposit' ||
          line.contains('deposit(cr)'),
    );
    final hasBalance = lowerLines.any(
      (line) => line == 'balance' || line == 'bal' || line.contains('closing balance'),
    );
    final hasDate = lowerLines.any(
      (line) =>
          line == 'date' ||
          line.contains('txn date') ||
          line.contains('transaction date') ||
          line.contains('tran date'),
    );
    final hasDescription = lowerLines.any(
      (line) =>
          line == 'transaction reference' ||
          line.contains('narration') ||
          line.contains('particular') ||
          line.contains('description') ||
          line.contains('remarks'),
    );
    return hasDate && hasDebit && hasCredit && hasBalance && hasDescription;
  }

  List<List<String>> _parseLooseTransactionLines(List<String> lines) {
    final rows = <List<String>>[
      ['Date', 'Description', 'Debit', 'Credit', 'Balance'],
    ];

    double? previousBalance;
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (_isNoiseLine(lower)) continue;

      final match = _dateStart.firstMatch(line);
      if (match == null) continue;

      final date = match.group(1)!;
      var remainder = match.group(2)!.trim();
      final amounts = _amountToken
          .allMatches(remainder.isEmpty ? line : '$date $remainder')
          .map((m) => m.group(1)!)
          .where((a) => _parseAmount(a) > 0)
          .toList();

      if (amounts.isEmpty) continue;

      final parsed = _splitAmounts(
        description: remainder,
        amounts: amounts,
        fullLine: line,
        previousBalance: previousBalance,
      );
      if (parsed == null) continue;

      rows.add([
        date,
        parsed.$1,
        parsed.$2 ?? '',
        parsed.$3 ?? '',
        parsed.$4 ?? '',
      ]);

      if (parsed.$4 != null) {
        previousBalance = _parseAmount(parsed.$4!);
      }
    }

    if (rows.length <= 1) throw Exception('no loose rows');
    return rows;
  }

  List<List<String>> _tryGlobalExtraction(String text) {
    final rows = <List<String>>[
      ['Date', 'Description', 'Debit', 'Credit', 'Balance'],
    ];

    double? previousBalance;
    for (final match in _globalTxnPattern.allMatches(text)) {
      final date = match.group(1)!;
      final description = match.group(2)!.trim();
      final amount1 = match.group(3)!;
      final amount2 = match.group(4);

      if (_isNoiseLine(description.toLowerCase())) continue;

      final amounts = [amount1, if (amount2 != null) amount2];
      final parsed = _splitAmounts(
        description: description,
        amounts: amounts,
        fullLine: match.group(0)!,
        previousBalance: previousBalance,
      );
      if (parsed == null) continue;

      rows.add([
        date,
        parsed.$1,
        parsed.$2 ?? '',
        parsed.$3 ?? '',
        parsed.$4 ?? '',
      ]);

      if (parsed.$4 != null) {
        previousBalance = _parseAmount(parsed.$4!);
      }
    }

    if (rows.length <= 1) throw Exception('no global rows');
    return rows;
  }

  (String description, String? withdrawal, String? deposit, String? balance)?
      _splitAmounts({
    required String description,
    required List<String> amounts,
    required String fullLine,
    double? previousBalance,
  }) {
    String? withdrawal;
    String? deposit;
    String? balance;

    var desc = description;
    for (final amount in amounts) {
      desc = desc.replaceFirst(amount, '').trim();
    }
    desc = desc.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    if (desc.isEmpty) desc = 'Bank transaction';

    if (amounts.length >= 3) {
      balance = amounts.last;
      final middle = amounts[amounts.length - 2];
      final first = amounts[amounts.length - 3];
      if (_parseAmount(first) > 0) withdrawal = first;
      if (_parseAmount(middle) > 0) deposit = middle;
    } else if (amounts.length == 2) {
      balance = amounts.last;
      final txnAmount = amounts.first;
      final txnVal = _parseAmount(txnAmount);
      final balVal = _parseAmount(balance!);

      if (previousBalance != null) {
        if ((previousBalance + txnVal - balVal).abs() < 0.02) {
          deposit = txnAmount;
          return (desc, withdrawal, deposit, balance);
        }
        if ((previousBalance - txnVal - balVal).abs() < 0.02) {
          withdrawal = txnAmount;
          return (desc, withdrawal, deposit, balance);
        }
      }

      if (_looksLikeCredit(description: desc, amount: txnAmount) ||
          _lineLooksLikeCredit(fullLine)) {
        deposit = txnAmount;
      } else {
        withdrawal = txnAmount;
      }
    } else {
      final only = amounts.first;
      if (_looksLikeCredit(description: desc, amount: only) ||
          _lineLooksLikeCredit(fullLine)) {
        deposit = only;
      } else {
        withdrawal = only;
      }
    }

    if (withdrawal == null && deposit == null) return null;
    return (desc, withdrawal, deposit, balance);
  }

  double _parseAmount(String raw) {
    final cleaned = raw.replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? 0;
  }

  bool _looksLikeCredit({required String description, required String amount}) {
    final lower = description.toLowerCase();
    return lower.contains('salary') ||
        lower.contains('credit') ||
        lower.contains('deposit') ||
        lower.contains('refund') ||
        lower.contains('int.pd') ||
        lower.contains('interest') ||
        lower.contains('ach-c') ||
        lower.contains('dividend') ||
        lower.contains('redemption') ||
        lower.contains('neft/') && lower.contains('credit') ||
        lower.contains('received') ||
        lower.contains('imps-in') ||
        lower.contains('imps in') ||
        lower.contains('upi/in/') ||
        lower.contains('credited') ||
        lower.contains('by transfer') ||
        lower.contains('neft cr');
  }

  bool _lineLooksLikeCredit(String line) {
    final lower = line.toLowerCase();
    // Balance suffix like "4,34,483.47 CR" is not a credit transaction marker.
    if (RegExp(r'[\d,]+\.\d{2}\s*cr\s*$').hasMatch(lower.trim())) {
      return false;
    }
    return lower.contains(' cr') ||
        lower.endsWith('cr') ||
        lower.contains('credit') ||
        lower.contains('deposit');
  }

  bool _isBranchOrMetaLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed == '-') return true;
    if (RegExp(r'^\d{3,5}$').hasMatch(trimmed)) return true;
    return false;
  }

  bool _isHeaderFragment(String lower) {
    const exactHeaders = {
      'date',
      'value date',
      'transaction date',
      'tran date',
      'txn date',
      'post date',
      'branch',
      'code',
      'cheque',
      'number',
      'transaction description',
      'narration',
      'particulars',
      'particular',
      'withdrawal',
      'deposit',
      'debit',
      'credit',
      'balance',
      'description',
      'remarks',
      'details',
      'cheque no',
      'chq',
      'ref no',
      'transaction reference',
      'reference',
      'null',
    };

    if (exactHeaders.contains(lower)) return true;
    return lower.contains('ref no.') ||
        lower.contains('ref.no.') ||
        lower.startsWith('chq/');
  }

  bool _isEmptyCellMarker(String line) {
    final lower = line.trim().toLowerCase();
    return lower == 'null' || lower == '-' || lower == '0' || lower == '0.00';
  }

  bool _isNoiseLine(String lower) {
    return lower.contains('opening balance') ||
        lower.contains('closing balance') ||
        lower.contains('statement of account') ||
        lower.contains('statement for account') ||
        lower.contains('account statement') ||
        lower.contains('page ') ||
        lower.contains('continued') ||
        lower.contains('ifsc code') ||
        lower.contains('customer id') ||
        lower.contains('registered email') ||
        lower.contains('account number') ||
        lower.contains('branch name') ||
        (lower.contains('total') && lower.contains('transaction'));
  }
}

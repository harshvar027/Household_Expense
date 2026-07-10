import '../models/bank_profile.dart';

/// Detects the issuing bank from statement metadata, headers, or filename.
class BankDetector {
  BankProfile detect({
    required List<List<dynamic>> rows,
    String? fileName,
    String? rawText,
  }) {
    if (rawText != null) {
      final lower = rawText.toLowerCase();
      if (_containsAny(lower, [
        'state bank of india',
        'sbi.co.in',
        'sbin000',
        'sbin0',
      ])) {
        return BankProfile.sbi;
      }
    }

    final preamble = _preambleBlob(rows, fileName, rawText);
    final headerBlob = _headerBlob(rows);

    if (_containsAny(preamble, ['indusind bank', 'indb0', 'ifsc code :- indb'])) {
      return BankProfile.indusInd;
    }
    if (_containsAny(preamble, [
      'axis bank',
      'utib0',
      'ifsc code :- utib',
      'ifsc code: utib',
    ])) {
      return BankProfile.axis;
    }
    if (_containsAny(preamble, ['hdfc bank', 'hdfc0', 'ifsc code :- hdfc'])) {
      return BankProfile.hdfc;
    }
    if (_containsAny(preamble, [
      'icici bank',
      'icic0',
      'ifsc code :- icic',
    ])) {
      return BankProfile.icici;
    }
    if (_containsAny(preamble, [
      'state bank of india',
      'sbin0',
      'sbin000',
      'ifsc code :- sbin',
      'ifsc code: sbin',
      'sbi.co.in',
    ])) {
      return BankProfile.sbi;
    }
    if (_containsAny(preamble, [
      'bank of baroda',
      'barb0',
      'ifsc code :- barb',
    ])) {
      return BankProfile.bob;
    }
    if (_containsAny(preamble, [
      'punjab national bank',
      'punb0',
      'ifsc code :- punb',
    ])) {
      return BankProfile.pnb;
    }
    if (_containsAny(preamble, [
      'au small finance bank',
      'aubl0',
      'ifsc code :- aubl',
    ])) {
      return BankProfile.au;
    }
    if (_containsAny(preamble, [
      'central bank of india',
      'cbin0',
      'ifsc code: cbin',
      'ifsc code :- cbin',
    ])) {
      return BankProfile.cbi;
    }

    if (_containsAny(headerBlob, ['transaction remarks', 'withdrawal amount(inr)'])) {
      return BankProfile.icici;
    }
    if (_containsAny(headerBlob, [
      'withdrawal amt',
      'deposit amt',
      'closing balance',
    ])) {
      return BankProfile.hdfc;
    }
    if (_containsAny(headerBlob, [
      'ref no./cheque no.',
      'ref.no./chq.no.',
      'transaction reference',
      'txn date',
    ])) {
      return BankProfile.sbi;
    }
    if (_containsAny(headerBlob, ['withdrawal(dr)', 'deposit(cr)'])) {
      return BankProfile.bob;
    }
    if (_containsAny(headerBlob, ['particulars', 'withdrawal', 'deposit']) &&
        !_containsAny(headerBlob, ['transaction remarks'])) {
      return BankProfile.pnb;
    }
    if (_containsAny(headerBlob, [
      'au small finance',
      'transaction date',
      'value date',
      'cheque no',
    ]) &&
        _containsAny(preamble, ['au '])) {
      return BankProfile.au;
    }

    if (_hasAxisStyleHeader(rows)) {
      return BankProfile.axis;
    }

    return BankProfile.generic;
  }

  String _preambleBlob(
    List<List<dynamic>> rows,
    String? fileName,
    String? rawText,
  ) {
    final buffer = StringBuffer();
    if (fileName != null) {
      buffer.writeln(fileName.toLowerCase());
    }
    if (rawText != null) {
      final lines = rawText.split('\n').take(25);
      buffer.writeln(lines.join('\n').toLowerCase());
    }

    final limit = rows.length < 20 ? rows.length : 20;
    for (var i = 0; i < limit; i++) {
      buffer.writeln(rows[i].join(',').toLowerCase());
    }
    return buffer.toString();
  }

  String _headerBlob(List<List<dynamic>> rows) {
    final buffer = StringBuffer();
    for (final row in rows.take(30)) {
      buffer.writeln(row.join(',').toLowerCase());
    }
    return buffer.toString();
  }

  bool _containsAny(String blob, List<String> needles) {
    for (final needle in needles) {
      if (blob.contains(needle)) return true;
    }
    return false;
  }

  bool _hasAxisStyleHeader(List<List<dynamic>> rows) {
    for (final row in rows.take(30)) {
      final headers = row.map((c) => c.toLowerCase().trim()).toList();
      final hasDr = headers.any((h) => h == 'dr');
      final hasCr = headers.any((h) => h == 'cr');
      final hasParticulars = headers.any((h) => h.contains('particular'));
      final hasStandardWithdrawal = headers.any(
        (h) => h.contains('withdrawal') || h.contains('deposit'),
      );
      if (hasDr && hasCr && hasParticulars && !hasStandardWithdrawal) {
        return true;
      }
    }
    return false;
  }
}

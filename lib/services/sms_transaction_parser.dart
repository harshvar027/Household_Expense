import '../models/bank_transaction.dart';
import '../models/parsed_sms_transaction.dart';
import 'amount_parser.dart';
import 'category_detector.dart';

class SmsTransactionParser {
  static const _otpKeywords = [
    'otp',
    'one time password',
    'one-time password',
    'verification code',
    'do not share',
    'never share',
    'is your',
    'login alert',
    'security alert',
  ];

  static const _transactionKeywords = [
    'debited',
    'debit',
    'credited',
    'credit',
    'spent',
    'received',
    'withdrawn',
    'deposited',
    'txn',
    'transaction',
    'a/c',
    'ac no',
    'account',
    'upi',
    'imps',
    'neft',
    'rtgs',
    'card ending',
    'card xx',
    'vpa',
    'avl bal',
    'available bal',
    'bal:',
    'balance:',
  ];

  static final _amountPatterns = [
    RegExp(
      r'(?:rs\.?|inr)\s*([0-9,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:debited|credited|spent|received|withdrawn|deposited)\s+(?:for\s+)?(?:rs\.?|inr)?\s*([0-9,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    ),
    RegExp(
      r'([0-9,]+(?:\.\d{1,2})?)\s*(?:rs\.?|inr)\b',
      caseSensitive: false,
    ),
  ];

  static ParsedSmsTransaction? parse(String message, {DateTime? receivedAt}) {
    final body = message.trim();
    if (body.isEmpty) return null;

    final lower = body.toLowerCase();
    if (_looksLikeOtp(lower)) return null;
    if (!_looksLikeTransaction(lower)) return null;

    final amount = _extractAmount(body);
    if (amount == null || amount <= 0) return null;

    final isDebit = _detectDebit(lower);
    final description = _extractDescription(body);
    final paymentMethod = _detectPaymentMethod(lower);
    final date = _extractDate(body) ?? receivedAt ?? DateTime.now();

    final bankTxn = BankTransaction(
      date: date,
      description: body,
      amount: amount,
      isDebit: isDebit,
    );

    final suggestedCategory = isDebit
        ? 'Other'
        : CategoryDetector.detectIncome(bankTxn);
    final isInvestmentHint = _looksLikeInvestment(lower, suggestedCategory);

    return ParsedSmsTransaction(
      rawMessage: body,
      amount: amount,
      isDebit: isDebit,
      description: description,
      date: date,
      paymentMethod: paymentMethod,
      suggestedCategory: suggestedCategory,
      isInvestmentHint: isInvestmentHint,
    );
  }

  static Future<ParsedSmsTransaction> withCategory(
    ParsedSmsTransaction parsed,
    List<String> dbCategories,
  ) async {
    if (!parsed.isDebit) return parsed;

    final bankTxn = BankTransaction(
      date: parsed.date,
      description: parsed.description,
      amount: parsed.amount,
      isDebit: true,
    );
    final category = await CategoryDetector.detectExpense(bankTxn, dbCategories);
    final isInvestmentHint =
        _looksLikeInvestment(parsed.rawMessage.toLowerCase(), category);

    return ParsedSmsTransaction(
      rawMessage: parsed.rawMessage,
      amount: parsed.amount,
      isDebit: parsed.isDebit,
      description: parsed.description,
      date: parsed.date,
      paymentMethod: parsed.paymentMethod,
      suggestedCategory: category,
      isInvestmentHint: isInvestmentHint,
    );
  }

  static bool _looksLikeOtp(String lower) {
    if (_otpKeywords.any(lower.contains)) return true;
    return RegExp(r'\b\d{4,8}\b.*\b(otp|pin|code)\b').hasMatch(lower);
  }

  static bool _looksLikeTransaction(String lower) {
    return _transactionKeywords.any(lower.contains);
  }

  static bool _looksLikeInvestment(String lower, String category) {
    if (category == 'Mutual Funds' || category == 'Investment') return true;
    return RegExp(
      r'\b(mutual fund|sip|groww|zerodha|demat|nse|bse)\b',
    ).hasMatch(lower);
  }

  static double? _extractAmount(String body) {
    for (final pattern in _amountPatterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final parsed = AmountParser.parse(match.group(1));
        if (parsed != null && parsed > 0) return parsed;
      }
    }
    return null;
  }

  static bool _detectDebit(String lower) {
    if (RegExp(r'\b(credited|credit alert|received|deposited)\b').hasMatch(lower)) {
      if (!RegExp(r'\bdebited\b').hasMatch(lower)) return false;
    }

    if (RegExp(r'\b(debited|debit alert|spent|withdrawn|paid)\b').hasMatch(lower)) {
      return true;
    }

    if (RegExp(r'\b(credited|received|deposited)\b').hasMatch(lower)) {
      return false;
    }

    return true;
  }

  static String _detectPaymentMethod(String lower) {
    if (lower.contains('upi') || lower.contains('vpa')) return 'UPI';
    if (lower.contains('credit card')) return 'Credit Card';
    if (lower.contains('debit card') || lower.contains('card ending')) {
      return 'Debit Card';
    }
    if (lower.contains('net banking') || lower.contains('neft') || lower.contains('imps')) {
      return 'Net Banking';
    }
    if (lower.contains('cash')) return 'Cash';
    return 'UPI';
  }

  static String _extractDescription(String body) {
    final patterns = [
      RegExp(r'info[:\s-]+(.+?)(?:\.| on | avl | bal | available|$)', caseSensitive: false),
      RegExp(r'at\s+(.+?)\s+on\s+\d', caseSensitive: false),
      RegExp(r'vpa[:\s-]+([^\s]+)', caseSensitive: false),
      RegExp(r'to\s+(.+?)\s+on\s+\d', caseSensitive: false),
      RegExp(r'from\s+(.+?)\s+on\s+\d', caseSensitive: false),
      RegExp(r'ref[:\s-]+(.+?)(?:\.| avl | bal |$)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final value = _cleanDescription(match.group(1) ?? '');
        if (value.isNotEmpty) return value;
      }
    }

    return 'Bank transaction';
  }

  static String _cleanDescription(String value) {
    return value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('*', '')
        .trim();
  }

  static DateTime? _extractDate(String body) {
    final patterns = [
      RegExp(r'on\s+(\d{1,2}[-/]\w{3}[-/]\d{2,4})', caseSensitive: false),
      RegExp(r'on\s+(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})', caseSensitive: false),
      RegExp(r'(\d{1,2}-\w{3}-\d{2,4})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match == null) continue;
      final parsed = _parseDateToken(match.group(1)!);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static DateTime? _parseDateToken(String token) {
    final normalized = token.replaceAll('/', '-');
    final parts = normalized.split('-');
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    if (day == null) return null;

    final month = _monthFromToken(parts[1]) ?? int.tryParse(parts[1]);
    if (month == null || month < 1 || month > 12) return null;

    var year = int.tryParse(parts[2]);
    if (year == null) return null;
    if (year < 100) year += 2000;

    return DateTime(year, month, day);
  }

  static int? _monthFromToken(String token) {
    final numeric = int.tryParse(token);
    if (numeric != null && numeric >= 1 && numeric <= 12) return numeric;

    if (token.length < 3) return null;
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
    return months[token.toLowerCase().substring(0, 3)];
  }
}

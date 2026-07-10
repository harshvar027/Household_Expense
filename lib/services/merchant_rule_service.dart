import '../database/database_helper.dart';

class MerchantRuleService {
  static final MerchantRuleService instance = MerchantRuleService._();
  MerchantRuleService._();

  final _db = DatabaseHelper.instance;

  /// Extracts a memorable merchant token from bank description text.
  String extractPattern(String text) {
    final lower = text.toLowerCase();
    final noise = RegExp(
      r'\b(upi|neft|imps|rtgs|ref|txn|payment|paytm|phonepe|gpay|googlepay|bhim|transfer|debit|credit|pos|atm|nfs|inb|ibank)\b',
    );
    var cleaned = lower.replaceAll(noise, ' ');
    cleaned = cleaned.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    final words = cleaned
        .split(' ')
        .where((w) => w.length >= 3 && !_isNumeric(w))
        .toList();

    if (words.isEmpty) {
      final fallback = lower.replaceAll(RegExp(r'[^a-z0-9]'), '');
      return fallback.length >= 3 ? fallback.substring(0, fallback.length.clamp(0, 20)) : lower;
    }

    // Prefer longer distinctive words (brand names)
    words.sort((a, b) => b.length.compareTo(a.length));
    return words.first;
  }

  bool _isNumeric(String s) => double.tryParse(s) != null;

  Future<void> learnFromCategoryChange(String description, String category) async {
    final pattern = extractPattern(description);
    if (pattern.length < 3) return;
    await _db.upsertMerchantRule(pattern, category);
  }

  Future<String?> applyRules(String description) async {
    return _db.matchMerchantRule(description);
  }
}

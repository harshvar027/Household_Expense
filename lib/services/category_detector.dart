import '../models/bank_transaction.dart';
import 'merchant_rule_service.dart';

class CategoryDetector {
  static String mapToDbCategory(String detected, List<String> dbCategories) {
    if (dbCategories.contains(detected)) {
      return detected;
    }

    if (dbCategories.contains('Other')) {
      return 'Other';
    }

    return dbCategories.isNotEmpty ? dbCategories.first : 'Other';
  }

  static Future<String> detectExpense(
    BankTransaction t,
    List<String> dbCategories,
  ) async {
    final learned = await MerchantRuleService.instance.applyRules(t.description);
    if (learned != null) {
      return mapToDbCategory(learned, dbCategories);
    }

    final text = t.description.toLowerCase();
    String detected = 'Other';

    if (_containsAny(text, ['amazon', 'flipkart', 'myntra', 'meesho'])) {
      detected = 'Shopping';
    } else if (_containsAny(text, [
      'canteen',
      'restaurant',
      'swiggy',
      'zomato',
      'food',
      'chicken',
      'cafe',
    ])) {
      detected = 'Food & Dining';
    } else if (_containsAny(text, ['kirana', 'grocery', 'groceries', 'dmart'])) {
      detected = 'Groceries';
    } else if (_containsAny(text, ['vegetable', 'sabzi'])) {
      detected = 'Vegetables';
    } else if (_containsAny(text, ['fruit', 'apple', 'banana'])) {
      detected = 'Fruits';
    } else if (text.contains('milk')) {
      detected = 'Milk';
    } else if (_containsAny(text, [
      'petrol',
      'diesel',
      'fuel',
      'service station',
      'hpcl',
      'iocl',
      'bpcl',
    ])) {
      detected = 'Petrol';
    } else if (_containsAny(text, ['airtel', 'jio', 'vodafone', 'recharge'])) {
      detected = 'Internet';
    } else if (_containsAny(text, [
      'google',
      'netflix',
      'spotify',
      'youtube',
      'prime',
      'subscription',
    ])) {
      detected = 'Subscriptions';
    } else if (_containsAny(text, [
      'policybazaar',
      'insurance',
      'lic ',
      'premium',
    ])) {
      detected = 'Insurance';
    } else if (_containsAny(text, ['irctc', 'makemytrip', 'uber', 'ola'])) {
      detected = 'Travel';
    } else if (_containsAny(text, [
      'maintenance',
      'plumber',
      'carpenter',
      'rent',
    ])) {
      detected = 'House Maintenance';
    } else if (_containsAny(text, [
      'mutual fund',
      'mf ',
      'sip',
      'groww',
      'zerodha',
      'coin',
      'navi mutual',
    ])) {
      detected = 'Mutual Funds';
    } else if (_containsAny(text, [
      '5paisa',
      'icici prudential',
      'hdfc securities',
      'share',
      'equity',
      'demat',
      'nse',
      'bse',
      'investment',
    ])) {
      detected = 'Investment';
    } else if (_containsAny(text, [
      'school',
      'college',
      'university',
      'newton',
      'education',
      'tuition',
    ])) {
      detected = 'Education';
    } else if (_containsAny(text, [
      'medical',
      'hospital',
      'pharmacy',
      'apollo',
      'medplus',
    ])) {
      detected = 'Medical';
    } else if (_containsAny(text, ['electric', 'mseb', 'bescom', 'tneb'])) {
      detected = 'Electricity';
    } else if (_containsAny(text, [
      'movie',
      'pvr',
      'inox',
      'entertainment',
      'game',
    ])) {
      detected = 'Entertainment';
    }

    return mapToDbCategory(detected, dbCategories);
  }

  static String detectIncome(BankTransaction t) {
    final text = t.description.toLowerCase();

    if (_containsAny(text, ['salary', 'munitions', 'payroll', 'wages'])) {
      return 'Salary';
    }

    if (text.contains('interest')) {
      return 'Interest';
    }

    if (text.contains('refund')) {
      return 'Refund';
    }

    if (_containsAny(text, ['dividend', ' div '])) {
      return 'Dividend';
    }

    if (_containsAny(text, ['mutual fund', 'mf redemption', 'redemption'])) {
      return 'Investment Return';
    }

    if (_containsAny(text, ['5paisa', 'investment return'])) {
      return 'Investment Return';
    }

    return 'Income';
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }
}

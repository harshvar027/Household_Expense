import '../config/region_config.dart';
import '../services/app_locale_service.dart';

class AmountParser {
  static double? parse(dynamic raw) {
    if (raw == null) return null;

    var value = raw.toString().trim();
    if (value.isEmpty ||
        value == '-' ||
        value.toUpperCase() == 'NA' ||
        value.toLowerCase() == 'null') {
      return null;
    }

    value = value
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('₹', '')
        .replaceAll(r'$', '')
        .replaceAll('€', '')
        .replaceAll('£', '')
        .replaceAll('Rs.', '')
        .replaceAll('Rs', '')
        .replaceAll('INR', '')
        .replaceAll('USD', '')
        .replaceAll('EUR', '')
        .replaceAll('GBP', '')
        .trim();

    value = _normalizeNumericSeparators(value);

    if (value == '0' || value == '0.00' || value == '0.0') {
      return null;
    }

    if (value.startsWith('(') && value.endsWith(')')) {
      value = value.substring(1, value.length - 1).trim();
    }

    value = value.replaceAll(RegExp(r'\s+(Dr|Cr|DR|CR)\s*$'), '').trim();

    if (value.isEmpty) return null;

    return double.tryParse(value);
  }

  static String _normalizeNumericSeparators(String value) {
    final european = RegExp(r'^\d{1,3}(\.\d{3})*,\d{1,2}$');
    if (european.hasMatch(value)) {
      return value.replaceAll('.', '').replaceAll(',', '.');
    }

    final order = AppLocaleService.instance.config.dateOrder;
    if (order == DateOrder.mdy && _looksIndianGrouped(value)) {
      return value.replaceAll(',', '');
    }

    return value.replaceAll(',', '');
  }

  static bool _looksIndianGrouped(String value) {
    return RegExp(r'^\d{1,2},\d{2},\d{3}\.\d{2}$').hasMatch(value) ||
        RegExp(r'^\d{1,3}(,\d{2})+(\.\d{2})$').hasMatch(value);
  }
}

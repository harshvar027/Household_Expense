import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/region_config.dart';
import '../services/app_locale_service.dart';

/// Standard decimal places for all monetary values in the app.
const int kMoneyDecimals = 2;

/// Keyboard type for amount entry fields.
const TextInputType kMoneyKeyboard =
    TextInputType.numberWithOptions(decimal: true);

/// Input formatters allowing up to two decimal places.
const List<TextInputFormatter> kMoneyInputFormatters = [MoneyInputFormatter()];

/// Rounds [value] to [kMoneyDecimals] decimal places.
double roundMoney(double value) {
  final factor = 100;
  return (value * factor).roundToDouble() / factor;
}

/// Parses user text into a monetary value, or null if invalid.
double? parseMoney(String? text) {
  if (text == null) return null;
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  final parsed = double.tryParse(trimmed);
  if (parsed == null) return null;
  return roundMoney(parsed);
}

/// Formats [value] with exactly [kMoneyDecimals] decimal places.
String formatMoney(double value) {
  return roundMoney(value).toStringAsFixed(kMoneyDecimals);
}

/// Active household currency symbol (₹, $, £, €, …).
String currencySymbol() => AppLocaleService.instance.currencySymbol;

/// Formats [value] with the active currency symbol.
String formatMoneyWithCurrency(double value) =>
    '${currencySymbol()}${formatMoney(value)}';

/// Backward-compatible alias.
String formatMoneyWithRupee(double value) => formatMoneyWithCurrency(value);

/// Prefix for amount text fields, e.g. "$ " or "₹ ".
String moneyInputPrefix() {
  final symbol = currencySymbol();
  return symbol.length > 1 ? '$symbol ' : '$symbol ';
}

InputDecoration moneyInputDecoration({
  required String labelText,
  String? hintText,
  IconData icon = Icons.payments_outlined,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixText: moneyInputPrefix(),
    prefixIcon: Icon(icon),
  );
}

/// Restricts input to a valid monetary amount (max 2 decimal places).
class MoneyInputFormatter extends TextInputFormatter {
  const MoneyInputFormatter();

  static final _pattern = RegExp(r'^\d*\.?\d{0,2}$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty || _pattern.hasMatch(text)) {
      return newValue;
    }
    return oldValue;
  }
}

String formatDisplayDate(DateTime date) {
  final order = AppLocaleService.instance.config.dateOrder;
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[date.month - 1];
  if (order == DateOrder.mdy) {
    return '${date.month} $month ${date.year}';
  }
  return '${date.day} $month ${date.year}';
}

String formatDbDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/money_format.dart';

/// How money flows: in (green +) or out (red −).
enum MoneyFlow { credit, debit }

class MoneyAmount extends StatelessWidget {
  final double amount;
  final MoneyFlow flow;
  final double fontSize;
  final FontWeight fontWeight;
  final bool showCurrency;
  final int decimals;

  const MoneyAmount({
    super.key,
    required this.amount,
    required this.flow,
    this.fontSize = 15,
    this.fontWeight = FontWeight.w700,
    this.showCurrency = true,
    this.decimals = kMoneyDecimals,
  });

  /// Green + for zero/positive, red − for negative.
  factory MoneyAmount.signed(
    double signedAmount, {
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w700,
    bool showCurrency = true,
  }) {
    if (signedAmount >= 0) {
      return MoneyAmount(
        amount: signedAmount,
        flow: MoneyFlow.credit,
        fontSize: fontSize,
        fontWeight: fontWeight,
        showCurrency: showCurrency,
      );
    }
    return MoneyAmount(
      amount: signedAmount.abs(),
      flow: MoneyFlow.debit,
      fontSize: fontSize,
      fontWeight: fontWeight,
      showCurrency: showCurrency,
    );
  }

  static String format(
    double amount,
    MoneyFlow flow, {
    bool showCurrency = true,
    int decimals = kMoneyDecimals,
  }) {
    final value = roundMoney(amount.abs()).toStringAsFixed(decimals);
    final prefix = flow == MoneyFlow.credit ? '+' : '-';
    if (showCurrency) return '$prefix${currencySymbol()}$value';
    return '$prefix$value';
  }

  Color get color =>
      flow == MoneyFlow.credit ? AppColors.income : AppColors.expense;

  @override
  Widget build(BuildContext context) {
    return Text(
      format(amount, flow, showCurrency: showCurrency, decimals: decimals),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: -0.3,
      ),
    );
  }
}

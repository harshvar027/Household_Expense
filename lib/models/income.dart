import '../utils/money_format.dart';

class Income {
  final int? id;
  final String incomeDate;
  final String? month;
  final String category;
  final String source;
  final double amount;
  final String paymentMethod;
  final int? accountId;

  Income({
    this.id,
    required this.incomeDate,
    required this.month,
    required this.category,
    required this.source,
    required double amount,
    required this.paymentMethod,
    this.accountId,
  }) : amount = roundMoney(amount);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'incomeDate': incomeDate,
      'month': month,
      'category': category,
      'source': source,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'accountId': accountId,
    };
  }

  factory Income.fromMap(Map<String, dynamic> json) {
    return Income(
      id: json['id'],
      incomeDate: json['incomeDate'],
      month: json['month'],
      category: json['category'],
      source: json['source'],
      amount: roundMoney((json['amount'] as num).toDouble()),
      paymentMethod: json['paymentMethod'],
      accountId: json['accountId'] as int?,
    );
  }
}

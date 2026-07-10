class ParsedSmsTransaction {
  final String rawMessage;
  final double amount;
  final bool isDebit;
  final String description;
  final DateTime date;
  final String paymentMethod;
  final String suggestedCategory;
  final bool isInvestmentHint;

  const ParsedSmsTransaction({
    required this.rawMessage,
    required this.amount,
    required this.isDebit,
    required this.description,
    required this.date,
    required this.paymentMethod,
    required this.suggestedCategory,
    this.isInvestmentHint = false,
  });

  String get fingerprint =>
      '${rawMessage.trim()}|$amount|${isDebit ? 'd' : 'c'}';

  Map<String, dynamic> toJson() => {
        'rawMessage': rawMessage,
        'amount': amount,
        'isDebit': isDebit,
        'description': description,
        'date': date.toIso8601String(),
        'paymentMethod': paymentMethod,
        'suggestedCategory': suggestedCategory,
        'isInvestmentHint': isInvestmentHint,
      };

  factory ParsedSmsTransaction.fromJson(Map<String, dynamic> json) {
    return ParsedSmsTransaction(
      rawMessage: json['rawMessage'] as String,
      amount: (json['amount'] as num).toDouble(),
      isDebit: json['isDebit'] as bool,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      paymentMethod: json['paymentMethod'] as String? ?? 'UPI',
      suggestedCategory: json['suggestedCategory'] as String? ?? 'Other',
      isInvestmentHint: json['isInvestmentHint'] as bool? ?? false,
    );
  }
}

enum QuickTransactionType { expense, income, investment }

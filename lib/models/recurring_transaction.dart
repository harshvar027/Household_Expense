class RecurringTransaction {
  final int? id;
  final String item;
  final double amount;
  final String category;
  final bool isIncome;
  final int dayOfMonth;
  final String paymentMethod;
  final int? memberId;
  final int? accountId;
  final bool isActive;
  final String? lastGeneratedMonth;

  RecurringTransaction({
    this.id,
    required this.item,
    required this.amount,
    required this.category,
    this.isIncome = false,
    this.dayOfMonth = 1,
    this.paymentMethod = 'UPI',
    this.memberId,
    this.accountId,
    this.isActive = true,
    this.lastGeneratedMonth,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'item': item,
        'amount': amount,
        'category': category,
        'isIncome': isIncome ? 1 : 0,
        'dayOfMonth': dayOfMonth,
        'paymentMethod': paymentMethod,
        'memberId': memberId,
        'accountId': accountId,
        'isActive': isActive ? 1 : 0,
        'lastGeneratedMonth': lastGeneratedMonth,
      };

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) =>
      RecurringTransaction(
        id: map['id'] as int?,
        item: map['item'] as String,
        amount: (map['amount'] as num).toDouble(),
        category: map['category'] as String,
        isIncome: (map['isIncome'] as int? ?? 0) == 1,
        dayOfMonth: map['dayOfMonth'] as int? ?? 1,
        paymentMethod: map['paymentMethod'] as String? ?? 'UPI',
        memberId: map['memberId'] as int?,
        accountId: map['accountId'] as int?,
        isActive: (map['isActive'] as int? ?? 1) == 1,
        lastGeneratedMonth: map['lastGeneratedMonth'] as String?,
      );
}

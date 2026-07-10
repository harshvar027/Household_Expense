import '../utils/money_format.dart';

class Expense {
  final int? id;
  final String expenseDate;
  final String category;
  final String item;
  final double amount;
  final String paymentMethod;
  final String? txnRef;
  final int? memberId;
  final int? accountId;
  final bool isTransfer;
  final String notes;

  Expense({
    this.id,
    required this.expenseDate,
    required this.category,
    required this.item,
    required double amount,
    required this.paymentMethod,
    this.txnRef,
    this.memberId,
    this.accountId,
    this.isTransfer = false,
    this.notes = '',
  }) : amount = roundMoney(amount);

  Map<String, dynamic> toMap() => {
        'id': id,
        'expenseDate': expenseDate,
        'category': category,
        'item': item,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'txnRef': txnRef ?? '',
        'memberId': memberId,
        'accountId': accountId,
        'isTransfer': isTransfer ? 1 : 0,
        'notes': notes,
      };

  factory Expense.fromMap(Map<String, dynamic> json) => Expense(
        id: json['id'] as int?,
        expenseDate: json['expenseDate'] as String,
        category: json['category'] as String,
        item: json['item'] as String,
        amount: roundMoney((json['amount'] as num).toDouble()),
        paymentMethod: json['paymentMethod'] as String,
        txnRef: json['txnRef'] as String?,
        memberId: json['memberId'] as int?,
        accountId: json['accountId'] as int?,
        isTransfer: (json['isTransfer'] as int? ?? 0) == 1,
        notes: json['notes'] as String? ?? '',
      );

  Expense copyWith({
    int? id,
    String? expenseDate,
    String? category,
    String? item,
    double? amount,
    String? paymentMethod,
    String? txnRef,
    int? memberId,
    int? accountId,
    bool? isTransfer,
    String? notes,
  }) =>
      Expense(
        id: id ?? this.id,
        expenseDate: expenseDate ?? this.expenseDate,
        category: category ?? this.category,
        item: item ?? this.item,
        amount: amount ?? this.amount,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        txnRef: txnRef ?? this.txnRef,
        memberId: memberId ?? this.memberId,
        accountId: accountId ?? this.accountId,
        isTransfer: isTransfer ?? this.isTransfer,
        notes: notes ?? this.notes,
      );
}

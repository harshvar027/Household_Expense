class CategoryBudget {
  final int? id;
  final String month;
  final String category;
  final double amount;

  CategoryBudget({
    this.id,
    required this.month,
    required this.category,
    required this.amount,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'month': month,
        'category': category,
        'amount': amount,
      };

  factory CategoryBudget.fromMap(Map<String, dynamic> map) => CategoryBudget(
        id: map['id'] as int?,
        month: map['month'] as String,
        category: map['category'] as String,
        amount: (map['amount'] as num).toDouble(),
      );
}

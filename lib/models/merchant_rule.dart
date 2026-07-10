class MerchantRule {
  final int? id;
  final String pattern;
  final String category;
  final String createdAt;

  MerchantRule({
    this.id,
    required this.pattern,
    required this.category,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'pattern': pattern,
        'category': category,
        'createdAt': createdAt,
      };

  factory MerchantRule.fromMap(Map<String, dynamic> map) => MerchantRule(
        id: map['id'] as int?,
        pattern: map['pattern'] as String,
        category: map['category'] as String,
        createdAt: map['createdAt'] as String,
      );
}

import '../utils/money_format.dart';

class Goal {
  final int? id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String? deadline;
  final String? linkedCategory;
  final bool isActive;

  Goal({
    this.id,
    required this.name,
    required double targetAmount,
    double currentAmount = 0,
    this.deadline,
    this.linkedCategory,
    this.isActive = true,
  })  : targetAmount = roundMoney(targetAmount),
        currentAmount = roundMoney(currentAmount);

  double get progress =>
      targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0.0, 1.0);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'deadline': deadline,
        'linkedCategory': linkedCategory,
        'isActive': isActive ? 1 : 0,
      };

  factory Goal.fromMap(Map<String, dynamic> map) => Goal(
        id: map['id'] as int?,
        name: map['name'] as String,
        targetAmount: roundMoney((map['targetAmount'] as num).toDouble()),
        currentAmount:
            roundMoney((map['currentAmount'] as num?)?.toDouble() ?? 0),
        deadline: map['deadline'] as String?,
        linkedCategory: map['linkedCategory'] as String?,
        isActive: (map['isActive'] as int? ?? 1) == 1,
      );
}

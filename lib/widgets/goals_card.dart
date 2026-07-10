import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../theme/app_theme.dart';
import '../theme/neo_palette.dart';
import 'money_amount.dart';
import '../utils/money_format.dart';
import 'ui/neo_glass.dart';

class GoalsCard extends StatelessWidget {
  final List<Goal> goals;
  final VoidCallback onManage;

  const GoalsCard({
    super.key,
    required this.goals,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return NeoGlass.card(
        glowColor: AppColors.savings,
        padding: const EdgeInsets.all(16),
        borderRadius: 24,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.flag_rounded, color: AppColors.savings),
          title: const Text(
            'Savings Goals',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: const Text(
            'Set targets for emergency fund, vacation, etc.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
          onTap: onManage,
        ),
      );
    }

    return NeoGlass.card(
      glowColor: AppColors.savings,
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: AppColors.savings),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Savings Goals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(onPressed: onManage, child: const Text('Manage')),
            ],
          ),
          const SizedBox(height: 16),
          ...goals.take(4).map((goal) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        goal.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${(goal.progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.savings,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: goal.progress,
                      minHeight: 12,
                      backgroundColor: NeoPalette.slateElevated,
                      valueColor: const AlwaysStoppedAnimation(AppColors.savings),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      MoneyAmount(
                        amount: goal.currentAmount,
                        flow: MoneyFlow.credit,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      Text(
                        ' of ${formatMoneyWithCurrency(goal.targetAmount)}'
                        '${goal.deadline != null ? ' · by ${goal.deadline}' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

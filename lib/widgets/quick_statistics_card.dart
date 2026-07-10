import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ui/glass_surface.dart';
import 'money_amount.dart';

class QuickStatisticsCard extends StatelessWidget {
  final String highestCategory;
  final double highestExpense;
  final int transactionCount;
  final double budgetUsed;

  const QuickStatisticsCard({
    super.key,
    required this.highestCategory,
    required this.highestExpense,
    required this.transactionCount,
    required this.budgetUsed,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface.card(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 10),
              Text(
                'Quick Stats',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _tile(
                  Icons.category_rounded,
                  'Top Category',
                  highestCategory,
                  null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _moneyTile(Icons.payments_rounded, 'Largest', highestExpense),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _tile(
                  Icons.receipt_rounded,
                  'Transactions',
                  '$transactionCount',
                  AppColors.savings,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _tile(
                  Icons.speed_rounded,
                  'Budget Used',
                  '${budgetUsed.toStringAsFixed(0)}%',
                  AppColors.income,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String value, Color? color) {
    final displayColor = color ?? AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: displayColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: displayColor, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: displayColor,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _moneyTile(IconData icon, String title, double amount) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.expense.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.expense.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.expense, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          MoneyAmount(amount: amount, flow: MoneyFlow.debit, fontSize: 14),
        ],
      ),
    );
  }
}

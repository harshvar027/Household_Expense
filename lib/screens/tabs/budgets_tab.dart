import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../utils/money_format.dart';
import '../../utils/responsive_layout.dart';
import '../../widgets/budget_progress_card.dart';
import '../../widgets/category_budget_card.dart';
import '../../widgets/ui/neo_glass.dart';

class BudgetsTab extends StatelessWidget {
  final String monthLabel;
  final double monthlyBudget;
  final double totalExpenses;
  final Map<String, double> categoryTotals;
  final Map<String, double> categoryBudgets;
  final List<String> categories;
  final VoidCallback onOpenFullBudget;
  final Future<void> Function(String category, double amount) onSaveCategoryBudget;
  final double bottomScrollPadding;

  const BudgetsTab({
    super.key,
    required this.monthLabel,
    required this.monthlyBudget,
    required this.totalExpenses,
    required this.categoryTotals,
    required this.categoryBudgets,
    required this.categories,
    required this.onOpenFullBudget,
    required this.onSaveCategoryBudget,
    this.bottomScrollPadding = 120,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accentOf(context);
    final remaining = monthlyBudget - totalExpenses;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: ResponsiveLayout.screenPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Budgets',
                        style: AppTheme.displayOf(context, fontSize: 26),
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: onOpenFullBudget,
                      child: const Text('Edit income'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  monthLabel,
                  style: GoogleFonts.spaceGrotesk(color: AppTheme.mutedOf(context)),
                ),
                const SizedBox(height: 16),
                NeoGlass.card(
                  glowColor: accent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly envelope',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      BudgetProgressCard(
                        budget: monthlyBudget,
                        spent: totalExpenses,
                        monthLabel: monthLabel,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        remaining >= 0
                            ? '₹${formatMoney(remaining)} left this month'
                            : 'Over by ₹${formatMoney(-remaining)}',
                        style: GoogleFonts.spaceGrotesk(
                          color: remaining >= 0 ? accent : AppColors.expense,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CategoryBudgetCard(
                  monthLabel: monthLabel,
                  categoryTotals: categoryTotals,
                  categoryBudgets: categoryBudgets,
                  categories: categories,
                  onSaveBudget: onSaveCategoryBudget,
                ),
                SizedBox(height: bottomScrollPadding),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

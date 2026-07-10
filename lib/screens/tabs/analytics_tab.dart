import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/neo_palette.dart';
import '../../widgets/ui/neo_glass.dart';
import '../../widgets/money_amount.dart';
import '../../widgets/ui/finance_illustration.dart';
import '../../widgets/ui/stagger_animate.dart';
import '../../widgets/category_budget_card.dart';
import '../../widgets/expense_pie_chart.dart';
import '../../widgets/goals_card.dart';
import '../../widgets/insights_card.dart';
import '../../widgets/member_spending_card.dart';
import '../../widgets/monthly_trend_chart.dart';
import '../../widgets/quick_statistics_card.dart';
import '../../services/insights_service.dart';
import '../../models/goal.dart';
import '../../utils/responsive_layout.dart';

class AnalyticsTab extends StatelessWidget {
  final String monthLabel;
  final Map<String, double> categoryTotals;
  final Map<String, double> monthlyExpenseTotals;
  final Map<String, double> categoryBudgets;
  final Map<String, double> memberSpending;
  final List<String> categories;
  final List<Color> barColors;
  final List<Insight> insights;
  final List<Goal> goals;
  final String highestCategory;
  final double highestExpense;
  final int transactionCount;
  final double budgetUsed;
  final void Function(String) onCategoryTap;
  final Future<void> Function(String, double) onSaveBudget;
  final VoidCallback onManageGoals;
  final double bottomScrollPadding;

  const AnalyticsTab({
    super.key,
    required this.monthLabel,
    required this.categoryTotals,
    required this.monthlyExpenseTotals,
    required this.categoryBudgets,
    required this.memberSpending,
    required this.categories,
    required this.barColors,
    required this.insights,
    required this.goals,
    required this.highestCategory,
    required this.highestExpense,
    required this.transactionCount,
    required this.budgetUsed,
    required this.onCategoryTap,
    required this.onSaveBudget,
    required this.onManageGoals,
    this.bottomScrollPadding = 160,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: ResponsiveLayout.screenPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Analytics',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.8,
                            ),
                          ).staggerIn(index: 0),
                          const SizedBox(height: 4),
                          Text(
                            'Insights for $monthLabel',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ).staggerIn(index: 1),
                        ],
                      ),
                    ),
                    const FinanceIllustration(
                      type: FinanceIllustrationType.chart,
                      size: 64,
                    ).staggerIn(index: 1),
                  ],
                ),
                const SizedBox(height: 20),
                QuickStatisticsCard(
                  highestCategory: highestCategory,
                  highestExpense: highestExpense,
                  transactionCount: transactionCount,
                  budgetUsed: budgetUsed,
                ),
                const SizedBox(height: 16),
                if (insights.isNotEmpty) ...[
                  InsightsCard(insights: insights),
                  const SizedBox(height: 20),
                ],
                _ChartCard(
                  title: 'Monthly Trend',
                  icon: Icons.show_chart_rounded,
                  color: AppColors.primary,
                  child: MonthlyTrendChart(
                    monthlyExpenseTotals: monthlyExpenseTotals,
                    barColors: barColors,
                  ),
                ),
                const SizedBox(height: 16),
                _ChartCard(
                  title: 'Expense Distribution',
                  icon: Icons.pie_chart_rounded,
                  color: AppColors.savings,
                  child: ExpensePieChart(
                    categoryTotals: categoryTotals,
                    onCategoryTap: onCategoryTap,
                  ),
                ),
                const SizedBox(height: 16),
                if (categoryTotals.isNotEmpty) _CategoryBreakdown(
                  categoryTotals: categoryTotals,
                  onCategoryTap: onCategoryTap,
                ),
                const SizedBox(height: 16),
                MemberSpendingCard(memberTotals: memberSpending),
                const SizedBox(height: 16),
                GoalsCard(goals: goals, onManage: onManageGoals),
                const SizedBox(height: 16),
                CategoryBudgetCard(
                  monthLabel: monthLabel,
                  categoryTotals: categoryTotals,
                  categoryBudgets: categoryBudgets,
                  categories: categories,
                  onSaveBudget: onSaveBudget,
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

class _ChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return NeoGlass.card(
      glowColor: color,
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.25),
                      color.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final void Function(String) onCategoryTap;

  const _CategoryBreakdown({
    required this.categoryTotals,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);

    return NeoGlass.card(
      glowColor: AppColors.primary,
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.list_alt_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 10),
              Text(
                'By Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sorted.asMap().entries.map((entry) {
            final cat = entry.value.key;
            final amount = entry.value.value;
            final pct = total == 0 ? 0.0 : amount / total;
            final colors = [
              AppColors.cyberMint,
              AppColors.electricAmethyst,
              AppColors.income,
              AppColors.warning,
              AppColors.expense,
              AppColors.balance,
            ];
            final color = colors[entry.key % colors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => onCategoryTap(cat),
                borderRadius: BorderRadius.circular(10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            cat,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        MoneyAmount(amount: amount, flow: MoneyFlow.debit, fontSize: 14),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 5,
                        backgroundColor: NeoPalette.slateElevated,
                        valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.85)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

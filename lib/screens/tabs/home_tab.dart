import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../theme/neo_palette.dart';
import '../../widgets/budget_progress_card.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/missing_recurring_banner.dart';
import '../../widgets/neo_metric_card.dart';
import '../../widgets/money_amount.dart';
import '../../widgets/ui/holographic_growth_chart.dart';
import '../../widgets/ui/neo_glass.dart';
import '../../widgets/ui/organic_donut_chart.dart';
import '../../widgets/ui/pressable_scale.dart';
import '../../services/insights_service.dart';
import '../../models/recurring_transaction.dart';
import '../../utils/responsive_layout.dart';

class HomeTab extends StatelessWidget {
  final String selectedMonth;
  final List<Map<String, String>> months;
  final String monthLabel;
  final double monthlyIncome;
  final double manualIncome;
  final double importedIncome;
  final double broughtForwardIncome;
  final double totalExpenses;
  final double investmentTotal;
  final double balance;
  final double monthlyBudget;
  final Map<String, double> categoryTotals;
  final Map<String, double> monthlyExpenseTotals;
  final List<Insight> insights;
  final List<RecurringTransaction> missingRecurring;
  final bool dismissMissingBanner;
  final String highestCategory;
  final int transactionCount;
  final ValueChanged<String> onMonthChanged;
  final VoidCallback onDismissBanner;
  final VoidCallback onAddExpense;
  final VoidCallback onViewTransactions;
  final VoidCallback onViewAnalytics;
  final VoidCallback? onAccountSettings;
  final VoidCallback? onManageSettings;
  final VoidCallback? onLogout;
  final double bottomScrollPadding;
  final String? userName;
  final String? householdName;

  const HomeTab({
    super.key,
    required this.selectedMonth,
    required this.months,
    required this.monthLabel,
    required this.monthlyIncome,
    required this.manualIncome,
    required this.importedIncome,
    required this.broughtForwardIncome,
    required this.totalExpenses,
    required this.investmentTotal,
    required this.balance,
    required this.monthlyBudget,
    required this.categoryTotals,
    required this.monthlyExpenseTotals,
    required this.insights,
    required this.missingRecurring,
    required this.dismissMissingBanner,
    required this.highestCategory,
    required this.transactionCount,
    required this.onMonthChanged,
    required this.onDismissBanner,
    required this.onAddExpense,
    required this.onViewTransactions,
    required this.onViewAnalytics,
    this.onAccountSettings,
    this.onManageSettings,
    this.onLogout,
    this.bottomScrollPadding = 160,
    this.userName,
    this.householdName,
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
                DashboardHeader(
                  selectedMonth: selectedMonth,
                  months: months,
                  onMonthChanged: onMonthChanged,
                  balance: balance,
                  userName: userName,
                  householdName: householdName,
                  onAccountSettings: onAccountSettings,
                  onManageSettings: onManageSettings,
                  onLogout: onLogout,
                ).animate().fadeIn(duration: 500.ms),
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, constraints) {
                    Widget incomeCard = NeoMetricCard(
                      animationIndex: 1,
                      title: 'INCOME',
                      amount: monthlyIncome,
                      moneyFlow: MoneyFlow.credit,
                      subtitle: broughtForwardIncome > 0
                          ? 'Includes brought forward'
                          : 'This month',
                      accent: AppColors.income,
                      icon: Icons.arrow_downward_rounded,
                    );
                    Widget expenseCard = NeoMetricCard(
                      animationIndex: 2,
                      title: 'EXPENSES',
                      amount: totalExpenses,
                      moneyFlow: MoneyFlow.debit,
                      subtitle: '$transactionCount transactions',
                      accent: AppColors.expense,
                      icon: Icons.shopping_bag_rounded,
                      onTap: onViewTransactions,
                    );
                    Widget savingsCard = NeoMetricCard(
                      animationIndex: 3,
                      title: 'SAVINGS',
                      amount: investmentTotal,
                      moneyFlow: MoneyFlow.credit,
                      subtitle: investmentTotal > 0
                          ? 'Investments'
                          : 'No investments',
                      accent: AppColors.savings,
                      icon: Icons.savings_rounded,
                    );
                    Widget topCategoryCard = NeoMetricCard(
                      animationIndex: 4,
                      title: 'TOP CATEGORY',
                      value: highestCategory == '-' ? '—' : highestCategory,
                      subtitle: 'Highest spending',
                      accent: AppColors.balance,
                      icon: Icons.category_rounded,
                      onTap: onViewAnalytics,
                    );

                    Widget pair(Widget left, Widget right) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: left),
                          const SizedBox(width: 12),
                          Expanded(child: right),
                        ],
                      );
                    }

                    if (constraints.maxWidth < 280) {
                      return Column(
                        children: [
                          incomeCard,
                          const SizedBox(height: 12),
                          expenseCard,
                          const SizedBox(height: 12),
                          savingsCard,
                          const SizedBox(height: 12),
                          topCategoryCard,
                        ],
                      );
                    }

                    return Column(
                      children: [
                        pair(incomeCard, expenseCard),
                        const SizedBox(height: 12),
                        pair(savingsCard, topCategoryCard),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                NeoGlass.sectionHeader('Spending by category', trailing: monthLabel),
                const SizedBox(height: 14),
                NeoGlass.card(
                  glowColor: NeoPalette.electricAmethyst,
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                  child: OrganicDonutChart(
                    categoryTotals: categoryTotals,
                  ),
                ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.06, end: 0),
                const SizedBox(height: 22),
                NeoGlass.sectionHeader('Monthly trend'),
                const SizedBox(height: 14),
                NeoGlass.card(
                  glowColor: NeoPalette.cyberMint,
                  padding: const EdgeInsets.all(18),
                  child: HolographicGrowthChart(
                    monthlyTotals: monthlyExpenseTotals,
                    title: 'Latest month spend',
                    accentColor: NeoPalette.cyberMint,
                  ),
                ).animate(delay: 280.ms).fadeIn().slideY(begin: 0.06, end: 0),
                const SizedBox(height: 22),
                BudgetProgressCard(
                  spent: totalExpenses,
                  budget: monthlyBudget,
                  monthLabel: monthLabel,
                ),
                const SizedBox(height: 16),
                if (!dismissMissingBanner && missingRecurring.isNotEmpty)
                  MissingRecurringBanner(
                    missing: missingRecurring,
                    onDismiss: onDismissBanner,
                  ).animate().fadeIn().slideY(begin: 0.08, end: 0),
                if (insights.isNotEmpty) ...[
                  _InsightPreview(insight: insights.first),
                  const SizedBox(height: 16),
                ],
                _QuickActions(
                  onAddExpense: onAddExpense,
                  onViewTransactions: onViewTransactions,
                  onViewAnalytics: onViewAnalytics,
                ).animate(delay: 360.ms).fadeIn().slideY(begin: 0.05, end: 0),
                SizedBox(height: bottomScrollPadding),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InsightPreview extends StatelessWidget {
  final Insight insight;

  const _InsightPreview({required this.insight});

  @override
  Widget build(BuildContext context) {
    final color = switch (insight.type) {
      'warning' => AppColors.warning,
      'success' => AppColors.income,
      _ => AppColors.primary,
    };
    final icon = switch (insight.type) {
      'warning' => Icons.lightbulb_rounded,
      'success' => Icons.check_circle_rounded,
      _ => Icons.insights_rounded,
    };

    return NeoGlass.card(
      glowColor: color,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight.message,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.05, end: 0);
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onAddExpense;
  final VoidCallback onViewTransactions;
  final VoidCallback onViewAnalytics;

  const _QuickActions({
    required this.onAddExpense,
    required this.onViewTransactions,
    required this.onViewAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NeoGlass.sectionHeader('Quick Actions'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.add_rounded,
                label: 'Add',
                color: AppColors.primary,
                onTap: onAddExpense,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.receipt_long_rounded,
                label: 'History',
                color: AppColors.expense,
                onTap: onViewTransactions,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.bar_chart_rounded,
                label: 'Insights',
                color: AppColors.savings,
                onTap: onViewAnalytics,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: NeoGlass.card(
        glowColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        borderRadius: 20,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.22),
                    color.withValues(alpha: 0.06),
                  ],
                ),
                border: Border.all(color: color.withValues(alpha: 0.45)),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/subscription_config.dart';
import '../../models/subscription_tier.dart';
import '../../services/entitlement_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/neo_palette.dart';
import '../../widgets/feature_tile.dart';
import '../../widgets/ui/finance_illustration.dart';
import '../../widgets/ui/glass_surface.dart';
import '../../widgets/ui/glass_icon_bubble.dart';
import '../../widgets/ui/stagger_animate.dart';
import '../../widgets/ads/inline_ad_ribbon.dart';
import '../../utils/responsive_layout.dart';

typedef MenuAction = void Function(String action);

class MenuTab extends StatelessWidget {
  final MenuAction onAction;
  final bool adsActive;
  final EntitlementStatus entitlement;
  final double bottomScrollPadding;

  const MenuTab({
    super.key,
    required this.onAction,
    required this.entitlement,
    this.adsActive = true,
    this.bottomScrollPadding = 120,
  });

  bool _isLocked(AppFeature feature) => !entitlement.canAccess(feature);

  void _tap(String action, AppFeature? feature) {
    if (feature != null && _isLocked(feature)) {
      onAction('upgrade:$feature');
      return;
    }
    onAction(action);
  }

  Widget _menuAdSlot() {
    if (!adsActive) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.only(top: 12, bottom: 4),
      child: InlineAdRibbon(),
    );
  }

  Widget _buildSection({
    required String label,
    required List<_Item> items,
    required int startIndex,
    bool adAfter = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label),
        const SizedBox(height: 12),
        _FeatureGrid(
          startIndex: startIndex,
          items: items,
          isLocked: _isLocked,
          onTap: _tap,
        ),
        if (adAfter) _menuAdSlot(),
      ],
    );
  }

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
                _HeroBanner().staggerIn(index: 0),
                const SizedBox(height: 16),
                _PlanBanner(
                  summary: entitlement.planSummary(),
                  isPremium: entitlement.hasActivePremium,
                  onUpgrade: () => onAction('subscription'),
                ).staggerIn(index: 1),
                const SizedBox(height: 20),
                _buildSection(
                  label: 'Daily Use',
                  startIndex: 0,
                  adAfter: true,
                  items: const [
                    _Item(Icons.add_rounded, 'Add Expense', 'Record a purchase', AppColors.primary, 'add_expense', null),
                    _Item(Icons.upload_file_rounded, 'Import Bank', 'CSV, Excel or PDF', AppColors.savings, 'import', AppFeature.importStatement),
                    _Item(Icons.receipt_long_rounded, 'Transactions', 'All expenses', AppColors.expense, 'transactions', null),
                    _Item(Icons.account_balance_wallet_rounded, 'Budget', 'Income & limits', AppColors.warning, 'budget', null),
                  ],
                ).staggerIn(index: 2),
                const SizedBox(height: 16),
                _buildSection(
                  label: 'Planning',
                  startIndex: 4,
                  adAfter: true,
                  items: const [
                    _Item(Icons.insights_rounded, 'Analytics', 'Charts & insights', AppColors.balance, 'analytics', null),
                    _Item(Icons.label_rounded, 'Categories', 'Spending tags', AppColors.primary, 'categories', null),
                    _Item(Icons.flag_rounded, 'Goals', 'Savings targets', AppColors.income, 'goals', null),
                    _Item(Icons.tune_rounded, 'Household', 'Members & accounts', AppColors.primaryDark, 'settings', null),
                  ],
                ).staggerIn(index: 3),
                const SizedBox(height: 16),
                _buildSection(
                  label: 'Data & Export',
                  startIndex: 8,
                  adAfter: true,
                  items: const [
                    _Item(Icons.picture_as_pdf_rounded, 'PDF Report', 'Monthly summary', Color(0xFFE53935), 'pdf', AppFeature.exportPdf),
                    _Item(Icons.table_view_rounded, 'Export CSV', 'Spreadsheet export', AppColors.income, 'csv', AppFeature.exportCsv),
                    _Item(Icons.cloud_upload_rounded, 'Backup', 'Save JSON backup', AppColors.savings, 'backup', AppFeature.backup),
                    _Item(Icons.cloud_download_rounded, 'Restore', 'Load backup file', AppColors.warning, 'restore', AppFeature.restore),
                    _Item(
                      Icons.event_busy_rounded,
                      'Delete month',
                      'Clear this month only',
                      AppColors.expense,
                      'delete_month',
                      null,
                    ),
                  ],
                ).staggerIn(index: 4),
                const SizedBox(height: 16),
                _buildSection(
                  label: 'Support',
                  startIndex: 13,
                  items: const [
                    _Item(Icons.help_outline_rounded, 'Help & About', 'Tips, feedback & app info', AppColors.balance, 'help', null),
                    _Item(Icons.feedback_outlined, 'Send feedback', 'Bug reports & ideas', AppColors.primary, 'feedback', null),
                  ],
                ).staggerIn(index: 5),
                const SizedBox(height: 24),
                _DangerZone(onClear: () => onAction('clear')).staggerIn(index: 6),
                SizedBox(height: bottomScrollPadding),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanBanner extends StatelessWidget {
  final String summary;
  final bool isPremium;
  final VoidCallback onUpgrade;

  const _PlanBanner({
    required this.summary,
    required this.isPremium,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface.card(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Row(
        children: [
          GlassIconBubble(
            icon: isPremium ? Icons.verified_rounded : Icons.schedule_rounded,
            color: isPremium ? AppColors.income : AppColors.warning,
            size: 44,
            iconSize: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                if (!isPremium)
                  Text(
                    'Free trial: ${SubscriptionConfig.freeTrialMonths} months · all features · ads shown',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          if (!isPremium)
            TextButton(onPressed: onUpgrade, child: const Text('Plans')),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A1035),
            Color(0xFF121A2E),
            Color(0xFF0A121F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: NeoPalette.cyberMint.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: NeoPalette.electricAmethyst.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: NeoPalette.neonGradient,
                  ).createShader(bounds),
                  child: const Text(
                    'Features',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your finance\ncommand center',
                  style: TextStyle(
                    color: NeoPalette.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Import, budget, analyze & export',
                  style: TextStyle(
                    color: NeoPalette.textSecondary.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const FinanceIllustration(
            type: FinanceIllustrationType.chart,
            size: 88,
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .rotate(begin: -0.02, end: 0.02, duration: 3.seconds),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.textMuted,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _Item {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String action;
  final AppFeature? feature;

  const _Item(
    this.icon,
    this.title,
    this.subtitle,
    this.color,
    this.action,
    this.feature,
  );
}

class _FeatureGrid extends StatelessWidget {
  final List<_Item> items;
  final bool Function(AppFeature) isLocked;
  final void Function(String action, AppFeature? feature) onTap;
  final int startIndex;

  const _FeatureGrid({
    required this.items,
    required this.isLocked,
    required this.onTap,
    required this.startIndex,
  });

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveLayout.gridCrossAxisCount(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: columns >= 3 ? 1.05 : 0.92,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final locked = item.feature != null && isLocked(item.feature!);
        return FeatureTile(
          animationIndex: startIndex + index,
          icon: item.icon,
          title: item.title,
          subtitle: item.subtitle,
          color: item.color,
          isLocked: locked,
          onTap: () => onTap(item.action, item.feature),
        );
      },
    );
  }
}

class _DangerZone extends StatelessWidget {
  final VoidCallback onClear;

  const _DangerZone({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return GlassSurface.card(
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Row(
        children: [
          const GlassIconBubble(
            icon: Icons.warning_amber_rounded,
            color: AppColors.expense,
            size: 44,
            iconSize: 22,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clear all data',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                Text(
                  'Resets expenses, income & imports',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

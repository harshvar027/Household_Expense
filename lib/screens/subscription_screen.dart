import 'package:flutter/material.dart';

import '../config/subscription_config.dart';
import '../models/subscription_tier.dart';
import '../services/entitlement_service.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/glass_surface.dart';
import '../widgets/ui/app_scaffold.dart';

/// Plan selection and purchase screen.
class SubscriptionScreen extends StatefulWidget {
  final EntitlementStatus status;
  final bool blocking;

  const SubscriptionScreen({
    super.key,
    required this.status,
    this.blocking = false,
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _busy = false;
  late EntitlementStatus _status = widget.status;

  @override
  void initState() {
    super.initState();
    SubscriptionService.instance.initialize();
  }

  Future<void> _refreshStatus() async {
    final next = await EntitlementService.instance.getStatus();
    if (mounted) setState(() => _status = next);
  }

  Future<void> _purchase(Future<bool> Function() buy) async {
    setState(() => _busy = true);
    try {
      if (!SubscriptionService.instance.storeAvailable) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Store not available. Configure the yearly product in Play Console.',
            ),
          ),
        );
        return;
      }

      final started = await buy();
      if (!started && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start purchase')),
        );
      } else {
        await Future<void>.delayed(const Duration(seconds: 2));
        await _refreshStatus();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      await SubscriptionService.instance.restorePurchases();
      await Future<void>.delayed(const Duration(seconds: 1));
      await _refreshStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _status.hasActivePremium
                ? 'Purchase restored'
                : 'No active purchase found',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDismiss = !widget.blocking || _status.canUseApp;

    return PopScope(
      canPop: canDismiss,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text(widget.blocking ? 'Purchase required' : 'Your plan'),
          automaticallyImplyLeading: canDismiss,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (!_status.canUseApp)
              GlassSurface.card(
                padding: const EdgeInsets.all(16),
                borderRadius: 20,
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your ${SubscriptionConfig.freeTrialMonths}-month free trial has ended. '
                        'Purchase the yearly plan (₹${SubscriptionConfig.yearlyPriceInr}) to continue.',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              )
            else
              GlassSurface.card(
                padding: const EdgeInsets.all(16),
                borderRadius: 20,
                child: Text(
                  _status.planSummary(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            const SizedBox(height: 24),
            _PlanCard(
              title: 'Free trial',
              price: '₹0',
              period: '${SubscriptionConfig.freeTrialMonths} months',
              highlight: _status.isFreeTrialActive,
              features: const [
                'All features unlocked',
                'Backup, restore & export',
                'Bank statement import',
                'Full analytics & history',
                'Ads supported',
              ],
              selected: !_status.hasActivePremium && _status.isFreeTrialActive,
              badge: _status.isFreeTrialActive ? 'Current' : null,
            ),
            const SizedBox(height: 14),
            _PlanCard(
              title: 'Yearly Pro',
              price: '₹${SubscriptionConfig.yearlyPriceInr}',
              period: 'one-time · 1 year',
              highlight: !_status.isFreeTrialActive,
              features: const [
                'All features unlocked',
                'Backup, restore & export',
                'Bank statement import',
                'Unlimited history',
                'Ad-free experience',
              ],
              selected: _status.tier == SubscriptionTier.yearly && _status.hasActivePremium,
              badge: 'Best value',
              onSelect: _busy ? null : () => _purchase(SubscriptionService.instance.buyYearly),
            ),
            const SizedBox(height: 24),
            if (_busy)
              const Center(child: CircularProgressIndicator())
            else ...[
              OutlinedButton.icon(
                onPressed: _restore,
                icon: const Icon(Icons.restore_rounded),
                label: const Text('Restore purchases'),
              ),
              if (_status.canUseApp && widget.blocking)
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Continue with free trial'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final List<String> features;
  final bool highlight;
  final bool selected;
  final String? badge;
  final VoidCallback? onSelect;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.highlight,
    required this.selected,
    this.badge,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.primary
        : highlight
            ? AppColors.income.withValues(alpha: 0.4)
            : Colors.black.withValues(alpha: 0.06);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: selected ? 2 : 1),
        boxShadow: [
          if (highlight)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  period,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.income.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f, style: const TextStyle(fontSize: 13))),
                ],
              ),
            ),
          ),
          if (onSelect != null) ...[
            const SizedBox(height: 12),
            PrimaryActionButton(
              onPressed: onSelect,
              icon: Icons.shopping_cart_checkout_rounded,
              label: 'Purchase yearly plan',
              color: AppColors.primary,
            ),
          ],
        ],
      ),
    );
  }
}

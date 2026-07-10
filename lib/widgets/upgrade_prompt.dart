import 'package:flutter/material.dart';

import '../config/subscription_config.dart';
import '../models/subscription_tier.dart';
import '../services/entitlement_service.dart';
import '../theme/app_theme.dart';
import '../screens/subscription_screen.dart';

String featureLabel(AppFeature feature) => switch (feature) {
      AppFeature.basicUsage => 'app access',
      AppFeature.backup => 'backup',
      AppFeature.restore => 'restore',
      AppFeature.exportCsv => 'CSV export',
      AppFeature.exportPdf => 'PDF reports',
      AppFeature.importStatement => 'bank import',
    };

Future<bool> showUpgradePrompt(
  BuildContext context, {
  required AppFeature feature,
  EntitlementStatus? status,
}) async {
  final current = status ?? await EntitlementService.instance.getStatus();

  if (!context.mounted) return false;

  if (!current.canUseApp) {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriptionScreen(
          status: current,
          blocking: true,
        ),
      ),
    );
    return EntitlementService.instance.canAccess(feature);
  }

  final upgrade = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.workspace_premium_rounded, color: AppColors.warning),
      title: const Text('Premium feature'),
      content: Text(
        'Your free trial has ended. Purchase the yearly plan '
        '(₹${SubscriptionConfig.yearlyPriceInr} for 1 year) to use ${featureLabel(feature)}.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('View plans'),
        ),
      ],
    ),
  );

  if (upgrade != true || !context.mounted) return false;

  await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => SubscriptionScreen(status: current),
    ),
  );

  return EntitlementService.instance.canAccess(feature);
}

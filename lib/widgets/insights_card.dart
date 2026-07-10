import 'package:flutter/material.dart';
import '../services/insights_service.dart';
import '../theme/app_theme.dart';
import 'ui/glass_surface.dart';

class InsightsCard extends StatelessWidget {
  final List<Insight> insights;

  const InsightsCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

    return GlassSurface.card(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppColors.warning, size: 22),
              SizedBox(width: 10),
              Text(
                'Smart Insights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...insights.map((insight) {
            final color = switch (insight.type) {
              'warning' => AppColors.warning,
              'success' => AppColors.income,
              _ => AppColors.primary,
            };
            final icon = switch (insight.type) {
              'warning' => Icons.warning_amber_rounded,
              'success' => Icons.check_circle_rounded,
              _ => Icons.info_outline_rounded,
            };
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      insight.message,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
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

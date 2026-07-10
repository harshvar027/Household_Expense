import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/neo_palette.dart';
import 'money_amount.dart';
import 'ui/neo_glass.dart';
import 'ui/pressable_scale.dart';

/// Futuristic glass metric tile with neon accent glow.
class NeoMetricCard extends StatelessWidget {
  final String title;
  final String? value;
  final double? amount;
  final MoneyFlow? moneyFlow;
  final Color accent;
  final IconData icon;
  final String subtitle;
  final int animationIndex;
  final VoidCallback? onTap;

  const NeoMetricCard({
    super.key,
    required this.title,
    this.value,
    this.amount,
    this.moneyFlow,
    required this.accent,
    required this.icon,
    required this.subtitle,
    this.animationIndex = 0,
    this.onTap,
  }) : assert(
          value != null || (amount != null && moneyFlow != null),
          'Provide value or amount with moneyFlow',
        );

  @override
  Widget build(BuildContext context) {
    final card = NeoGlass.card(
      glowColor: accent,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.25),
                      accent.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const Spacer(),
              Icon(
                Icons.auto_graph_rounded,
                size: 14,
                color: accent.withValues(alpha: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: NeoPalette.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          if (value != null)
            Text(
              value!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: accent,
                letterSpacing: -0.3,
                shadows: [
                  Shadow(
                    color: accent.withValues(alpha: 0.45),
                    blurRadius: 10,
                  ),
                ],
              ),
            )
          else
            Text(
              MoneyAmount.format(amount!, moneyFlow!),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: accent,
                letterSpacing: -0.3,
                shadows: [
                  Shadow(
                    color: accent.withValues(alpha: 0.45),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: NeoPalette.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    )
        .animate(delay: (animationIndex * 70).ms)
        .fadeIn(duration: 450.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);

    if (onTap == null) return card;

    return PressableScale(onTap: onTap, child: card);
  }
}

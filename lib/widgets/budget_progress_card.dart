import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/money_format.dart';
import 'money_amount.dart';
import 'ui/glass_surface.dart';
import 'ui/stagger_animate.dart';

class BudgetProgressCard extends StatefulWidget {
  final double spent;
  final double budget;
  final String monthLabel;

  const BudgetProgressCard({
    super.key,
    required this.spent,
    required this.budget,
    required this.monthLabel,
  });

  @override
  State<BudgetProgressCard> createState() => _BudgetProgressCardState();
}

class _BudgetProgressCardState extends State<BudgetProgressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _progressAnim = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );
    _progressController.forward();
  }

  @override
  void didUpdateWidget(BudgetProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spent != widget.spent || oldWidget.budget != widget.budget) {
      _progressController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = widget.budget == 0
        ? 0.0
        : (widget.spent / widget.budget).clamp(0.0, 1.5);
    final percent = widget.budget == 0
        ? 0
        : (widget.spent / widget.budget * 100).round();
    final remaining = widget.budget - widget.spent;
    final isOver = widget.spent > widget.budget && widget.budget > 0;
    final barColor = isOver ? AppColors.expense : AppColors.accent;

    return GlassSurface.card(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassSurface.onGradient(
                padding: const EdgeInsets.all(10),
                borderRadius: 14,
                child: Icon(
                  Icons.speed_rounded,
                  color: AppColors.cyberMint,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Budget Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      widget.monthLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.budget > 0)
                GlassSurface.onGradient(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  borderRadius: 20,
                  child: Text(
                    '$percent%',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: barColor,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: AnimatedBuilder(
                animation: _progressAnim,
                builder: (_, __) {
                  final animatedRatio = widget.budget == 0
                      ? 0.0
                      : (ratio.clamp(0.0, 1.0) * _progressAnim.value);
                  return Stack(
                    children: [
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: animatedRatio,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [barColor, barColor.withValues(alpha: 0.65)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _stat('Spent', null, widget.spent, MoneyFlow.debit)),
              _divider(),
              Expanded(
                child: _stat('Budget', formatMoneyWithCurrency(widget.budget), null, null),
              ),
              _divider(),
              Expanded(
                child: _stat('Left', null, remaining, null, signed: true),
              ),
            ],
          ),
        ],
      ),
    ).staggerIn(index: 4);
  }

  Widget _stat(
    String label,
    String? text,
    double? amount,
    MoneyFlow? flow, {
    bool signed = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        if (text != null)
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          )
        else if (signed)
          MoneyAmount.signed(amount!, fontSize: 14, fontWeight: FontWeight.w800)
        else
          MoneyAmount(
            amount: amount!,
            flow: flow!,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        color: AppColors.cyberMint.withValues(alpha: 0.12),
      );
}

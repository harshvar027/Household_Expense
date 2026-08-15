import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/goal.dart';
import '../../theme/app_theme.dart';
import '../../utils/money_format.dart';
import '../../utils/responsive_layout.dart';
import '../../widgets/ui/empty_state.dart';
import '../../widgets/ui/neo_glass.dart';

class GoalsTab extends StatelessWidget {
  final List<Goal> goals;
  final VoidCallback onManage;
  final double bottomScrollPadding;

  const GoalsTab({
    super.key,
    required this.goals,
    required this.onManage,
    this.bottomScrollPadding = 120,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accentOf(context);
    final active = goals.where((g) => g.isActive).toList();

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
                        'Goals',
                        style: AppTheme.displayOf(context, fontSize: 26),
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: onManage,
                      child: const Text('Manage'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Track savings targets without leaving the home shell.',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.mutedOf(context),
                  ),
                ),
                const SizedBox(height: 18),
                if (active.isEmpty)
                  EmptyState(
                    icon: Icons.flag_outlined,
                    title: 'No goals yet',
                    subtitle:
                        'Create a savings goal from Manage → Goals and watch progress here.',
                    actionLabel: 'Open Manage',
                    onAction: onManage,
                  )
                else
                  for (final goal in active) ...[
                    NeoGlass.card(
                      glowColor: accent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  goal.name,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Text(
                                '${(goal.progress * 100).toStringAsFixed(0)}%',
                                style: GoogleFonts.spaceGrotesk(
                                  color: accent,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: goal.progress,
                              minHeight: 10,
                              backgroundColor: accent.withValues(alpha: 0.12),
                              color: accent,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '₹${formatMoney(goal.currentAmount)} of ₹${formatMoney(goal.targetAmount)}',
                            style: GoogleFonts.spaceGrotesk(
                              color: AppTheme.mutedOf(context),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                SizedBox(height: bottomScrollPadding),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

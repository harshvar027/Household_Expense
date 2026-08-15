import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../theme/chart_styles.dart';
import '../../theme/neo_palette.dart';
import '../../utils/money_format.dart';

/// Clean spending trend curve for Home.
class HolographicGrowthChart extends StatefulWidget {
  final Map<String, double> monthlyTotals;
  final String title;
  final Color accentColor;

  const HolographicGrowthChart({
    super.key,
    required this.monthlyTotals,
    this.title = 'Spending Trajectory',
    this.accentColor = NeoPalette.cyberMint,
  });

  @override
  State<HolographicGrowthChart> createState() => _HolographicGrowthChartState();
}

class _HolographicGrowthChartState extends State<HolographicGrowthChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _appearController;

  @override
  void initState() {
    super.initState();
    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _appearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.monthlyTotals.isEmpty) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: ChartStyles.emptyChart(),
        child: const Text(
          'Trend data builds over time',
          style: ChartStyles.hintLabel,
        ),
      );
    }

    final months = widget.monthlyTotals.keys.toList()..sort();
    final values = months.map((m) => widget.monthlyTotals[m]!).toList();
    final maxY = values.reduce(math.max);
    final minY = values.reduce(math.min);
    final range = (maxY - minY).abs();
    final paddedMax =
        (maxY + (range == 0 ? math.max(maxY * 0.2, 1) : range * 0.18))
            .toDouble();
    final paddedMin =
        math.max(0.0, minY - (range == 0 ? minY * 0.1 : range * 0.1)).toDouble();

    final spots = List.generate(
      months.length,
      (i) => FlSpot(i.toDouble(), values[i]),
    );

    final latest = values.last;
    final previous = values.length > 1 ? values[values.length - 2] : latest;
    final delta = previous == 0 ? 0.0 : ((latest - previous) / previous * 100);
    final trendingUp = latest >= previous;

    return AnimatedBuilder(
      animation: _appearController,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_appearController.value);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: NeoPalette.textSecondary,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatMoneyWithCurrency(latest),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: NeoPalette.textPrimary,
                          letterSpacing: -0.6,
                          shadows: [
                            Shadow(
                              color: widget.accentColor.withValues(alpha: 0.28),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _DeltaBadge(
                  delta: delta,
                  trendingUp: trendingUp,
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 158,
              child: Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: LineChart(
                  LineChartData(
                    minY: paddedMin,
                    maxY: paddedMax,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: (paddedMax - paddedMin) / 3,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: NeoPalette.cyberMint.withValues(alpha: 0.10),
                        strokeWidth: 1,
                        dashArray: [4, 6],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final i = value.round();
                            if (i < 0 || i >= months.length) {
                              return const SizedBox.shrink();
                            }
                            // Avoid label clutter on dense series.
                            if (months.length > 6 && i % 2 != 0) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _shortMonth(months[i]),
                                style: ChartStyles.axisLabelSmall,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipRoundedRadius: 12,
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        getTooltipColor: (_) => NeoPalette.slateCard,
                        getTooltipItems: (touched) => touched.map((s) {
                          final i = s.x.round().clamp(0, months.length - 1);
                          return LineTooltipItem(
                            '${_shortMonth(months[i])}\n${formatMoneyWithCurrency(s.y)}',
                            const TextStyle(
                              color: NeoPalette.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          );
                        }).toList(),
                      ),
                      getTouchedSpotIndicator: (bar, indexes) {
                        return indexes.map((index) {
                          return TouchedSpotIndicatorData(
                            FlLine(
                              color: widget.accentColor.withValues(alpha: 0.35),
                              strokeWidth: 1.5,
                              dashArray: [4, 4],
                            ),
                            FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, i) {
                                return FlDotCirclePainter(
                                  radius: 6,
                                  color: widget.accentColor,
                                  strokeWidth: 3,
                                  strokeColor: NeoPalette.textPrimary,
                                );
                              },
                            ),
                          );
                        }).toList();
                      },
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.32,
                        barWidth: 3.5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) {
                            final isLast = index == spots.length - 1;
                            return FlDotCirclePainter(
                              radius: isLast ? 5.5 : 3.5,
                              color: isLast
                                  ? NeoPalette.electricAmethyst
                                  : widget.accentColor,
                              strokeWidth: 2,
                              strokeColor: NeoPalette.obsidianSlate,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              widget.accentColor.withValues(alpha: 0.28 * t),
                              NeoPalette.electricAmethyst
                                  .withValues(alpha: 0.06 * t),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        gradient: LinearGradient(
                          colors: [
                            widget.accentColor,
                            Color.lerp(
                              widget.accentColor,
                              NeoPalette.electricAmethyst,
                              0.55,
                            )!,
                          ],
                        ),
                        shadow: Shadow(
                          color: widget.accentColor.withValues(alpha: 0.45),
                          blurRadius: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _shortMonth(String key) {
    final parts = key.split('-');
    if (parts.length < 2) return key;
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final month = int.tryParse(parts[1]);
    if (month == null || month < 1 || month > 12) return parts[1];
    return names[month - 1];
  }
}

class _DeltaBadge extends StatelessWidget {
  final double delta;
  final bool trendingUp;

  const _DeltaBadge({
    required this.delta,
    required this.trendingUp,
  });

  @override
  Widget build(BuildContext context) {
    // Higher spend vs last month = expense (pink); lower = good (mint).
    final color = trendingUp ? NeoPalette.expenseNeon : NeoPalette.incomeNeon;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            trendingUp ? Icons.north_east_rounded : Icons.south_east_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${delta.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

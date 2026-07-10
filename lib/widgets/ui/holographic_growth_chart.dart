import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../theme/chart_styles.dart';
import '../../theme/neo_palette.dart';
import '../../utils/money_format.dart';

/// Holographic-style asset / spending growth curve.
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
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.monthlyTotals.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'Trend data builds over time',
            style: TextStyle(
              color: NeoPalette.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final months = widget.monthlyTotals.keys.toList()..sort();
    final values = months.map((m) => widget.monthlyTotals[m]!).toList();
    final maxY = values.reduce(math.max);
    final minY = values.reduce(math.min);
    final range = (maxY - minY).abs();
    final paddedMax = (maxY + (range == 0 ? maxY * 0.2 : range * 0.15)).toDouble();
    final paddedMin = math.max(0.0, minY - (range == 0 ? minY * 0.1 : range * 0.1)).toDouble();

    final spots = List.generate(
      months.length,
      (i) => FlSpot(i.toDouble(), values[i]),
    );

    final latest = values.last;
    final previous = values.length > 1 ? values[values.length - 2] : latest;
    final delta = previous == 0 ? 0.0 : ((latest - previous) / previous * 100);
    final trendingUp = latest >= previous;

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
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
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: NeoPalette.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatMoneyWithCurrency(latest),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: widget.accentColor,
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(
                              color: widget.accentColor.withValues(alpha: 0.5),
                              blurRadius: 12,
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
                  accent: widget.accentColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(double.infinity, 150),
                    painter: _HoloGridPainter(shimmer: _shimmerController.value),
                  ),
                  LineChart(
                    LineChartData(
                      minY: paddedMin,
                      maxY: paddedMax,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval:
                            (paddedMax - paddedMin) / 4,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: NeoPalette.cyberMint.withValues(alpha: 0.2),
                          strokeWidth: 1,
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
                            reservedSize: 22,
                            getTitlesWidget: (value, meta) {
                              final i = value.round();
                              if (i < 0 || i >= months.length) {
                                return const SizedBox.shrink();
                              }
                              final label = _shortMonth(months[i]);
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  label,
                                  style: ChartStyles.axisLabelSmall,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => NeoPalette.slateCard,
                          getTooltipItems: (spots) => spots.map((s) {
                            final i = s.x.round();
                            return LineTooltipItem(
                              '${_shortMonth(months[i])}\n${formatMoneyWithCurrency(s.y)}',
                              TextStyle(
                                color: NeoPalette.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.35,
                          barWidth: 4.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) {
                              final isLast = index == spots.length - 1;
                              return FlDotCirclePainter(
                                radius: isLast ? 6 : 4,
                                color: isLast
                                    ? NeoPalette.electricAmethyst
                                    : widget.accentColor,
                                strokeWidth: 2.5,
                                strokeColor: NeoPalette.textPrimary,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                widget.accentColor.withValues(
                                  alpha: 0.35 + _shimmerController.value * 0.1,
                                ),
                                NeoPalette.electricAmethyst.withValues(
                                  alpha: 0.08 + _shimmerController.value * 0.05,
                                ),
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
                                0.5 + _shimmerController.value * 0.3,
                              )!,
                              NeoPalette.electricAmethystSoft,
                            ],
                          ),
                          shadow: Shadow(
                            color: widget.accentColor.withValues(alpha: 0.85),
                            blurRadius: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
  final Color accent;

  const _DeltaBadge({
    required this.delta,
    required this.trendingUp,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = trendingUp ? NeoPalette.expenseNeon : NeoPalette.incomeNeon;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 10,
          ),
        ],
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

class _HoloGridPainter extends CustomPainter {
  final double shimmer;

  _HoloGridPainter({required this.shimmer});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NeoPalette.cyberMint.withValues(alpha: 0.12 + shimmer * 0.04)
      ..strokeWidth = 1.2;

    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final beam = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1 + shimmer * 2, 0),
        end: Alignment(shimmer * 2, 0),
        colors: [
          Colors.transparent,
          NeoPalette.electricAmethyst.withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), beam);
  }

  @override
  bool shouldRepaint(covariant _HoloGridPainter oldDelegate) =>
      oldDelegate.shimmer != shimmer;
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/chart_styles.dart';
import '../theme/neo_palette.dart';
import '../utils/money_format.dart';
import '../utils/responsive_layout.dart';

class MonthlyTrendChart extends StatelessWidget {
  final Map<String, double> monthlyExpenseTotals;
  final List<Color> barColors;

  const MonthlyTrendChart({
    super.key,
    required this.monthlyExpenseTotals,
    required this.barColors,
  });

  String _formatYAxis(double value) {
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return formatMoney(value);
  }

  String _monthLabel(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length < 2) return monthKey;

    const names = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final monthNo = int.tryParse(parts[1]) ?? 0;
    if (monthNo < 1 || monthNo > 12) return monthKey;

    final year = parts[0].length >= 4 ? parts[0].substring(2) : parts[0];
    return '${names[monthNo]}\n$year';
  }

  @override
  Widget build(BuildContext context) {
    if (monthlyExpenseTotals.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: ChartStyles.emptyChart(),
        child: const Text(
          'No monthly data available',
          style: ChartStyles.hintLabel,
        ),
      );
    }

    final textScale = ResponsiveLayout.textScale(context);
    final compact = ResponsiveLayout.isCompactWidth(context);
    final months = monthlyExpenseTotals.keys.toList();
    final maxValue = monthlyExpenseTotals.values.reduce(max);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    final interval = safeMax <= 5000
        ? 1000.0
        : safeMax <= 50000
            ? 5000.0
            : 10000.0;
    final leftAxisWidth = (48 * textScale).clamp(44.0, 64.0);
    final bottomAxisHeight = compact ? 40.0 : 44.0;
    final chartHeight = compact ? 228.0 : 256.0;
    final barWidth = compact ? 18.0 : 22.0;

    final bars = <BarChartGroupData>[];
    for (int i = 0; i < months.length; i++) {
      final t = months.length == 1 ? 0.5 : i / (months.length - 1);
      final color = Color.lerp(
            NeoPalette.cyberMint,
            NeoPalette.electricAmethyst,
            t,
          )!;
      final value = monthlyExpenseTotals[months[i]]!;

      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value,
              width: barWidth,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  color.withValues(alpha: 0.55),
                  color,
                  Color.lerp(color, Colors.white, 0.22)!,
                ],
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: safeMax * 1.18,
                color: NeoPalette.slateElevated.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: chartHeight,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          groupsSpace: compact ? 12 : 16,
          maxY: safeMax * 1.18,
          barGroups: bars,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: NeoPalette.cyberMint.withValues(alpha: 0.10),
              strokeWidth: 1,
              dashArray: [4, 6],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: leftAxisWidth,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  if (value < 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      _formatYAxis(value),
                      style: ChartStyles.axisLabelSmall.copyWith(
                        fontSize: compact ? 10 : 11,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: bottomAxisHeight,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= months.length) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _monthLabel(months[index]),
                      textAlign: TextAlign.center,
                      style: ChartStyles.axisLabelSmall.copyWith(
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w700,
                        color: NeoPalette.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipRoundedRadius: 12,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              tooltipMargin: 10,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipColor: (_) => NeoPalette.slateCard,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final month = months[group.x];
                final amountLabel = formatMoneyWithCurrency(rod.toY);
                return BarTooltipItem(
                  '${_monthLabel(month).replaceAll('\n', ' ')}\n$amountLabel',
                  const TextStyle(
                    color: NeoPalette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.35,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

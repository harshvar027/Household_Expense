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

    final year = parts[0].substring(2);
    return '${names[monthNo]}\n$year';
  }

  @override
  Widget build(BuildContext context) {
    if (monthlyExpenseTotals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No monthly data available',
            style: TextStyle(color: NeoPalette.textMuted),
          ),
        ),
      );
    }

    final textScale = ResponsiveLayout.textScale(context);
    final compact = ResponsiveLayout.isCompactWidth(context);
    final months = monthlyExpenseTotals.keys.toList();
    final maxValue = monthlyExpenseTotals.values.reduce(max);
    final interval = maxValue <= 5000
        ? 1000.0
        : maxValue <= 50000
        ? 5000.0
        : 10000.0;
    final leftAxisWidth = (48 * textScale).clamp(44.0, 64.0);
    final bottomAxisHeight = compact ? 40.0 : 44.0;
    final chartHeight = compact ? 220.0 : 250.0;
    final barWidth = compact ? 16.0 : 20.0;

    final neonColors = NeoPalette.categoryNeons(months.length);

    final bars = <BarChartGroupData>[];
    for (int i = 0; i < months.length; i++) {
      final color = barColors.isNotEmpty
          ? barColors[i % barColors.length]
          : neonColors[i];
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: monthlyExpenseTotals[months[i]]!,
              width: barWidth,
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color.lerp(color, NeoPalette.obsidian, 0.35)!,
                  color,
                  Color.lerp(color, Colors.white, 0.15)!,
                ],
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxValue * 1.2,
                color: NeoPalette.slateElevated.withValues(alpha: 0.55),
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
          groupsSpace: compact ? 10 : 14,
          maxY: maxValue * 1.2,
          barGroups: bars,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: NeoPalette.cyberMint.withValues(alpha: 0.22),
              strokeWidth: 1.2,
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
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _monthLabel(months[index]),
                      textAlign: TextAlign.center,
                      style: ChartStyles.axisLabelSmall.copyWith(
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w700,
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
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              tooltipMargin: 12,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipColor: (_) => NeoPalette.slateCard,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final month = months[group.x];
                final amountLabel = formatMoneyWithCurrency(rod.toY);
                return BarTooltipItem(
                  '$month\n$amountLabel',
                  TextStyle(
                    color: NeoPalette.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    height: 1.2,
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

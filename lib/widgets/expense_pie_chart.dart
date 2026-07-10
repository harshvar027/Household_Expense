import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/chart_styles.dart';
import '../theme/neo_palette.dart';
import '../utils/money_format.dart';

class ExpensePieChart extends StatefulWidget {
  final Map<String, double> categoryTotals;
  final void Function(String category) onCategoryTap;

  const ExpensePieChart({
    super.key,
    required this.categoryTotals,
    required this.onCategoryTap,
  });

  @override
  State<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<ExpensePieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.categoryTotals.isEmpty) {
      return Container(
        height: 280,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: NeoPalette.slateElevated.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: NeoPalette.cyberMint.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          'No expense data available',
          style: TextStyle(
            fontSize: 15,
            color: NeoPalette.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final entries = widget.categoryTotals.entries.toList();
    final total = entries.fold<double>(0, (s, e) => s + e.value);
    final colors = NeoPalette.categoryNeons(entries.length);

    return Column(
      children: [
        SizedBox(
          height: 260,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 44,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions ||
                      response == null ||
                      response.touchedSection == null) {
                    setState(() => touchedIndex = -1);
                    return;
                  }

                  final index = response.touchedSection!.touchedSectionIndex;
                  setState(() => touchedIndex = index);

                  if (event is FlTapUpEvent) {
                    widget.onCategoryTap(entries[index].key);
                  }
                },
              ),
              sections: List.generate(entries.length, (index) {
                final entry = entries[index];
                final isTouched = index == touchedIndex;
                final percent = total == 0 ? 0 : (entry.value / total) * 100;
                final color = colors[index];

                return PieChartSectionData(
                  color: color,
                  value: entry.value,
                  title: isTouched
                      ? '${percent.toStringAsFixed(0)}%'
                      : (percent >= 8 ? entry.key.split(' ').first : ''),
                  radius: isTouched ? 88 : 78,
                  titleStyle: isTouched
                      ? ChartStyles.sliceTitleLarge
                      : ChartStyles.sliceTitle,
                  showTitle: true,
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap a slice to view expenses',
          style: ChartStyles.hintLabel,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: List.generate(entries.length, (index) {
            final entry = entries[index];
            final color = colors[index];
            return GestureDetector(
              onTap: () => widget.onCategoryTap(entry.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: ChartStyles.legendChip(color),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.8),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${entry.key} (${formatMoneyWithCurrency(entry.value)})',
                      style: ChartStyles.legendLabel,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

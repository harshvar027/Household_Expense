import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        height: 240,
        alignment: Alignment.center,
        decoration: ChartStyles.emptyChart(),
        child: const Text(
          'No expense data available',
          style: ChartStyles.hintLabel,
        ),
      );
    }

    final entries = widget.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (s, e) => s + e.value);
    final colors = NeoPalette.categoryNeons(entries.length);

    final centerLabel = touchedIndex >= 0 && touchedIndex < entries.length
        ? entries[touchedIndex].key
        : 'Total';
    final centerAmount = touchedIndex >= 0 && touchedIndex < entries.length
        ? entries[touchedIndex].value
        : total;
    final centerPct = touchedIndex >= 0 && touchedIndex < entries.length && total > 0
        ? (entries[touchedIndex].value / total * 100)
        : null;

    return Column(
      children: [
        SizedBox(
          height: 248,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2.5,
                  centerSpaceRadius: 68,
                  startDegreeOffset: -90,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        setState(() => touchedIndex = -1);
                        return;
                      }

                      final index =
                          response.touchedSection!.touchedSectionIndex;
                      if (index < 0 || index >= entries.length) {
                        setState(() => touchedIndex = -1);
                        return;
                      }

                      setState(() => touchedIndex = index);

                      if (event is FlTapUpEvent) {
                        HapticFeedback.selectionClick();
                        widget.onCategoryTap(entries[index].key);
                      }
                    },
                  ),
                  sections: List.generate(entries.length, (index) {
                    final entry = entries[index];
                    final isTouched = index == touchedIndex;
                    final color = colors[index];

                    return PieChartSectionData(
                      color: color,
                      value: entry.value,
                      title: '',
                      radius: isTouched ? 54 : 44,
                      borderSide: BorderSide(
                        color: NeoPalette.obsidian.withValues(alpha: 0.55),
                        width: 1.5,
                      ),
                      badgeWidget: isTouched
                          ? _PercentBadge(
                              percent: total == 0
                                  ? 0
                                  : entry.value / total * 100,
                              color: color,
                            )
                          : null,
                      badgePositionPercentageOffset: 1.15,
                    );
                  }),
                ),
              ),
              IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 72),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        centerLabel,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ChartStyles.centerTitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatMoneyWithCurrency(centerAmount),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ChartStyles.centerValue,
                      ),
                      if (centerPct != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${centerPct.toStringAsFixed(0)}% of spend',
                          style: ChartStyles.hintLabel,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tap a slice for details',
          style: ChartStyles.hintLabel,
        ),
        const SizedBox(height: 14),
        ...List.generate(entries.length, (index) {
          final entry = entries[index];
          final color = colors[index];
          final pct = total == 0 ? 0.0 : entry.value / total;
          final selected = touchedIndex == index;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => touchedIndex = selected ? -1 : index);
                  widget.onCategoryTap(entry.key);
                },
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: 0.12)
                        : NeoPalette.slateElevated.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? color.withValues(alpha: 0.45)
                          : NeoPalette.cyberMint.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.55),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: ChartStyles.legendLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(pct * 100).toStringAsFixed(0)}%',
                            style: ChartStyles.legendMeta,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            formatMoneyWithCurrency(entry.value),
                            style: ChartStyles.legendLabel.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor:
                              NeoPalette.obsidian.withValues(alpha: 0.45),
                          valueColor: AlwaysStoppedAnimation(
                            color.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _PercentBadge extends StatelessWidget {
  final double percent;
  final Color color;

  const _PercentBadge({required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: NeoPalette.slateCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 10,
          ),
        ],
      ),
      child: Text(
        '${percent.toStringAsFixed(0)}%',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

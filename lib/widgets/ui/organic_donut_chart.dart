import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/chart_styles.dart';
import '../../theme/neo_palette.dart';
import '../../utils/money_format.dart';
import 'pressable_scale.dart';

/// Clean dark donut for Home — readable center total + soft neon ring.
class OrganicDonutChart extends StatefulWidget {
  final Map<String, double> categoryTotals;
  final void Function(String category)? onCategoryTap;

  const OrganicDonutChart({
    super.key,
    required this.categoryTotals,
    this.onCategoryTap,
  });

  @override
  State<OrganicDonutChart> createState() => _OrganicDonutChartState();
}

class _OrganicDonutChartState extends State<OrganicDonutChart>
    with SingleTickerProviderStateMixin {
  int? _touchedIndex;
  late AnimationController _appearController;

  @override
  void initState() {
    super.initState();
    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _appearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categoryTotals.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: ChartStyles.emptyChart(),
        child: const Text(
          'No spending data yet',
          style: ChartStyles.hintLabel,
        ),
      );
    }

    final entries = widget.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (s, e) => s + e.value);
    final colors = NeoPalette.categoryNeons(entries.length);
    final centerLabel = _touchedIndex != null
        ? entries[_touchedIndex!].key
        : 'This month';
    final centerValue = _touchedIndex != null
        ? entries[_touchedIndex!].value
        : total;
    final centerPct = _touchedIndex != null && total > 0
        ? entries[_touchedIndex!].value / total * 100
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 236,
          child: AnimatedBuilder(
            animation: _appearController,
            builder: (context, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final chartSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  return CustomPaint(
                    painter: _CleanDonutPainter(
                      entries: entries,
                      colors: colors,
                      touchedIndex: _touchedIndex,
                      progress: Curves.easeOutCubic.transform(
                        _appearController.value,
                      ),
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) => _handleTap(
                        details.localPosition,
                        entries,
                        chartSize,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 56),
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
                                formatMoneyWithCurrency(centerValue),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ChartStyles.centerValue,
                              ),
                              if (centerPct != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${centerPct.toStringAsFixed(0)}%',
                                  style: ChartStyles.hintLabel,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(entries.length.clamp(0, 8), (i) {
            final entry = entries[i];
            final pct = total == 0 ? 0 : (entry.value / total * 100).round();
            final selected = _touchedIndex == i;
            return PressableScale(
              scale: 0.97,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _touchedIndex = selected ? null : i);
                widget.onCategoryTap?.call(entry.key);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: ChartStyles.legendChip(
                  colors[i],
                  selected: selected,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors[i],
                        boxShadow: [
                          BoxShadow(
                            color: colors[i].withValues(alpha: 0.65),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${entry.key} · $pct%',
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

  void _handleTap(
    Offset position,
    List<MapEntry<String, double>> entries,
    Size chartSize,
  ) {
    final center = Offset(chartSize.width / 2, chartSize.height / 2);
    final delta = position - center;
    final distance = delta.distance;
    final outerR = chartSize.shortestSide * 0.42;
    final innerR = chartSize.shortestSide * 0.22;

    if (distance < innerR || distance > outerR) {
      setState(() => _touchedIndex = null);
      return;
    }

    var angle = math.atan2(delta.dy, delta.dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;

    final total = entries.fold<double>(0, (s, e) => s + e.value);
    var sweepStart = 0.0;
    for (var i = 0; i < entries.length; i++) {
      final sweep = (entries[i].value / total) * 2 * math.pi;
      if (angle >= sweepStart && angle < sweepStart + sweep) {
        HapticFeedback.selectionClick();
        setState(() => _touchedIndex = i);
        widget.onCategoryTap?.call(entries[i].key);
        return;
      }
      sweepStart += sweep;
    }
  }
}

class _CleanDonutPainter extends CustomPainter {
  final List<MapEntry<String, double>> entries;
  final List<Color> colors;
  final int? touchedIndex;
  final double progress;

  _CleanDonutPainter({
    required this.entries,
    required this.colors,
    required this.touchedIndex,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.34;
    final total = entries.fold<double>(0, (s, e) => s + e.value);
    if (total == 0) return;

    // Track ring
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..color = NeoPalette.slateElevated.withValues(alpha: 0.9)
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    var startAngle = -math.pi / 2;
    final gap = entries.length > 1 ? 0.035 : 0.0;

    for (var i = 0; i < entries.length; i++) {
      final fullSweep = (entries[i].value / total) * 2 * math.pi;
      final sweep = (fullSweep - gap).clamp(0.02, fullSweep) * progress;
      final selected = touchedIndex == i;
      final thickness = selected ? 34.0 : 28.0;
      final rect = Rect.fromCircle(center: center, radius: radius);

      if (selected) {
        final glow = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness + 10
          ..strokeCap = StrokeCap.butt
          ..color = colors[i].withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        canvas.drawArc(rect, startAngle, sweep, false, glow);
      }

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.butt
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + math.max(sweep, 0.01),
          colors: [
            colors[i],
            Color.lerp(colors[i], Colors.white, 0.18)!,
            colors[i].withValues(alpha: 0.92),
          ],
          transform: GradientRotation(startAngle),
        ).createShader(rect);

      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += fullSweep;
    }

    // Soft inner disc
    final inner = Paint()
      ..shader = RadialGradient(
        colors: [
          NeoPalette.slateCard.withValues(alpha: 0.55),
          NeoPalette.obsidian.withValues(alpha: 0.15),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.62));
    canvas.drawCircle(center, radius * 0.58, inner);
  }

  @override
  bool shouldRepaint(covariant _CleanDonutPainter oldDelegate) =>
      oldDelegate.touchedIndex != touchedIndex ||
      oldDelegate.progress != progress ||
      oldDelegate.entries != entries;
}

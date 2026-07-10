import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/chart_styles.dart';
import '../../theme/neo_palette.dart';
import '../../utils/money_format.dart';
import 'pressable_scale.dart';

/// Organic asymmetrical donut chart with neon glow segments.
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
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categoryTotals.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'No spending data yet',
            style: TextStyle(
              color: NeoPalette.textMuted.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final entries = widget.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (s, e) => s + e.value);
    final colors = NeoPalette.categoryNeons(entries.length);
    final centerLabel = _touchedIndex != null
        ? entries[_touchedIndex!].key
        : 'Total';
    final centerValue = _touchedIndex != null
        ? entries[_touchedIndex!].value
        : total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 230,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return CustomPaint(
                painter: _OrganicDonutPainter(
                  entries: entries,
                  colors: colors,
                  touchedIndex: _touchedIndex,
                  pulse: _pulseController.value,
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) => _handleTap(details.localPosition, entries),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          centerLabel,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: ChartStyles.hintLabel.copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatMoneyWithCurrency(centerValue),
                          style: ChartStyles.axisLabel.copyWith(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(entries.length.clamp(0, 6), (i) {
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
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                            color: colors[i].withValues(alpha: 0.8),
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

  void _handleTap(Offset position, List<MapEntry<String, double>> entries) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final size = box.size;
    final center = Offset(size.width / 2, size.height / 2);
    final delta = position - center;
    final distance = delta.distance;
    final innerR = size.shortestSide * 0.22;
    final outerR = size.shortestSide * 0.42;

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

class _OrganicDonutPainter extends CustomPainter {
  final List<MapEntry<String, double>> entries;
  final List<Color> colors;
  final int? touchedIndex;
  final double pulse;

  _OrganicDonutPainter({
    required this.entries,
    required this.colors,
    required this.touchedIndex,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.shortestSide * 0.34;
    final total = entries.fold<double>(0, (s, e) => s + e.value);
    if (total == 0) return;

    var startAngle = -math.pi / 2;
    for (var i = 0; i < entries.length; i++) {
      final sweep = (entries[i].value / total) * 2 * math.pi;
      final organic = 1 + 0.12 * math.sin(i * 1.7 + pulse * math.pi * 2);
      final thickness = (baseRadius * 0.28 * organic).clamp(22.0, 42.0);
      final radius = baseRadius + (i.isEven ? 6 : -4) + pulse * 3 * (i.isEven ? 1 : -1);
      final selected = touchedIndex == i;

      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? thickness + 6 : thickness
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweep,
          colors: [
            colors[i],
            Color.lerp(colors[i], NeoPalette.electricAmethyst, 0.35)!,
            colors[i].withValues(alpha: 0.85),
          ],
        ).createShader(rect);

      if (selected) {
        final glow = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness + 14
          ..strokeCap = StrokeCap.round
          ..color = colors[i].withValues(alpha: 0.25 + pulse * 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawArc(rect, startAngle, sweep * 0.98, false, glow);
      }

      canvas.drawArc(rect, startAngle, sweep * 0.96, false, paint);
      startAngle += sweep;
    }

    final innerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          NeoPalette.cyberMint.withValues(alpha: 0.08 + pulse * 0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius * 0.5));
    canvas.drawCircle(center, baseRadius * 0.5, innerGlow);
  }

  @override
  bool shouldRepaint(covariant _OrganicDonutPainter oldDelegate) =>
      oldDelegate.touchedIndex != touchedIndex ||
      oldDelegate.pulse != pulse ||
      oldDelegate.entries != entries;
}

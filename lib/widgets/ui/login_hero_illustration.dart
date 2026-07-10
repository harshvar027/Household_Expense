import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Catchy expense-manager hero art for the login / unlock screen.
class LoginHeroIllustration extends StatelessWidget {
  final double size;

  const LoginHeroIllustration({super.key, this.size = 196});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LoginHeroPainter(),
      ),
    );
  }
}

class _LoginHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    _drawGlow(canvas, center, w * 0.48);
    _drawOrbitRing(canvas, center, w * 0.44);
    _drawOrbitRing(canvas, center, w * 0.36, alpha: 0.12);

    _drawReceipt(canvas, Offset(w * 0.08, h * 0.18), w * 0.22);
    _drawCoinStack(canvas, Offset(w * 0.82, h * 0.22), w * 0.09);
    _drawBudgetBadge(canvas, Offset(w * 0.86, h * 0.72), w * 0.18);

    _drawDashboardCard(canvas, Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.54),
      width: w * 0.62,
      height: h * 0.46,
    ));

    _drawWallet(canvas, Offset(w * 0.18, h * 0.66), w * 0.2);
    _drawPieChart(canvas, Offset(w * 0.78, h * 0.48), w * 0.13);
    _drawCurrencyBadge(canvas, Offset(w * 0.5, h * 0.14), w * 0.16);
    _drawSparkles(canvas, size);
  }

  void _drawGlow(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.28),
            AppColors.accent.withValues(alpha: 0.12),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  void _drawOrbitRing(Canvas canvas, Offset center, double radius, {double alpha = 0.2}) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.primary.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawDashboardCard(Canvas canvas, Rect rect) {
    final card = RRect.fromRectAndRadius(rect, const Radius.circular(22));
    canvas.drawRRect(
      card,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF4F7FF)],
        ).createShader(rect),
    );
    canvas.drawRRect(
      card,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    final header = RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.22),
      const Radius.circular(22),
    );
    canvas.drawRRect(
      header,
      Paint()
        ..shader = LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ).createShader(header.outerRect),
    );

    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(rect.left + 16 + i * 10, rect.top + 14),
        2.5,
        dotPaint,
      );
    }

    final chartBase = rect.bottom - 18;
    final bars = [
      (AppColors.income, 0.42),
      (AppColors.expense, 0.62),
      (AppColors.savings, 0.36),
      (AppColors.warning, 0.5),
    ];
    final barW = rect.width * 0.11;
    final gap = rect.width * 0.05;
    final startX = rect.left + rect.width * 0.12;

    for (var i = 0; i < bars.length; i++) {
      final color = bars[i].$1;
      final heightFactor = bars[i].$2;
      final barH = rect.height * 0.34 * heightFactor;
      final x = startX + i * (barW + gap);
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, chartBase - barH, barW, barH),
        const Radius.circular(6),
      );
      canvas.drawRRect(barRect, Paint()..color = color);
    }

    final trend = Path()
      ..moveTo(rect.left + rect.width * 0.12, rect.top + rect.height * 0.52)
      ..quadraticBezierTo(
        rect.left + rect.width * 0.42,
        rect.top + rect.height * 0.34,
        rect.right - rect.width * 0.12,
        rect.top + rect.height * 0.44,
      );
    canvas.drawPath(
      trend,
      Paint()
        ..color = AppColors.balance
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawWallet(Canvas canvas, Offset origin, double width) {
    final h = width * 0.72;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(origin.dx, origin.dy, width, h),
      const Radius.circular(12),
    );
    canvas.drawRRect(rect, Paint()..color = AppColors.primaryDark);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx, origin.dy - h * 0.18, width, h * 0.34),
        const Radius.circular(10),
      ),
      Paint()..color = AppColors.primary,
    );
    canvas.drawCircle(
      Offset(origin.dx + width * 0.78, origin.dy + h * 0.48),
      width * 0.09,
      Paint()..color = AppColors.accent,
    );
  }

  void _drawPieChart(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final slices = [
      (AppColors.primary, -math.pi / 2, math.pi * 0.9),
      (AppColors.expense, math.pi * 0.4, math.pi * 0.8),
      (AppColors.income, math.pi * 1.2, math.pi * 0.55),
    ];

    for (final slice in slices) {
      final paint = Paint()..color = slice.$1;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 3),
        slice.$2,
        slice.$3,
        true,
        paint,
      );
    }

    canvas.drawCircle(center, radius * 0.42, Paint()..color = Colors.white);
  }

  void _drawReceipt(Canvas canvas, Offset origin, double width) {
    final height = width * 1.35;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(origin.dx, origin.dy, width, height),
      const Radius.circular(10),
    );
    canvas.drawRRect(rect, Paint()..color = Colors.white);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = AppColors.expense.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final line = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.45)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final y = origin.dy + 14 + i * 10;
      canvas.drawLine(
        Offset(origin.dx + 10, y),
        Offset(origin.dx + width - 10, y),
        line,
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx + 8, origin.dy + height - 18, width - 16, 10),
        const Radius.circular(4),
      ),
      Paint()..color = AppColors.expense.withValues(alpha: 0.18),
    );
  }

  void _drawCoinStack(Canvas canvas, Offset top, double radius) {
    final coinPaint = Paint()..color = AppColors.warning;
    final edgeColor = const Color(0xFFE09B1A);
    for (var i = 0; i < 3; i++) {
      final c = Offset(top.dx, top.dy + i * 5);
      canvas.drawCircle(c, radius, coinPaint);
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..color = edgeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  void _drawBudgetBadge(Canvas canvas, Offset center, double size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size, height: size * 0.72),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = AppColors.income.withValues(alpha: 0.16),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = AppColors.income
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final check = Paint()
      ..color = AppColors.income
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final p = Path()
      ..moveTo(center.dx - size * 0.16, center.dy)
      ..lineTo(center.dx - size * 0.02, center.dy + size * 0.12)
      ..lineTo(center.dx + size * 0.18, center.dy - size * 0.12);
    canvas.drawPath(p, check);
  }

  void _drawCurrencyBadge(Canvas canvas, Offset center, double size) {
    canvas.drawCircle(
      center,
      size * 0.5,
      Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.warning, Color(0xFFE09B1A)],
        ).createShader(Rect.fromCircle(center: center, radius: size * 0.5)),
    );
    canvas.drawCircle(
      center,
      size * 0.5,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: '₹',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawSparkles(Canvas canvas, Size size) {
    final sparkle = Paint()..color = AppColors.accent.withValues(alpha: 0.85);
    final points = [
      Offset(size.width * 0.28, size.height * 0.1),
      Offset(size.width * 0.7, size.height * 0.08),
      Offset(size.width * 0.12, size.height * 0.52),
      Offset(size.width * 0.9, size.height * 0.56),
    ];
    for (final p in points) {
      canvas.drawCircle(p, 2.2, sparkle);
      canvas.drawCircle(p, 5, Paint()..color = AppColors.accent.withValues(alpha: 0.18));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

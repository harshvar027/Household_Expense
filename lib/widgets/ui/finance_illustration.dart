import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum FinanceIllustrationType { wallet, chart, empty, savings }

class FinanceIllustration extends StatelessWidget {
  final FinanceIllustrationType type;
  final double size;

  const FinanceIllustration({
    super.key,
    required this.type,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FinancePainter(type),
      ),
    );
  }
}

class _FinancePainter extends CustomPainter {
  final FinanceIllustrationType type;

  _FinancePainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.42;

    final bg = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primaryLight.withValues(alpha: 0.35),
          AppColors.accent.withValues(alpha: 0.08),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, bg);

    switch (type) {
      case FinanceIllustrationType.wallet:
        _drawWallet(canvas, size);
      case FinanceIllustrationType.chart:
        _drawChart(canvas, size);
      case FinanceIllustrationType.empty:
        _drawEmpty(canvas, size);
      case FinanceIllustrationType.savings:
        _drawSavings(canvas, size);
    }
  }

  void _drawWallet(Canvas canvas, Size size) {
    final w = size.width * 0.55;
    final h = size.height * 0.38;
    final left = (size.width - w) / 2;
    final top = size.height * 0.32;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, w, h),
      const Radius.circular(14),
    );
    final wallet = Paint()..color = AppColors.primary;
    canvas.drawRRect(rect, wallet);

    final flap = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top - h * 0.22, w, h * 0.35),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      flap,
      Paint()..color = AppColors.primaryDark,
    );

    canvas.drawCircle(
      Offset(left + w * 0.78, top + h * 0.5),
      w * 0.08,
      Paint()..color = AppColors.accent,
    );

    final coin = Paint()..color = AppColors.warning;
    canvas.drawCircle(Offset(left + w * 0.25, top - h * 0.45), w * 0.1, coin);
    canvas.drawCircle(Offset(left + w * 0.45, top - h * 0.55), w * 0.07, coin);
  }

  void _drawChart(Canvas canvas, Size size) {
    final baseY = size.height * 0.68;
    final barW = size.width * 0.1;
    final colors = [AppColors.primary, AppColors.accent, AppColors.expense, AppColors.savings];
    final heights = [0.25, 0.42, 0.32, 0.55];
    for (var i = 0; i < 4; i++) {
      final x = size.width * 0.22 + i * (barW + size.width * 0.06);
      final h = size.height * heights[i];
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, baseY - h, barW, h),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, Paint()..color = colors[i]);
    }
    final line = Path()
      ..moveTo(size.width * 0.18, size.height * 0.35)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.2,
        size.width * 0.82,
        size.height * 0.28,
      );
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.balance
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawEmpty(Canvas canvas, Size size) {
    final doc = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.5),
        width: size.width * 0.42,
        height: size.height * 0.5,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(doc, Paint()..color = Colors.white);
    canvas.drawRRect(
      doc,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final line = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.5)
      ..strokeWidth = 2;
    for (var i = 0; i < 3; i++) {
      final y = size.height * 0.42 + i * size.height * 0.08;
      canvas.drawLine(
        Offset(size.width * 0.34, y),
        Offset(size.width * 0.66, y),
        line,
      );
    }
  }

  void _drawSavings(Canvas canvas, Size size) {
    final jar = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.52),
        width: size.width * 0.38,
        height: size.height * 0.48,
      ),
      const Radius.circular(16),
    );
    canvas.drawRRect(jar, Paint()..color = AppColors.savings.withValues(alpha: 0.85));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height * 0.3),
          width: size.width * 0.44,
          height: size.height * 0.08,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = AppColors.savings,
    );
    final coin = Paint()..color = AppColors.warning;
    canvas.drawCircle(Offset(size.width * 0.42, size.height * 0.58), 8, coin);
    canvas.drawCircle(Offset(size.width * 0.55, size.height * 0.62), 7, coin);
    canvas.drawCircle(Offset(size.width * 0.48, size.height * 0.68), 6, coin);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import 'app_logo.dart';

/// Spinning ring text around the Household Expense mark.
class CircularBrandMark extends StatefulWidget {
  final double size;
  final String ringText;
  final Duration spinDuration;
  final bool showWordmark;

  const CircularBrandMark({
    super.key,
    this.size = 48,
    this.ringText = 'PRIVATE · SECURE · ',
    this.spinDuration = const Duration(seconds: 22),
    this.showWordmark = true,
  });

  @override
  State<CircularBrandMark> createState() => _CircularBrandMarkState();
}

class _CircularBrandMarkState extends State<CircularBrandMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: widget.spinDuration)
      ..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accentOf(context);
    final markSize = widget.size * 0.46;
    final fontSize = math.max(7.5, widget.size * 0.088);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              RotationTransition(
                turns: _spin,
                child: CustomPaint(
                  size: Size.square(widget.size),
                  painter: _CircularTextPainter(
                    text: widget.ringText,
                    color: accent.withValues(alpha: 0.88),
                    fontSize: fontSize,
                    radiusFactor: 0.42,
                  ),
                ),
              ),
              Container(
                width: markSize + 6,
                height: markSize + 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).scaffoldBackgroundColor.withValues(
                        alpha: 0.72,
                      ),
                ),
              ),
              ClipOval(
                child: Image.asset(
                  AppLogo.assetPath,
                  width: markSize,
                  height: markSize,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.home_work_rounded,
                    size: markSize * 0.7,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.showWordmark) ...[
          const SizedBox(width: 10),
          Text(
            'Household',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

class _CircularTextPainter extends CustomPainter {
  final String text;
  final Color color;
  final double fontSize;
  final double radiusFactor;

  _CircularTextPainter({
    required this.text,
    required this.color,
    required this.fontSize,
    required this.radiusFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final letters = text.split('');
    if (letters.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * radiusFactor;
    final style = GoogleFonts.spaceGrotesk(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1,
    );

    for (var i = 0; i < letters.length; i++) {
      final letter = letters[i] == ' ' ? '\u00A0' : letters[i];
      final angle = (2 * math.pi / letters.length) * i;
      final tp = TextPainter(
        text: TextSpan(text: letter, style: style),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.translate(0, -radius);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CircularTextPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.color != color ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.radiusFactor != radiusFactor;
  }
}

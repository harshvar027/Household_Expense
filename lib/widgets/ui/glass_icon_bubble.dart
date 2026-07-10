import 'dart:ui';

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Frosted circular / rounded icon container — Apple-style.
class GlassIconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final bool highlighted;

  const GlassIconBubble({
    super.key,
    required this.icon,
    required this.color,
    this.size = 48,
    this.iconSize = 24,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.32),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: highlighted
                  ? [
                      color.withValues(alpha: 0.28),
                      color.withValues(alpha: 0.14),
                    ]
                  : [
                      color.withValues(alpha: 0.18),
                      color.withValues(alpha: 0.06),
                    ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: highlighted ? 0.85 : 0.55),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: highlighted ? 0.2 : 0.1),
                blurRadius: highlighted ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }
}

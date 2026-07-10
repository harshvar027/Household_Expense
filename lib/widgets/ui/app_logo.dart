import 'package:flutter/material.dart';

/// Official Household Expense / Expense Tracker brand mark.
class AppLogo extends StatelessWidget {
  final double size;
  final BorderRadiusGeometry? borderRadius;
  final bool showShadow;

  const AppLogo({
    super.key,
    this.size = 96,
    this.borderRadius,
    this.showShadow = true,
  });

  static const assetPath = 'assets/branding/app_logo.png';

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size * 0.22);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: size * 0.18,
                  offset: Offset(0, size * 0.06),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, error, stackTrace) => ColoredBox(
            color: Colors.black,
            child: Icon(Icons.home_work_rounded, size: size * 0.45, color: Colors.white70),
          ),
        ),
      ),
    );
  }
}

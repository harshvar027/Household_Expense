import 'dart:ui';

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Apple-style frosted glass surface (iOS vibrancy / material blur).
class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final double opacity;
  final Color? tint;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;

  const GlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 22,
    this.blurSigma = 28,
    this.opacity = 0.62,
    this.tint,
    this.border,
    this.boxShadow,
    this.width,
    this.height,
  });

  /// Dark neo glass cards on obsidian backgrounds.
  factory GlassSurface.card({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 22,
  }) {
    return GlassSurface(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      borderRadius: borderRadius,
      blurSigma: 28,
      opacity: 0.65,
      tint: const Color(0xFF1A2233),
      border: Border.all(
        color: AppColors.cyberMint.withValues(alpha: 0.15),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.electricAmethyst.withValues(alpha: 0.1),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
      child: child,
    );
  }

  /// Stronger glass for nav bars, FABs, floating chrome.
  factory GlassSurface.chrome({
    required Widget child,
    EdgeInsetsGeometry? padding,
    double borderRadius = 28,
    double? height,
  }) {
    return GlassSurface(
      padding: padding,
      borderRadius: borderRadius,
      blurSigma: 40,
      opacity: 0.78,
      height: height,
      tint: const Color(0xFF141B29),
      border: Border.all(
        color: AppColors.cyberMint.withValues(alpha: 0.18),
        width: 1.4,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
        BoxShadow(
          color: AppColors.electricAmethyst.withValues(alpha: 0.12),
          blurRadius: 32,
          offset: const Offset(0, 4),
        ),
      ],
      child: child,
    );
  }

  /// Glass on top of gradient hero sections.
  factory GlassSurface.onGradient({
    required Widget child,
    EdgeInsetsGeometry? padding,
    double borderRadius = 18,
  }) {
    return GlassSurface(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: borderRadius,
      blurSigma: 18,
      opacity: 0.12,
      tint: Colors.white,
      border: Border.all(
        color: AppColors.cyberMint.withValues(alpha: 0.2),
        width: 1,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fill = (tint ?? Colors.white).withValues(alpha: opacity);

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: fill,
              border: border,
              boxShadow: boxShadow,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A2233).withValues(alpha: opacity * 0.9),
                  const Color(0xFF0D121C).withValues(alpha: opacity * 0.5),
                ],
              ),
            ),
            child: padding != null ? Padding(padding: padding!, child: child) : child,
          ),
        ),
      ),
    );
  }
}

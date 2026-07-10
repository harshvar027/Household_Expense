import 'dart:ui';

import 'package:flutter/material.dart';
import '../../theme/neo_palette.dart';

/// Dark glassmorphism surfaces for the neo-futuristic dashboard.
class NeoGlass {
  NeoGlass._();

  static Widget card({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 24,
    Color? glowColor,
    double glowIntensity = 0.18,
  }) {
    final glow = glowColor ?? NeoPalette.cyberMint;
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  NeoPalette.slateCard.withValues(alpha: 0.72),
                  NeoPalette.slateElevated.withValues(alpha: 0.45),
                ],
              ),
              border: Border.all(
                color: glow.withValues(alpha: 0.22),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: glowIntensity),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  static Widget chrome({
    required Widget child,
    double borderRadius = 32,
    double? height,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                NeoPalette.slateCard.withValues(alpha: 0.85),
                NeoPalette.obsidianSlate.withValues(alpha: 0.65),
              ],
            ),
            border: Border.all(
              color: NeoPalette.cyberMint.withValues(alpha: 0.18),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: NeoPalette.electricAmethyst.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  static Widget onGradient({
    required Widget child,
    EdgeInsetsGeometry? padding,
    double borderRadius = 16,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: NeoPalette.cyberMint.withValues(alpha: 0.2),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  static Widget sectionHeader(String title, {String? trailing}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: NeoPalette.neonGradient,
            ),
            boxShadow: [
              BoxShadow(
                color: NeoPalette.cyberMint.withValues(alpha: 0.5),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: NeoPalette.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: NeoPalette.textMuted,
            ),
          ),
      ],
    );
  }
}

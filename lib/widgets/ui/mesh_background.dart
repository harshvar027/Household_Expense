import 'dart:ui';

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/neo_palette.dart';

class MeshBackground extends StatelessWidget {
  final Widget child;

  const MeshBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: NeoPalette.obsidian)),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.2, -0.6),
                radius: 1.2,
                colors: [
                  NeoPalette.obsidianSlate,
                  NeoPalette.obsidian,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -100,
          right: -80,
          child: _blob(280, AppColors.meshBlob1.withValues(alpha: 0.22)),
        ),
        Positioned(
          top: 180,
          left: -120,
          child: _blob(320, AppColors.meshBlob2.withValues(alpha: 0.16)),
        ),
        Positioned(
          bottom: 60,
          right: -60,
          child: _blob(240, AppColors.meshBlob3.withValues(alpha: 0.14)),
        ),
        Positioned(
          bottom: -40,
          left: 40,
          child: _blob(180, NeoPalette.electricAmethyst.withValues(alpha: 0.08)),
        ),
        child,
      ],
    );
  }

  Widget _blob(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

extension StaggerAnimate on Widget {
  Widget staggerIn({
    required int index,
    int baseDelayMs = 50,
    double slideY = 0.12,
  }) {
    return animate(delay: (index * baseDelayMs).ms)
        .fadeIn(duration: 420.ms, curve: Curves.easeOutCubic)
        .slideY(
          begin: slideY,
          end: 0,
          duration: 480.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

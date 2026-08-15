import 'package:flutter/material.dart';
import 'neo_palette.dart';

/// Shared axis / legend typography for dark neo charts.
class ChartStyles {
  ChartStyles._();

  static const axisLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: NeoPalette.textPrimary,
    height: 1.2,
    letterSpacing: -0.2,
  );

  static const axisLabelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: NeoPalette.textSecondary,
    height: 1.15,
  );

  static const legendLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: NeoPalette.textPrimary,
    height: 1.25,
  );

  static const legendMeta = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: NeoPalette.textSecondary,
    height: 1.2,
  );

  static const hintLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: NeoPalette.textMuted,
  );

  static const centerTitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: NeoPalette.textSecondary,
    letterSpacing: 0.2,
  );

  static const centerValue = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: NeoPalette.textPrimary,
    letterSpacing: -0.6,
    height: 1.1,
  );

  static const sliceTitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    shadows: [
      Shadow(color: Color(0x99000000), blurRadius: 8, offset: Offset(0, 1)),
    ],
  );

  static const sliceTitleLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    shadows: [
      Shadow(color: Color(0xAA000000), blurRadius: 10, offset: Offset(0, 1)),
    ],
  );

  static BoxDecoration legendChip(Color accent, {bool selected = false}) {
    return BoxDecoration(
      color: selected
          ? accent.withValues(alpha: 0.18)
          : NeoPalette.slateElevated.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: selected
            ? accent.withValues(alpha: 0.65)
            : NeoPalette.cyberMint.withValues(alpha: 0.14),
        width: 1,
      ),
    );
  }

  static BoxDecoration emptyChart() {
    return BoxDecoration(
      color: NeoPalette.slateElevated.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: NeoPalette.cyberMint.withValues(alpha: 0.12),
      ),
    );
  }
}

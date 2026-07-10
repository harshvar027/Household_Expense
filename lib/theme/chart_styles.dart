import 'package:flutter/material.dart';
import 'neo_palette.dart';

/// Shared axis / legend typography for dark neo charts.
class ChartStyles {
  ChartStyles._();

  static const axisLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: NeoPalette.textPrimary,
    height: 1.2,
  );

  static const axisLabelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: NeoPalette.textPrimary,
    height: 1.15,
  );

  static const legendLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: NeoPalette.textPrimary,
    height: 1.25,
  );

  static const hintLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: NeoPalette.textSecondary,
  );

  static const sliceTitle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    shadows: [
      Shadow(color: Color(0xCC000000), blurRadius: 6, offset: Offset(0, 1)),
      Shadow(color: Color(0x99000000), blurRadius: 2),
    ],
  );

  static const sliceTitleLarge = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    shadows: [
      Shadow(color: Color(0xCC000000), blurRadius: 8, offset: Offset(0, 1)),
      Shadow(color: Color(0x99000000), blurRadius: 3),
    ],
  );

  static BoxDecoration legendChip(Color accent, {bool selected = false}) {
    return BoxDecoration(
      color: selected
          ? accent.withValues(alpha: 0.22)
          : NeoPalette.slateElevated,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: selected
            ? accent.withValues(alpha: 0.75)
            : NeoPalette.cyberMint.withValues(alpha: 0.22),
        width: 1.2,
      ),
    );
  }
}

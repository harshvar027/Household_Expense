import 'package:flutter/material.dart';

/// Futuristic obsidian + neon accent palette for the premium dashboard.
class NeoPalette {
  NeoPalette._();

  static const obsidian = Color(0xFF070B12);
  static const obsidianSlate = Color(0xFF0D121C);
  static const slateElevated = Color(0xFF141B29);
  static const slateCard = Color(0xFF1A2233);

  static const cyberMint = Color(0xFF3FFFD8);
  static const cyberMintSoft = Color(0xFF7CFFE8);
  static const electricAmethyst = Color(0xFFB366FF);
  static const electricAmethystSoft = Color(0xFFD49BFF);

  static const textPrimary = Color(0xFFEEF2FF);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);

  static const incomeNeon = Color(0xFF34F5C5);
  static const expenseNeon = Color(0xFFFF5C8A);
  static const savingsNeon = Color(0xFF6B8CFF);
  static const warningNeon = Color(0xFFFFB84D);

  static const mintGlow = Color(0x403FFFD8);
  static const amethystGlow = Color(0x40B366FF);

  static const heroGradient = [
    Color(0xFF1A1035),
    Color(0xFF0F1A2E),
    Color(0xFF0A1628),
  ];

  static const neonGradient = [
    cyberMint,
    electricAmethyst,
  ];

  static const meshMint = Color(0xFF3FFFD8);
  static const meshAmethyst = Color(0xFFB366FF);
  static const meshViolet = Color(0xFF6366F1);

  static List<Color> categoryNeons(int index) {
    const palette = [
      cyberMint,
      electricAmethyst,
      incomeNeon,
      expenseNeon,
      savingsNeon,
      warningNeon,
      Color(0xFF22D3EE),
      Color(0xFFF472B6),
      Color(0xFFA78BFA),
      Color(0xFF4ADE80),
    ];
    return List.generate(
      index,
      (i) => palette[i % palette.length],
    );
  }
}

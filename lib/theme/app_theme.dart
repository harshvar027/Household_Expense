import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'neo_palette.dart';

class AppColors {
  // Neo-futuristic core
  static const primary = NeoPalette.electricAmethyst;
  static const primaryDark = Color(0xFF9333EA);
  static const primaryLight = NeoPalette.electricAmethystSoft;
  static const accent = NeoPalette.cyberMint;
  static const accentSoft = NeoPalette.cyberMintSoft;

  static const surface = NeoPalette.obsidianSlate;
  static const surfaceElevated = NeoPalette.slateElevated;
  static const card = NeoPalette.slateCard;

  static const textPrimary = NeoPalette.textPrimary;
  static const textSecondary = NeoPalette.textSecondary;
  static const textMuted = NeoPalette.textMuted;

  static const income = NeoPalette.incomeNeon;
  static const expense = NeoPalette.expenseNeon;
  static const savings = NeoPalette.savingsNeon;
  static const balance = NeoPalette.electricAmethyst;
  static const warning = NeoPalette.warningNeon;

  static const heroGradient = NeoPalette.heroGradient;

  static const meshBlob1 = NeoPalette.meshAmethyst;
  static const meshBlob2 = NeoPalette.meshMint;
  static const meshBlob3 = NeoPalette.meshViolet;

  static const cyberMint = NeoPalette.cyberMint;
  static const electricAmethyst = NeoPalette.electricAmethyst;
  static const obsidian = NeoPalette.obsidian;
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.12)),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        highlightElevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.accent.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.accent.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.cyberMint, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: NeoPalette.slateCard,
        contentTextStyle: GoogleFonts.spaceGrotesk(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.accent.withValues(alpha: 0.08),
        thickness: 1,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }
}

/// iOS-style full-screen push with Cupertino slide.
Route<T> appPageRoute<T>(Widget page) {
  return CupertinoPageRoute<T>(builder: (_) => page);
}

/// Soft haptic for taps — feels native on iOS.
void hapticTap() => HapticFeedback.lightImpact();

void hapticSelect() => HapticFeedback.selectionClick();

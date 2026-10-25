import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Studio-dark palette: ink, amber accent, cool slate — not purple-default AI.
class AppColors {
  static const ink = Color(0xFF12151A);
  static const inkElevated = Color(0xFF1A1F27);
  static const inkSoft = Color(0xFF242B36);
  static const line = Color(0xFF343D4C);
  static const text = Color(0xFFE8EDF5);
  static const textMuted = Color(0xFF9AA6B8);
  static const amber = Color(0xFFE8A54B);
  static const amberDim = Color(0xFFB87A2E);
  static const mint = Color(0xFF6FCFB0);
  static const danger = Color(0xFFE57373);
}

class AppTheme {
  static ThemeData dark() {
    final display = GoogleFonts.fraunces();
    final body = GoogleFonts.sourceSans3();

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.ink,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.inkElevated,
        primary: AppColors.amber,
        onPrimary: AppColors.ink,
        secondary: AppColors.mint,
        error: AppColors.danger,
        onSurface: AppColors.text,
        outline: AppColors.line,
      ),
      fontFamily: body.fontFamily,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: body.fontFamily,
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ).copyWith(
        displayLarge: display.copyWith(
          fontSize: 57,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        displayMedium: display.copyWith(
          fontSize: 45,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        displaySmall: display.copyWith(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        headlineLarge: display.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        headlineMedium: display.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        headlineSmall: display.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        titleLarge: display.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: display.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.inkElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inkSoft,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.ink,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.line),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.inkSoft,
        selectedColor: AppColors.amberDim,
        labelStyle: const TextStyle(color: AppColors.text),
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerColor: AppColors.line,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.inkSoft,
        contentTextStyle: const TextStyle(color: AppColors.text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

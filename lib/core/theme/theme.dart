import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        surface: AppColors.cardBackground,
        primary: AppColors.primaryAccent,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.periodRose,
        onSecondary: AppColors.onPrimary,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        error: AppColors.errorRed,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.sora(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: AppColors.onBackground,
        ),
        headlineLarge: GoogleFonts.sora(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: AppColors.onBackground,
        ),
        headlineMedium: GoogleFonts.sora(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.onBackground,
        ),
        titleMedium: GoogleFonts.sora(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.onBackground,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: AppColors.onBackground,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.onSurfaceVariant,
          height: 1.45,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.onBackground,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryAccent,
        contentTextStyle: GoogleFonts.inter(color: AppColors.onPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Kept as alias for backwards compatibility
  static ThemeData get darkTheme => lightTheme;
}

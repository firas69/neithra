import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      primarySwatch: MaterialColor(AppColors.navyBlue.toARGB32(), {
        50: AppColors.lightSilver,
        100: AppColors.silver,
        200: AppColors.lightNavy,
        300: AppColors.navyBlue,
        400: AppColors.navyBlue,
        500: AppColors.navyBlue,
        600: AppColors.navyBlue,
        700: AppColors.navyBlue,
        800: AppColors.navyBlue,
        900: AppColors.navyBlue,
      }),
      scaffoldBackgroundColor: AppColors.lightGray,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navyBlue,
        foregroundColor: AppColors.white,
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navyBlue,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.navyBlue,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.navyBlue,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: AppColors.darkGray, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.darkGray, fontSize: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.silver),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.navyBlue, width: 2),
        ),
        filled: true,
        fillColor: AppColors.white,
      ),
    );
  }
}

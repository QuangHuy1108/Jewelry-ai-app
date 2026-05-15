import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: AppColors.canvasParchment,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.ink,
      surface: AppColors.canvas,
      onPrimary: AppColors.bodyOnDark,
      onSurface: AppColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surfaceBlack,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.bodyOnDark),
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.bodyOnDark,
        fontSize: 17, // SF Pro dense link / navigation sizing
        fontWeight: FontWeight.w400,
        letterSpacing: -0.12,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        letterSpacing: 0,
        height: 1.1,
      ),
      headlineMedium: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        letterSpacing: -0.374,
        height: 1.47,
      ),
      bodyLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
        letterSpacing: -0.374,
        height: 1.47,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
        letterSpacing: -0.224,
        height: 1.43,
      ),
    ),
    useMaterial3: true,
  );
}
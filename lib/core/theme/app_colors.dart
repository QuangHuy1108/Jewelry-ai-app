import 'package:flutter/material.dart';

class AppColors {
  // Brand & Accent
  static const Color primary = Color(0xFF0066CC);
  static const Color primaryFocus = Color(0xFF0071E3);
  static const Color primaryOnDark = Color(0xFF2997FF);

  // Surface
  static const Color canvas = Color(0xFFFFFFFF);
  static const Color canvasParchment = Color(0xFFF5F5F7);
  static const Color surfacePearl = Color(0xFFFAFAFC);
  static const Color surfaceTile1 = Color(0xFF272729);
  static const Color surfaceTile2 = Color(0xFF2A2A2C);
  static const Color surfaceTile3 = Color(0xFF252527);
  static const Color surfaceBlack = Color(0xFF000000);
  static const Color surfaceChipTranslucent = Color(0xD2D2D2D7); // ~82% opacity base

  // Text
  static const Color ink = Color(0xFF1D1D1F);
  static const Color body = Color(0xFF1D1D1F);
  static const Color bodyOnDark = Color(0xFFFFFFFF);
  static const Color bodyMuted = Color(0xFFCCCCCC);
  static const Color inkMuted80 = Color(0xFF333333);
  static const Color inkMuted48 = Color(0xFF7A7A7A);

  // Hairlines & Borders
  static const Color dividerSoft = Color(0xFFF0F0F0);
  static const Color hairline = Color(0xFFE0E0E0);

  // Fallback equivalents for legacy integration compatibility
  static const Color primaryGold = primary;
  static const Color backgroundCream = canvasParchment;
  static const Color luxuryBlack = ink;
  static const Color textGrey = inkMuted48;
  static const Color errorRed = Color(0xFFD32F2F);
}
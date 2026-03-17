import 'package:flutter/material.dart';

class AppTheme {
  // 1. Định nghĩa các màu sắc chủ đạo (Luxury Minimal)
  static const Color gold = Color(0xFFD4AF37); // Vàng hoàng gia sang trọng
  static const Color black = Color(0xFF1A1A1A); // Đen tuyền bí ẩn
  static const Color cream = Color(0xFFF9F6F0); // Trắng kem nhẹ nhàng

  // 2. Cấu hình Theme sáng (Light Theme)
  static final ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: cream, // Màu nền chính của ứng dụng
    colorScheme: const ColorScheme.light(
      primary: gold,
      secondary: black,
      surface: cream,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: cream,
      elevation: 0, // Bỏ bóng đổ để giao diện phẳng và hiện đại hơn
      iconTheme: IconThemeData(color: black),
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: black,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2, // Khoảng cách chữ rộng ra một chút cho sang trọng
      ),
    ),
    useMaterial3: true,
  );
}
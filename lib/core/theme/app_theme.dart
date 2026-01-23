import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static final _inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide.none,
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      surface: AppColors.scaffoldLight,
    ),
    scaffoldBackgroundColor: AppColors.scaffoldLight,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF111827)), // Dark text for light mode
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      labelStyle: const TextStyle(color: Color(0xFF6B7280)),
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      border: _inputBorder,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      surface: AppColors.scaffoldDark,
    ),
    scaffoldBackgroundColor: AppColors.scaffoldDark,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 16, color: Colors.white), // White text for dark mode
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white60),
      border: _inputBorder,
    ),
  );
}
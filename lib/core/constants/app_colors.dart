import 'package:flutter/material.dart';

class AppColors {
  // 🌈 Brand (premium indigo → blue)
  static const Color primary = Color(0xFF4F46E5);
  static const Color primarySoft = Color(0xFFEEF2FF);

  // 🧱 Backgrounds
  static const Color scaffoldLight = Color(0xFFF8FAFC);
  static const Color scaffoldDark = Color(0xFF0F172A);

  // 🃏 Cards
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1E293B);
  static const double cardRadius = 16;
  static const double cardElevation = 1.5;

  // ➕ FAB
  static const Color fabBackground = primary;
  static const Color fabForeground = Colors.white;

  // 🏷 Chips
  static const Color chipBackground = Color(0xFFE5E7EB);
  static const Color chipSelectedBackground = primary;

  // 📊 Progress
  static const Color progressBackground = Color(0xFFE5E7EB);
  static const Color progressForeground = primary;

  // 🎨 Gradients (premium soft)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient todayGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
  );

  static const LinearGradient overdueGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFF87171)],
  );

  static const LinearGradient upcomingGradient = LinearGradient(
    colors: [Color(0xFF16A34A), Color(0xFF4ADE80)],
  );

  static const LinearGradient completedGradient = LinearGradient(
    colors: [Color(0xFF6B7280), Color(0xFFD1D5DB)],
  );
}

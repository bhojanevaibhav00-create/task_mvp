import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ================= BRAND =================
  static const Color primary = Color(0xFF4F46E5); // Indigo-600
  static const Color primarySoft = Color(0xFFEEF2FF);

  // ================= BACKGROUNDS =================
  static const Color scaffoldLight = Color(0xFFF8FAFC);
  static const Color scaffoldDark = Color(0xFF0F172A);

  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF020617);

  // ================= CARDS =================
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1E293B);

  static const double cardRadius = 16;
  static const double cardElevation = 1.5;

  // ================= TEXT =================
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);

  // ================= ICONS =================
  static const Color iconLight = Color(0xFF475569);
  static const Color iconDark = Color(0xFFCBD5E1);

  // ================= FAB =================
  static const Color fabBackground = primary;
  static const Color fabForeground = Colors.white;

  // ================= CHIPS =================
  static const Color chipBackground = Color(0xFFE5E7EB);
  static const Color chipSelectedBackground = primary;
  static const Color chipTextLight = Color(0xFF1E293B);
  static const Color chipTextDark = Color(0xFFF8FAFC);

  // ================= INPUTS =================
  static const Color inputBackgroundLight = Color(0xFFF1F5F9);
  static const Color inputBackgroundDark = Color(0xFF020617);
  static const Color inputBorder = Color(0xFFE5E7EB);

  // ================= PROGRESS =================
  static const Color progressBackground = Color(0xFFE5E7EB);
  static const Color progressForeground = primary;

  // ================= STATUS COLORS =================
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  // ================= GRADIENTS =================
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient todayGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient overdueGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient upcomingGradient = LinearGradient(
    colors: [Color(0xFF16A34A), Color(0xFF4ADE80)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient completedGradient = LinearGradient(
    colors: [Color(0xFF6B7280), Color(0xFFD1D5DB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ================= BRAND =================
  // Standardised Indigo-600 for a more modern, premium feel
  static const Color primary = Color(0xFF6366F1); 
  static const Color primarySoft = Color(0xFFEEF2FF);

  // ================= BACKGROUNDS =================
  // Using a specific off-white slate for the scaffold to make white cards pop
  static const Color scaffoldLight = Color(0xFFF8F9FD);
  static const Color scaffoldDark = Color(0xFF0F172A);

  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF020617);

  // ================= CARDS =================
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1E293B);

  // Increased radius to 24.0 for a more modern, friendly "Premium" look
  static const double cardRadius = 24.0;
  static const double cardElevation = 0.0; // Modern UI prefers subtle shadows over elevation

  // ================= TEXT (HIGH CONTRAST) =================
  // Slate-900 for primary text to ensure maximum readability on white/off-white
  static const Color textPrimaryLight = Color(0xFF1A1C1E); 
  static const Color textSecondaryLight = Color(0xFF64748B);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);

  // ================= ICONS =================
  static const Color iconLight = Color(0xFF94A3B8);
  static const Color iconDark = Color(0xFFCBD5E1);

  // ================= FAB =================
  static const Color fabBackground = primary;
  static const Color fabForeground = Colors.white;

  // ================= CHIPS =================
  static const Color chipBackground = Color(0xFFF1F5F9);
  static const Color chipSelectedBackground = primary;
  static const Color chipTextLight = Color(0xFF475569);
  static const Color chipTextDark = Color(0xFFF8FAFC);

  // ================= INPUTS =================
  // Light slate-50 for subtle input fields
  static const Color inputBackgroundLight = Color(0xFFF1F5F9); 
  static const Color inputBackgroundDark = Color(0xFF1E293B);
  static const Color inputBorder = Color(0xFFE2E8F0);

  // ================= PROGRESS =================
  static const Color progressBackground = Color(0xFFF1F5F9);
  static const Color progressForeground = primary;

  // ================= STATUS COLORS =================
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ================= GRADIENTS =================
  // Premium Indigo Gradient used for Dashboard and Project Detail AppBars
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient todayGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient overdueGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient upcomingGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient completedGradient = LinearGradient(
    colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
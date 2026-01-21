// lib/core/constants/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF4F46E5);

  static const cardLight = Color(0xFFF5F5F5);
  static const cardDark = Color(0xFF1F2937);
  static const cardRadius = 12.0;
  static const cardElevation = 2.0;

  static const fabBackground = primary;
  static const fabForeground = Colors.white;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
  );

  static const LinearGradient todayGradient =
  LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF818CF8)]);
  static const LinearGradient overdueGradient =
  LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF87171)]);
  static const LinearGradient upcomingGradient =
  LinearGradient(colors: [Color(0xFF10B981), Color(0xFF34D399)]);
  static const LinearGradient completedGradient =
  LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]);
}

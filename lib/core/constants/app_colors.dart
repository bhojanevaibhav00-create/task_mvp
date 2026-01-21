import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Summary card gradients
  static const LinearGradient todayGradient = LinearGradient(
    colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
  );
  static const LinearGradient overdueGradient = LinearGradient(
    colors: [Color(0xFFF87171), Color(0xFFB91C1C)],
  );
  static const LinearGradient upcomingGradient = LinearGradient(
    colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
  );
  static const LinearGradient completedGradient = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
  );

  // Card radius
  static const double cardRadius = 12;

  // TaskTile colors
  static const Color highPriority = Color(0xFFEF4444);
  static const Color mediumPriority = Color(0xFFF59E0B);
  static const Color lowPriority = Color(0xFF10B981);

  // Progress indicator
  static const Color progressForeground = Color(0xFF4F46E5);
  static const Color progressBackground = Color(0xFFE0E7FF);
}

import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF4F46E5); // Purple
  static const scaffoldLight = Color(0xFFF5F5F5);
  static const cardLight = Colors.white;
  static const background = scaffoldLight;
  static const scaffoldDark = Color(0xFF121212);
  static const cardDark = Color(0xFF1E1E1E);
  static const chipBackground = Color(0xFFE0E0E0);
  static const chipBackgroundDark = Color(0xFF2C2C2C);

  static const fabBackground = Color(0xFF4F46E5);
  static const fabForeground = Colors.white;

  static const double cardRadius = 12.0;
  static const double cardElevation = 4.0;

  // Gradients for Dashboard Summary Cards
  static const LinearGradient todayGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient overdueGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient upcomingGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient completedGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

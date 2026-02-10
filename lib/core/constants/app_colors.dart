import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF4F46E5);

  // GRADIENTS
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const upcomingGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
  );

  static const completedGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
  );

  // BACKGROUNDS
  static const scaffoldLight = Color(0xFFF6F7FB);
  static const scaffoldDark = Color(0xFF0F172A);

  static const cardDark = Color(0xFF1E293B);

  static const inputBackgroundDark = Color(0xFF1E293B);
}
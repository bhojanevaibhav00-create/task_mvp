import 'package:flutter/material.dart';

class UITokens {
  // 🎨 Brand Colors
  static const Color primary = Color(0xFF5B5FE9);   // Blue-Purple
  static const Color secondary = Color(0xFF6C63FF); // Soft Violet
  static const Color success = Color(0xFF22C55E);   // Green
  static const Color warning = Color(0xFFFB923C);   // Orange
  static const Color danger = Color(0xFFEF4444);    // Red

  // 🌈 Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF4ADE80), success],
  );

  // 🧩 Radius
  static const double radiusSM = 10;
  static const double radiusMD = 14;
  static const double radiusLG = 18;

  // 🌫 Shadows
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];
}

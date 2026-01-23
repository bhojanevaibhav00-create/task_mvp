import 'package:flutter/material.dart';

class AppTextStyles {
  // Use a very dark grey/black for primary text visibility
  static const Color primaryTextColor = Color(0xFF1A1C1E); 

  static const title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: primaryTextColor, // Added color
  );

  static const subtitle = TextStyle(
    fontSize: 14,
    color: Color(0xFF757575), // Specified a clear grey
  );

  static const body = TextStyle(
    fontSize: 16,
    height: 1.4,
    color: primaryTextColor, // Added color
  );

  static const chip = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: primaryTextColor, // Added color
  );
}
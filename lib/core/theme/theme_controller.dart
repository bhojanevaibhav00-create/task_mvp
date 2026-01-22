import 'package:flutter/material.dart';

class ThemeController {
  // This ValueNotifier holds the current theme mode
  static ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  // Toggle between light and dark
  static void toggleTheme() {
    themeMode.value =
    themeMode.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}

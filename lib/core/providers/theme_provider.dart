import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system);

  void toggle() {
    state = state == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  }

  void setSystem() => state = ThemeMode.system;
}

final themeModeProvider =
StateNotifierProvider<ThemeNotifier, ThemeMode>(
      (ref) => ThemeNotifier(),
);
import 'package:flutter/material.dart';

class ThemeService {
  // Singleton setup to match your other services
  ThemeService._privateConstructor();
  static final ThemeService instance = ThemeService._privateConstructor();

  // Reactive variable holding the current theme (defaults to system)
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  // Method to update the theme
  void updateThemeMode(ThemeMode mode) {
    themeMode.value = mode;
  }
}
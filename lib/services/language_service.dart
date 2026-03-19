import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Moved the enum here so all screens can share it
enum AppLanguage { english, sinhala, tamil }

class LanguageService {
  // Singleton pattern
  LanguageService._privateConstructor();
  static final LanguageService instance = LanguageService._privateConstructor();

  // Reactive state variable
  final ValueNotifier<AppLanguage> currentLanguage = ValueNotifier(
    AppLanguage.english,
  );

  static const String _langKey = 'app_language_preference';

  // Called once when the app starts
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString(_langKey) ?? AppLanguage.english.name;

    currentLanguage.value = AppLanguage.values.firstWhere(
      (e) => e.name == savedLang,
      orElse: () => AppLanguage.english,
    );
  }

  // Called when the user selects a new language from the dropdown
  Future<void> setLanguage(AppLanguage lang) async {
    currentLanguage.value = lang; // Instantly updates UI globally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang.name); // Saves to device storage
  }
}

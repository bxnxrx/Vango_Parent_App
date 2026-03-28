import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

enum AppLanguage { english, sinhala, tamil }

class LanguageService {
  LanguageService._privateConstructor();
  static final LanguageService instance = LanguageService._privateConstructor();

  final ValueNotifier<AppLanguage> currentLanguage = ValueNotifier(
    AppLanguage.english,
  );

  static const String _langKey = 'app_language_preference';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString(_langKey) ?? AppLanguage.english.name;

    currentLanguage.value = AppLanguage.values.firstWhere(
      (e) => e.name == savedLang,
      orElse: () => AppLanguage.english,
    );
  }

  // Helper method to feed into MaterialApp(locale: ...)
  Locale get currentLocale {
    switch (currentLanguage.value) {
      case AppLanguage.sinhala:
        return const Locale('si');
      case AppLanguage.tamil:
        return const Locale('ta');
      case AppLanguage.english:
      default:
        return const Locale('en');
    }
  }

  Future<void> setLanguage(AppLanguage lang) async {
    if (currentLanguage.value == lang) return; // Prevent redundant saves/logs

    currentLanguage.value = lang;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang.name);

    FirebaseAnalytics.instance.logEvent(
      name: 'user_language_changed',
      parameters: {'language': lang.name},
    );
  }
}

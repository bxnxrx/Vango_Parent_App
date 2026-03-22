import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart'; // ✅ ADD THIS

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

  Future<void> setLanguage(AppLanguage lang) async {
    if (currentLanguage.value == lang) return; // Prevent redundant saves/logs

    currentLanguage.value = lang;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang.name);

    // ✅ ENTERPRISE ANALYTICS: Centralized logging guarantees consistency
    FirebaseAnalytics.instance.logEvent(
      name: 'user_language_changed', // Standardized global event name
      parameters: {'language': lang.name},
    );
  }
}

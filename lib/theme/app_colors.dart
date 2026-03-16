import 'package:flutter/material.dart';

class AppColors {
  // --- LIGHT THEME COLORS (Your existing colors) ---
  static const Color background = Color(0xFFF6F6F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceStrong = Color(0xFFF1F1F5);
  static const Color stroke = Color(0xFFE1E3EC);
  static const Color overlay = Color(0xB31E1F33);
  static const Color white = Colors.white;

  static const Color textPrimary = Color(0xFF1E1F33);
  static const Color textSecondary = Color(0xFF7C7F92);

  // --- DARK THEME COLORS (New) ---
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E2C);
  static const Color darkSurfaceStrong = Color(0xFF2A2A3D);
  static const Color darkStroke = Color(0xFF3F3F5A);
  
  static const Color darkTextPrimary = Color(0xFFF6F6F9);
  static const Color darkTextSecondary = Color(0xFFA0A3B5);

  // --- SHARED BRAND COLORS ---
  static const Color accent = Color(0xFF2E335B);
  static const Color accentLow = Color(0x552E335B);
  
  // Lighter accent for dark mode to ensure contrast against dark backgrounds
  static const Color darkAccent = Color(0xFF6C75B3); 

  static const Color success = Color(0xFF2EB67D);
  static const Color warning = Color(0xFFF3A03C);
  static const Color danger = Color(0xFFE06D6D);

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [accent, Color(0xFF24284C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF7F7FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Optional: A dark mode card gradient
  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1E1E2C), Color(0xFF191925)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppShadows {
  static final List<BoxShadow> subtle = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 20,
      offset: const Offset(0, 12),
    ),
  ];
}
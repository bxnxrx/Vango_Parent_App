import 'package:flutter/material.dart';

class AppColors {
  // Base surfaces and overlays used throughout the UI.
  static const Color background = Color(0xFFF6F6F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceStrong = Color(0xFFF1F1F5);
  static const Color stroke = Color(0xFFE1E3EC);
  static const Color overlay = Color(0xB31E1F33);
  static const Color white = Colors.white;

  // Brand accent shades for buttons and highlights.
  static const Color accent = Color(0xFF2E335B);
  static const Color accentLow = Color(0x552E335B);

  // Default text colors.
  static const Color textPrimary = Color(0xFF1E1F33);
  static const Color textSecondary = Color(0xFF7C7F92);

  // Status colors for success, warning, and error states.
  static const Color success = Color(0xFF2EB67D);
  static const Color warning = Color(0xFFF3A03C);
  static const Color danger = Color(0xFFE06D6D);

  // Gradients reused by buttons and cards.
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
}

class AppShadows {
  // Soft drop shadow seen on elevated surfaces.
  static final List<BoxShadow> subtle = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 20,
      offset: const Offset(0, 12),
    ),
  ];
}

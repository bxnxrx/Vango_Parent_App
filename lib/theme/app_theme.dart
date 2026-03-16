import 'package:flutter/material.dart';
// Note: adjust import paths to match your project
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  // --- EXISTING LIGHT THEME ---
  static ThemeData light() {
    // ... (Keep your existing light() method exactly as it is) ...
    // Returning ThemeData(...)
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTypography.textTheme(AppColors.textPrimary), // Passes dark text
      // ... rest of your light theme properties
    );
  }

  // --- NEW DARK THEME ---
  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: AppColors.darkAccent,
      background: AppColors.darkBackground,
      primary: AppColors.darkAccent,
      secondary: AppColors.darkSurface,
    );

    const appBarTheme = AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.darkTextPrimary,
    );

    final navigationBarTheme = NavigationBarThemeData(
      indicatorColor: AppColors.darkAccent.withOpacity(0.15),
      backgroundColor: AppColors.darkBackground,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      elevation: 0,
    );

    final listTileTheme = ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      tileColor: AppColors.darkSurface,
      iconColor: AppColors.darkAccent,
    );

    const bottomSheetTheme = BottomSheetThemeData(
      backgroundColor: AppColors.darkSurface,
      modalBackgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    );

    final chipTheme = ChipThemeData(
      backgroundColor: AppColors.darkSurfaceStrong,
      selectedColor: AppColors.darkAccent,
      labelStyle: AppTypography.label.copyWith(color: AppColors.darkTextPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );

    const floatingActionButtonTheme = FloatingActionButtonThemeData(
      backgroundColor: AppColors.darkAccent,
      foregroundColor: Colors.white,
    );

    final elevatedButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: AppColors.darkAccent,
      foregroundColor: Colors.white,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: AppTypography.label.copyWith(fontSize: 16, color: Colors.white),
    );

    final inputDecorationTheme = InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: AppColors.darkStroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: AppColors.darkAccent, width: 1.4),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: AppColors.darkStroke),
      ),
    );

    final cardTheme = CardThemeData(
      color: AppColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      margin: EdgeInsets.zero,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      // Pass the light text color so it shows up on dark backgrounds
      textTheme: AppTypography.textTheme(AppColors.darkTextPrimary), 
      appBarTheme: appBarTheme,
      dividerColor: AppColors.darkStroke,
      dividerTheme: const DividerThemeData(color: AppColors.darkStroke, thickness: 1),
      navigationBarTheme: navigationBarTheme,
      listTileTheme: listTileTheme,
      bottomSheetTheme: bottomSheetTheme,
      chipTheme: chipTheme,
      floatingActionButtonTheme: floatingActionButtonTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(style: elevatedButtonStyle),
      inputDecorationTheme: inputDecorationTheme,
      cardTheme: cardTheme,
    );
  }
}
import 'package:flutter/material.dart';

import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

class AppTheme {
  static ThemeData light() {
    // Base palette pulled from the shared color file.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      background: AppColors.background,
      primary: AppColors.accent,
      secondary: AppColors.surface,
    );

    // Material 3 app bar styling keeps chrome minimal.
    const appBarTheme = AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.textPrimary,
    );

    // Navigation bar stays subtle behind bottom tabs.
    final navigationBarTheme = NavigationBarThemeData(
      indicatorColor: AppColors.accent.withOpacity(0.08),
      backgroundColor: AppColors.background,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      elevation: 0,
    );

    // Rounded list tiles match the rest of the cards.
    final listTileTheme = ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      tileColor: AppColors.surface,
      iconColor: AppColors.accent,
    );

    // Shared sheet look for modal bottom sheets.
    const bottomSheetTheme = BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      modalBackgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    );

    // Chip styling mirrors the cards and gradients.
    final chipTheme = ChipThemeData(
      backgroundColor: AppColors.surfaceStrong,
      selectedColor: AppColors.accent,
      labelStyle: AppTypography.label,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );

    // Floating action button palette sits on the accent color.
    const floatingActionButtonTheme = FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
    );

    // Buttons use the gradient palette but stay easy to override.
    final elevatedButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: AppTypography.label.copyWith(fontSize: 16, color: Colors.white),
    );

    // Forms share the same rounded outline treatment.
    final inputDecorationTheme = InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: AppColors.stroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: AppColors.stroke),
      ),
    );

    // Card defaults keep spacing consistent across screens.
    final cardTheme = CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      margin: EdgeInsets.zero,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTypography.textTheme(AppColors.textPrimary),
      appBarTheme: appBarTheme,
      dividerColor: AppColors.stroke,
      dividerTheme: const DividerThemeData(color: AppColors.stroke, thickness: 1),
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


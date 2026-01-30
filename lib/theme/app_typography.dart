import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  // Display text for big headers.
  static final TextStyle display = GoogleFonts.manrope(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  // Used for medium sized headings.
  static final TextStyle headline = GoogleFonts.manrope(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // Default title style for cards and sections.
  static final TextStyle title = GoogleFonts.manrope(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // Primary body copy across the app.
  static final TextStyle body = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
  );

  // Slightly smaller body text.
  static final TextStyle bodySmall = body.copyWith(
    fontSize: 14,
  );

  // Labels for buttons and chips.
  static final TextStyle label = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.8,
  );

  // Builds the text theme injected into ThemeData.
  static TextTheme textTheme(Color baseColor) {
    final Color mutedColor = baseColor.withOpacity(0.86);

    // Map the shared styles onto Flutter's text theme slots.
    return TextTheme(
      displayLarge: display.copyWith(color: baseColor),
      displayMedium: headline.copyWith(color: baseColor),
      displaySmall: title.copyWith(color: baseColor),
      headlineMedium: title.copyWith(color: baseColor),
      bodyLarge: body.copyWith(color: baseColor),
      bodyMedium: bodySmall.copyWith(color: mutedColor),
      labelLarge: label.copyWith(color: baseColor),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Color
  static const Color primaryColor = Color(0xFF0091FF);
  static const Color primaryLightColor = Color(0xFF4FB0FF);
  static const Color primaryDarkColor = Color(0xFF0072CC);

  // Accent Color
  static const Color accentColor = Color(0xFFFF7B49);

  // Background Colors
  static const Color scaffoldBackgroundColor = Color(0xFFF5F7FB);
  static const Color cardColor = Colors.white;

  // Text Colors
  static const Color textPrimaryColor = Color(0xFF333333);
  static const Color textSecondaryColor = Color(0xFF747474);
  static const Color textLightColor = Color(0xFF9E9E9E);

  // Status Colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color infoColor = Color(0xFF2196F3);

  // Other Colors
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color disabledColor = Color(0xFFBDBDBD);

  // Typography
  static TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.poppins(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: textPrimaryColor,
    ),
    displayMedium: GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: textPrimaryColor,
    ),
    displaySmall: GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: textPrimaryColor,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: textPrimaryColor,
    ),
    headlineSmall: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: textPrimaryColor,
    ),
    titleLarge: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: textPrimaryColor,
    ),
    bodyLarge: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: textPrimaryColor,
    ),
    bodyMedium: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: textPrimaryColor,
    ),
    bodySmall: GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: textSecondaryColor,
    ),
    labelLarge: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
  );

  // Button Theme
  static ButtonThemeData buttonTheme = const ButtonThemeData(
    buttonColor: primaryColor,
    disabledColor: disabledColor,
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  );

  // Input Decoration Theme
  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: dividerColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: dividerColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryColor),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: errorColor),
    ),
    hintStyle: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: textLightColor,
    ),
    labelStyle: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: textSecondaryColor,
    ),
  );

  // Card Theme
  static CardThemeData cardTheme = CardThemeData(
    color: cardColor,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  // App Bar Theme
  static AppBarTheme appBarTheme = AppBarTheme(
    backgroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    iconTheme: const IconThemeData(color: textPrimaryColor),
    titleTextStyle: GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: textPrimaryColor,
    ),
  );

  static ThemeData getTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      cardColor: cardColor,
      cardTheme: cardTheme,
      appBarTheme: appBarTheme,
      textTheme: textTheme,
      buttonTheme: buttonTheme,
      inputDecorationTheme: inputDecorationTheme,
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: primaryColor,
        secondary: accentColor,
        error: errorColor,
      ),
    );
  }
}

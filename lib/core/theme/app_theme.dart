import 'package:flutter/material.dart';

/// A class that houses all the color and theme configuration for SafePick.
/// Strictly enforces the finalized brand guidelines:
/// - Primary/Accent: #C1942B (A premium dark golden/amber)
/// - Backgrounds/Surfaces: Black (#000000 or very dark grey variants)
/// - Text/Icons: White (#FFFFFF)
class AppTheme {
  AppTheme._();

  // Premium Brand Colors
  static const Color primaryGold = Color(0xFFC1942B); // Premium Dark Golden/Amber
  static const Color primaryGoldDark = Color(0xFF9E751D);
  static const Color primaryGoldLight = Color(0xFFE4C374);

  // Backgrounds & Surfaces
  static const Color bgBlack = Color(0xFF000000); // Pure Black
  static const Color surfaceDark = Color(0xFF121212); // Very Dark Grey (Elevated Surface)
  static const Color surfaceCard = Color(0xFF1E1E1E); // Elevated Card Surface

  // Text & Icons
  static const Color textWhite = Color(0xFFFFFFFF); // Pure White
  static const Color textGrey = Color(0xFFB3B3B3); // Light Grey for secondary text
  static const Color textMuted = Color(0xFF757575); // Darker Grey for subtle labels

  // Borders & Accents
  static const Color borderDark = Color(0xFF2C2C2C); // Subtle borders
  static const Color errorRed = Color(0xFFCF6679); // Material dark mode error red
  static const Color successGreen = Color(0xFF03DAC6); // Emerald/Teal success accent
  static const Color warningOrange = Color(0xFFF59E0B);

  /// Helper to build the dark theme config shared by both system modes.
  static ThemeData _buildPremiumDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark, // Ensures white status bar icons and text defaults
      colorScheme: const ColorScheme.dark(
        primary: primaryGold,
        onPrimary: bgBlack,
        secondary: primaryGold,
        onSecondary: bgBlack,
        error: errorRed,
        onError: bgBlack,
        surface: surfaceDark,
        onSurface: textWhite,
      ),
      scaffoldBackgroundColor: bgBlack,
      appBarTheme: const AppBarTheme(
        backgroundColor: bgBlack,
        foregroundColor: textWhite,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textWhite),
        titleTextStyle: TextStyle(
          color: textWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderDark, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: bgBlack,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textWhite,
          side: const BorderSide(color: borderDark, width: 1.5),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderDark, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        labelStyle: const TextStyle(color: textGrey, fontSize: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textWhite, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1.0),
        headlineMedium: TextStyle(color: textWhite, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        titleLarge: TextStyle(color: textWhite, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.5),
        titleMedium: TextStyle(color: textWhite, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textWhite, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: textGrey, fontSize: 14, height: 1.4),
        labelLarge: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  /// Light Theme Configuration (Redirected to Premium Dark)
  static ThemeData get lightTheme => _buildPremiumDarkTheme();

  /// Dark Theme Configuration
  static ThemeData get darkTheme => _buildPremiumDarkTheme();
}

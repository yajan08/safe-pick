import 'package:flutter/material.dart';

/// A class that houses all the color and theme configuration for SafePick.
/// Uses a premium Safety Amber and Midnight Navy palette.
class AppTheme {
  AppTheme._();

  // Premium Color Palette Constants
  static const Color primaryAmber = Color(0xFFFF9E0B); // Vibrant Safety Amber
  static const Color primaryAmberDark = Color(0xFFE08600);
  static const Color primaryAmberLight = Color(0xFFFFD54F);

  static const Color secondaryNavy = Color(0xFF0F172A); // Midnight Navy (Slate 900)
  static const Color secondaryNavyLight = Color(0xFF1E293B); // Slate 800
  static const Color accentTeal = Color(0xFF0D9488); // Teal for success/accents

  // Light Mode Colors
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface = Colors.white;
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF475569); // Slate 600
  static const Color lightBorder = Color(0xFFE2E8F0); // Slate 200

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF0B0F19); // Extremely deep navy-black
  static const Color darkSurface = Color(0xFF151C2C); // Dark Navy Surface
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color darkBorder = Color(0xFF1E293B); // Slate 800

  // Common Colors
  static const Color errorRed = Color(0xFFEF4444); // Red 500
  static const Color successGreen = Color(0xFF10B981); // Emerald 500
  static const Color warningOrange = Color(0xFFF59E0B); // Amber 500

  /// Light Theme Configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryAmber,
        onPrimary: Colors.white,
        secondary: secondaryNavy,
        onSecondary: Colors.white,
        error: errorRed,
        onError: Colors.white,
        surface: lightSurface,
        onSurface: lightTextPrimary,
      ),
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: lightTextPrimary),
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 2,
        shadowColor: lightTextPrimary.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAmber,
          foregroundColor: Colors.white,
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
          foregroundColor: secondaryNavy,
          side: const BorderSide(color: lightBorder, width: 1.5),
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
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryAmber, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        labelStyle: const TextStyle(color: lightTextSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: lightTextPrimary, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1.0),
        headlineMedium: TextStyle(color: lightTextPrimary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        titleLarge: TextStyle(color: lightTextPrimary, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.5),
        titleMedium: TextStyle(color: lightTextPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: lightTextPrimary, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: lightTextSecondary, fontSize: 14, height: 1.4),
        labelLarge: TextStyle(color: lightTextSecondary, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  /// Dark Theme Configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryAmber,
        onPrimary: Colors.white,
        secondary: primaryAmber,
        onSecondary: Colors.white,
        error: errorRed,
        onError: Colors.white,
        surface: darkSurface,
        onSurface: darkTextPrimary,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: darkTextPrimary),
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAmber,
          foregroundColor: Colors.white,
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
          foregroundColor: darkTextPrimary,
          side: const BorderSide(color: darkBorder, width: 1.5),
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
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryAmber, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        labelStyle: const TextStyle(color: darkTextSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: darkTextPrimary, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1.0),
        headlineMedium: TextStyle(color: darkTextPrimary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        titleLarge: TextStyle(color: darkTextPrimary, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.5),
        titleMedium: TextStyle(color: darkTextPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: darkTextPrimary, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: darkTextSecondary, fontSize: 14, height: 1.4),
        labelLarge: TextStyle(color: darkTextSecondary, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

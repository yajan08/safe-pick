import 'package:flutter/material.dart';

/// A class that houses all the color and theme configuration for SafePick.
/// Strictly enforces the finalized brand guidelines:
/// - Primary/Accent: #C1942B (A premium dark golden/amber)
/// - Backgrounds/Surfaces: Light grey/White for Light Mode
/// - Text/Icons: Dark grey/Black for Light Mode
class AppTheme {
  AppTheme._();

  // Premium Brand Colors
  static const Color primaryGold = Color(0xFFC1942B); // Premium Dark Golden/Amber
  static const Color primaryGoldDark = Color(0xFF9E751D);
  static const Color primaryGoldLight = Color(0xFFE4C374);

  // Backgrounds & Surfaces (Light Mode)
  static const Color background = Color(0xFFF8F9FA); // Off-white premium background
  static const Color surface = Color(0xFFFFFFFF); // Pure White Surface
  static const Color surfaceCard = Color(0xFFFFFFFF); // Elevated Card Surface

  // Text & Icons (Light Mode)
  static const Color textPrimary = Color(0xFF1A1A1A); // Almost Black
  static const Color textSecondary = Color(0xFF4A4A4A); // Medium Grey for secondary text
  static const Color textMuted = Color(0xFF8E8E93); // Light Grey for subtle labels

  // Borders & Accents
  static const Color border = Color(0xFFE5E5EA); // Subtle borders
  static const Color errorRed = Color(0xFFD32F2F); // Material light mode error red
  static const Color successGreen = Color(0xFF388E3C); // Emerald/Teal success accent
  static const Color warningOrange = Color(0xFFF57C00);

  /// Helper to build the premium light theme config.
  static ThemeData _buildPremiumLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light, 
      colorScheme: const ColorScheme.light(
        primary: primaryGold,
        onPrimary: surface,
        secondary: primaryGold,
        onSecondary: surface,
        error: errorRed,
        onError: surface,
        surface: surface,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0, // Removed hard elevation
        shadowColor: Colors.black.withValues(alpha: 0.03),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border.withValues(alpha: 0.5), width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: surface,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: border.withValues(alpha: 0.5), width: 1),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border.withValues(alpha: 0.5), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border.withValues(alpha: 0.5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1.0),
        headlineMedium: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        titleLarge: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.5),
        titleMedium: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14, height: 1.4, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  /// Light Theme Configuration
  static ThemeData get lightTheme => _buildPremiumLightTheme();

  /// Dark Theme Configuration (Mapped to Light for complete conversion as requested)
  static ThemeData get darkTheme => _buildPremiumLightTheme();
}


import 'package:flutter/material.dart';

/// A premium, highly refined theme system for SafePick.
/// Enforces absolute visual hierarchy, elegant micro-interactions,
/// and pixel-perfect architectural consistency.
class AppTheme {
  AppTheme._();

  // --- Premium Brand Core Palette ---
  static const Color primaryGold = Color(0xFFC1942B);      // Premium Dark Golden / Amber
  static const Color primaryGoldDark = Color(0xFF9E751D);  // Deeper metallic tone for states
  static const Color primaryGoldLight = Color(0xFFE4C374); // Luminescent premium accent

  // --- Spatial Surface Mechanics ---
  static const Color background = Color(0xFFF9FAFB);     // Ultra-clean light gray base
  static const Color surface = Color(0xFFFFFFFF);        // Pristine pure white structural container
  static const Color surfaceCard = Color(0xFFFFFFFF);    // Raised interactive container surface

  // --- Human Interface Typography Scale ---
  static const Color textPrimary = Color(0xFF111827);    // Deep slate black for high legibility
  static const Color textSecondary = Color(0xFF4B5563);  // Muted gray for body copy and contexts
  static const Color textMuted = Color(0xFF9CA3AF);      // Subdued gray for micro-captions & inactive labels

  // --- Semantic Health Indicators ---
  static const Color border = Color(0xFFE5E7EB);         // Razor-sharp structural dividers
  static const Color errorRed = Color(0xFFDC2626);       // Refined alert signaling red
  static const Color successGreen = Color(0xFF10B981);   // Elegant emerald confirmation green
  static const Color warningOrange = Color(0xFFF59E0B);  // Soft amber notification warning

  /// Generates a unified Material 3 theme scheme optimized for elegant tactile interactions.
  static ThemeData _buildPremiumTheme() {
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
      
      // --- System Bar Architecture ---
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary, size: 22),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),

      // --- Cards & Semantic Grouping ---
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1),
        ),
      ),

      // --- High-Emphasis Buttons ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: surface,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // --- Medium-Emphasis Buttons ---
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border, width: 1.2),
          minimumSize: const Size(double.infinity, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // --- Form Architecture Fields ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),

      // --- Unified Typography System ---
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8),
        headlineMedium: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleLarge: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.3),
        titleMedium: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14, height: 1.45, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.1),
      ),
    );
  }

  static ThemeData get lightTheme => _buildPremiumTheme();
  static ThemeData get darkTheme => _buildPremiumTheme();
}
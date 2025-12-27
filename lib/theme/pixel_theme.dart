import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pixel_colors.dart';

class PixelTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.light,

      // Color scheme
      primaryColor: PixelColors.primary,
      scaffoldBackgroundColor: PixelColors.background,
      cardColor: PixelColors.card,

      // Typography - Pixel fonts
      textTheme: TextTheme(
        displayLarge: GoogleFonts.pressStart2p(
          fontSize: 32,
          color: PixelColors.textPrimary,
          letterSpacing: 0,
        ),
        displayMedium: GoogleFonts.pressStart2p(
          fontSize: 24,
          color: PixelColors.textPrimary,
          letterSpacing: 0,
        ),
        displaySmall: GoogleFonts.pressStart2p(
          fontSize: 20,
          color: PixelColors.textPrimary,
          letterSpacing: 0,
        ),
        headlineMedium: GoogleFonts.pixelifySans(
          fontSize: 18,
          color: PixelColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.pixelifySans(
          fontSize: 16,
          color: PixelColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: GoogleFonts.pixelifySans(
          fontSize: 14,
          color: PixelColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.vt323(
          fontSize: 20,
          color: PixelColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.vt323(
          fontSize: 18,
          color: PixelColors.textPrimary,
        ),
        bodySmall: GoogleFonts.vt323(
          fontSize: 16,
          color: PixelColors.textSecondary,
        ),
        labelLarge: GoogleFonts.pixelifySans(
          fontSize: 14,
          color: PixelColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: PixelColors.primary,
        foregroundColor: PixelColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.pressStart2p(
          fontSize: 16,
          color: PixelColors.background,
          letterSpacing: 0,
        ),
        iconTheme: const IconThemeData(
          color: PixelColors.background,
          size: 24,
        ),
      ),

      // Card theme
      cardTheme: const CardTheme(
        color: PixelColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        margin: EdgeInsets.all(8),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PixelColors.primary,
          foregroundColor: PixelColors.background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          textStyle: GoogleFonts.pixelifySans(
              fontSize: 14,
              fontWeight: FontWeight.bold
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PixelColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          textStyle: GoogleFonts.pixelifySans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PixelColors.surface,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: PixelColors.border, width: 2),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: PixelColors.border, width: 2),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: PixelColors.primary, width: 3),
        ),
        labelStyle: GoogleFonts.vt323(
          fontSize: 18,
          color: PixelColors.textSecondary,
        ),
        hintStyle: GoogleFonts.vt323(
          fontSize: 18,
          color: PixelColors.textLight,
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: PixelColors.border,
        thickness: 2,
        space: 8,
      ),
    );
  }
}
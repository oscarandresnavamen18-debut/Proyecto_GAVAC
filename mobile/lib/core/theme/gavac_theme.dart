import 'package:flutter/material.dart';
import 'gavac_colors.dart';

class GavacTheme {
  static ThemeData get lightTheme {
    ThemeData.light().textTheme.copyWith(
      displayLarge: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: GavacColors.textPrimary,
      ),
      headlineLarge: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: GavacColors.textPrimary,
      ),
      titleLarge: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: GavacColors.textPrimary,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: GavacColors.textPrimary,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: GavacColors.textSecondary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: GavacColors.primary,
      scaffoldBackgroundColor: GavacColors.background,
      colorScheme: const ColorScheme.light(
        primary: GavacColors.primary,
        secondary: GavacColors.accent,
        surface: GavacColors.surface,
        error: GavacColors.dangerText,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: GavacColors.textPrimary,
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GavacColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: GavacColors.border,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: GavacColors.border,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: GavacColors.primary,
            width: 2,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: GavacColors.primary,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF2E5A4D),
        secondary: GavacColors.primary,
        surface: Color(0xFF1E293B),
        error: GavacColors.dangerText,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFF1F5F9),
        onError: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GavacColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF334155),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF334155),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: GavacColors.accent,
            width: 2,
          ),
        ),
      ),
    );
  }
}

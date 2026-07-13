import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFF97316);
  static const Color primaryDark = Color(0xFFEA580C);
  static const Color primaryLight = Color(0xFFFFF7ED);
  static const Color primarySoft = Color(0xFFFFEDD5);
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray900 = Color(0xFF111827);
}

class AppTheme {
  /// Font supports Vietnamese:
  /// - Web: Be Vietnam Pro loaded via CDN in index.html
  /// - Mobile: Noto Sans / Roboto (system fonts)
  ///
  /// fontFamilyFallback ensures Vietnamese characters display correctly
  /// on all platforms even if the primary font doesn't load.
  static const String _primaryFont = 'Be Vietnam Pro';

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: _primaryFont,
      fontFamilyFallback: const [
        'Noto Sans Vietnamese',
        'Noto Sans',
        'Roboto',
        'Arial',
        'sans-serif',
      ],
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.gray50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
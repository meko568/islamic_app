import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary - Deep Emerald Green
  static const Color primaryDark = Color(0xFF0F5132);
  static const Color primary = Color(0xFF1B7347);
  static const Color primaryLight = Color(0xFF52B788);

  // Secondary - Warm Gold
  static const Color accent = Color(0xFFD4AF37);
  static const Color accentLight = Color(0xFFE8C547);
  static const Color accentDark = Color(0xFFA68C2B);

  // Backgrounds
  static const Color lightBackground = Color(0xFFFAF7F0);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);

  // Text
  static const Color darkText = Color(0xFF1a1a1a);
  static const Color lightText = Color(0xFFFAF7F0);
  static const Color secondaryText = Color(0xFF666666);

  // Status
  static const Color success = Color(0xFF52B788);
  static const Color warning = Color(0xFFFFA500);
  static const Color error = Color(0xFFe74c3c);
}

class AppTheme {
  // Helper to create scaled text theme
  static TextTheme _textTheme(double fontSize, bool isDark) {
    final scale = fontSize / 16.0;
    final textColor = isDark ? AppColors.lightText : AppColors.darkText;
    final secondaryTextColor =
        isDark ? Colors.grey[400] : AppColors.secondaryText;

    return TextTheme(
      // Arabic/Azkar text
      displayLarge: GoogleFonts.amiri(
        fontSize: (fontSize + 18) * scale,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.8,
      ),
      displayMedium: GoogleFonts.amiri(
        fontSize: (fontSize + 14) * scale,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.8,
      ),
      displaySmall: GoogleFonts.amiri(
        fontSize: (fontSize + 10) * scale,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.8,
      ),
      // UI labels and buttons
      headlineLarge: GoogleFonts.cairo(
        fontSize: (fontSize + 8) * scale,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.cairo(
        fontSize: (fontSize + 6) * scale,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.cairo(
        fontSize: (fontSize + 4) * scale,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      titleLarge: GoogleFonts.cairo(
        fontSize: (fontSize + 4) * scale,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: GoogleFonts.cairo(
        fontSize: (fontSize + 2) * scale,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleSmall: GoogleFonts.cairo(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.cairo(fontSize: (fontSize + 2), color: textColor),
      bodyMedium: GoogleFonts.cairo(
        fontSize: fontSize,
        color: secondaryTextColor,
      ),
      bodySmall: GoogleFonts.cairo(
        fontSize: (fontSize - 2),
        color: secondaryTextColor,
      ),
      labelLarge: GoogleFonts.cairo(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkBackground : Colors.white,
      ),
      labelMedium: GoogleFonts.cairo(
        fontSize: (fontSize - 1),
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkBackground : Colors.white,
      ),
      labelSmall: GoogleFonts.cairo(
        fontSize: (fontSize - 2),
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkBackground : Colors.white,
      ),
    );
  }

  // Light Theme
  static ThemeData lightTheme(double fontSize) {
    final scale = fontSize / 16.0; // Scale based on default 16.0

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.lightBackground,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 24 * scale,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        shadowColor: Color.fromARGB(26, 27, 115, 71),
      ),
      textTheme: _textTheme(fontSize, false),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 16 * scale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData darkTheme(double fontSize) {
    final scale = fontSize / 16.0; // Scale based on default 16.0

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primaryLight,
        secondary: AppColors.accentLight,
        surface: AppColors.darkSurface,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.accentLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 24 * scale,
          fontWeight: FontWeight.w700,
          color: AppColors.accentLight,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppColors.darkSurface,
        shadowColor: Color.fromARGB(77, 0, 0, 0),
      ),
      textTheme: _textTheme(fontSize, true),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.darkBackground,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 16 * scale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentLight, width: 2),
        ),
      ),
    );
  }
}

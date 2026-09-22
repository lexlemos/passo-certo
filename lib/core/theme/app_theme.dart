import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static const Color spaceBlue = AppColors.spaceBlue;
  static const Color mintGreen = AppColors.mintGreen;
  static const Color emergencyRed = AppColors.emergencyRed;
  static const Color softGreyBg = AppColors.softGreyBg;
  static const Color cardWhite = AppColors.cardWhite;
  static const Color textMuted = AppColors.textMuted;
  static const Color tealPrimary = AppColors.tealPrimary;
  static const Color limeGreen = AppColors.limeGreen;
  static const Color trackInactive = AppColors.trackInactive;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: softGreyBg,

      colorScheme: const ColorScheme.light(
        primary: spaceBlue,
        secondary: mintGreen,
        error: emergencyRed,
        surface: cardWhite,
      ),
      cardTheme: const CardThemeData(
        color: cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        margin: EdgeInsets.symmetric(vertical: 8),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: spaceBlue,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: spaceBlue,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: spaceBlue,
        ),
        bodyMedium: TextStyle(fontSize: 14, color: textMuted),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardWhite,
        selectedItemColor: Color(0xFF319795),
        unselectedItemColor: textMuted,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

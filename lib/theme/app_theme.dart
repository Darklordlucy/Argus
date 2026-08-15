import 'package:flutter/material.dart';

class AppColors {
  // Primary Obsidian Backgrounds
  static const Color obsidian = Color(0xFF070A11);
  static const Color obsidianSurface = Color(0xFF0D111D);
  static const Color obsidianCard = Color(0xFF151C2E);
  static const Color obsidianGlass = Color(0xCC151C2E);

  // Cyber Accents
  static const Color cyberCyan = Color(0xFF00F2FE);
  static const Color cyberBlue = Color(0xFF4FACFE);
  static const Color cyberPurple = Color(0xFF7F00FF);
  
  // Status & Hazard Severity Colors
  static const Color hazardRed = Color(0xFFFF3B30);      // Severe hazard
  static const Color hazardOrange = Color(0xFFFF9500);   // Rough surface
  static const Color hazardYellow = Color(0xFFFFCC00);   // Moderate vibration
  static const Color hazardGreen = Color(0xFF30D158);    // Smooth pavement

  // Text & Borders
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderSubtle = Color(0x1AFFFFFF);
  static const Color borderGlow = Color(0x6600F2FE);
}

class AppGradients {
  static const LinearGradient cyberPrimary = LinearGradient(
    colors: [AppColors.cyberCyan, AppColors.cyberBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassCard = LinearGradient(
    colors: [
      Color(0x33151C2E),
      Color(0x1A0D111D),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient hazardAlert = LinearGradient(
    colors: [AppColors.hazardRed, Color(0xFFB91C1C)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.obsidian,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.obsidianSurface,
        primary: AppColors.cyberCyan,
        secondary: AppColors.cyberBlue,
        error: AppColors.hazardRed,
      ),
      fontFamily: 'Roboto', // Fallback font, Google Fonts handles specific styles
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.obsidianSurface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.obsidianSurface,
        selectedItemColor: AppColors.cyberCyan,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
    );
  }
}

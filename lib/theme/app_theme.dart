import 'package:flutter/material.dart';

class AppColors {
  // Light Mode White Backgrounds & Surfaces
  static const Color scaffoldBackground = Color(0xFFF8FAFC); // Slate-50
  static const Color surface = Color(0xFFFFFFFF);            // Pure White
  static const Color card = Color(0xFFFFFFFF);               // Crisp White Card
  static const Color cardSubtle = Color(0xFFF1F5F9);         // Slate-100

  // Dark Mode Backgrounds (Retained for legacy/toggle)
  static const Color obsidian = Color(0xFF070A11);
  static const Color obsidianSurface = Color(0xFF0D111D);
  static const Color obsidianCard = Color(0xFF151C2E);

  // Vibrant Accents (Optimized for High Contrast on White)
  static const Color cyberCyan = Color(0xFF0284C7);   // Sky-600
  static const Color cyberBlue = Color(0xFF2563EB);   // Blue-600
  static const Color cyberPurple = Color(0xFF7C3AED); // Violet-600
  
  // Status & Hazard Severity Colors (Light-mode friendly & high contrast)
  static const Color hazardRed = Color(0xFFDC2626);      // Severe hazard
  static const Color hazardOrange = Color(0xFFD97706);   // Rough surface
  static const Color hazardYellow = Color(0xFFCA8A04);   // Moderate vibration
  static const Color hazardGreen = Color(0xFF16A34A);    // Smooth pavement

  // Text & Borders for White Mode
  static const Color textPrimary = Color(0xFF0F172A);    // Slate-900
  static const Color textSecondary = Color(0xFF475569);  // Slate-600
  static const Color textMuted = Color(0xFF94A3B8);      // Slate-400
  static const Color borderSubtle = Color(0xFFE2E8F0);   // Slate-200
  static const Color borderGlow = Color(0x400284C7);
}

class AppGradients {
  static const LinearGradient cyberPrimary = LinearGradient(
    colors: [AppColors.cyberCyan, AppColors.cyberBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassCard = LinearGradient(
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF8FAFC),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient hazardAlert = LinearGradient(
    colors: [AppColors.hazardRed, Color(0xFF991B1B)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class AppTheme {
  // Light / White Mode Theme (Default)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      colorScheme: const ColorScheme.light(
        surface: AppColors.surface,
        primary: AppColors.cyberCyan,
        secondary: AppColors.cyberBlue,
        error: AppColors.hazardRed,
        onSurface: AppColors.textPrimary,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.cyberCyan,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
      ),
      cardTheme: CardTheme(
        color: AppColors.card,
        elevation: 2,
        shadowColor: const Color(0x1A0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cardSubtle,
        selectedColor: AppColors.cyberCyan,
        secondarySelectedColor: AppColors.cyberBlue,
        side: const BorderSide(color: AppColors.borderSubtle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Dark Theme option
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
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.obsidianSurface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
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

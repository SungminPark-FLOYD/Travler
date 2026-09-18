import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _primaryColor = Color(0xFF2E66E7);
  static const _secondaryColor = Color(0xFF00C6AE);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.light,
        primary: _primaryColor,
        secondary: _secondaryColor,
        surface: const Color(0xFFF8F9FD),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1E293B),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 3,
        indicatorColor: _primaryColor.withValues(alpha: 0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.dark,
        primary: _primaryColor,
        secondary: _secondaryColor,
        surface: const Color(0xFF12141A),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Color(0xFF12141A),
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 3,
        indicatorColor: _primaryColor.withValues(alpha: 0.25),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade800),
        ),
      ),
    );
  }
}

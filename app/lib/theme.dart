import 'package:flutter/material.dart';

class S8llColors {
  static const lime = Color(0xFFD4FF3F);
  static const black = Color(0xFF0A0A0A);
  static const charcoal = Color(0xFF1A1A1A);
  static const grey = Color(0xFF8A8A8A);
}

ThemeData buildS8llTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: S8llColors.black,
    colorScheme: const ColorScheme.dark(
      primary: S8llColors.lime,
      onPrimary: S8llColors.black,
      secondary: S8llColors.lime,
      surface: S8llColors.charcoal,
    ),
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: S8llColors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    ),
    cardTheme: const CardTheme(
      color: S8llColors.charcoal,
      elevation: 0,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: S8llColors.lime,
        foregroundColor: S8llColors.black,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    bottomAppBarTheme: const BottomAppBarTheme(
      color: S8llColors.charcoal,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: S8llColors.charcoal,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

import 'package:flutter/material.dart';

/// S8LL's brand colors — black + lime stays the identity (it's what's on
/// every mockup and the Thomas St signage), but as a proper system: tonal
/// variants for elevation/pressed states, and semantic colors so "sold" or
/// an error doesn't have to borrow a color that means something else.
class S8llColors {
  // Brand
  static const lime = Color(0xFFD4FF3F);
  static const limeDim = Color(0xFFA8CC32); // pressed/disabled lime states
  static const limeSoft = Color(0x33D4FF3F); // 20% lime, for tints/indicators

  // Surfaces, darkest to lightest — three tiers of elevation instead of
  // one flat "charcoal" for every card, sheet, and input alike.
  static const black = Color(0xFF0A0A0A);
  static const charcoal = Color(0xFF1A1A1A);
  static const charcoalHigh = Color(0xFF242424);

  // Text/icon on dark surfaces
  static const white = Color(0xFFFFFFFF);
  static const grey = Color(0xFF8A8A8A);
  static const greyLow = Color(0xFF5C5C5C);
  static const divider = Color(0xFF2E2E2E);

  // Semantic — never reuse lime for these; lime means "brand/positive/go"
  static const error = Color(0xFFFF5C5C);
  static const warning = Color(0xFFFFB020);
}

/// A small spacing/radius scale so every screen stops inventing its own
/// magic numbers for padding and corner radii.
class S8llSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}

class S8llRadius {
  static const sm = 12.0;
  static const md = 16.0;
  static const pill = 999.0;
}

ThemeData buildS8llTheme() {
  const textTheme = TextTheme(
    headlineLarge: TextStyle(
      color: S8llColors.white,
      fontWeight: FontWeight.w800,
      fontSize: 32,
      letterSpacing: -0.5,
    ),
    titleLarge: TextStyle(
      color: S8llColors.white,
      fontWeight: FontWeight.w800,
      fontSize: 20,
      letterSpacing: 0.5,
    ),
    titleMedium: TextStyle(
      color: S8llColors.white,
      fontWeight: FontWeight.w700,
      fontSize: 16,
    ),
    bodyLarge: TextStyle(color: S8llColors.white, fontSize: 16),
    bodyMedium: TextStyle(color: S8llColors.white, fontSize: 14),
    bodySmall: TextStyle(color: S8llColors.grey, fontSize: 12),
    labelLarge: TextStyle(
      color: S8llColors.black,
      fontWeight: FontWeight.w700,
      fontSize: 15,
    ),
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: S8llColors.black,
    textTheme: textTheme,
    colorScheme: const ColorScheme.dark(
      primary: S8llColors.lime,
      onPrimary: S8llColors.black,
      secondary: S8llColors.lime,
      onSecondary: S8llColors.black,
      surface: S8llColors.charcoal,
      onSurface: S8llColors.white,
      error: S8llColors.error,
      onError: S8llColors.white,
      outline: S8llColors.divider,
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
    cardTheme: const CardThemeData(
      color: S8llColors.charcoal,
      elevation: 0,
      margin: EdgeInsets.symmetric(horizontal: S8llSpacing.md, vertical: S8llSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(S8llRadius.md)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: S8llColors.lime,
        foregroundColor: S8llColors.black,
        disabledBackgroundColor: S8llColors.limeDim.withValues(alpha: 0.4),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(S8llRadius.sm)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: S8llColors.white,
        side: const BorderSide(color: S8llColors.divider),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(S8llRadius.sm)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: S8llColors.charcoalHigh,
      labelStyle: const TextStyle(color: S8llColors.white, fontSize: 12, fontWeight: FontWeight.w600),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(S8llRadius.pill)),
      padding: const EdgeInsets.symmetric(horizontal: S8llSpacing.sm, vertical: S8llSpacing.xs),
    ),
    dividerTheme: const DividerThemeData(color: S8llColors.divider, thickness: 1, space: 1),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: S8llColors.charcoalHigh,
      contentTextStyle: TextStyle(color: S8llColors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(S8llRadius.sm)),
      ),
    ),
    bottomAppBarTheme: const BottomAppBarThemeData(
      color: S8llColors.charcoal,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: S8llColors.charcoal,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(S8llRadius.sm),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

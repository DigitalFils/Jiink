import 'package:flutter/material.dart';

/// S8LL's brand colors — black + lime stays the identity (it's what's on
/// every mockup and the Thomas St signage), but as a proper system: tonal
/// variants for elevation/pressed states, and semantic colors so "sold" or
/// an error doesn't have to borrow a color that means something else.
///
/// These are the ones that never change with brightness — the same lime
/// reads as "S8LL" whether the phone is in light or dark mode. Anything
/// that *does* need to flip (surfaces, body text) lives in [S8llTint]
/// instead, reached via `context.s8ll` rather than a static constant.
class S8llColors {
  // Brand
  static const lime = Color(0xFFD4FF3F);
  static const limeDim = Color(0xFFA8CC32); // pressed/disabled lime states
  static const limeSoft = Color(0x33D4FF3F); // 20% lime, for tints/indicators

  // The dark theme's surfaces, darkest to lightest — three tiers of
  // elevation instead of one flat "charcoal" for every card, sheet, and
  // input alike. (Light-theme equivalents live in S8llTint.light.)
  static const black = Color(0xFF0A0A0A);
  static const charcoal = Color(0xFF1A1A1A);
  static const charcoalHigh = Color(0xFF242424);

  // Text/icon on dark surfaces.
  static const white = Color(0xFFFFFFFF);
  static const grey = Color(0xFF8A8A8A);
  static const greyLow = Color(0xFF5C5C5C);
  static const divider = Color(0xFF2E2E2E);

  // Semantic — never reuse lime for these; lime means "brand/positive/go".
  // Same in both themes: an error is an error regardless of brightness.
  static const error = Color(0xFFFF5C5C);
  static const warning = Color(0xFFFFB020);
}

/// The roles that DO flip between light and dark — page background, card
/// surfaces, and the text tiers on top of them. A `ThemeExtension` (rather
/// than more static constants) so a widget can read the right one for the
/// live theme via `context.s8ll.textSecondary` instead of hardcoding
/// `S8llColors.grey`, which was always the dark-mode value.
@immutable
class S8llTint extends ThemeExtension<S8llTint> {
  const S8llTint({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
  });

  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color divider;

  static const dark = S8llTint(
    background: S8llColors.black,
    surface: S8llColors.charcoal,
    surfaceHigh: S8llColors.charcoalHigh,
    textPrimary: S8llColors.white,
    textSecondary: S8llColors.grey,
    textTertiary: S8llColors.greyLow,
    divider: S8llColors.divider,
  );

  // A soft off-white rather than stark #FFFFFF, with true-white cards for
  // elevation contrast on top of it — the light-mode mirror of black +
  // three charcoal tiers.
  static const light = S8llTint(
    background: Color(0xFFF6F6F3),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFECECE8),
    textPrimary: Color(0xFF14140F),
    textSecondary: Color(0xFF66665F),
    textTertiary: Color(0xFF9A9A92),
    divider: Color(0xFFE1E1DC),
  );

  @override
  S8llTint copyWith({
    Color? background,
    Color? surface,
    Color? surfaceHigh,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? divider,
  }) {
    return S8llTint(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      divider: divider ?? this.divider,
    );
  }

  @override
  S8llTint lerp(ThemeExtension<S8llTint>? other, double t) {
    if (other is! S8llTint) return this;
    return S8llTint(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}

/// `context.s8ll.textSecondary` instead of `Theme.of(context).extension<S8llTint>()!.textSecondary`.
extension S8llThemeX on BuildContext {
  S8llTint get s8ll => Theme.of(this).extension<S8llTint>()!;
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

ThemeData buildS8llTheme({Brightness brightness = Brightness.dark}) {
  final isDark = brightness == Brightness.dark;
  final tint = isDark ? S8llTint.dark : S8llTint.light;

  final textTheme = TextTheme(
    headlineLarge: TextStyle(
      color: tint.textPrimary,
      fontWeight: FontWeight.w800,
      fontSize: 32,
      letterSpacing: -0.5,
    ),
    titleLarge: TextStyle(
      color: tint.textPrimary,
      fontWeight: FontWeight.w800,
      fontSize: 20,
      letterSpacing: 0.5,
    ),
    titleMedium: TextStyle(
      color: tint.textPrimary,
      fontWeight: FontWeight.w700,
      fontSize: 16,
    ),
    bodyLarge: TextStyle(color: tint.textPrimary, fontSize: 16),
    bodyMedium: TextStyle(color: tint.textPrimary, fontSize: 14),
    bodySmall: TextStyle(color: tint.textSecondary, fontSize: 12),
    labelLarge: const TextStyle(
      color: S8llColors.black,
      fontWeight: FontWeight.w700,
      fontSize: 15,
    ),
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: tint.background,
    textTheme: textTheme,
    extensions: [tint],
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: S8llColors.lime,
      onPrimary: S8llColors.black,
      secondary: S8llColors.lime,
      onSecondary: S8llColors.black,
      surface: tint.surface,
      onSurface: tint.textPrimary,
      error: S8llColors.error,
      onError: S8llColors.white,
      outline: tint.divider,
    ),
  );
  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: tint.background,
      foregroundColor: tint.textPrimary,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: tint.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: tint.surface,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: S8llSpacing.md, vertical: S8llSpacing.sm),
      shape: const RoundedRectangleBorder(
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
        foregroundColor: tint.textPrimary,
        side: BorderSide(color: tint.divider),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(S8llRadius.sm)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: tint.surfaceHigh,
      labelStyle: TextStyle(color: tint.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(S8llRadius.pill)),
      padding: const EdgeInsets.symmetric(horizontal: S8llSpacing.sm, vertical: S8llSpacing.xs),
    ),
    dividerTheme: DividerThemeData(color: tint.divider, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: tint.surfaceHigh,
      contentTextStyle: TextStyle(color: tint.textPrimary),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(S8llRadius.sm)),
      ),
    ),
    bottomAppBarTheme: BottomAppBarThemeData(
      color: tint.surface,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tint.surface,
      hintStyle: TextStyle(color: tint.textTertiary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(S8llRadius.sm),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

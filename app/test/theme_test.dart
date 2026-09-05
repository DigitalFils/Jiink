import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:s8ll/theme.dart';

void main() {
  test('every built theme carries the S8llTint extension', () {
    for (final brightness in Brightness.values) {
      final theme = buildS8llTheme(brightness: brightness);
      expect(theme.extension<S8llTint>(), isNotNull, reason: '$brightness theme is missing S8llTint');
    }
  });

  test('light and dark use visibly different surface/text colors', () {
    final light = buildS8llTheme(brightness: Brightness.light).extension<S8llTint>()!;
    final dark = buildS8llTheme(brightness: Brightness.dark).extension<S8llTint>()!;

    expect(light.background, isNot(dark.background));
    expect(light.surface, isNot(dark.surface));
    expect(light.textPrimary, isNot(dark.textPrimary));
    expect(light.textSecondary, isNot(dark.textSecondary));
  });

  test('the brand lime accent stays the same across themes', () {
    final light = buildS8llTheme(brightness: Brightness.light);
    final dark = buildS8llTheme(brightness: Brightness.dark);

    expect(light.colorScheme.primary, S8llColors.lime);
    expect(dark.colorScheme.primary, S8llColors.lime);
  });

  test('S8llTint.lerp blends toward the target and falls back on a foreign extension', () {
    const start = S8llTint.dark;
    const end = S8llTint.light;

    final blended = start.lerp(end, 0.5);
    expect(blended.background, Color.lerp(start.background, end.background, 0.5));

    // lerp with an incompatible extension type is a no-op, per the
    // ThemeExtension contract.
    expect(start.lerp(null, 0.5), start);
  });
}

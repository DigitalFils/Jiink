import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:s8ll/state/theme_controller.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  test('defaults to system mode when nothing is stored', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final controller = ThemeController();
    await Future<void>.delayed(Duration.zero);

    expect(controller.mode, ThemeMode.system);
  });

  test('setMode updates and persists the choice', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final controller = ThemeController();
    await Future<void>.delayed(Duration.zero);

    await controller.setMode(ThemeMode.dark);

    expect(controller.mode, ThemeMode.dark);
  });

  test('loads a previously persisted choice on construction', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({'themeMode': 'light'});
    final controller = ThemeController();
    await Future<void>.delayed(Duration.zero);

    expect(controller.mode, ThemeMode.light);
  });
}

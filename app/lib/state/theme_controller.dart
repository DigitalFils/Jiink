import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's light/dark/system preference, persisted locally so it
/// survives an app restart — this is a per-device display setting, not
/// account data, so it deliberately never touches Firestore.
class ThemeController extends ChangeNotifier {
  ThemeController({SharedPreferencesAsync? prefs}) : _prefs = prefs ?? SharedPreferencesAsync() {
    _load();
  }

  static const _prefsKey = 'themeMode';

  final SharedPreferencesAsync _prefs;
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  Future<void> _load() async {
    final stored = await _prefs.getString(_prefsKey);
    final match = ThemeMode.values.where((m) => m.name == stored);
    if (match.isNotEmpty) {
      _mode = match.first;
      notifyListeners();
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _prefs.setString(_prefsKey, mode.name);
  }
}

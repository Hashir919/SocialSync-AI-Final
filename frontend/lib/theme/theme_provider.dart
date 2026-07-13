import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'theme_mode';
  final SharedPreferences _prefs;

  ThemeNotifier(this._prefs) : super(ThemeMode.system) {
    _loadTheme();
  }

  void _loadTheme() {
    final savedTheme = _prefs.getString(_key);
    if (savedTheme == 'light') {
      state = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    if (mode == ThemeMode.light) {
      await _prefs.setString(_key, 'light');
    } else if (mode == ThemeMode.dark) {
      await _prefs.setString(_key, 'dark');
    } else {
      await _prefs.remove(_key);
    }
  }
}

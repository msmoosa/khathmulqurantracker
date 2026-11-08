import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's light/dark choice. Light unless the user picks otherwise.
class AppearanceStore extends ChangeNotifier {
  AppearanceStore(this._prefs);

  static const _modeKey = 'theme_mode';

  final SharedPreferences _prefs;

  ThemeMode get themeMode => ThemeMode.values.firstWhere(
    (m) => m.name == _prefs.getString(_modeKey),
    orElse: () => ThemeMode.light,
  );

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == themeMode) return;
    final saved = _prefs.setString(_modeKey, mode.name);
    notifyListeners();
    await saved;
  }
}

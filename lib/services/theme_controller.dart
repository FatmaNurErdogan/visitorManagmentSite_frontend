import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcının açık/koyu/sistem tema tercihini tutar ve cihazda saklar.
class ThemeController extends ChangeNotifier {
  ThemeController({SharedPreferencesAsync? prefs}) : _prefs = prefs ?? SharedPreferencesAsync();

  static const _key = 'vizit_theme_mode';

  final SharedPreferencesAsync _prefs;
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  Future<void> restore() async {
    final stored = await _prefs.getString(_key);
    _mode = _parse(stored);
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    await _prefs.setString(_key, mode.name);
  }

  ThemeMode _parse(String? value) {
    return ThemeMode.values.firstWhere((m) => m.name == value, orElse: () => ThemeMode.system);
  }
}

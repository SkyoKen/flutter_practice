import 'package:flutter/material.dart';
import 'package:cyber_table_order/models/app_preferences.dart';
import 'package:cyber_table_order/theme/app_theme.dart';
import 'package:cyber_table_order/theme/app_theme_mode.dart';

class ThemeController extends ChangeNotifier {
  static const _themePreferenceKey = 'app_theme_mode';

  final AppPreferencesStorage preferences;
  final AppPreferencesWriteQueue _preferenceWrites = AppPreferencesWriteQueue();
  AppThemeMode _mode = AppThemeMode.neoBrutalism;
  bool _isLoaded = false;

  ThemeController({AppPreferencesStorage? preferences})
      : preferences = preferences ?? SharedPreferencesAppPreferencesStorage();

  AppThemeMode get mode => _mode;
  bool get isLoaded => _isLoaded;

  ThemeData get themeData => AppTheme.data(_mode);

  Future<void> load() async {
    final storedMode = await preferences.getString(_themePreferenceKey);
    for (final mode in AppThemeMode.values) {
      if (mode.name == storedMode) {
        _mode = mode;
        break;
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await _preferenceWrites.setString(
      preferences,
      _themePreferenceKey,
      mode.name,
    );
  }
}

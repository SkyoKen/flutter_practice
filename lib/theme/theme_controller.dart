import 'package:flutter/material.dart';
import 'package:cyber_table_order/theme/app_theme.dart';
import 'package:cyber_table_order/theme/app_theme_mode.dart';

class ThemeController extends ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.neoBrutalism;

  ThemeController() {
    AppTheme.setActiveMode(_mode);
  }

  AppThemeMode get mode => _mode;

  ThemeData get themeData => AppTheme.data(_mode);

  void setMode(AppThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    AppTheme.setActiveMode(mode);
    notifyListeners();
  }
}

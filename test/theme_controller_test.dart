import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_table_order/theme/app_theme.dart';
import 'package:cyber_table_order/theme/app_theme_mode.dart';
import 'package:cyber_table_order/theme/theme_controller.dart';
import 'package:cyber_table_order/theme/theme_tokens.dart';

void main() {
  test('ThemeController updates active theme tokens', () {
    final controller = ThemeController();

    expect(controller.mode, AppThemeMode.neoBrutalism);
    expect(AppTheme.activeTokens.background, AppTheme.neoBrutalism.background);

    controller.setMode(AppThemeMode.neonTerminal);

    final themeTokens =
        controller.themeData.extension<AppThemeTokens>() as AppThemeTokens;
    expect(controller.mode, AppThemeMode.neonTerminal);
    expect(AppTheme.activeTokens.background, AppTheme.neonTerminal.background);
    expect(themeTokens.background, AppTheme.neonTerminal.background);
  });

  test('all theme modes provide theme tokens', () {
    for (final mode in AppThemeMode.values) {
      final tokens = AppTheme.tokensFor(mode);
      expect(tokens.background, isNot(equals(tokens.surface)));
      expect(tokens.ink, isNot(equals(tokens.background)));
    }
  });
}

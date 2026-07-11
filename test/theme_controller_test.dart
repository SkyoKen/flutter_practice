import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_table_order/models/app_preferences.dart';
import 'package:cyber_table_order/theme/app_theme.dart';
import 'package:cyber_table_order/theme/app_theme_mode.dart';
import 'package:cyber_table_order/theme/theme_controller.dart';
import 'package:cyber_table_order/theme/theme_tokens.dart';

class _DelayedPreferencesStorage extends MemoryAppPreferencesStorage {
  final List<Duration> delays;
  int _writeIndex = 0;

  _DelayedPreferencesStorage(this.delays);

  @override
  Future<void> setString(String key, String value) async {
    final delay = delays[_writeIndex++];
    await Future<void>.delayed(delay);
    await super.setString(key, value);
  }
}

void main() {
  test('ThemeController updates and persists theme tokens', () async {
    final preferences = MemoryAppPreferencesStorage();
    final controller = ThemeController(preferences: preferences);

    expect(controller.mode, AppThemeMode.neoBrutalism);

    await controller.setMode(AppThemeMode.neonTerminal);

    final themeTokens =
        controller.themeData.extension<AppThemeTokens>() as AppThemeTokens;
    expect(controller.mode, AppThemeMode.neonTerminal);
    expect(themeTokens.background, AppTheme.neonTerminal.background);
    expect(preferences.values['app_theme_mode'], 'neonTerminal');
  });

  test('rapid theme changes persist the last selection', () async {
    final preferences = _DelayedPreferencesStorage([
      const Duration(milliseconds: 30),
      Duration.zero,
    ]);
    final controller = ThemeController(preferences: preferences);

    final firstChange = controller.setMode(AppThemeMode.neonTerminal);
    final lastChange = controller.setMode(AppThemeMode.paperReceipt);

    expect(controller.mode, AppThemeMode.paperReceipt);
    await Future.wait([firstChange, lastChange]);
    expect(preferences.values['app_theme_mode'], 'paperReceipt');
  });

  test('ThemeController restores a valid mode and ignores corrupt values',
      () async {
    final stored = ThemeController(
      preferences: MemoryAppPreferencesStorage({
        'app_theme_mode': 'paperReceipt',
      }),
    );
    await stored.load();

    expect(stored.isLoaded, isTrue);
    expect(stored.mode, AppThemeMode.paperReceipt);

    final corrupt = ThemeController(
      preferences: MemoryAppPreferencesStorage({
        'app_theme_mode': 'missing',
      }),
    );
    await corrupt.load();

    expect(corrupt.mode, AppThemeMode.neoBrutalism);
  });

  test('all theme modes provide theme tokens', () {
    for (final mode in AppThemeMode.values) {
      final tokens = AppTheme.tokensFor(mode);
      expect(tokens.mode, mode);
      expect(tokens.background, isNot(equals(tokens.surface)));
      expect(tokens.ink, isNot(equals(tokens.background)));
      expect(
        AppTheme.contrastRatio(
          AppTheme.foregroundOn(tokens.accent),
          tokens.accent,
        ),
        greaterThanOrEqualTo(4.5),
      );
      final textButtonColor = AppTheme.accessibleForeground(
        preferred: tokens.accentSoft,
        background: tokens.surface,
      );
      expect(
        AppTheme.contrastRatio(textButtonColor, tokens.surface),
        greaterThanOrEqualTo(4.5),
      );
    }
  });
}

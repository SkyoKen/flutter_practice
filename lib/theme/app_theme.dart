import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cyber_table_order/theme/app_theme_mode.dart';
import 'package:cyber_table_order/theme/theme_tokens.dart';

class AppTheme {
  static const AppThemeTokens neonTerminal = AppThemeTokens(
    mode: AppThemeMode.neonTerminal,
    background: Color(0xFF0B0D10),
    surface: Color(0xFF171A1F),
    surfaceHigh: Color(0xFF22252A),
    ink: Color(0xFFF8FAFC),
    border: Color(0xFF343A46),
    accent: Color(0xFFFF6B2C),
    accentSoft: Color(0xFFFFA45B),
    cyan: Color(0xFF32D6D0),
    amber: Color(0xFFFFC857),
    danger: Color(0xFFFF6B6B),
    useHardShadow: false,
    strongBorderWidth: 2,
    radius: 8,
  );

  static const AppThemeTokens neoBrutalism = AppThemeTokens(
    mode: AppThemeMode.neoBrutalism,
    background: Color(0xFFF2F4F7),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFE8ECF3),
    ink: Color(0xFF111111),
    border: Color(0xFF111111),
    accent: Color(0xFFFF6B35),
    accentSoft: Color(0xFFFFA53E),
    cyan: Color(0xFF00C2D1),
    amber: Color(0xFFFFD166),
    danger: Color(0xFFFF4D4D),
    useHardShadow: true,
    strongBorderWidth: 3,
    radius: 4,
  );

  static const AppThemeTokens paperReceipt = AppThemeTokens(
    mode: AppThemeMode.paperReceipt,
    background: Color(0xFFF7F0DF),
    surface: Color(0xFFFFFCF2),
    surfaceHigh: Color(0xFFF0E5CC),
    ink: Color(0xFF241A12),
    border: Color(0xFF3D2E1F),
    accent: Color(0xFFC83D2D),
    accentSoft: Color(0xFFE5B85C),
    cyan: Color(0xFF3D7B78),
    amber: Color(0xFFE8C36A),
    danger: Color(0xFFC83D2D),
    useHardShadow: false,
    strongBorderWidth: 2,
    radius: 2,
  );

  static const AppThemeTokens retroOS = AppThemeTokens(
    mode: AppThemeMode.retroOS,
    background: Color(0xFFC0C0C0),
    surface: Color(0xFFE6E6E6),
    surfaceHigh: Color(0xFFD4D0C8),
    ink: Color(0xFF050505),
    border: Color(0xFF050505),
    accent: Color(0xFF000080),
    accentSoft: Color(0xFF008080),
    cyan: Color(0xFF00A6A6),
    amber: Color(0xFFFFFF99),
    danger: Color(0xFFB00020),
    useHardShadow: true,
    strongBorderWidth: 2,
    radius: 0,
  );

  static AppThemeTokens tokensFor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.neonTerminal:
        return neonTerminal;
      case AppThemeMode.neoBrutalism:
        return neoBrutalism;
      case AppThemeMode.paperReceipt:
        return paperReceipt;
      case AppThemeMode.retroOS:
        return retroOS;
    }
  }

  static AppThemeTokens of(BuildContext context) {
    return Theme.of(context).extension<AppThemeTokens>() ?? neoBrutalism;
  }

  static AppThemeMode modeOf(BuildContext context) => of(context).mode;

  static double contrastRatio(Color foreground, Color background) {
    final foregroundLuminance = foreground.computeLuminance();
    final backgroundLuminance = background.computeLuminance();
    final lighter = max(foregroundLuminance, backgroundLuminance);
    final darker = min(foregroundLuminance, backgroundLuminance);
    return (lighter + 0.05) / (darker + 0.05);
  }

  static Color foregroundOn(Color background) {
    final blackContrast = contrastRatio(Colors.black, background);
    final whiteContrast = contrastRatio(Colors.white, background);
    return blackContrast >= whiteContrast ? Colors.black : Colors.white;
  }

  static Color accessibleForeground({
    required Color preferred,
    required Color background,
  }) {
    if (contrastRatio(preferred, background) >= 4.5) return preferred;
    return foregroundOn(background);
  }

  static ThemeData data(AppThemeMode mode) {
    final tokens = tokensFor(mode);
    final brightness =
        mode == AppThemeMode.neonTerminal ? Brightness.dark : Brightness.light;
    final base = ThemeData(useMaterial3: true, brightness: brightness);
    final scheme = ColorScheme.fromSeed(
      seedColor: tokens.accent,
      brightness: brightness,
      primary: tokens.accent,
      onPrimary: foregroundOn(tokens.accent),
      secondary: tokens.cyan,
      onSecondary: foregroundOn(tokens.cyan),
      tertiary: tokens.amber,
      surface: tokens.surface,
      onSurface: tokens.ink,
    );

    return base.copyWith(
      colorScheme: scheme,
      extensions: [tokens],
      scaffoldBackgroundColor: tokens.background,
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.surface,
        foregroundColor: tokens.ink,
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radius),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radius),
          side: BorderSide(
            color: tokens.border,
            width: tokens.strongBorderWidth,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.ink.withValues(alpha: 0.18),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.accent,
        contentTextStyle: TextStyle(
          color: foregroundOn(tokens.accent),
          fontWeight: FontWeight.bold,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.accent,
          foregroundColor: foregroundOn(tokens.accent),
          elevation: 0,
          side: BorderSide(
            color: tokens.border,
            width: mode == AppThemeMode.neonTerminal ? 1.5 : 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radius),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accessibleForeground(
            preferred: tokens.accentSoft,
            background: tokens.surface,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        prefixIconColor: tokens.accent,
        labelStyle: TextStyle(
          color: tokens.ink,
          fontFamily: 'Courier',
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(tokens.radius)),
          borderSide: BorderSide(
            color: tokens.border,
            width: mode == AppThemeMode.neonTerminal ? 1 : 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(tokens.radius)),
          borderSide: BorderSide(
            color: tokens.accent,
            width: mode == AppThemeMode.neonTerminal ? 2 : 3,
          ),
        ),
      ),
    );
  }
}

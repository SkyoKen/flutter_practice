enum AppThemeMode {
  neonTerminal,
  neoBrutalism,
  paperReceipt,
  retroOS,
}

extension AppThemeModeLabel on AppThemeMode {
  String get label {
    switch (this) {
      case AppThemeMode.neonTerminal:
        return 'Neon Terminal';
      case AppThemeMode.neoBrutalism:
        return 'Neo Brutalism';
      case AppThemeMode.paperReceipt:
        return 'Paper Receipt';
      case AppThemeMode.retroOS:
        return 'Retro OS';
    }
  }

  String get description {
    switch (this) {
      case AppThemeMode.neonTerminal:
        return 'Dark terminal neon';
      case AppThemeMode.neoBrutalism:
        return 'Bold borders and hard shadows';
      case AppThemeMode.paperReceipt:
        return 'Warm paper and receipt ink';
      case AppThemeMode.retroOS:
        return 'Classic desktop controls';
    }
  }
}

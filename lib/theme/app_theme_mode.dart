enum AppThemeMode {
  neonTerminal,
  neoBrutalism,
  paperReceipt,
  retroOS,
}

extension AppThemeModeTranslationKeys on AppThemeMode {
  String get labelKey => switch (this) {
        AppThemeMode.neonTerminal => 'theme_neon_terminal_label',
        AppThemeMode.neoBrutalism => 'theme_neo_brutalism_label',
        AppThemeMode.paperReceipt => 'theme_paper_receipt_label',
        AppThemeMode.retroOS => 'theme_retro_os_label',
      };

  String get descriptionKey => switch (this) {
        AppThemeMode.neonTerminal => 'theme_neon_terminal_description',
        AppThemeMode.neoBrutalism => 'theme_neo_brutalism_description',
        AppThemeMode.paperReceipt => 'theme_paper_receipt_description',
        AppThemeMode.retroOS => 'theme_retro_os_description',
      };
}

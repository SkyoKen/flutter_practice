import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cyber_table_order/pages/home_page.dart';
import 'package:cyber_table_order/models/restaurant.dart';
import 'package:cyber_table_order/theme/app_theme.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      body: Consumer<Restaurant>(
        builder: (context, restaurant, child) => Stack(
          children: [
            const Positioned.fill(child: _IntroBackdrop()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 760;
                  final horizontalPadding = isWide ? 48.0 : 24.0;
                  final minHeight = constraints.maxHeight - 48;

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: _LanguageSelector(restaurant: restaurant),
                          ),
                          SizedBox(height: isWide ? 88 : 60),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 500),
                              child: Column(
                                children: [
                                  const _BrandMark(),
                                  const SizedBox(height: 32),
                                  Text(
                                    restaurant.translate('app_title'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: isWide ? 31 : 25,
                                      color: theme.ink,
                                      fontFamily: 'Courier',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    restaurant.translate('accessing_logs'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.ink,
                                      height: 1.45,
                                      fontFamily: 'Courier',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 44),
                                  SizedBox(
                                    width: isWide ? 300 : double.infinity,
                                    height: 54,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        boxShadow: theme.hardShadow(),
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const HomePage(),
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme.accent,
                                          foregroundColor: theme.useHardShadow
                                              ? theme.ink
                                              : Colors.black,
                                          side: BorderSide(
                                            color: theme.border,
                                            width: theme.strongBorderWidth,
                                          ),
                                        ),
                                        icon: const Icon(Icons.login, size: 20),
                                        label: Text(
                                          restaurant.translate('start_session'),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: theme.amber,
        borderRadius: BorderRadius.circular(theme.radius),
        border: Border.all(
          color: theme.border,
          width: theme.strongBorderWidth,
        ),
        boxShadow: theme.hardShadow(),
      ),
      child: Icon(
        Icons.table_restaurant,
        size: 42,
        color: theme.ink,
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  final Restaurant restaurant;

  const _LanguageSelector({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _LanguageButton(
          label: 'EN',
          code: 'en',
          isSelected: restaurant.languageCode == 'en',
          onTap: () => restaurant.setLanguage('en'),
        ),
        _LanguageButton(
          label: '中文',
          code: 'zh',
          isSelected: restaurant.languageCode == 'zh',
          onTap: () => restaurant.setLanguage('zh'),
        ),
        _LanguageButton(
          label: 'JP',
          code: 'ja',
          isSelected: restaurant.languageCode == 'ja',
          onTap: () => restaurant.setLanguage('ja'),
        ),
      ],
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String label;
  final String code;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.label,
    required this.code,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Tooltip(
      message: code.toUpperCase(),
      child: Material(
        color: isSelected
            ? theme.amber
            : theme.surface.withValues(alpha: theme.useHardShadow ? 0.92 : 1),
        borderRadius: BorderRadius.circular(theme.radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(theme.radius),
          child: Container(
            width: 52,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.border,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(theme.radius),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: theme.ink,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                fontFamily: 'Courier',
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroBackdrop extends StatelessWidget {
  const _IntroBackdrop();

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return ColoredBox(
      color: theme.background,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.border,
              width: theme.useHardShadow ? 4 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

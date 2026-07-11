import 'package:cyber_table_order/components/themed_app_dialog.dart';
import 'package:cyber_table_order/models/game_controller.dart';
import 'package:cyber_table_order/models/onboarding_controller.dart';
import 'package:cyber_table_order/models/restaurant.dart';
import 'package:cyber_table_order/pages/menu_page.dart';
import 'package:cyber_table_order/theme/app_theme.dart';
import 'package:cyber_table_order/theme/app_theme_mode.dart';
import 'package:cyber_table_order/theme/theme_controller.dart';
import 'package:cyber_table_order/utils/app_message.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _onboardingScheduled = false;

  void _scheduleOnboarding() {
    if (_onboardingScheduled) return;
    _onboardingScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final onboarding = context.read<OnboardingController>();
      if (!onboarding.isComplete) {
        _showOnboardingDialog();
      }
    });
  }

  void _showOnboardingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Consumer2<Restaurant, OnboardingController>(
          builder: (context, restaurant, onboarding, child) {
            final step = onboarding.step.clamp(
              0,
              OnboardingController.totalSteps - 1,
            );
            final titleKey = switch (step) {
              0 => 'onboarding_auto_title',
              1 => 'onboarding_upgrade_title',
              _ => 'onboarding_rush_title',
            };
            final descriptionKey = switch (step) {
              0 => 'onboarding_auto_description',
              1 => 'onboarding_upgrade_description',
              _ => 'onboarding_rush_description',
            };
            final icon = switch (step) {
              0 => Icons.auto_awesome,
              1 => Icons.insights,
              _ => Icons.bolt,
            };
            final isLast = step == OnboardingController.totalSteps - 1;

            return ThemedAppDialog(
              title: restaurant.translate('onboarding_title'),
              icon: Icons.school_outlined,
              maxWidth: 460,
              actions: [
                ThemedDialogButton(
                  label: restaurant.translate('onboarding_skip'),
                  onPressed: () async {
                    await onboarding.complete();
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                ),
                ThemedDialogButton(
                  label: restaurant.translate(
                    isLast ? 'onboarding_done' : 'onboarding_next',
                  ),
                  icon: isLast ? Icons.check : Icons.arrow_forward,
                  primary: true,
                  onPressed: () async {
                    if (isLast) {
                      await onboarding.complete();
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    } else {
                      await onboarding.advance();
                    }
                  },
                ),
              ],
              child: Semantics(
                liveRegion: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      restaurant.translate(titleKey),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      restaurant.translate(descriptionKey),
                      textAlign: TextAlign.center,
                      style: const TextStyle(height: 1.45),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '${step + 1}/${OnboardingController.totalSteps}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSettingsDialog(BuildContext pageContext) {
    showDialog<void>(
      context: pageContext,
      builder: (dialogContext) {
        return Consumer2<Restaurant, ThemeController>(
          builder: (context, restaurant, themeController, child) {
            return ThemedAppDialog(
              title: restaurant.translate('system_config'),
              icon: Icons.settings,
              maxWidth: 560,
              actions: [
                ThemedDialogButton(
                  label: restaurant.translate('close'),
                  primary: true,
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSettingSectionLabel(
                    context,
                    restaurant.translate('settings_language'),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildLanguageOption(
                        label: 'EN',
                        code: 'en',
                        restaurant: restaurant,
                      ),
                      _buildLanguageOption(
                        label: '中文',
                        code: 'zh',
                        restaurant: restaurant,
                      ),
                      _buildLanguageOption(
                        label: '日本語',
                        code: 'ja',
                        restaurant: restaurant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildSettingSectionLabel(
                    context,
                    restaurant.translate('settings_theme'),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppThemeMode.values
                        .map(
                          (themeMode) => _buildThemeOption(
                            mode: themeMode,
                            controller: themeController,
                            restaurant: restaurant,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ThemedDialogButton(
                      label: restaurant.translate('reset_idle_save'),
                      icon: Icons.restart_alt,
                      destructive: true,
                      onPressed: () => _confirmAndResetIdleSave(
                        pageContext: pageContext,
                        settingsDialogContext: dialogContext,
                        restaurant: restaurant,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingSectionLabel(BuildContext context, String label) {
    final theme = AppTheme.of(context);
    return Text(
      label,
      style: TextStyle(
        color: theme.ink.withValues(alpha: 0.72),
        fontWeight: FontWeight.w800,
        fontFamily: 'Courier',
      ),
    );
  }

  Widget _buildLanguageOption({
    required String label,
    required String code,
    required Restaurant restaurant,
  }) {
    return ThemedOptionTile(
      label: label,
      selected: restaurant.languageCode == code,
      minWidth: 72,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      onTap: () => restaurant.setLanguage(code),
    );
  }

  Widget _buildThemeOption({
    required AppThemeMode mode,
    required ThemeController controller,
    required Restaurant restaurant,
  }) {
    return ThemedOptionTile(
      label: restaurant.translate(mode.labelKey),
      description: restaurant.translate(mode.descriptionKey),
      selected: controller.mode == mode,
      minWidth: 132,
      onTap: () => controller.setMode(mode),
    );
  }

  Future<void> _confirmAndResetIdleSave({
    required BuildContext pageContext,
    required BuildContext settingsDialogContext,
    required Restaurant restaurant,
  }) async {
    final confirmed = await showDialog<bool>(
      context: settingsDialogContext,
      builder: (confirmationContext) {
        final theme = AppTheme.of(confirmationContext);
        return ThemedAppDialog(
          title: restaurant.translate('reset_idle_save'),
          icon: Icons.warning_amber,
          maxWidth: 400,
          actions: [
            ThemedDialogButton(
              label: restaurant.translate('cancel'),
              onPressed: () => Navigator.pop(confirmationContext, false),
            ),
            ThemedDialogButton(
              label: restaurant.translate('confirm'),
              icon: Icons.restart_alt,
              destructive: true,
              onPressed: () => Navigator.pop(confirmationContext, true),
            ),
          ],
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.delete_forever, color: theme.danger, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${restaurant.translate('reset_idle_save')}?',
                  style: TextStyle(
                    color: theme.ink,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true || !pageContext.mounted) return;

    await pageContext.read<GameController>().reset();
    if (!pageContext.mounted) return;

    if (settingsDialogContext.mounted) {
      Navigator.pop(settingsDialogContext);
    }

    final theme = AppTheme.of(pageContext);
    AppMessage.show(
      pageContext,
      backgroundColor: theme.surfaceHigh,
      content: Text(
        restaurant.translate('idle_save_reset'),
        style: TextStyle(
          color: theme.ink,
          fontWeight: FontWeight.bold,
          fontFamily: 'Courier',
        ),
      ),
      duration: const Duration(seconds: 2),
    );
  }

  Color _appBarBackgroundColor(BuildContext context) {
    final theme = AppTheme.of(context);
    return switch (AppTheme.modeOf(context)) {
      AppThemeMode.neonTerminal => theme.surface,
      AppThemeMode.paperReceipt => theme.surface,
      AppThemeMode.retroOS => theme.accent,
      AppThemeMode.neoBrutalism => theme.amber,
    };
  }

  Color _appBarForegroundColor(BuildContext context) {
    final theme = AppTheme.of(context);
    return switch (AppTheme.modeOf(context)) {
      AppThemeMode.neonTerminal => theme.cyan,
      AppThemeMode.retroOS => Colors.white,
      AppThemeMode.paperReceipt || AppThemeMode.neoBrutalism => theme.ink,
    };
  }

  IconData _appBarTitleIcon(BuildContext context) {
    return switch (AppTheme.modeOf(context)) {
      AppThemeMode.neonTerminal => Icons.terminal,
      AppThemeMode.paperReceipt => Icons.receipt_long,
      AppThemeMode.retroOS => Icons.window,
      AppThemeMode.neoBrutalism => Icons.storefront,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Restaurant>(
      builder: (context, restaurant, child) {
        final gameLoaded = context.select<GameController, bool>(
          (game) => game.isLoaded,
        );
        final onboardingReady = context.select<OnboardingController, bool>(
          (onboarding) => onboarding.isLoaded && !onboarding.isComplete,
        );
        if (gameLoaded && onboardingReady) {
          _scheduleOnboarding();
        }
        final theme = AppTheme.of(context);
        final mode = AppTheme.modeOf(context);
        final foreground = _appBarForegroundColor(context);
        final borderColor =
            mode == AppThemeMode.neonTerminal ? theme.cyan : theme.ink;
        final borderWidth = switch (mode) {
          AppThemeMode.neonTerminal || AppThemeMode.paperReceipt => 1.0,
          AppThemeMode.retroOS => 2.0,
          AppThemeMode.neoBrutalism => 3.0,
        };

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: _appBarBackgroundColor(context),
            elevation: 0,
            centerTitle: false,
            shape: Border(
              bottom: BorderSide(color: borderColor, width: borderWidth),
            ),
            titleSpacing: 16,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_appBarTitleIcon(context), color: foreground, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    restaurant.translate('app_title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontFamily: 'Courier',
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: IconButton(
                  onPressed:
                      gameLoaded ? () => _showSettingsDialog(context) : null,
                  icon: Icon(
                    Icons.settings,
                    color: gameLoaded
                        ? foreground
                        : foreground.withValues(alpha: 0.45),
                    size: 22,
                  ),
                  tooltip: restaurant.translate('system_config'),
                ),
              ),
            ],
          ),
          body: gameLoaded
              ? const MenuPage()
              : Center(
                  child: CircularProgressIndicator(color: theme.accent),
                ),
        );
      },
    );
  }
}

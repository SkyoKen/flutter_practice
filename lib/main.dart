import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cyber_table_order/models/game_controller.dart';
import 'package:cyber_table_order/models/restaurant.dart';
import 'package:cyber_table_order/models/onboarding_controller.dart';
import 'package:cyber_table_order/pages/intro_page.dart';
import 'package:cyber_table_order/theme/app_theme.dart';
import 'package:cyber_table_order/theme/theme_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => GameController()..load()),
        ChangeNotifierProvider(create: (context) => Restaurant()..load()),
        ChangeNotifierProvider(
          create: (context) => ThemeController()..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => OnboardingController()..load(),
        ),
      ],
      builder: (context, child) {
        final themeController = context.watch<ThemeController>();
        final restaurantLoaded = context.select<Restaurant, bool>(
          (restaurant) => restaurant.isLoaded,
        );
        final settingsLoaded = restaurantLoaded && themeController.isLoaded;
        final onboardingLoaded = context.select<OnboardingController, bool>(
          (onboarding) => onboarding.isLoaded,
        );

        return MaterialApp(
          title: 'Table Nova',
          debugShowCheckedModeBanner: false,
          theme: themeController.themeData,
          home: settingsLoaded && onboardingLoaded
              ? const IntroPage()
              : const _BootstrapScreen(),
        );
      },
    );
  }
}

class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: theme.background,
      body: Center(
        child: CircularProgressIndicator(color: theme.accent),
      ),
    );
  }
}

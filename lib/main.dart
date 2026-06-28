import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cyber_table_order/models/game_controller.dart';
import 'package:cyber_table_order/models/restaurant.dart';
import 'package:cyber_table_order/pages/intro_page.dart';
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
        ChangeNotifierProvider(create: (context) => Restaurant()),
        ChangeNotifierProvider(create: (context) => ThemeController()),
      ],
      builder: (context, child) {
        final themeController = context.watch<ThemeController>();

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeController.themeData,
          home: const IntroPage(),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cyber_table_order/models/restaurant.dart';
import 'package:cyber_table_order/pages/intro_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => Restaurant(),
      builder: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepOrange, // 餐饮常用暖色调
          scaffoldBackgroundColor: Colors.grey[200],
        ),
        home: const IntroPage(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cyber_table_order/pages/home_page.dart';
import 'package:cyber_table_order/models/restaurant.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // 全局深黑背景
      body: Consumer<Restaurant>(
        builder: (context, restaurant, child) => Stack(
          children: [
            // Main Content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo (霓虹橙图标)
                    Icon(
                      Icons.memory, // 换成更具科技感的图标
                      size: 140,
                      color: Colors.deepOrangeAccent,
                      shadows: [
                        BoxShadow(
                          color: Colors.deepOrange.withValues(alpha: 0.8),
                          blurRadius: 20,
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // 标题
                    Text(
                      restaurant.translate('app_title'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: Colors.white,
                        fontFamily: 'Courier',
                        letterSpacing: 2.0,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 副标题 (数据流风格)
                    Text(
                      restaurant.translate('accessing_logs'),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.deepOrange,
                        height: 1.5,
                        fontFamily: 'Courier',
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    // 按钮 - 直接导航到 HomePage
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomePage(),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.deepOrange,
                          borderRadius: BorderRadius.circular(4), // 方正的科幻风按钮
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepOrange.withValues(alpha: 0.6),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            )
                          ],
                          border: Border.all(
                              color: Colors.deepOrangeAccent, width: 2),
                        ),
                        padding: const EdgeInsets.all(25),
                        child: Center(
                          child: Text(
                            restaurant.translate('start_session'),
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),

            // Language Switcher (Top Right)
            Positioned(
              top: 50,
              right: 20,
              child: Row(
                children: [
                  _LanguageButton(
                    label: 'EN',
                    code: 'en',
                    isSelected: restaurant.languageCode == 'en',
                    onTap: () => restaurant.setLanguage('en'),
                  ),
                  const SizedBox(width: 10),
                  _LanguageButton(
                    label: '中文',
                    code: 'zh',
                    isSelected: restaurant.languageCode == 'zh',
                    onTap: () => restaurant.setLanguage('zh'),
                  ),
                  const SizedBox(width: 10),
                  _LanguageButton(
                    label: 'JP',
                    code: 'ja',
                    isSelected: restaurant.languageCode == 'ja',
                    onTap: () => restaurant.setLanguage('ja'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widget for language button
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrangeAccent : Colors.transparent,
          border: Border.all(color: Colors.deepOrangeAccent),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.deepOrangeAccent,
            fontWeight: FontWeight.bold,
            fontFamily: 'Courier',
          ),
        ),
      ),
    );
  }
}

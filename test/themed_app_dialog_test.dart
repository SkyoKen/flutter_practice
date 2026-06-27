import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_table_order/components/themed_app_dialog.dart';
import 'package:cyber_table_order/theme/app_theme.dart';
import 'package:cyber_table_order/theme/app_theme_mode.dart';

void main() {
  testWidgets('themed app dialog renders in every theme mode',
      (WidgetTester tester) async {
    for (final mode in AppThemeMode.values) {
      AppTheme.setActiveMode(mode);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.data(mode),
          home: Scaffold(
            body: ThemedAppDialog(
              title: mode.label,
              icon: Icons.info_outline,
              actions: [
                ThemedDialogButton(
                  label: 'OK',
                  primary: true,
                  onPressed: () {},
                ),
              ],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Dialog body'),
                  const SizedBox(height: 8),
                  ThemedOptionTile(
                    label: 'Option',
                    description: 'Selectable item',
                    selected: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text(mode.label), findsOneWidget);
      expect(find.text('Dialog body'), findsOneWidget);
      expect(find.textContaining('Option'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    }
  });
}

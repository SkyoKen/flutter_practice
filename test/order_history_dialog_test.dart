import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_table_order/components/order_history_dialog.dart';
import 'package:cyber_table_order/models/restaurant.dart';
import 'package:cyber_table_order/theme/app_theme.dart';
import 'package:cyber_table_order/theme/app_theme_mode.dart';

void main() {
  testWidgets('order history dialog renders in every theme mode',
      (WidgetTester tester) async {
    final titleByMode = {
      AppThemeMode.neonTerminal: 'HISTORY::LOG',
      AppThemeMode.neoBrutalism: 'HISTORY',
      AppThemeMode.paperReceipt: 'ORDER HISTORY',
      AppThemeMode.retroOS: 'HISTORY.LOG',
    };

    for (final mode in AppThemeMode.values) {
      AppTheme.setActiveMode(mode);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.data(mode),
          home: Scaffold(
            body: OrderHistoryDialog(
              restaurant: Restaurant(),
              tableId: 'T-001',
            ),
          ),
        ),
      );

      expect(find.text(titleByMode[mode]!), findsOneWidget);
      expect(find.textContaining('T-001'), findsOneWidget);
    }
  });
}

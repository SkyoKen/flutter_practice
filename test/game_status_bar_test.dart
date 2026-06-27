import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cyber_table_order/components/game_status_bar.dart';
import 'package:cyber_table_order/models/game_controller.dart';
import 'package:cyber_table_order/models/restaurant.dart';
import 'package:cyber_table_order/theme/app_theme.dart';
import 'package:cyber_table_order/theme/app_theme_mode.dart';

void main() {
  testWidgets('game status bar renders and claims offline earnings in themes',
      (WidgetTester tester) async {
    for (final mode in AppThemeMode.values) {
      for (final width in const [390.0, 1000.0]) {
        final storage = MemoryGameStorage();
        final start = DateTime(2026, 1, 1, 12);
        final firstSession = GameController(storage: storage);
        await firstSession.load(now: start);
        await firstSession.save();

        final game = GameController(storage: storage);
        await game.load(now: start.add(const Duration(minutes: 30)));
        final restaurant = Restaurant();

        AppTheme.setActiveMode(mode);
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<GameController>.value(value: game),
              ChangeNotifierProvider<Restaurant>.value(value: restaurant),
            ],
            child: MaterialApp(
              theme: AppTheme.data(mode),
              home: Scaffold(
                body: GameStatusBar(
                  restaurant: restaurant,
                  menu: restaurant.getMenu(),
                ),
              ),
            ),
          ),
        );

        expect(find.textContaining('COINS'), findsOneWidget);
        expect(find.textContaining('YEN/MIN'), findsOneWidget);
        expect(find.text('NEW CUSTOMER ORDER'), findsOneWidget);
        expect(find.text('GOALS'), findsOneWidget);
        expect(find.text('UPGRADES'), findsOneWidget);
        expect(find.textContaining('+'), findsWidgets);

        await tester.tap(find.text('NEW CUSTOMER ORDER'));
        await tester.pumpAndSettle();

        final seatedAt = game.manualDiningCustomer!.phaseStartedAt;
        await game.simulateBusinessTick(
          const [],
          elapsed: GameController.customerSeatingDuration,
          now: seatedAt.add(GameController.customerSeatingDuration),
        );
        await tester.pump();

        expect(find.textContaining('CUSTOMER ORDER'), findsOneWidget);

        await tester.tap(find.textContaining('CUSTOMER ORDER'));
        await tester.pumpAndSettle();

        await game.simulateBusinessTick(
          const [],
          elapsed: const Duration(seconds: 40),
          now: seatedAt.add(const Duration(seconds: 42)),
        );
        await tester.pump();

        expect(game.coins, greaterThan(GameController.startingCoins));
        expect(game.customerOrdersServed, 1);
        expect(game.customerOrderFoodId, isNull);
        expect(find.textContaining('NEXT CUSTOMER IN'), findsOneWidget);
        expect(find.text('GOALS 1'), findsOneWidget);

        await tester.tap(find.text('GOALS 1'));
        await tester.pumpAndSettle();

        expect(find.text('SHIFT GOALS'), findsOneWidget);
        expect(find.text('First Service'), findsOneWidget);
        expect(find.text('CLAIM'), findsOneWidget);

        await tester.tap(find.text('CLAIM').first);
        await tester.pumpAndSettle();

        expect(game.claimedMilestoneIds, contains('first_service'));
        expect(find.text('CLAIMED'), findsOneWidget);

        await tester.tap(find.text('CLOSE'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.savings));
        await tester.pumpAndSettle();

        expect(find.text('NO IDLE'), findsOneWidget);
      }
    }
  });
}

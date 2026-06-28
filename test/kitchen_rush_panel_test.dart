import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cyber_table_order/components/kitchen_rush_panel.dart';
import 'package:cyber_table_order/models/game_controller.dart';
import 'package:cyber_table_order/models/restaurant.dart';
import 'package:cyber_table_order/theme/app_theme.dart';
import 'package:cyber_table_order/theme/app_theme_mode.dart';

void main() {
  testWidgets('kitchen rush seats customer and rewards correct dish',
      (WidgetTester tester) async {
    final game = GameController(storage: MemoryGameStorage());
    final restaurant = Restaurant();
    await game.load(now: DateTime(2026, 1, 1, 12));
    AppTheme.setActiveMode(AppThemeMode.neoBrutalism);

    tester.view.physicalSize = const Size(390, 700);
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
          theme: AppTheme.data(AppThemeMode.neoBrutalism),
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: KitchenRushPanel(
                restaurant: restaurant,
                menu: restaurant.getMenu(),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('KITCHEN RUSH'), findsOneWidget);
    expect(find.text('SEAT CUSTOMER'), findsOneWidget);

    await tester.tap(find.text('SEAT CUSTOMER'));
    await tester.pumpAndSettle();

    expect(find.text('Guiding guest'), findsOneWidget);

    final seatedAt = game.manualDiningCustomer!.phaseStartedAt;
    final ticketAt = seatedAt.add(GameController.customerSeatingDuration);
    await game.simulateBusinessTick(
      const [],
      elapsed: GameController.customerSeatingDuration,
      now: ticketAt,
    );
    await tester.pump();

    expect(find.textContaining('REQUEST TICKET'), findsOneWidget);
    expect(find.text('招牌和牛汉堡'), findsWidgets);

    await tester.tap(find.text('招牌和牛汉堡').last);
    await tester.pumpAndSettle();

    expect(find.text('Delivering dish'), findsOneWidget);
    await game.simulateBusinessTick(
      const [],
      elapsed: const Duration(seconds: 40),
      now: ticketAt.add(const Duration(seconds: 40)),
    );
    await tester.pump();

    expect(game.coins, greaterThan(GameController.startingCoins));
    expect(game.customerOrdersServed, 1);
    expect(game.bestCombo, 1);
    expect(game.customerOrderFoodId, isNull);
    expect(find.text('BEST x1'), findsOneWidget);
    expect(find.textContaining('NEXT CUSTOMER IN'), findsOneWidget);
  });
}

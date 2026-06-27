import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cyber_table_order/components/customer_arrival_stage.dart';
import 'package:cyber_table_order/models/game_controller.dart';
import 'package:cyber_table_order/models/restaurant.dart';
import 'package:cyber_table_order/theme/app_theme.dart';
import 'package:cyber_table_order/theme/app_theme_mode.dart';

void main() {
  testWidgets('customer arrival stage shows auto and manual service states',
      (WidgetTester tester) async {
    for (final mode in AppThemeMode.values) {
      for (final width in const [390.0, 1000.0]) {
        final game = GameController(storage: MemoryGameStorage());
        final restaurant = Restaurant();
        final start = DateTime.now();
        await game.load(now: start);

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
                body: CustomerArrivalStage(
                  restaurant: restaurant,
                  menu: restaurant.getMenu(),
                ),
              ),
            ),
          ),
        );

        expect(find.text('AUTO SERVICE RUNNING'), findsOneWidget);
        expect(find.textContaining('Queue 0/4'), findsOneWidget);
        expect(find.textContaining('Tables 0/2'), findsOneWidget);
        expect(find.textContaining('Flow K0 E0 P0'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('business-queue-customer-0')),
          findsNothing,
        );

        expect(await game.upgradeSeats(), isTrue);
        await tester.pump();
        expect(find.textContaining('Tables 0/3'), findsOneWidget);

        expect(
          await game.claimMilestone(
            'better_seats',
            now: DateTime.now(),
          ),
          greaterThan(0),
        );
        expect(await game.upgradeService(), isTrue);
        await tester.pump();
        expect(find.textContaining('Tables 0/3'), findsOneWidget);

        await game.ensureCustomerOrder(
          [1, 2],
          now: start,
        );
        await tester.pump();

        expect(find.text('Customer walking in'), findsOneWidget);
        expect(find.byKey(const ValueKey('dining-customer-1')), findsOneWidget);

        final ticketAt = start.add(GameController.customerSeatingDuration);
        await game.simulateBusinessTick(
          const [],
          elapsed: GameController.customerSeatingDuration,
          now: ticketAt,
        );
        await tester.pump();

        expect(find.textContaining('Serving:'), findsOneWidget);

        await game.serveCustomerOrder(
          [1, 2],
          now: ticketAt,
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Delivering dish'), findsOneWidget);

        await game.simulateBusinessTick(
          const [],
          elapsed: const Duration(seconds: 40),
          now: ticketAt.add(const Duration(seconds: 40)),
        );
        await tester.pump();

        expect(find.text('AUTO SERVICE RUNNING'), findsOneWidget);
      }
    }
  });

  testWidgets('customer arrival stage renders auto flow chips and coin burst',
      (WidgetTester tester) async {
    final game = GameController(
      storage: MemoryGameStorage({
        'idle_seat_level': 2,
        'idle_dining_customers': jsonEncode([
          {
            'id': 1,
            'source': 'auto',
            'phase': 'servingFood',
            'seatIndex': 0,
            'foodId': 1,
            'reward': 25.0,
            'customerType': 'normal',
            'phaseStartedAt': '2026-01-01T12:00:00.000',
          },
          {
            'id': 2,
            'source': 'auto',
            'phase': 'eating',
            'seatIndex': 1,
            'foodId': 2,
            'reward': 25.0,
            'customerType': 'normal',
            'phaseStartedAt': '2026-01-01T12:00:00.000',
          },
          {
            'id': 3,
            'source': 'auto',
            'phase': 'checkout',
            'seatIndex': 2,
            'foodId': 3,
            'reward': 25.0,
            'customerType': 'normal',
            'phaseStartedAt': '2026-01-01T12:00:00.000',
          },
          for (final id in [4, 5, 6])
            {
              'id': id,
              'source': 'auto',
              'phase': 'queueing',
              'seatIndex': null,
              'foodId': 1,
              'reward': 25.0,
              'customerType': 'normal',
              'phaseStartedAt': '2026-01-01T12:00:00.000',
            },
        ]),
        'idle_pending_business_earnings': 48.0,
      }),
    );
    final restaurant = Restaurant();
    final start = DateTime(2026, 1, 1, 12);
    await game.load(now: start);
    AppTheme.setActiveMode(AppThemeMode.neoBrutalism);

    tester.view.physicalSize = const Size(390, 844);
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
            body: CustomerArrivalStage(
              restaurant: restaurant,
              menu: restaurant.getMenu(),
              prominent: true,
              recentCompletedOrders: 2,
              coinBurstSeed: 1,
            ),
          ),
        ),
      ),
    );

    expect(find.text('AUTO SERVICE RUNNING'), findsOneWidget);
    expect(find.textContaining('Queue 3/6'), findsOneWidget);
    expect(find.textContaining('Tables 3/3'), findsOneWidget);
    expect(find.textContaining('Flow K1 E1 P1'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dining-customer-4')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dining-customer-6')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dining-customer-1')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('kitchen-order-chip-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('checkout-order-chip-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('coin-burst')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('business-leaving-customer')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.directions_walk), findsWidgets);
  });

  testWidgets('customer arrival stage respects disabled animations',
      (WidgetTester tester) async {
    final game = GameController(
      storage: MemoryGameStorage({
        'idle_dining_customers': jsonEncode([
          {
            'id': 1,
            'source': 'auto',
            'phase': 'servingFood',
            'seatIndex': 0,
            'foodId': 1,
            'reward': 25.0,
            'customerType': 'normal',
            'phaseStartedAt': '2026-01-01T12:00:00.000',
          },
          {
            'id': 2,
            'source': 'auto',
            'phase': 'queueing',
            'seatIndex': null,
            'foodId': 2,
            'reward': 25.0,
            'customerType': 'normal',
            'phaseStartedAt': '2026-01-01T12:00:00.000',
          },
        ]),
      }),
    );
    final restaurant = Restaurant();
    final start = DateTime(2026, 1, 1, 12);
    await game.load(now: start);
    AppTheme.setActiveMode(AppThemeMode.paperReceipt);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<GameController>.value(value: game),
          ChangeNotifierProvider<Restaurant>.value(value: restaurant),
        ],
        child: MaterialApp(
          theme: AppTheme.data(AppThemeMode.paperReceipt),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: CustomerArrivalStage(
                restaurant: restaurant,
                menu: restaurant.getMenu(),
                prominent: true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('AUTO SERVICE RUNNING'), findsOneWidget);
    expect(find.textContaining('Queue 1/4'), findsOneWidget);
    expect(find.byKey(const ValueKey('kitchen-order-chip-1')), findsOneWidget);
  });
}

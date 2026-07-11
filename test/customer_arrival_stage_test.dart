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
          find.byWidgetPredicate((widget) {
            final key = widget.key;
            return key is ValueKey<String> &&
                key.value.startsWith('dining-customer-');
          }),
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
          selectedFoodId: 1,
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
    final semantics = tester.ensureSemantics();
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
                recentCompletedOrders: 2,
                coinBurstSeed: 1,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('AUTO SERVICE RUNNING'), findsOneWidget);
    expect(find.textContaining('Queue 1/4'), findsOneWidget);
    expect(find.byKey(const ValueKey('kitchen-order-chip-1')), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp(r'AUTO SERVICE RUNNING.*Entrance Queue 1/4'),
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp(r'^\+')), findsNothing);
    semantics.dispose();

    final customer = find.byKey(const ValueKey('dining-customer-2'));
    final initialCustomerPosition = tester.getTopLeft(customer);
    final coinOpacity = tester.widget<Opacity>(
      find.ancestor(
        of: find.byKey(const ValueKey('coin-burst')),
        matching: find.byType(Opacity),
      ),
    );
    expect(coinOpacity.opacity, 0);
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pump(const Duration(seconds: 2));

    expect(tester.getTopLeft(customer), initialCustomerPosition);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('queue customers stay inside the entrance waiting area', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final width in const [390.0, 1000.0]) {
      final start = DateTime(2026, 1, 1, 12);
      final game = GameController(
        storage: MemoryGameStorage({
          'idle_seat_level': 2,
          'idle_dining_customers': jsonEncode([
            for (var id = 1; id <= 6; id += 1)
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
            for (var seatIndex = 0; seatIndex < 3; seatIndex += 1)
              {
                'id': 100 + seatIndex,
                'source': 'auto',
                'phase': 'eating',
                'seatIndex': seatIndex,
                'foodId': 1,
                'reward': 25.0,
                'customerType': 'normal',
                'phaseStartedAt': '2026-01-01T12:00:00.000',
              },
          ]),
        }),
      );
      final restaurant = Restaurant();
      await game.load(now: start);
      tester.view.physicalSize = Size(width, 900);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<GameController>.value(value: game),
            ChangeNotifierProvider<Restaurant>.value(value: restaurant),
          ],
          child: MaterialApp(
            theme: AppTheme.data(AppThemeMode.neoBrutalism),
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 900),
                disableAnimations: true,
              ),
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

      final waitingArea = find.byKey(
        const ValueKey('business-entrance-waiting-area'),
      );
      final serviceRoute = find.byKey(
        const ValueKey('business-service-route'),
      );
      final entranceMarker = find.byKey(
        const ValueKey('business-entrance-marker'),
      );
      final waitingRect = tester.getRect(waitingArea);
      final routeRect = tester.getRect(serviceRoute);
      final entranceRect = tester.getRect(entranceMarker);
      final tableRects = [
        for (var index = 0; index < 3; index += 1)
          tester.getRect(
            find.byKey(ValueKey('business-dining-table-$index')),
          ),
      ];

      expect(waitingRect.overlaps(routeRect), isFalse);
      expect(
        entranceRect.left - waitingRect.right,
        inInclusiveRange(0, 8),
        reason: 'the waiting area should stay beside the entrance at $width',
      );

      final queuedCustomerRects = <Rect>[];
      for (var id = 1; id <= 6; id += 1) {
        final customer = find.byKey(ValueKey('dining-customer-$id'));
        final customerRect = tester.getRect(customer);

        expect(
          waitingRect.inflate(0.1).contains(customerRect.topLeft) &&
              waitingRect.inflate(0.1).contains(customerRect.bottomRight),
          isTrue,
          reason: 'queued customer $id left the waiting area at $width',
        );
        for (final queuedCustomerRect in queuedCustomerRects) {
          expect(
            customerRect.overlaps(queuedCustomerRect),
            isFalse,
            reason: 'queued customers overlapped at $width',
          );
        }
        for (final tableRect in tableRects) {
          expect(
            customerRect.overlaps(tableRect),
            isFalse,
            reason: 'queued customer $id overlapped a table at $width',
          );
        }
        queuedCustomerRects.add(customerRect);
      }

      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('customer arrival stage aggregates large customer populations',
      (WidgetTester tester) async {
    final game = GameController(
      storage: MemoryGameStorage({
        'idle_seat_level': 60,
        'idle_dining_customers': jsonEncode([
          for (var id = 1; id <= 120; id += 1)
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
          for (var index = 1; index <= 20; index += 1)
            {
              'id': 200 + index,
              'source': 'auto',
              'phase': 'eating',
              'seatIndex': index,
              'foodId': 1,
              'reward': 25.0,
              'customerType': 'normal',
              'phaseStartedAt': '2026-01-01T12:00:00.000',
            },
          {
            'id': 1000,
            'source': 'manual',
            'phase': 'waitingForFood',
            'seatIndex': 0,
            'foodId': 1,
            'reward': 25.0,
            'customerType': 'normal',
            'phaseStartedAt': '2026-01-01T12:00:00.000',
          },
        ]),
      }),
    );
    final restaurant = Restaurant();
    await game.load(now: DateTime(2026, 1, 1, 12));
    tester.view.physicalSize = const Size(1000, 900);
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
          theme: AppTheme.data(AppThemeMode.retroOS),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(1000, 900),
              disableAnimations: true,
            ),
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

    final renderedCustomers = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith('dining-customer-');
    });

    expect(find.textContaining('Queue 120/122'), findsOneWidget);
    expect(renderedCustomers, findsNWidgets(14));
    expect(
      find.byKey(const ValueKey('dining-customer-1000')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dining-customer-11')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('queue-customer-overflow')),
        matching: find.text('+112'),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .getRect(
            find.byKey(const ValueKey('business-entrance-waiting-area')),
          )
          .contains(
            tester
                .getRect(
                  find.byKey(const ValueKey('queue-customer-overflow')),
                )
                .center,
          ),
      isTrue,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('floor-customer-overflow')),
        matching: find.text('+15'),
      ),
      findsOneWidget,
    );
  });
}

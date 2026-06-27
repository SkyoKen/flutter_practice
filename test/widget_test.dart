import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_table_order/main.dart';
import 'package:cyber_table_order/models/game_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('opens the ordering screen from the intro page',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());

    expect(find.text('CYBER TABLE ORDER'), findsOneWidget);
    expect(find.text('START SESSION'), findsOneWidget);

    await tester.tap(find.text('START SESSION'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('ACCESS ID:'), findsOneWidget);
    expect(find.text('AUTO DINING ROOM'), findsOneWidget);
    expect(find.text('AUTO SERVICE RUNNING'), findsWidgets);
    expect(find.text('DISH BOOK'), findsOneWidget);
    expect(find.text('OPERATIONS'), findsOneWidget);
  });

  testWidgets('opens the ordering screen on a narrow viewport',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('START SESSION'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('T-0'), findsOneWidget);
    expect(find.text('AUTO DINING ROOM'), findsOneWidget);
    expect(find.text('RUSH'), findsOneWidget);

    final game =
        tester.element(find.byType(MaterialApp)).read<GameController>();
    await game.reset(now: DateTime.now());
    await tester.pump();

    await tester.tap(find.text('RUSH'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('KITCHEN RUSH'), findsWidgets);
    expect(find.text('SEAT CUSTOMER'), findsOneWidget);

    await tester.tap(find.text('SEAT CUSTOMER'));
    await tester.pump();
    if (game.manualDiningCustomer == null) {
      await game.ensureCustomerOrder([1, 2, 3], now: DateTime.now());
    }
    final seatedAt = game.manualDiningCustomer!.phaseStartedAt;
    await game.simulateBusinessTick(
      const [],
      elapsed: GameController.customerSeatingDuration,
      now: seatedAt.add(GameController.customerSeatingDuration),
    );
    await tester.pump();

    expect(find.textContaining('REQUEST TICKET'), findsOneWidget);
    expect(find.text('招牌和牛汉堡'), findsWidgets);

    await tester.tap(find.text('招牌和牛汉堡').last);
    await tester.pump();
    await game.simulateBusinessTick(
      const [],
      elapsed: const Duration(seconds: 40),
      now: seatedAt.add(const Duration(seconds: 42)),
    );
    await tester.pump();

    expect(find.text('CLAIM'), findsOneWidget);
  });
}

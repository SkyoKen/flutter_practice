import 'dart:ui' show SemanticsAction, SemanticsFlag;

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
    final semantics = tester.ensureSemantics();
    final game = GameController(storage: MemoryGameStorage());
    final restaurant = Restaurant();
    await game.load(now: DateTime(2026, 1, 1, 12));
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
    final seatAction = find.byKey(
      const ValueKey('rush-seat-customer-action'),
    );
    final seatSemantics = tester.getSemantics(seatAction).getSemanticsData();
    expect(seatSemantics.hasFlag(SemanticsFlag.isButton), isTrue);
    expect(seatSemantics.hasFlag(SemanticsFlag.isEnabled), isTrue);
    expect(seatSemantics.hasAction(SemanticsAction.tap), isTrue);
    expect(tester.getSize(seatAction).height, greaterThanOrEqualTo(48));

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
    expect(find.text('Signature Wagyu Burger'), findsWidgets);
    final activeFoodId = game.customerOrderFoodId!;
    final activeDishAction = find.byKey(
      ValueKey('rush-dish-choice-$activeFoodId'),
    );
    final dishSemantics =
        tester.getSemantics(activeDishAction).getSemanticsData();
    expect(dishSemantics.hasFlag(SemanticsFlag.isButton), isTrue);
    expect(dishSemantics.hasFlag(SemanticsFlag.isEnabled), isTrue);
    expect(dishSemantics.hasAction(SemanticsAction.tap), isTrue);
    expect(tester.getSize(activeDishAction).height, greaterThanOrEqualTo(48));
    semantics.dispose();

    await tester.tap(find.text('Signature Wagyu Burger').last);
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

  testWidgets('reduced motion removes rush feedback animation',
      (WidgetTester tester) async {
    final semantics = tester.ensureSemantics();
    final game = GameController(storage: MemoryGameStorage());
    final restaurant = Restaurant();
    await game.load(now: DateTime(2026, 1, 1, 12));

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
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
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
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('rush-seat-customer-action')),
    );
    await tester.pumpAndSettle();

    final seatedAt = game.manualDiningCustomer!.phaseStartedAt;
    await game.simulateBusinessTick(
      const [],
      elapsed: GameController.customerSeatingDuration,
      now: seatedAt.add(GameController.customerSeatingDuration),
    );
    await tester.pump();

    final activeFoodId = game.customerOrderFoodId!;
    final wrongFood = restaurant.getMenu().firstWhere(
          (food) => food.id != activeFoodId && game.isFoodUnlocked(food.id),
        );
    final wrongDishAction = find.byKey(
      ValueKey('rush-dish-choice-${wrongFood.id}'),
    );
    await tester.ensureVisible(wrongDishAction);
    await tester.pump();
    expect(tester.getSize(wrongDishAction).height, greaterThanOrEqualTo(48));

    await tester.tap(wrongDishAction);
    await tester.pumpAndSettle();

    final selectedDishSemantics =
        tester.getSemantics(wrongDishAction).getSemanticsData();
    expect(selectedDishSemantics.hasFlag(SemanticsFlag.isButton), isTrue);
    expect(selectedDishSemantics.hasFlag(SemanticsFlag.isEnabled), isTrue);
    expect(selectedDishSemantics.hasFlag(SemanticsFlag.isSelected), isTrue);
    expect(selectedDishSemantics.hasAction(SemanticsAction.tap), isTrue);
    semantics.dispose();

    final switchers = tester.widgetList<AnimatedSwitcher>(
      find.byWidgetPredicate((widget) => widget is AnimatedSwitcher),
    );
    expect(switchers, isNotEmpty);
    expect(
        switchers.every((widget) => widget.duration == Duration.zero), isTrue);

    final tweens = tester.widgetList<TweenAnimationBuilder<double>>(
      find.byWidgetPredicate(
        (widget) => widget is TweenAnimationBuilder<double>,
      ),
    );
    expect(tweens, isNotEmpty);
    expect(tweens.every((widget) => widget.duration == Duration.zero), isTrue);

    final containers = tester.widgetList<AnimatedContainer>(
      find.byWidgetPredicate((widget) => widget is AnimatedContainer),
    );
    expect(containers, isNotEmpty);
    expect(
      containers.every((widget) => widget.duration == Duration.zero),
      isTrue,
    );

    final transforms = tester.widgetList<Transform>(
      find.descendant(
        of: find.byType(KitchenRushPanel),
        matching: find.byType(Transform),
      ),
    );
    expect(transforms, isNotEmpty);
    expect(
      transforms.every(
        (widget) => widget.transform.getMaxScaleOnAxis() == 1,
      ),
      isTrue,
    );
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('shows a shift summary as soon as the target order completes',
      (WidgetTester tester) async {
    final game = GameController(
      storage: MemoryGameStorage({
        'idle_shift_orders_served': GameController.shiftTargetOrders,
        'idle_shift_missed_orders': 1,
        'idle_shift_best_combo': 3,
        'idle_shift_coins_earned': 96.0,
      }),
    );
    final restaurant = Restaurant();
    await game.load(now: DateTime(2026, 1, 1, 12));
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
    await tester.pumpAndSettle();

    expect(find.text('SHIFT SUMMARY'), findsOneWidget);
    expect(find.text('${GameController.shiftTargetOrders}'), findsWidgets);
    expect(game.shiftOrdersServed, 0);
    expect(game.shiftMissedOrders, 0);
    expect(game.shiftCoinsEarned, 0);
  });
}

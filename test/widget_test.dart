import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_table_order/main.dart';
import 'package:cyber_table_order/models/game_controller.dart';
import 'package:cyber_table_order/models/restaurant.dart';
import 'package:cyber_table_order/pages/menu_page.dart';
import 'package:cyber_table_order/theme/app_theme.dart';
import 'package:cyber_table_order/theme/app_theme_mode.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RetryableGameStorage extends MemoryGameStorage {
  bool failNextWrite = false;

  @override
  Future<void> setString(String key, String value) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('simulated save failure');
    }
    await super.setString(key, value);
  }
}

int _operationLevel(GameController game, GameOperationUpgradeType type) {
  return switch (type) {
    GameOperationUpgradeType.seats => game.seatLevel,
    GameOperationUpgradeType.kitchen => game.kitchenLevel,
    GameOperationUpgradeType.service => game.serviceLevel,
  };
}

Future<void> _completeFirstService(GameController game) async {
  final startedAt = DateTime.now();
  await game.reset(now: startedAt);
  expect(await game.ensureCustomerOrder([1], now: startedAt), isTrue);

  var cursor = startedAt;
  for (var index = 0; index < 10 && game.customerOrderFoodId == null; index++) {
    cursor = cursor.add(const Duration(seconds: 1));
    await game.simulateBusinessTick(
      const [],
      elapsed: const Duration(seconds: 1),
      now: cursor,
    );
  }

  expect(game.customerOrderFoodId, 1);
  expect(
    await game.serveCustomerOrder(
      [1],
      selectedFoodId: 1,
      now: cursor,
    ),
    greaterThan(0),
  );

  for (var index = 0;
      index < 80 && game.manualDiningCustomer != null;
      index++) {
    cursor = cursor.add(const Duration(seconds: 1));
    await game.simulateBusinessTick(
      const [],
      elapsed: const Duration(seconds: 1),
      now: cursor,
    );
  }

  expect(game.manualDiningCustomer, isNull);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'app_onboarding_step_v1': '3',
    });
  });

  testWidgets('shows and persists the three-step first-run guide',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('START BUSINESS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('QUICK START'), findsOneWidget);
    expect(find.text('THE DINING ROOM RUNS ITSELF'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);

    await tester.tap(find.text('NEXT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('FIX THE CURRENT BOTTLENECK'), findsOneWidget);
    expect(find.text('2/3'), findsOneWidget);

    await tester.tap(find.text('NEXT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('JUMP IN WITH RUSH'), findsOneWidget);
    expect(find.text('3/3'), findsOneWidget);

    await tester.tap(find.text('GOT IT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('QUICK START'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('START BUSINESS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('QUICK START'), findsNothing);
  });

  testWidgets('opens the restaurant dashboard from the intro page',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('TABLE NOVA'), findsOneWidget);
    expect(find.text('START BUSINESS'), findsOneWidget);

    await tester.tap(find.text('START BUSINESS'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('TABLE NOVA'), findsOneWidget);
    expect(find.text('AUTO DINING ROOM'), findsOneWidget);
    expect(find.text('AUTO SERVICE RUNNING'), findsWidgets);
    expect(find.text('RUSH'), findsOneWidget);
    expect(find.text('DISH BOOK'), findsOneWidget);
    expect(find.text('OPERATIONS'), findsOneWidget);
    expect(find.text('GOALS'), findsOneWidget);
    expect(find.text('HISTORY'), findsNothing);
    expect(find.text('MOBILE ORDER QR'), findsNothing);
    expect(find.text('CALL STAFF'), findsNothing);

    final controlPanel = find.byKey(const ValueKey('idle-control-panel'));
    final controlPanelRect = tester.getRect(controlPanel);
    final stageRect = tester.getRect(
      find.byKey(const ValueKey('customer-arrival-stage-summary')),
    );
    final metricKeys = [
      'auto-metric-queue',
      'auto-metric-tables',
      'auto-metric-kitchen',
      'auto-metric-dining',
      'auto-metric-checkout',
    ];

    expect(find.byKey(const ValueKey('idle-metrics-grid')), findsOneWidget);
    expect(find.byKey(const ValueKey('idle-metrics-scroll')), findsNothing);
    expect(controlPanelRect.top, closeTo(stageRect.top, 0.1));
    expect(controlPanelRect.bottom, closeTo(stageRect.bottom, 0.1));
    for (final key in metricKeys) {
      final metricRect = tester.getRect(find.byKey(ValueKey(key)));
      expect(
        controlPanelRect.inflate(0.1).contains(metricRect.topLeft) &&
            controlPanelRect.inflate(0.1).contains(metricRect.bottomRight),
        isTrue,
        reason: '$key was clipped outside the wide control panel',
      );
    }
    for (final key in const ['idle-rush-action', 'idle-claim-action']) {
      expect(
        controlPanelRect.contains(
          tester.getRect(find.byKey(ValueKey(key))).center,
        ),
        isTrue,
      );
    }
    expect(
      controlPanelRect.bottom -
          tester.getRect(find.byKey(const ValueKey('idle-rush-action'))).bottom,
      inInclusiveRange(14, 18),
    );
  });

  testWidgets('compact restaurant dashboard fits short phone viewports',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final viewport in const [Size(390, 700), Size(390, 844)]) {
      SharedPreferences.setMockInitialValues({
        'app_onboarding_step_v1': '3',
      });
      tester.view.physicalSize = viewport;

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('START BUSINESS'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(
        tester.takeException(),
        isNull,
        reason: 'dashboard overflowed at $viewport',
      );
      expect(find.text('AUTO DINING ROOM'), findsOneWidget);
      expect(find.text('RUSH'), findsOneWidget);
      expect(find.byKey(const ValueKey('idle-metrics-grid')), findsNothing);
      expect(
        find.byKey(const ValueKey('idle-metrics-scroll')),
        findsOneWidget,
      );

      final controlPanelRect = tester.getRect(
        find.byKey(const ValueKey('idle-control-panel')),
      );
      for (final key in const ['idle-rush-action', 'idle-claim-action']) {
        final actionRect = tester.getRect(find.byKey(ValueKey(key)));
        expect(
          controlPanelRect.inflate(0.1).contains(actionRect.topLeft) &&
              controlPanelRect.inflate(0.1).contains(actionRect.bottomRight),
          isTrue,
          reason: '$key left the compact control panel at $viewport',
        );
      }

      final game =
          tester.element(find.byType(MaterialApp)).read<GameController>();
      final now = DateTime.now();
      final completed = await game.simulateBusinessTick(
        const [1, 2, 3],
        elapsed: const Duration(minutes: 3),
        now: now.add(const Duration(minutes: 3)),
      );
      expect(completed, greaterThan(0));
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'dashboard overflowed with claimable income at $viewport',
      );
      final incomeButtons = find.ancestor(
        of: find.byIcon(Icons.savings),
        matching: find.byWidgetPredicate(
          (widget) => widget is ButtonStyleButton,
          description: 'income claim button',
        ),
      );
      final enabledIncomeButtons = tester
          .widgetList<ButtonStyleButton>(incomeButtons)
          .where((button) => button.onPressed != null);
      final incomeTooltip = find.byWidgetPredicate(
        (widget) =>
            widget is Tooltip &&
            (widget.message ?? '').startsWith('CLAIM INCOME'),
        description: 'income claim tooltip',
      );
      expect(incomeTooltip, findsOneWidget);
      expect(find.textContaining('CLAIM +'), findsOneWidget);
      expect(
        enabledIncomeButtons,
        hasLength(1),
        reason: 'expected one enabled income claim action at $viewport',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('minimum wide dashboard keeps side rail content visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(820, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('START BUSINESS'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final panelRect = tester.getRect(
      find.byKey(const ValueKey('idle-control-panel')),
    );
    final stageRect = tester.getRect(
      find.byKey(const ValueKey('customer-arrival-stage-summary')),
    );
    expect(panelRect.width, closeTo(340, 0.1));
    expect(panelRect.bottom, closeTo(stageRect.bottom, 0.1));
    expect(find.byKey(const ValueKey('idle-metrics-grid')), findsOneWidget);

    for (final key in const [
      'auto-metric-queue',
      'auto-metric-tables',
      'auto-metric-kitchen',
      'auto-metric-dining',
      'auto-metric-checkout',
      'idle-rush-action',
      'idle-claim-action',
    ]) {
      final itemRect = tester.getRect(find.byKey(ValueKey(key)));
      expect(
        panelRect.inflate(0.1).contains(itemRect.topLeft) &&
            panelRect.inflate(0.1).contains(itemRect.bottomRight),
        isTrue,
        reason: '$key was clipped at the minimum wide breakpoint',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the restaurant dashboard on a narrow viewport',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('START BUSINESS'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('TABLE NOVA'), findsOneWidget);
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
    expect(find.text('Signature Wagyu Burger'), findsWidgets);

    await tester.tap(find.text('Signature Wagyu Burger').last);
    await tester.pump();
    await game.simulateBusinessTick(
      const [],
      elapsed: const Duration(seconds: 40),
      now: seatedAt.add(const Duration(seconds: 42)),
    );
    await tester.pump();

    expect(game.claimableRewardCount, greaterThan(0));
    expect(find.text('CLAIM'), findsWidgets);
  });

  testWidgets('claimable next goal strip grants and marks milestone',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('START BUSINESS'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final game =
        tester.element(find.byType(MaterialApp)).read<GameController>();
    await _completeFirstService(game);
    await tester.pump();

    final milestone = game.nextMilestone!;
    expect(milestone.id, 'first_service');
    expect(milestone.claimable, isTrue);
    final coinsBeforeClaim = game.coins;
    final action = find.byKey(
      ValueKey('next-goal-action-${milestone.id}'),
    );
    expect(action, findsOneWidget);

    await tester.tap(action);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(game.coins, coinsBeforeClaim + milestone.reward);
    expect(game.claimedMilestoneIds, contains(milestone.id));
    expect(
      game.milestones.firstWhere((item) => item.id == milestone.id).claimed,
      isTrue,
    );
  });

  testWidgets('incomplete next goal strip opens goals dialog',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('START BUSINESS'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final game =
        tester.element(find.byType(MaterialApp)).read<GameController>();
    final milestone = game.nextMilestone!;
    expect(milestone.claimable, isFalse);
    final coinsBeforeTap = game.coins;

    await tester.tap(
      find.byKey(ValueKey('next-goal-action-${milestone.id}')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('SHIFT GOALS'), findsOneWidget);
    expect(find.text('First Service'), findsWidgets);
    expect(game.coins, coinsBeforeTap);
    expect(game.claimedMilestoneIds, isNot(contains(milestone.id)));
  });

  testWidgets('operations shows diagnosis previews and keeps upgrades active',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('START BUSINESS'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final game =
        tester.element(find.byType(MaterialApp)).read<GameController>();
    final diagnosis = game.businessDiagnosis;
    final previews = game.operationUpgradePreviews;
    final recommended =
        previews.singleWhere((preview) => preview.isRecommended);
    final affordable = previews.firstWhere((preview) => preview.canAfford);
    final levelBefore = _operationLevel(game, affordable.type);

    await tester.tap(find.text('OPERATIONS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(
        ValueKey('business-diagnosis-${diagnosis.bottleneck.name}'),
      ),
      findsOneWidget,
    );
    expect(find.text('BOTTLENECK'), findsOneWidget);
    expect(find.text('BALANCED'), findsOneWidget);
    expect(find.textContaining('CURRENT '), findsNWidgets(3));
    expect(find.textContaining('PROJECTED'), findsNWidgets(3));
    expect(find.textContaining('GAIN +'), findsNWidgets(3));
    expect(find.textContaining('COINS/MIN'), findsWidgets);
    expect(find.text('RECOMMENDED'), findsOneWidget);
    expect(
      find.byKey(ValueKey('operation-preview-${recommended.type.name}')),
      findsOneWidget,
    );

    final upgradeAction = find.byKey(
      ValueKey('operation-upgrade-${affordable.type.name}'),
    );
    await tester.ensureVisible(upgradeAction);
    await tester.tap(upgradeAction);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(_operationLevel(game, affordable.type), levelBefore + 1);
  });

  testWidgets('save error strip retries the failed snapshot',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = _RetryableGameStorage();
    final game = GameController(storage: storage);
    final restaurant = Restaurant();
    await game.load(now: DateTime(2026, 1, 1, 12));
    await restaurant.load();
    storage.failNextWrite = true;
    await game.save();
    expect(game.hasSaveError, isTrue);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<GameController>.value(value: game),
          ChangeNotifierProvider<Restaurant>.value(value: restaurant),
        ],
        child: MaterialApp(
          theme: AppTheme.data(AppThemeMode.neoBrutalism),
          home: const MenuPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('save-error-strip')), findsOneWidget);
    expect(find.text('PROGRESS COULD NOT BE SAVED'), findsOneWidget);
    expect(find.text('RETRY'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('save-retry-action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(game.hasSaveError, isFalse);
    expect(find.byKey(const ValueKey('save-error-strip')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('requires confirmation before resetting restaurant progress',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('START BUSINESS'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final game =
        tester.element(find.byType(MaterialApp)).read<GameController>();
    expect(await game.upgradeSeats(), isTrue);
    await tester.pump();
    expect(game.seatLevel, 2);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('SYSTEM CONFIG'), findsOneWidget);

    await tester.tap(find.text('RESET IDLE SAVE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('CANCEL'), findsOneWidget);
    expect(find.text('CONFIRM'), findsOneWidget);

    await tester.tap(find.text('CANCEL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(game.seatLevel, 2);

    await tester.tap(find.text('RESET IDLE SAVE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('CONFIRM'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(game.seatLevel, 1);
    expect(find.text('IDLE SAVE RESET'), findsOneWidget);
  });
}

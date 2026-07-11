import 'dart:ui' show SemanticsFlag;

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

String _testDateKey(DateTime date) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)}';
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

    for (final label in const ['EN', '中文', 'JP']) {
      final languageAction = find.ancestor(
        of: find.text(label),
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(languageAction).height, greaterThanOrEqualTo(48));
    }

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
    await tester.ensureVisible(find.text('START BUSINESS'));
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
    expect(find.text('DISH UPGRADES'), findsOneWidget);
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
    expect(
      find.byKey(const ValueKey('recommended-upgrade-full')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('recommended-upgrade-compact')),
      findsNothing,
    );
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
    final recommendationRect = tester.getRect(
      find.byKey(const ValueKey('recommended-upgrade-card')),
    );
    expect(
      controlPanelRect.inflate(0.1).contains(recommendationRect.topLeft) &&
          controlPanelRect
              .inflate(0.1)
              .contains(recommendationRect.bottomRight),
      isTrue,
    );
    expect(
      controlPanelRect.bottom -
          tester.getRect(find.byKey(const ValueKey('idle-rush-action'))).bottom,
      inInclusiveRange(14, 18),
    );

    await tester.tap(find.text('DISH UPGRADES'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.byTooltip('UPGRADE: Signature Wagyu Burger'),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('dish-upgrade-1'))).height,
      greaterThanOrEqualTo(48),
    );
    final lockedDishSemantics = tester
        .getSemantics(find.byKey(const ValueKey('dish-upgrade-6')))
        .getSemanticsData();
    expect(lockedDishSemantics.hasFlag(SemanticsFlag.isButton), isTrue);
    expect(
      lockedDishSemantics.hasFlag(SemanticsFlag.hasEnabledState),
      isTrue,
    );
    expect(lockedDishSemantics.hasFlag(SemanticsFlag.isEnabled), isFalse);
    expect(lockedDishSemantics.label, contains('LOCKED'));
    await tester.tap(find.text('CLOSE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final game =
        tester.element(find.byType(MaterialApp)).read<GameController>();
    expect(await game.upgradeMenuItem(1), isTrue);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('recommended-upgrade-shortfall')),
      findsOneWidget,
    );
    final recommendation = game.recommendedOperationUpgradePreview!;
    await tester.tap(
      find.byKey(
        ValueKey('recommended-upgrade-action-${recommendation.type.name}'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.byKey(ValueKey('operation-preview-${recommendation.type.name}')),
      findsOneWidget,
    );
  });

  testWidgets('recommended upgrade card renders in every theme',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final mode in AppThemeMode.values) {
      SharedPreferences.setMockInitialValues({
        'app_onboarding_step_v1': '3',
        'app_theme_mode': mode.name,
      });
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('START BUSINESS'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final panelRect = tester.getRect(
        find.byKey(const ValueKey('idle-control-panel')),
      );
      final recommendationRect = tester.getRect(
        find.byKey(const ValueKey('recommended-upgrade-card')),
      );
      expect(
        panelRect.inflate(0.1).contains(recommendationRect.topLeft) &&
            panelRect.inflate(0.1).contains(recommendationRect.bottomRight),
        isTrue,
        reason: 'recommended card left the side rail in ${mode.name}',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'recommended card overflowed in ${mode.name}',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('active event icon stays visible in every theme',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    for (final mode in AppThemeMode.values) {
      final game = GameController(
        storage: MemoryGameStorage({
          'idle_customer_orders_served': 4,
          'idle_claimed_milestone_ids': '["first_service"]',
          'idle_daily_task_date': _testDateKey(now),
        }),
      );
      final restaurant = Restaurant();
      await game.load(now: now);
      await restaurant.load();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<GameController>.value(value: game),
            ChangeNotifierProvider<Restaurant>.value(value: restaurant),
          ],
          child: MaterialApp(
            theme: AppTheme.data(mode),
            home: const MenuPage(),
          ),
        ),
      );
      await tester.pump();

      final event = tester.widget<Container>(
        find.byKey(const ValueKey('active-event-strip')),
      );
      final eventDecoration = event.decoration! as BoxDecoration;
      final eventIcon = tester.widget<Icon>(
        find.byKey(const ValueKey('active-event-icon')),
      );
      expect(
        eventIcon.color,
        isNot(eventDecoration.color),
        reason: 'event icon blended into the background in ${mode.name}',
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
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
      expect(
        find.byKey(const ValueKey('recommended-upgrade-compact')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('recommended-upgrade-full')),
        findsNothing,
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
        elapsed: const Duration(minutes: 2),
        now: now.add(const Duration(minutes: 2)),
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

  testWidgets('dashboard remains usable at 200 percent text scale',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('START BUSINESS'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    for (final key in const ['idle-rush-action', 'idle-claim-action']) {
      final action = find.byKey(ValueKey(key));
      expect(action, findsOneWidget);
      await tester.ensureVisible(action);
      expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('wide dashboard remains usable at 200 percent text scale',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('START BUSINESS'));
    await tester.tap(find.text('START BUSINESS'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    for (final key in const ['idle-rush-action', 'idle-claim-action']) {
      final action = find.byKey(ValueKey(key));
      expect(action, findsOneWidget);
      await tester.ensureVisible(action);
      expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('tall wide dashboard supports 200 percent text scale',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('START BUSINESS'));
    await tester.tap(find.text('START BUSINESS'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('idle-metrics-scroll')), findsOneWidget);
    for (final key in const ['idle-rush-action', 'idle-claim-action']) {
      final action = find.byKey(ValueKey(key));
      expect(action, findsOneWidget);
      expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('short wide floor stays inside the stage at 200 percent scale',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 390);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('START BUSINESS'));
    await tester.tap(find.text('START BUSINESS'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    final stageRect = tester.getRect(
      find.byKey(const ValueKey('customer-arrival-stage-summary')),
    );
    final waitingAreaRect = tester.getRect(
      find.byKey(const ValueKey('business-entrance-waiting-area')),
    );
    expect(stageRect.inflate(0.1).contains(waitingAreaRect.bottomLeft), isTrue);
    expect(
      stageRect.inflate(0.1).contains(waitingAreaRect.bottomRight),
      isTrue,
    );
    final rushAction = find.byKey(const ValueKey('idle-rush-action'));
    await tester.ensureVisible(rushAction);
    expect(tester.getSize(rushAction).height, greaterThanOrEqualTo(48));
  });

  testWidgets('main dialogs support 200 percent text scale',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final game = GameController(
      storage: MemoryGameStorage({'idle_best_combo': 3}),
    );
    final restaurant = Restaurant();
    await game.load(now: DateTime.now());
    await restaurant.load();
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

    await tester.tap(find.byKey(const ValueKey('idle-rush-action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('kitchen-rush-dialog-content')),
          )
          .height,
      390,
    );
    expect(
      tester
          .getCenter(
            find.byKey(const ValueKey('rush-seat-customer-action')),
          )
          .dy,
      inInclusiveRange(0, 844),
    );
    await tester.tap(find.text('CLOSE'));
    await tester.pump();

    for (final label in const ['GOALS', 'OPERATIONS', 'DISH UPGRADES']) {
      await tester.tap(find.text(label));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.takeException(),
        isNull,
        reason: '$label dialog overflowed at 200 percent text scale',
      );
      await tester.tap(find.text('CLOSE'));
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
    expect(panelRect.width, closeTo(300, 0.1));
    expect(panelRect.bottom, closeTo(stageRect.bottom, 0.1));
    expect(find.byKey(const ValueKey('idle-metrics-grid')), findsOneWidget);

    for (final key in const [
      'auto-metric-queue',
      'auto-metric-tables',
      'auto-metric-kitchen',
      'auto-metric-dining',
      'auto-metric-checkout',
      'recommended-upgrade-card',
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

  testWidgets('short landscape dashboards keep wide content scrollable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final viewport in const [Size(820, 390), Size(900, 430)]) {
      SharedPreferences.setMockInitialValues({
        'app_onboarding_step_v1': '3',
      });
      tester.view.physicalSize = Size(viewport.width, 700);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('START BUSINESS'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      tester.view.physicalSize = viewport;
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'dashboard overflowed at $viewport',
      );
      final wideRow = find.byKey(const ValueKey('wide-dashboard-row'));
      final panel = find.byKey(const ValueKey('idle-control-panel'));
      final stage = find.byKey(
        const ValueKey('customer-arrival-stage-summary'),
      );
      final rowRect = tester.getRect(wideRow);
      final panelRect = tester.getRect(panel);
      final stageRect = tester.getRect(stage);
      final expectedPanelWidth = (viewport.width * 0.34).clamp(300.0, 430.0);

      expect(rowRect.height, greaterThanOrEqualTo(190));
      expect(stageRect.height, closeTo(rowRect.height, 0.1));
      expect(panelRect.height, closeTo(rowRect.height, 0.1));
      expect(panelRect.width, closeTo(expectedPanelWidth, 0.1));
      expect(stageRect.right, closeTo(panelRect.left, 0.1));
      expect(panelRect.right, closeTo(viewport.width, 0.1));

      if (viewport == const Size(820, 390)) {
        expect(
          find.byKey(const ValueKey('wide-dashboard-scroll')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('dashboard-scrollbar')),
          findsOneWidget,
        );
      }

      final rushAction = find.byKey(const ValueKey('idle-rush-action'));
      await tester.ensureVisible(rushAction);
      await tester.pump();
      await tester.tap(rushAction);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final rushContent = find.byKey(
        const ValueKey('kitchen-rush-dialog-content'),
      );
      expect(rushContent, findsOneWidget);
      expect(
        tester.getSize(rushContent).height,
        closeTo((viewport.height - 190).clamp(260.0, 390.0), 0.1),
      );
      final rushException = tester.takeException();
      expect(
        rushException,
        isNull,
        reason: 'Kitchen Rush overflowed at $viewport',
      );
      final seatCustomer = find.byKey(
        const ValueKey('rush-seat-customer-action'),
      );
      expect(seatCustomer, findsOneWidget);
      expect(
        tester.getCenter(seatCustomer).dy,
        inInclusiveRange(0, viewport.height),
        reason: 'Kitchen Rush CTA started outside the viewport at $viewport',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
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

    expect(find.text('KITCHEN RUSH'), findsOneWidget);
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

    final coinsBeforeServing = game.coins;
    await tester.tap(find.text('Signature Wagyu Burger').last);
    await tester.pump();

    expect(find.textContaining('EXPECTED BILL'), findsWidgets);
    expect(game.coins, coinsBeforeServing);

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

  testWidgets('next goal strip surfaces a claimable daily reward',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final game = GameController(
      storage: MemoryGameStorage({
        'idle_customer_orders_served': 3,
        'idle_claimed_milestone_ids': '["first_service"]',
        'idle_daily_task_date': _testDateKey(now),
        'idle_daily_orders_served': 3,
      }),
    );
    final restaurant = Restaurant();
    await game.load(now: now);
    await restaurant.load();

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

    final dailyAction = find.byKey(
      const ValueKey('next-goal-action-daily_service_three'),
    );
    expect(dailyAction, findsOneWidget);
    final coinsBeforeClaim = game.coins;

    await tester.tap(dailyAction);
    await tester.pump();

    expect(game.coins, coinsBeforeClaim + 90);
    expect(
      game.claimedDailyTaskIds,
      contains('daily_service_three'),
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
    final closeAction = find.ancestor(
      of: find.text('CLOSE'),
      matching: find.byType(ElevatedButton),
    );
    expect(tester.getSize(closeAction).height, greaterThanOrEqualTo(48));
    expect(game.coins, coinsBeforeTap);
    expect(game.claimedMilestoneIds, isNot(contains(milestone.id)));
  });

  testWidgets(
      'goals prioritize claimable rewards and collapse claimed progress',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final game = GameController(
      storage: MemoryGameStorage({
        'idle_customer_orders_served': 74,
        'idle_best_combo': 10,
        'idle_claimed_milestone_ids': '["first_service"]',
        'idle_daily_task_date': _testDateKey(now),
        'idle_daily_orders_served': 74,
        'idle_daily_best_combo': 10,
      }),
    );
    final restaurant = Restaurant();
    await game.load(now: now);
    await restaurant.load();

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

    await tester.tap(find.text('GOALS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('claimable-rewards-section')),
      findsOneWidget,
    );
    expect(find.text('74/3'), findsNothing);
    expect(find.text('10/2'), findsNothing);
    expect(find.text('3/3'), findsOneWidget);
    expect(find.text('2/2'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('goal-tile-first_service')),
      findsNothing,
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(
              const ValueKey('daily-task-tile-daily_service_three'),
            ),
          )
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('goal-tile-better_seats')),
            )
            .dy,
      ),
    );

    final claimedToggle = find.byKey(
      const ValueKey('claimed-rewards-toggle'),
    );
    await tester.ensureVisible(claimedToggle);
    var claimedToggleSemantics =
        tester.getSemantics(claimedToggle).getSemanticsData();
    expect(
      claimedToggleSemantics.hasFlag(SemanticsFlag.hasExpandedState),
      isTrue,
    );
    expect(
      claimedToggleSemantics.hasFlag(SemanticsFlag.isExpanded),
      isFalse,
    );
    await tester.tap(claimedToggle);
    await tester.pump();
    claimedToggleSemantics =
        tester.getSemantics(claimedToggle).getSemanticsData();
    expect(
      claimedToggleSemantics.hasFlag(SemanticsFlag.isExpanded),
      isTrue,
    );
    expect(
      find.byKey(const ValueKey('goal-tile-first_service')),
      findsOneWidget,
    );

    await tester.tap(claimedToggle);
    await tester.pump();
    final dailyClaim = find.byKey(
      const ValueKey('daily-task-claim-daily_service_three'),
    );
    await tester.ensureVisible(dailyClaim);
    final coinsBeforeClaim = game.coins;
    await tester.tap(dailyClaim);
    await tester.pump();

    expect(game.coins, coinsBeforeClaim + 90);
    expect(
      game.claimedDailyTaskIds,
      contains('daily_service_three'),
    );
    expect(
      find.byKey(
        const ValueKey('daily-task-tile-daily_service_three'),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
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
    expect(find.text('CURRENT CONGESTION'), findsOneWidget);
    expect(find.text('BALANCED'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^CURRENT [0-9]')), findsNWidgets(3));
    expect(find.textContaining('PROJECTED'), findsNWidgets(3));
    expect(find.textContaining('GAIN +'), findsNWidgets(3));
    expect(find.textContaining('COINS/MIN'), findsWidgets);
    expect(find.text('BEST ROI'), findsOneWidget);
    expect(
      find.byKey(ValueKey('operation-preview-${recommended.type.name}')),
      findsOneWidget,
    );
    final recommendedTop = tester
        .getTopLeft(
          find.byKey(
            ValueKey('operation-preview-${recommended.type.name}'),
          ),
        )
        .dy;
    for (final preview in previews.where((item) => !item.isRecommended)) {
      expect(
        recommendedTop,
        lessThan(
          tester
              .getTopLeft(
                find.byKey(
                  ValueKey('operation-preview-${preview.type.name}'),
                ),
              )
              .dy,
        ),
        reason: 'recommended operation was not shown first',
      );
    }

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

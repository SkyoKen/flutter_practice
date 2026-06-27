import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_table_order/main.dart';

void main() {
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
    await tester.pumpAndSettle();

    expect(find.textContaining('ACCESS ID:'), findsOneWidget);
    expect(find.text('ORDER CART'), findsOneWidget);
    expect(find.text('POPULAR'), findsOneWidget);
  });

  testWidgets('opens the ordering screen on a narrow viewport',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('START SESSION'));
    await tester.pumpAndSettle();

    expect(find.textContaining('T-0'), findsOneWidget);
    expect(find.text('ORDER CART'), findsOneWidget);
  });
}

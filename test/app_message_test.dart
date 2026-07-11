import 'package:cyber_table_order/utils/app_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app messages stay near the top and clear bottom actions', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final viewport in const [Size(390, 700), Size(1280, 800)]) {
      tester.view.physicalSize = viewport;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Dashboard')),
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    key: const ValueKey('show-message'),
                    onPressed: () => AppMessage.show(
                      context,
                      content: const Text('Upgrade complete'),
                      duration: const Duration(minutes: 1),
                    ),
                    child: const Text('Show'),
                  ),
                );
              },
            ),
            bottomNavigationBar: const SizedBox(
              key: ValueKey('bottom-action-area'),
              height: 72,
              child: Center(child: Text('Bottom actions')),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('show-message')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final messageFinder = find.byKey(const ValueKey('app-message'));
      final messageRect = tester.getRect(messageFinder);
      final bottomActionTop = tester
          .getTopLeft(find.byKey(const ValueKey('bottom-action-area')))
          .dy;

      expect(messageRect.top, greaterThanOrEqualTo(kToolbarHeight + 12));
      expect(messageRect.top, lessThan(80));
      expect(messageRect.bottom, lessThan(bottomActionTop));
      expect(messageRect.width, lessThanOrEqualTo(560));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('a newer app message replaces stale feedback', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Column(
                children: [
                  ElevatedButton(
                    onPressed: () => AppMessage.show(
                      context,
                      content: const Text('First message'),
                      duration: const Duration(minutes: 1),
                    ),
                    child: const Text('First'),
                  ),
                  ElevatedButton(
                    onPressed: () => AppMessage.show(
                      context,
                      content: const Text('Second message'),
                      duration: const Duration(minutes: 1),
                    ),
                    child: const Text('Second'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('First'));
    await tester.pumpAndSettle();
    expect(find.text('First message'), findsOneWidget);

    await tester.tap(find.text('Second'));
    await tester.pumpAndSettle();

    expect(find.text('First message'), findsNothing);
    expect(find.text('Second message'), findsOneWidget);
    expect(find.byKey(const ValueKey('app-message')), findsOneWidget);
  });

  testWidgets('dialog feedback stays visible without blocking its controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Rush'),
                    content: ElevatedButton(
                      onPressed: () => AppMessage.show(
                        dialogContext,
                        content: const Text('Correct dish'),
                        duration: const Duration(minutes: 1),
                      ),
                      child: const Text('Serve'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Serve'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Correct dish'), findsOneWidget);
    expect(find.byKey(const ValueKey('app-message')), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Rush'), findsNothing);
    expect(find.text('Correct dish'), findsOneWidget);
  });
}

import 'package:desy_overlay/desy_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps the consumer app interactive outside selection mode', (
    tester,
  ) async {
    var presses = 0;
    await tester.pumpWidget(
      _TestApp(onPressed: () => presses++, onAnnotationSubmitted: (_) {}),
    );

    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('consumer-button'))),
    );
    await tester.pump();

    expect(presses, 1);
    expect(find.byKey(const ValueKey('desy-overlay-controls')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('desy-overlay-annotation-card')),
      findsNothing,
    );
  });

  testWidgets('selects a widget and forwards rich typed metadata', (
    tester,
  ) async {
    DesyAnnotation? submitted;
    var presses = 0;
    await tester.pumpWidget(
      _TestApp(
        onPressed: () => presses++,
        onAnnotationSubmitted: (annotation) => submitted = annotation,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('desy-overlay-select')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('desy-overlay-selection-prompt')),
      findsOneWidget,
    );

    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('consumer-button'))),
    );
    await tester.pumpAndSettle();

    expect(presses, 0);
    expect(
      find.byKey(const ValueKey('desy-overlay-annotation-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('desy-overlay-selection-prompt')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('desy-overlay-feedback')), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('desy-overlay-comment')),
      'Increase the label contrast.',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('desy-overlay-submit')));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.comment, 'Increase the label contrast.');
    expect(submitted!.target.buildMode, DesyBuildMode.debug);
    expect(submitted!.target.bounds, isNot(Rect.zero));
    expect(submitted!.target.paintBounds, isNot(Rect.zero));
    expect(submitted!.target.renderSize, isNotNull);
    expect(submitted!.target.layoutConstraints, isNotEmpty);
    expect(submitted!.target.ancestorWidgetTypes, isNotEmpty);
    expect(
      submitted!.target.identitySignals,
      contains(
        const DesyWidgetSignal(
          kind: DesyWidgetSignalKind.key,
          value: 'consumer-button',
        ),
      ),
    );
    expect(
      submitted!.target.identitySignals,
      contains(
        const DesyWidgetSignal(
          kind: DesyWidgetSignalKind.semanticsIdentifier,
          value: 'consumer.primaryAction',
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('desy-overlay-annotation-card')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('desy-overlay-selection-prompt')),
      findsOneWidget,
    );
  });

  testWidgets('annotation card keeps its position across another selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(onPressed: () {}, onAnnotationSubmitted: (_) {}),
    );

    await _selectConsumerButton(tester);
    final card = find.byKey(const ValueKey('desy-overlay-annotation-card'));
    final before = tester.getTopLeft(card);

    await tester.drag(
      find.byKey(const ValueKey('desy-overlay-drag-handle')),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();

    final after = tester.getTopLeft(card);
    expect(after.dx, before.dx);
    expect(after.dy, lessThan(before.dy));

    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('consumer-secondary-button'))),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(card), after);

    await tester.tap(find.byKey(const ValueKey('desy-overlay-close')));
    await tester.pumpAndSettle();
    expect(card, findsNothing);
    expect(
      find.byKey(const ValueKey('desy-overlay-selection-prompt')),
      findsOneWidget,
    );
  });

  testWidgets('disabled overlay returns the consumer child unchanged', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DesyOverlay(
          enabled: false,
          onAnnotationSubmitted: (_) {},
          child: const Text('Consumer app'),
        ),
      ),
    );

    expect(find.text('Consumer app'), findsOneWidget);
    expect(find.byKey(const ValueKey('desy-overlay-controls')), findsNothing);
  });
}

Future<void> _selectConsumerButton(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('desy-overlay-select')));
  await tester.pumpAndSettle();
  await tester.tapAt(
    tester.getCenter(find.byKey(const ValueKey('consumer-button'))),
  );
  await tester.pumpAndSettle();
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.onPressed,
    required this.onAnnotationSubmitted,
  });

  final VoidCallback onPressed;
  final DesyAnnotationCallback onAnnotationSubmitted;

  @override
  Widget build(BuildContext context) => MaterialApp(
    builder: DesyOverlay.builder(onAnnotationSubmitted: onAnnotationSubmitted),
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              identifier: 'consumer.primaryAction',
              label: 'Primary action',
              child: ElevatedButton(
                key: const ValueKey('consumer-button'),
                onPressed: onPressed,
                child: const Text('Inspect me'),
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              identifier: 'consumer.secondaryAction',
              label: 'Secondary action',
              child: ElevatedButton(
                key: const ValueKey('consumer-secondary-button'),
                onPressed: onPressed,
                child: const Text('Inspect something else'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

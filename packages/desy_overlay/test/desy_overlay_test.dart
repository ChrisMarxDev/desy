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
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('desy-overlay-selection-layer')),
      findsNothing,
    );

    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('consumer-button'))),
    );
    await tester.pump();
    expect(presses, 1);
  });

  testWidgets('whole annotation card drags and keeps its position', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(onPressed: () {}, onAnnotationSubmitted: (_) {}),
    );

    await _selectConsumerButton(tester);
    final card = find.byKey(const ValueKey('desy-overlay-annotation-card'));
    final before = tester.getTopLeft(card);

    final cardSize = tester.getSize(card);
    await tester.dragFrom(
      before + Offset(16, cardSize.height - 16),
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

  testWidgets('mounts and selects beneath a non-Material application shell', (
    tester,
  ) async {
    DesyAnnotation? submitted;
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFFFFFFFF),
        pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
        ),
        builder: DesyOverlay.builder(
          onAnnotationSubmitted: (annotation) => submitted = annotation,
        ),
        home: ColoredBox(
          color: const Color(0xFFFFFFFF),
          child: Center(
            child: Semantics(
              identifier: 'consumer.genericAction',
              label: 'Generic action',
              child: const _GenericAction(),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('desy-overlay-select')));
    await tester.pumpAndSettle();
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('consumer-generic-action'))),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('desy-overlay-annotation-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('desy-overlay-selection-outline')),
      findsOneWidget,
    );
    final overlayTextStyles = tester.widgetList<DefaultTextStyle>(
      find.byKey(const ValueKey('desy-overlay-default-text-style')),
    );
    expect(overlayTextStyles, isNotEmpty);
    expect(
      overlayTextStyles.every(
        (defaultStyle) =>
            defaultStyle.style.color != null &&
            defaultStyle.style.fontFamily != null,
      ),
      isTrue,
    );
    await tester.enterText(
      find.byKey(const ValueKey('desy-overlay-comment')),
      'Generic feedback.',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('desy-overlay-submit')));
    await tester.pumpAndSettle();

    expect(submitted?.comment, 'Generic feedback.');
    expect(
      submitted?.target.identitySignals,
      contains(
        const DesyWidgetSignal(
          kind: DesyWidgetSignalKind.semanticsIdentifier,
          value: 'consumer.genericAction',
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('desy-overlay-selection-layer')),
      findsNothing,
    );
  });

  testWidgets(
    'keeps mobile chrome above safe areas and the keyboard',
    (tester) async {
      const viewport = Size(390, 844);
      const keyboardHeight = 336.0;
      await tester.binding.setSurfaceSize(viewport);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _MobileTestApp(
          mediaQueryData: const MediaQueryData(
            size: viewport,
            padding: EdgeInsets.only(top: 47, bottom: 34),
            viewInsets: EdgeInsets.only(bottom: keyboardHeight),
          ),
        ),
      );

      final select = find.byKey(const ValueKey('desy-overlay-select'));
      final selectRect = tester.getRect(select);
      expect(selectRect.width, greaterThanOrEqualTo(44));
      expect(selectRect.height, greaterThanOrEqualTo(44));
      expect(selectRect.right, lessThanOrEqualTo(viewport.width - 16));
      expect(
        selectRect.bottom,
        lessThanOrEqualTo(viewport.height - keyboardHeight - 16),
      );

      await tester.tap(select);
      await tester.pumpAndSettle();
      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('consumer-generic-action'))),
      );
      await tester.pumpAndSettle();

      final card = find.byKey(const ValueKey('desy-overlay-annotation-card'));
      final cardRect = tester.getRect(card);
      expect(cardRect.left, greaterThanOrEqualTo(8));
      expect(cardRect.right, lessThanOrEqualTo(viewport.width - 8));
      expect(cardRect.top, greaterThanOrEqualTo(47 + 8));
      expect(
        cardRect.bottom,
        lessThanOrEqualTo(viewport.height - keyboardHeight - 8),
      );

      await tester.drag(
        find.byKey(const ValueKey('desy-overlay-drag-handle')),
        const Offset(0, 500),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getRect(card).bottom,
        lessThanOrEqualTo(viewport.height - keyboardHeight - 8),
      );
    },
    variant: TargetPlatformVariant.mobile(),
  );

  testWidgets(
    'uses compact mobile chrome above a landscape keyboard',
    (tester) async {
      const viewport = Size(844, 390);
      const keyboardHeight = 200.0;
      await tester.binding.setSurfaceSize(viewport);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _MobileTestApp(
          targetTop: 48,
          mediaQueryData: const MediaQueryData(
            size: viewport,
            padding: EdgeInsets.only(left: 44, right: 44, bottom: 21),
            viewInsets: EdgeInsets.only(bottom: keyboardHeight),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('desy-overlay-select')));
      await tester.pumpAndSettle();
      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('consumer-generic-action'))),
      );
      await tester.pumpAndSettle();

      final cardRect = tester.getRect(
        find.byKey(const ValueKey('desy-overlay-annotation-card')),
      );
      expect(cardRect.left, greaterThanOrEqualTo(44 + 8));
      expect(cardRect.right, lessThanOrEqualTo(viewport.width - 44 - 8));
      expect(cardRect.top, greaterThanOrEqualTo(8));
      expect(
        cardRect.bottom,
        lessThanOrEqualTo(viewport.height - keyboardHeight - 8),
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.mobile(),
  );
}

class _GenericAction extends StatelessWidget {
  const _GenericAction();

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const ValueKey('consumer-generic-action'),
    onTap: () {},
    child: const DecoratedBox(
      decoration: BoxDecoration(color: Color(0xFF222222)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'Inspect generic widget',
          style: TextStyle(color: Color(0xFFFFFFFF)),
        ),
      ),
    ),
  );
}

class _MobileTestApp extends StatelessWidget {
  const _MobileTestApp({required this.mediaQueryData, this.targetTop = 96});

  final MediaQueryData mediaQueryData;
  final double targetTop;

  @override
  Widget build(BuildContext context) => WidgetsApp(
    color: const Color(0xFFFFFFFF),
    pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    ),
    builder: (context, child) => MediaQuery(
      data: mediaQueryData,
      child: DesyOverlay(
        onAnnotationSubmitted: (_) {},
        child: child ?? const SizedBox.shrink(),
      ),
    ),
    home: ColoredBox(
      color: const Color(0xFFFFFFFF),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: targetTop),
          child: const _GenericAction(),
        ),
      ),
    ),
  );
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

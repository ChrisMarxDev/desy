import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/presentation/canvas_v2_screen.dart';
import 'package:desy_bench/src/workbench/presentation/desy_drag_box.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Canvas beta presents every component and selects its knobs', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = DesyWorkbenchSession(registry: _registry);
    addTearDown(session.dispose);

    await tester.pumpWidget(
      _Harness(child: DesyCanvasV2Screen(session: session)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('canvas-v2-viewport')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('canvas-v2-item-test.button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('canvas-v2-item-test.status')),
      findsOneWidget,
    );
    expect(find.byType(DesyDragBox), findsNWidgets(2));
    expect(find.byKey(const ValueKey('canvas-v2-inspector')), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('canvas-v2-content-test.status')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('canvas-v2-inspector')), findsOneWidget);
    expect(find.text('No knobs declared'), findsOneWidget);

    // A later item must not claim the whole stage: every raw drag box remains
    // selectable after another item has been brought to the front.
    await tester.tap(
      find.byKey(const ValueKey('canvas-v2-content-test.button')),
    );
    await tester.pumpAndSettle();

    final frame = find.byKey(const ValueKey('canvas-v2-frame-test.button'));
    final beforeMove = tester.getRect(frame);
    await tester.drag(
      find.byKey(const ValueKey('canvas-v2-content-test.button')),
      const Offset(44, 28),
    );
    await tester.pumpAndSettle();

    expect(tester.getRect(frame).topLeft.dx, greaterThan(beforeMove.left));
    expect(
      find.byKey(const ValueKey('canvas-v2-selection-size-test.button')),
      findsOneWidget,
    );

    final beforeScroll = tester.getRect(frame);
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(
          find.byKey(const ValueKey('canvas-v2-content-test.button')),
        ),
        scrollDelta: const Offset(36, 24),
      ),
    );
    await tester.pump();

    expect(tester.getRect(frame).left, isNot(equals(beforeScroll.left)));
    expect(find.text('Controls'), findsOneWidget);
    expect(find.text('Label'), findsOneWidget);
    expect(find.text('Primary action'), findsWidgets);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('canvas-v2-inspector')),
        matching: find.byType(EditableText),
      ),
      'Secondary action',
    );
    await tester.pump();

    expect(find.text('Secondary action'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('canvas-v2-close-inspector')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<AnimatedSlide>(
            find.byKey(const ValueKey('canvas-v2-inspector-drawer')),
          )
          .offset,
      const Offset(1.1, 0),
    );
  });

  testWidgets('Canvas beta is reachable from the persistent registry sidebar', (
    tester,
  ) async {
    await tester.pumpWidget(DesyBenchApp(registry: _registry));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('registry-canvas-nav')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('canvas-v2-viewport')), findsOneWidget);
    expect(find.text('Canvas'), findsWidgets);
  });
}

final _registry = DesyRegistry(
  name: 'Canvas v2',
  themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
  components: [
    DesyComponent(
      id: 'test.button',
      name: 'Button',
      path: '/actions',
      knobs: (knobs) => (
        label: knobs.string('label', name: 'Label', initial: 'Primary action'),
      ),
      build: (context, knobs) => Text(knobs.label.value),
    ),
    DesyStaticComponent(
      id: 'test.status',
      name: 'Status',
      path: '/feedback',
      instances: {'default': (_) => const Text('Ready')},
    ),
  ],
);

class _Harness extends StatelessWidget {
  const _Harness({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => FTheme(
    data: FTheme.neutral.light.desktop,
    child: MaterialApp(
      home: Scaffold(body: SizedBox(width: 1280, height: 760, child: child)),
    ),
  );
}

Widget _wrap(BuildContext context, Widget child) => child;

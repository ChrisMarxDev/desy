import 'package:desy_bench/src/registry.dart';
import 'package:desy_bench/src/workbench/components_canvas/components_canvas_controller.dart';
import 'package:desy_bench/src/workbench/components_canvas/components_canvas_screen.dart';
import 'package:desy_bench/src/workbench/presentation/detail_screen.dart';
import 'package:desy_bench/src/workbench/widget_preview.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:state_beacon/state_beacon.dart';

void main() {
  const theme = DesyTheme(id: 'test', name: 'Test', wrap: _wrap);

  testWidgets(
    'detail resizes responsive widgets and only scales fixed device previews',
    (tester) async {
      BoxConstraints? receivedConstraints;
      final session = DesyWorkbenchSession(
        registry: DesyRegistry(name: 'Test', themes: const [theme]),
      );
      addTearDown(session.dispose);

      await tester.pumpWidget(
        _TestHarness(
          child: SizedBox(
            width: 560,
            height: 440,
            child: Builder(
              builder: (context) => DesyPreviewCanvas(
                session: session,
                theme: theme,
                bezel: session.previewBezel.watch(context),
                toolbar: const SizedBox.shrink(),
                child: DesyWidgetPreview(
                  theme: theme,
                  builder: (context) => LayoutBuilder(
                    builder: (context, constraints) {
                      receivedConstraints = constraints;
                      return SizedBox(
                        key: ValueKey(
                          constraints.maxWidth >= 600
                              ? 'responsive-wide-detail'
                              : 'responsive-compact-detail',
                        ),
                        width: constraints.maxWidth >= 600 ? 800 : 120,
                        height: 64,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('responsive-wide-detail')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('responsive-compact-detail')),
        findsOneWidget,
      );
      expect(receivedConstraints!.maxWidth, 320);
      expect(
        tester.getSize(find.byKey(const ValueKey('detail-artboard'))),
        const Size(320, 240),
      );

      await tester.drag(
        find.byKey(const ValueKey('detail-resize-bottomRight')),
        const Offset(580, 0),
      );
      await tester.pump();

      expect(session.stage.value.size, const Size(880, 240));
      expect(receivedConstraints!.maxWidth, 880);
      expect(
        find.byKey(const ValueKey('responsive-wide-detail')),
        findsOneWidget,
      );

      session.selectPreviewBezel(DesyPreviewBezel.iPhone15Pro);
      await tester.pumpAndSettle();
      final phoneSize = tester.getSize(
        find.byKey(const ValueKey('detail-artboard')),
      );
      expect(
        phoneSize.aspectRatio,
        closeTo(Devices.ios.iPhone15Pro.frameSize.aspectRatio, 0.001),
      );
      expect(
        receivedConstraints!.maxWidth,
        Devices.ios.iPhone15Pro.screenSize.width,
      );
    },
  );

  testWidgets('sketch elements keep their own logical preview measurement', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    BoxConstraints? receivedConstraints;
    final component = DesyComponent(
      id: 'responsive',
      name: 'Responsive',
      preview: (context) => const SizedBox.shrink(),
      instances: [
        DesyComponentInstance.widget(
          id: 'default',
          name: 'Default',
          builder: (context) => LayoutBuilder(
            builder: (context, constraints) {
              receivedConstraints = constraints;
              return const SizedBox(key: ValueKey('responsive-sketch'));
            },
          ),
        ),
      ],
    );
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'Test',
        themes: const [theme],
        components: [component],
      ),
    );
    final controller = DesyComponentsCanvasController()
      ..add('responsive.default');
    addTearDown(session.dispose);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _TestHarness(
        child: DesyComponentsCanvas(
          session: session,
          controller: controller,
          onBack: () {},
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('responsive.default#0')),
        matching: find.byKey(const ValueKey('responsive-sketch')),
      ),
      findsOneWidget,
    );
    expect(receivedConstraints!.maxWidth, 1024);
  });

  testWidgets('bezel and component are independent flat stack items', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _CanvasFixture();
    final bezel = fixture.controller.addArtboard(
      DesyCanvasArtboard.iPhone15Pro,
    );
    final component = fixture.controller.add('gesture.default');
    const overlap = Rect.fromLTWH(120, 160, 220, 120);
    fixture.controller.update(
      fixture.controller.nodes.value[component]!.copyWith(rect: overlap),
    );
    fixture.controller.select(component);
    addTearDown(fixture.dispose);

    await tester.pumpWidget(_TestHarness(child: fixture.canvas()));
    final bezelBefore = fixture.controller.nodes.value[bezel]!.rect;
    final componentBefore = fixture.controller.nodes.value[component]!.rect;

    await tester.drag(
      find.byKey(ValueKey('canvas-hit-$component')),
      const Offset(64, 0),
    );
    await tester.pump();

    final componentAfterDrag = fixture.controller.nodes.value[component]!.rect;
    expect(componentAfterDrag.left, greaterThan(componentBefore.left));
    expect(fixture.controller.nodes.value[bezel]!.rect, bezelBefore);

    fixture.controller.update(
      fixture.controller.nodes.value[bezel]!.copyWith(
        rect: bezelBefore.shift(const Offset(48, 32)),
      ),
    );
    await tester.pump();

    expect(fixture.controller.nodes.value[component]!.rect, componentAfterDrag);
    expect(
      find.descendant(
        of: find.byKey(ValueKey(component)),
        matching: find.byKey(const ValueKey('gesture-visual')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('components over a bezel keep the workspace media context', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Size? mediaSize;
    final component = DesyComponent(
      id: 'media-aware',
      name: 'Media aware',
      preview: (context) => const SizedBox.shrink(),
      instances: [
        DesyComponentInstance.widget(
          id: 'default',
          name: 'Default',
          builder: (context) {
            mediaSize = MediaQuery.sizeOf(context);
            return const SizedBox(key: ValueKey('media-aware-visual'));
          },
        ),
      ],
    );
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'Test',
        themes: const [theme],
        components: [component],
      ),
    );
    final controller = DesyComponentsCanvasController();
    final bezel = controller.addArtboard(DesyCanvasArtboard.iPhone15Pro);
    final item = controller.add('media-aware.default');
    controller.update(
      controller.nodes.value[item]!.copyWith(
        rect: controller.nodes.value[bezel]!.rect.deflate(24),
      ),
    );
    addTearDown(session.dispose);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _TestHarness(
        child: DesyComponentsCanvas(
          session: session,
          controller: controller,
          onBack: () {},
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(ValueKey(item)),
        matching: find.byKey(const ValueKey('media-aware-visual')),
      ),
      findsOneWidget,
    );
    expect(mediaSize, const Size(800, 600));
    expect(mediaSize, isNot(Devices.ios.iPhone15Pro.screenSize));
  });

  testWidgets('flat stack hit testing follows insertion order', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _CanvasFixture();
    final lower = fixture.controller.add('gesture.default');
    final bezel = fixture.controller.addArtboard(
      DesyCanvasArtboard.iPhone15Pro,
    );
    final overlap = fixture.controller.nodes.value[bezel]!.rect.deflate(24);
    fixture.controller.update(
      fixture.controller.nodes.value[lower]!.copyWith(rect: overlap),
    );
    fixture.controller.select(null);
    addTearDown(fixture.dispose);

    await tester.pumpWidget(_TestHarness(child: fixture.canvas()));
    final stage = tester.getRect(find.byKey(const ValueKey('sketch-stage')));
    await tester.tapAt(stage.topLeft + overlap.center);
    await tester.pump();
    expect(fixture.controller.selectedId.value, bezel);

    final upper = fixture.controller.add('gesture.default');
    fixture.controller.update(
      fixture.controller.nodes.value[upper]!.copyWith(rect: overlap),
    );
    fixture.controller.select(null);
    await tester.pumpAndSettle();
    final upperHit = find.byKey(ValueKey('canvas-hit-$upper'));
    expect(tester.getRect(upperHit), overlap.shift(stage.topLeft));
    await tester.tap(upperHit);
    await tester.pump();
    expect(fixture.controller.selectedId.value, upper);
  });

  testWidgets('bezel move and resize never alter overlapping components', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _CanvasFixture();
    final component = fixture.controller.add('gesture.default');
    final bezel = fixture.controller.addArtboard(
      DesyCanvasArtboard.iPhone15Pro,
    );
    fixture.controller.update(
      fixture.controller.nodes.value[component]!.copyWith(
        rect: fixture.controller.nodes.value[bezel]!.rect.deflate(24),
      ),
    );
    fixture.controller.select(bezel);
    addTearDown(fixture.dispose);

    await tester.pumpWidget(_TestHarness(child: fixture.canvas()));
    final componentRect = fixture.controller.nodes.value[component]!.rect;
    final bezelBefore = fixture.controller.nodes.value[bezel]!.rect;

    await tester.drag(
      find.byKey(ValueKey('canvas-hit-$bezel')),
      const Offset(-32, -24),
    );
    await tester.pump();
    final moved = fixture.controller.nodes.value[bezel]!.rect;
    expect(moved.topLeft, isNot(bezelBefore.topLeft));
    expect(moved.size, bezelBefore.size);
    expect(fixture.controller.nodes.value[component]!.rect, componentRect);

    final bezelBox = tester.getRect(find.byKey(ValueKey(bezel)));
    await tester.dragFrom(
      bezelBox.bottomRight - const Offset(3, 3),
      const Offset(-32, -24),
    );
    await tester.pump();
    final resized = fixture.controller.nodes.value[bezel]!.rect;
    expect(resized.size, isNot(moved.size));
    expect(
      resized.size.aspectRatio,
      closeTo(bezelBefore.size.aspectRatio, 0.0001),
    );
    expect(fixture.controller.nodes.value[component]!.rect, componentRect);
  });

  testWidgets('stage shrink normalizes only the bezel layer', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _CanvasFixture();
    final bezel = fixture.controller.addArtboard(
      DesyCanvasArtboard.iPhone15Pro,
    );
    final component = fixture.controller.add('gesture.default');
    fixture.controller.select(null);
    addTearDown(fixture.dispose);

    await tester.pumpWidget(_TestHarness(child: fixture.canvas()));
    await tester.pumpAndSettle();
    final initialBezel = fixture.controller.nodes.value[bezel]!.rect;
    final componentRect = fixture.controller.nodes.value[component]!.rect;

    await tester.binding.setSurfaceSize(const Size(580, 700));
    await tester.pumpAndSettle();

    final stage = tester.getRect(find.byKey(const ValueKey('sketch-stage')));
    final stageBounds = Rect.fromLTWH(0, 0, stage.width, stage.height);
    final compactBezel = fixture.controller.nodes.value[bezel]!.rect;
    expect(_rectContainedBy(stageBounds, compactBezel), isTrue);
    expect(
      compactBezel.size.aspectRatio,
      closeTo(initialBezel.size.aspectRatio, 0.0001),
    );
    expect(fixture.controller.nodes.value[component]!.rect, componentRect);
  });
}

bool _rectContainedBy(Rect bounds, Rect rect) =>
    rect.left >= bounds.left &&
    rect.top >= bounds.top &&
    rect.right <= bounds.right &&
    rect.bottom <= bounds.bottom;

class _CanvasFixture {
  _CanvasFixture()
    : session = DesyWorkbenchSession(
        registry: DesyRegistry(
          name: 'Test',
          themes: const [DesyTheme(id: 'test', name: 'Test', wrap: _wrap)],
          components: [_component],
        ),
      );

  static final _component = DesyComponent(
    id: 'gesture',
    name: 'Gesture',
    preview: (context) => const SizedBox.shrink(),
    instances: [
      DesyComponentInstance.widget(
        id: 'default',
        name: 'Default',
        builder: (context) => const SizedBox(
          key: ValueKey('gesture-visual'),
          width: 220,
          height: 120,
        ),
      ),
    ],
  );

  final DesyWorkbenchSession session;
  final controller = DesyComponentsCanvasController();

  Widget canvas() => DesyComponentsCanvas(
    session: session,
    controller: controller,
    onBack: () {},
  );

  void dispose() {
    session.dispose();
    controller.dispose();
  }
}

Widget _wrap(BuildContext context, Widget child) => child;

class _TestHarness extends StatelessWidget {
  const _TestHarness({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: FTheme(data: FTheme.neutral.light.desktop, child: child),
  );
}

import 'package:desy_bench/src/registry.dart';
import 'package:desy_bench/src/workbench/components_canvas/components_canvas_controller.dart';
import 'package:desy_bench/src/workbench/components_canvas/components_canvas_screen.dart';
import 'package:desy_bench/src/workbench/presentation/desy_drag_box.dart';
import 'package:desy_bench/src/workbench/presentation/detail_screen.dart';
import 'package:desy_bench/src/workbench/widget_preview.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:state_beacon/state_beacon.dart';

void main() {
  const theme = DesyTheme(id: 'test', name: 'Test', wrap: _wrap);

  testWidgets('drag box clips oversized content to its frame', (tester) async {
    const frameKey = ValueKey('clipped-frame');
    const contentKey = ValueKey('clipped-content');

    await tester.pumpWidget(
      _TestHarness(
        child: SizedBox(
          width: 320,
          height: 240,
          child: DesyDragBox(
            geometry: const DesyDragBoxGeometry(
              rect: Rect.fromLTWH(60, 40, 120, 80),
            ),
            clampingRect: const Rect.fromLTWH(0, 0, 320, 240),
            constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
            frameKey: frameKey,
            contentKey: contentKey,
            onChanged: (_) {},
            child: const OverflowBox(
              maxWidth: 240,
              maxHeight: 160,
              child: ColoredBox(color: Colors.red),
            ),
          ),
        ),
      ),
    );

    final contentClip = find.ancestor(
      of: find.byKey(contentKey),
      matching: find.byType(ClipRect),
    );
    expect(contentClip, findsOneWidget);
    expect(tester.getRect(contentClip), tester.getRect(find.byKey(frameKey)));
  });

  testWidgets('drag box keeps movement local until the gesture ends', (
    tester,
  ) async {
    const frameKey = ValueKey('local-drag-frame');
    var liveChanges = 0;
    var finalChanges = 0;
    DesyDragBoxGeometry? committed;
    await tester.pumpWidget(
      _TestHarness(
        child: SizedBox(
          width: 320,
          height: 240,
          child: DesyDragBox(
            geometry: const DesyDragBoxGeometry(
              rect: Rect.fromLTWH(60, 40, 120, 80),
            ),
            clampingRect: const Rect.fromLTWH(0, 0, 320, 240),
            constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
            frameKey: frameKey,
            onChanged: (_) => liveChanges++,
            onChangeEnd: (geometry) {
              finalChanges++;
              committed = geometry;
            },
            child: const ColoredBox(color: Colors.red),
          ),
        ),
      ),
    );
    final before = tester.getRect(find.byKey(frameKey));
    final gesture = await tester.startGesture(before.center);

    await gesture.moveBy(const Offset(32, 16));
    await gesture.moveBy(const Offset(32, 16));
    await tester.pump();

    expect(tester.getRect(find.byKey(frameKey)).topLeft, isNot(before.topLeft));
    expect(liveChanges, 0);
    expect(finalChanges, 0);

    await gesture.up();
    await tester.pump();

    expect(liveChanges, 0);
    expect(finalChanges, 1);
    expect(committed!.rect.topLeft, isNot(const Offset(60, 40)));
  });

  testWidgets('drag box coalesces resize updates to one per frame', (
    tester,
  ) async {
    var liveChanges = 0;
    var finalChanges = 0;
    await tester.pumpWidget(
      _TestHarness(
        child: SizedBox(
          width: 320,
          height: 240,
          child: DesyDragBox(
            geometry: const DesyDragBoxGeometry(
              rect: Rect.fromLTWH(60, 40, 120, 80),
            ),
            clampingRect: const Rect.fromLTWH(0, 0, 320, 240),
            constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
            resizeHandleKeyPrefix: 'coalesced-resize',
            onChanged: (_) => liveChanges++,
            onChangeEnd: (_) => finalChanges++,
            child: const ColoredBox(color: Colors.red),
          ),
        ),
      ),
    );
    final handle = find.byKey(const ValueKey('coalesced-resize-bottomRight'));
    final gesture = await tester.startGesture(tester.getCenter(handle));

    await gesture.moveBy(const Offset(16, 8));
    await gesture.moveBy(const Offset(16, 8));
    expect(liveChanges, 0);
    await tester.pump();
    expect(liveChanges, 1);

    await gesture.moveBy(const Offset(16, 8));
    await gesture.moveBy(const Offset(16, 8));
    expect(liveChanges, 1);
    await tester.pump();
    expect(liveChanges, 2);

    await gesture.up();
    await tester.pump();
    expect(finalChanges, 1);
  });

  testWidgets(
    'detail resizes responsive widgets and only scales fixed device previews',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
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
      expect(find.byType(DesyDragBox), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('detail-artboard'))),
        const Size(320, 240),
      );

      await tester.drag(
        find.byKey(const ValueKey('detail-resize-bottomRight')),
        const Offset(580, 0),
      );
      await tester.pump();

      expect(session.stage.value.size, const Size(900, 240));
      expect(receivedConstraints!.maxWidth, 900);
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

  testWidgets('sketch resize supplies real responsive widget constraints', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final component = DesyComponent(
      id: 'responsive',
      name: 'Responsive',
      preview: (context) => LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            key: ValueKey(
              constraints.maxWidth >= 320
                  ? 'responsive-sketch-wide'
                  : 'responsive-sketch-compact',
            ),
            width: constraints.maxWidth,
            height: constraints.maxHeight,
          );
        },
      ),
      instances: [DesyComponentInstance(id: 'default', name: 'Default')],
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

    final compactPreview = find.descendant(
      of: find.byKey(const ValueKey('responsive.default#0')),
      matching: find.byKey(const ValueKey('responsive-sketch-compact')),
    );
    expect(compactPreview, findsOneWidget);
    expect(find.byType(DesyDragBox), findsOneWidget);
    expect(
      find.byKey(const ValueKey('sketch-node-label-responsive.default#0')),
      findsOneWidget,
    );
    expect(find.text('responsive.default'), findsOneWidget);
    expect(find.text('220 × 120 px'), findsOneWidget);
    expect(tester.getSize(compactPreview), const Size(220, 120));

    final nodeBox = tester.getRect(
      find.byKey(const ValueKey('responsive.default#0')),
    );
    await tester.dragFrom(
      nodeBox.bottomRight - const Offset(3, 3),
      const Offset(160, 80),
    );
    await tester.pump();

    expect(
      controller.nodes.value['responsive.default#0']!.rect.size,
      const Size(384, 200),
    );
    final widePreview = find.descendant(
      of: find.byKey(const ValueKey('responsive.default#0')),
      matching: find.byKey(const ValueKey('responsive-sketch-wide')),
    );
    expect(widePreview, findsOneWidget);
    expect(tester.getSize(widePreview), const Size(384, 200));
    expect(find.text('384 × 200 px'), findsOneWidget);
    expect(find.text('220 × 120 px'), findsNothing);
  });

  testWidgets('sketch geometry changes do not rebuild live previews', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var previewBuilds = 0;
    final component = DesyComponent(
      id: 'counted',
      name: 'Counted',
      preview: (context) {
        previewBuilds++;
        return const SizedBox(
          key: ValueKey('counted-visual'),
          width: 220,
          height: 120,
        );
      },
      instances: [DesyComponentInstance(id: 'default', name: 'Default')],
    );
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'Test',
        themes: const [theme],
        components: [component],
      ),
    );
    final controller = DesyComponentsCanvasController();
    final nodeId = controller.add('counted.default');
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
    await tester.pumpAndSettle();
    final buildsBeforeMove = previewBuilds;

    final node = controller.nodes.value[nodeId]!;
    controller.updateTransient(
      node.copyWith(rect: node.rect.shift(const Offset(8, 0))),
    );
    await tester.pump();

    expect(controller.nodes.value[nodeId]!.rect, node.rect);
    expect(previewBuilds, buildsBeforeMove);
  });

  testWidgets('sketch toggles Flutter repaint-rainbow diagnostics', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    debugRepaintRainbowEnabled = false;
    addTearDown(() {
      debugRepaintRainbowEnabled = false;
      debugCurrentRepaintColor = const HSVColor.fromAHSV(0.4, 60, 1, 1);
    });
    final fixture = _CanvasFixture();
    addTearDown(fixture.dispose);

    await tester.pumpWidget(_TestHarness(child: fixture.canvas()));
    final toggle = find.byKey(const ValueKey('sketch-repaint-rainbow'));
    expect(toggle, findsOneWidget);

    await tester.tap(toggle);
    await tester.pump(const Duration(milliseconds: 200));
    expect(debugRepaintRainbowEnabled, isTrue);
    expect(find.text('Rainbow on'), findsOneWidget);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(debugRepaintRainbowEnabled, isFalse);
    expect(find.text('Repaint rainbow'), findsOneWidget);
    debugCurrentRepaintColor = const HSVColor.fromAHSV(0.4, 60, 1, 1);
  });

  testWidgets('an unselected sketch node moves on its first drag', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _CanvasFixture();
    final component = fixture.controller.add('gesture.default');
    fixture.controller.select(null);
    addTearDown(fixture.dispose);

    await tester.pumpWidget(_TestHarness(child: fixture.canvas()));
    final before = fixture.controller.nodes.value[component]!.rect;

    final frame = find.byKey(ValueKey(component));
    final frameBefore = tester.getRect(frame);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(ValueKey('canvas-hit-$component'))),
    );
    await gesture.moveBy(const Offset(32, 16));
    await gesture.moveBy(const Offset(32, 16));
    await tester.pump();

    expect(fixture.controller.selectedId.value, component);
    expect(fixture.controller.nodes.value[component]!.rect, before);
    expect(tester.getRect(frame).topLeft, isNot(frameBefore.topLeft));

    await gesture.up();
    await tester.pump();

    expect(
      fixture.controller.nodes.value[component]!.rect.topLeft,
      isNot(before.topLeft),
    );
  });

  testWidgets('Backspace and Delete remove the selected sketch node', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _CanvasFixture();
    final first = fixture.controller.add('gesture.default');
    addTearDown(fixture.dispose);

    await tester.pumpWidget(_TestHarness(child: fixture.canvas()));

    await tester.tap(find.byKey(const ValueKey('sketch-component-filter')));
    await tester.enterText(
      find.byKey(const ValueKey('sketch-component-filter')),
      'ge',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(fixture.controller.nodes.value, contains(first));

    await tester.tap(find.byKey(ValueKey('canvas-hit-$first')));
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(fixture.controller.nodes.value, isEmpty);

    final second = fixture.controller.add('gesture.default');
    await tester.pump();
    await tester.tap(find.byKey(ValueKey('canvas-hit-$second')));
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();
    expect(fixture.controller.nodes.value, isEmpty);
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
      preview: (context) {
        mediaSize = MediaQuery.sizeOf(context);
        return const SizedBox(key: ValueKey('media-aware-visual'));
      },
      instances: [DesyComponentInstance(id: 'default', name: 'Default')],
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
    preview: (context) => const SizedBox(
      key: ValueKey('gesture-visual'),
      width: 220,
      height: 120,
    ),
    instances: [DesyComponentInstance(id: 'default', name: 'Default')],
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

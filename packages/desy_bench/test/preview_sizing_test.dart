import 'package:desy_bench/src/registry.dart';
import 'package:desy_bench/src/workbench/components_canvas/components_canvas_controller.dart';
import 'package:desy_bench/src/workbench/components_canvas/components_canvas_screen.dart';
import 'package:desy_bench/src/workbench/presentation/detail_screen.dart';
import 'package:desy_bench/src/workbench/widget_preview.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

void main() {
  const theme = DesyTheme(id: 'test', name: 'Test', wrap: _wrap);

  testWidgets(
    'detail measures responsive previews before scaling them to the artboard',
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
            child: DesyPreviewCanvas(
              session: session,
              theme: theme,
              bezel: null,
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
      );

      expect(
        find.byKey(const ValueKey('responsive-wide-detail')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('responsive-compact-detail')),
        findsNothing,
      );
      expect(receivedConstraints!.maxWidth, 1024);
      expect(
        tester.getSize(find.byKey(const ValueKey('detail-artboard'))),
        const Size(320, 240),
      );
    },
  );

  testWidgets('sketch elements scale a logically measured responsive preview', (
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
              return SizedBox(
                key: ValueKey(
                  constraints.maxWidth >= 600
                      ? 'responsive-wide-sketch'
                      : 'responsive-compact-sketch',
                ),
                width: constraints.maxWidth >= 600 ? 800 : 120,
                height: 64,
              );
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
    final controller = DesyComponentsCanvasController();
    controller.add('responsive.default');
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
      find.byKey(const ValueKey('responsive-wide-sketch')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('responsive-compact-sketch')),
      findsNothing,
    );
    expect(receivedConstraints!.maxWidth, 1024);
  });

  testWidgets('attached sketch components receive the real device screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Size? receivedSize;
    EdgeInsets? receivedPadding;
    double? receivedDpr;
    BoxConstraints? receivedConstraints;
    final component = DesyComponent(
      id: 'device-aware',
      name: 'Device aware',
      preview: (context) => const SizedBox.shrink(),
      instances: [
        DesyComponentInstance.widget(
          id: 'default',
          name: 'Default',
          builder: (context) => LayoutBuilder(
            builder: (context, constraints) {
              final media = MediaQuery.of(context);
              receivedSize = media.size;
              receivedPadding = media.padding;
              receivedDpr = media.devicePixelRatio;
              receivedConstraints = constraints;
              return const SizedBox(key: ValueKey('attached-device-aware'));
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
    final controller = DesyComponentsCanvasController();
    controller.addArtboard(DesyCanvasArtboard.iPhone15Pro);
    controller.add('device-aware.default');
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

    expect(find.byKey(const ValueKey('attached-device-aware')), findsOneWidget);
    expect(receivedSize, const Size(393, 852));
    expect(receivedPadding, const EdgeInsets.only(top: 59, bottom: 34));
    expect(receivedDpr, 3);
    expect(receivedConstraints!.maxWidth, 220);
    expect(receivedConstraints!.maxHeight, 120);

    controller.clear();
    controller.addArtboard(DesyCanvasArtboard.iPadPro11);
    controller.add('device-aware.default');
    await tester.pump();

    expect(receivedSize, const Size(834, 1194));
    expect(receivedPadding, const EdgeInsets.only(top: 20));
    expect(receivedDpr, 3);
    expect(receivedConstraints!.maxWidth, 220);
    expect(receivedConstraints!.maxHeight, 120);
  });

  testWidgets(
    'canvas gestures attach, detach, resize, and keep device overlays aligned',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const componentId = 'gesture.default';
      final component = DesyComponent(
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
      final session = DesyWorkbenchSession(
        registry: DesyRegistry(
          name: 'Test',
          themes: const [theme],
          components: [component],
        ),
      );
      final controller = DesyComponentsCanvasController();
      final free = controller.add(componentId);
      final artboard = controller.addArtboard(DesyCanvasArtboard.iPhone15Pro);
      controller.update(
        controller.nodes.value[free]!.copyWith(
          rect: const Rect.fromLTWH(360, 500, 220, 120),
        ),
      );
      controller.select(free);
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
      final stage = tester.getRect(find.byKey(const ValueKey('sketch-stage')));
      final screen = DesyCanvasGeometry.screenSceneRect(
        controller.nodes.value[artboard]!,
      );

      // Rounded screen corners are not a rectangular artboard hit target.
      controller.select(null);
      await tester.pump();
      await tester.tapAt(stage.topLeft + screen.topLeft);
      await tester.pump();
      expect(controller.selectedId.value, isNull);

      // Free component enters the device when its drag ends in the real path.
      controller.select(free);
      await tester.pump();
      final freeOverlay = find.byKey(ValueKey('canvas-hit-$free'));
      await tester.tap(freeOverlay);
      await tester.pump();
      await tester.dragFrom(
        tester.getCenter(freeOverlay),
        stage.topLeft + screen.center - tester.getCenter(freeOverlay),
      );
      await tester.pump();
      expect(controller.nodes.value[free]!.parentArtboardId, artboard);
      final attachedScene = controller.sceneRectFor(
        controller.nodes.value[free]!,
      );
      final overlay = find.byKey(ValueKey('canvas-hit-$free'));
      expect(
        tester.getRect(overlay).topLeft.dx,
        closeTo((stage.topLeft + attachedScene.topLeft).dx, 0.001),
      );

      // Attached resize updates the logical node and its stage overlay together.
      final beforeResize = controller.nodes.value[free]!.rect;
      await tester.drag(
        find.byKey(ValueKey('canvas-handle-$free-bottomRight')),
        const Offset(24, 16),
      );
      await tester.pump();
      expect(controller.nodes.value[free]!.rect.size, isNot(beforeResize.size));
      final resizedScene = controller.sceneRectFor(
        controller.nodes.value[free]!,
      );
      expect(tester.getRect(overlay).width, closeTo(resizedScene.width, 0.001));
      expect(
        tester.getRect(overlay).height,
        closeTo(resizedScene.height, 0.001),
      );

      // Dragging out of every screen detaches back to stage coordinates.
      controller.select(free);
      await tester.pump();
      await tester.drag(overlay, const Offset(360, 0));
      await tester.pump();
      expect(controller.nodes.value[free]!.parentArtboardId, isNull);
    },
  );

  testWidgets(
    'component drag continues across an artboard boundary before ownership commits',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fixture = _CanvasFixture();
      final component = fixture.controller.add('gesture.default');
      final artboard = fixture.controller.addArtboard(
        DesyCanvasArtboard.iPhone15Pro,
      );
      fixture.controller.update(
        fixture.controller.nodes.value[component]!.copyWith(
          rect: const Rect.fromLTWH(420, 520, 160, 96),
        ),
      );
      fixture.controller.select(component);
      addTearDown(fixture.dispose);

      await tester.pumpWidget(_TestHarness(child: fixture.canvas()));
      final stage = tester.getRect(find.byKey(const ValueKey('sketch-stage')));
      final screen = DesyCanvasGeometry.screenSceneRect(
        fixture.controller.nodes.value[artboard]!,
      );
      final overlay = find.byKey(ValueKey('canvas-hit-$component'));
      final start = tester.getCenter(overlay);
      final destination = stage.topLeft + screen.center;
      final delta = destination - start;

      // A real pointer gets two distinct updates. The first has crossed the
      // visual artboard boundary but the component keeps its free subtree and
      // recognizer until the gesture ends.
      final entering = await tester.startGesture(start);
      // The first movement wins the pan arena; the following updates are
      // deliberately separate boundary-crossing samples.
      const panKickoff = Offset(20, 0);
      await entering.moveBy(panKickoff);
      await tester.pump();
      await entering.moveBy(delta / 2);
      await tester.pump();
      // The arena resolution movement is not an update to TransformableBox.
      await entering.moveBy(delta / 2);
      await tester.pump();
      expect(fixture.controller.isMovingComponent(component), isTrue);
      expect(
        fixture.controller.nodes.value[component]!.parentArtboardId,
        isNull,
      );
      final transientHalfway = fixture.controller.interactionSceneRectFor(
        fixture.controller.nodes.value[component]!,
      );
      final insideScreen = tester.getCenter(
        find.byKey(ValueKey('canvas-hit-$component')),
      );
      expect(
        insideScreen.dx,
        closeTo(stage.left + transientHalfway.center.dx, 1),
      );
      expect(
        insideScreen.dy,
        closeTo(stage.top + transientHalfway.center.dy, 1),
      );
      expect(
        DesyCanvasGeometry.screenContains(
          fixture.controller.nodes.value[artboard]!,
          transientHalfway.center,
        ),
        isTrue,
      );

      // A fourth update after crossing must still reach this recognizer.
      await entering.moveBy(const Offset(-16, 0));
      await tester.pump();
      expect(fixture.controller.isMovingComponent(component), isTrue);
      expect(
        tester.getCenter(find.byKey(ValueKey('canvas-hit-$component'))).dx,
        closeTo(destination.dx - 16, 1),
      );
      await entering.moveBy(const Offset(16, 0));
      await tester.pump();
      await entering.up();
      await tester.pump();
      expect(fixture.controller.isMovingComponent(component), isFalse);
      expect(
        fixture.controller.nodes.value[component]!.parentArtboardId,
        artboard,
      );

      // The attached interaction subtree also remains mounted while leaving
      // the screen; detachment occurs only after the final pointer update.
      final leaving = await tester.startGesture(
        tester.getCenter(find.byKey(ValueKey('canvas-hit-$component'))),
      );
      await leaving.moveBy(const Offset(180, 0));
      await tester.pump();
      expect(fixture.controller.isMovingComponent(component), isTrue);
      expect(
        fixture.controller.nodes.value[component]!.parentArtboardId,
        artboard,
      );
      final afterFirstLeave = tester.getCenter(
        find.byKey(ValueKey('canvas-hit-$component')),
      );
      await leaving.moveBy(const Offset(180, 0));
      await tester.pump();
      expect(
        tester.getCenter(find.byKey(ValueKey('canvas-hit-$component'))).dx,
        closeTo(afterFirstLeave.dx + 180, 5),
      );
      await leaving.up();
      await tester.pump();
      expect(
        fixture.controller.nodes.value[component]!.parentArtboardId,
        isNull,
      );
    },
  );

  testWidgets(
    'moving and resizing an artboard preserves attached logical geometry',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fixture = _CanvasFixture();
      final artboard = fixture.controller.addArtboard(
        DesyCanvasArtboard.iPhone15Pro,
      );
      final child = fixture.controller.add('gesture.default');
      fixture.controller.select(artboard);
      addTearDown(fixture.dispose);

      await tester.pumpWidget(_TestHarness(child: fixture.canvas()));
      final childOverlay = find.byKey(ValueKey('canvas-hit-$child'));
      final childVisual = find.byKey(const ValueKey('gesture-visual'));
      final artboardBeforeMove = fixture.controller.nodes.value[artboard]!.rect;
      final logicalBefore = fixture.controller.nodes.value[child]!.rect;
      final overlayBefore = tester.getRect(childOverlay);
      final visualBefore = tester.getRect(childVisual);

      final stage = tester.getRect(find.byKey(const ValueKey('sketch-stage')));
      final screenBeforeMove = DesyCanvasGeometry.screenSceneRect(
        fixture.controller.nodes.value[artboard]!,
      );
      // The component is centred in the screen, so move the frame from an
      // unobscured, visible screen pixel instead of its covered centre.
      await tester.dragFrom(
        stage.topLeft +
            Offset(screenBeforeMove.center.dx, screenBeforeMove.bottom - 16),
        const Offset(32, 24),
      );
      await tester.pump();
      final artboardAfterMove = fixture.controller.nodes.value[artboard]!.rect;
      expect(
        artboardAfterMove.topLeft,
        artboardBeforeMove.topLeft + const Offset(32, 24),
      );
      expect(artboardAfterMove.size, artboardBeforeMove.size);
      expect(fixture.controller.nodes.value[child]!.rect, logicalBefore);
      final movedScene = fixture.controller.sceneRectFor(
        fixture.controller.nodes.value[child]!,
      );
      expect(
        tester.getRect(childOverlay).topLeft,
        isNot(overlayBefore.topLeft),
      );
      expect(tester.getRect(childVisual).topLeft, isNot(visualBefore.topLeft));
      expect(
        tester.getRect(childOverlay).left,
        closeTo(stage.left + movedScene.left, 0.001),
      );
      expect(
        tester.getRect(childOverlay).top,
        closeTo(stage.top + movedScene.top, 0.001),
      );
      expect(
        tester.getRect(childVisual).left,
        closeTo(tester.getRect(childOverlay).left, 0.2),
      );
      expect(
        tester.getRect(childVisual).top,
        closeTo(tester.getRect(childOverlay).top, 0.2),
      );
      expect(tester.getRect(childVisual).width, closeTo(movedScene.width, 0.2));
      expect(
        tester.getRect(childVisual).height,
        closeTo(movedScene.height, 0.2),
      );

      final beforeBoundaryMove = fixture.controller.nodes.value[artboard]!.rect;
      final screenBeforeBoundaryMove = DesyCanvasGeometry.screenSceneRect(
        fixture.controller.nodes.value[artboard]!,
      );
      await tester.dragFrom(
        stage.topLeft +
            Offset(
              screenBeforeBoundaryMove.center.dx,
              screenBeforeBoundaryMove.bottom - 16,
            ),
        const Offset(-240, -200),
      );
      await tester.pump();
      final boundaryMovedArtboard =
          fixture.controller.nodes.value[artboard]!.rect;
      expect(boundaryMovedArtboard.topLeft, Offset.zero);
      expect(boundaryMovedArtboard.size, beforeBoundaryMove.size);
      expect(fixture.controller.nodes.value[child]!.rect, logicalBefore);
      final boundaryMovedScene = fixture.controller.sceneRectFor(
        fixture.controller.nodes.value[child]!,
      );
      expect(
        tester.getRect(childVisual).left,
        closeTo(stage.left + boundaryMovedScene.left, 0.2),
      );
      expect(
        tester.getRect(childVisual).top,
        closeTo(stage.top + boundaryMovedScene.top, 0.2),
      );

      final beforeResize = fixture.controller.nodes.value[artboard]!.rect;
      await tester.drag(
        find.byKey(ValueKey('canvas-handle-$artboard-bottomRight')),
        const Offset(32, 24),
      );
      await tester.pump();
      final resizedArtboard = fixture.controller.nodes.value[artboard]!;
      final sceneChild = fixture.controller.sceneRectFor(
        fixture.controller.nodes.value[child]!,
      );
      expect(resizedArtboard.rect.size, isNot(beforeResize.size));
      expect(fixture.controller.nodes.value[child]!.rect, logicalBefore);
      expect(
        tester.getRect(childOverlay).left,
        closeTo(stage.left + sceneChild.left, 0.001),
      );
      expect(
        tester.getRect(childOverlay).top,
        closeTo(stage.top + sceneChild.top, 0.001),
      );
      expect(
        tester.getRect(childOverlay).width,
        closeTo(sceneChild.width, 0.001),
      );
      expect(
        tester.getRect(childOverlay).height,
        closeTo(sceneChild.height, 0.001),
      );
      expect(
        tester.getRect(childVisual).left,
        closeTo(tester.getRect(childOverlay).left, 0.2),
      );
      expect(
        tester.getRect(childVisual).top,
        closeTo(tester.getRect(childOverlay).top, 0.2),
      );
      expect(tester.getRect(childVisual).width, closeTo(sceneChild.width, 0.2));
      expect(
        tester.getRect(childVisual).height,
        closeTo(sceneChild.height, 0.2),
      );
    },
  );

  testWidgets('overlapping screens attach to and select the topmost artboard', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _CanvasFixture();
    final lower = fixture.controller.addArtboard(
      DesyCanvasArtboard.iPhone15Pro,
    );
    final lowerChild = fixture.controller.add('gesture.default');
    // A free component registered before the upper artboard must stay below
    // that later screen in both paint and hit-test order.
    final freeBeforeUpper = fixture.controller.add('gesture.default');
    final upper = fixture.controller.addArtboard(
      DesyCanvasArtboard.iPhone15Pro,
    );
    // Reuse the device's exact physical frame geometry so the overlapping
    // target exercises the same rounded screen path as production artboards.
    final overlapRect = fixture.controller.nodes.value[upper]!.rect;
    fixture.controller.update(
      fixture.controller.nodes.value[lower]!.copyWith(rect: overlapRect),
    );
    fixture.controller.update(
      fixture.controller.nodes.value[upper]!.copyWith(rect: overlapRect),
    );
    fixture.controller.update(
      fixture.controller.nodes.value[freeBeforeUpper]!.copyWith(
        rect: const Rect.fromLTWH(240, 220, 120, 72),
      ),
    );
    final free = fixture.controller.add('gesture.default');
    fixture.controller.update(
      fixture.controller.nodes.value[free]!.copyWith(
        rect: const Rect.fromLTWH(440, 300, 120, 72),
        clearParentArtboard: true,
      ),
    );
    fixture.controller.select(null);
    addTearDown(fixture.dispose);

    await tester.pumpWidget(_TestHarness(child: fixture.canvas()));
    final stage = tester.getRect(find.byKey(const ValueKey('sketch-stage')));
    final overlap = DesyCanvasGeometry.screenSceneRect(
      fixture.controller.nodes.value[upper]!,
    ).center;

    // The upper visible screen wins before the lower attached overlay can
    // receive this tap.
    await tester.tapAt(stage.topLeft + overlap);
    await tester.pump();
    expect(fixture.controller.selectedId.value, upper);
    expect(fixture.controller.selectedId.value, isNot(lowerChild));

    fixture.controller.select(free);
    await tester.pump();
    final freeOverlay = find.byKey(ValueKey('canvas-hit-$free'));
    await tester.tap(freeOverlay);
    await tester.pump();
    expect(fixture.controller.selectedId.value, free);
    await tester.dragFrom(
      tester.getCenter(freeOverlay),
      stage.topLeft + overlap - tester.getCenter(freeOverlay),
    );
    await tester.pump();
    expect(
      fixture.controller.nodes.value[free]!.parentArtboardId,
      upper,
      reason: 'drag ended at ${fixture.controller.nodes.value[free]!.rect}',
    );
  });

  testWidgets(
    'attached children remain in their parent artboard z-order group',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fixture = _CanvasFixture();
      final lower = fixture.controller.addArtboard(
        DesyCanvasArtboard.iPhone15Pro,
      );
      final firstChild = fixture.controller.add('gesture.default');
      fixture.controller.select(lower);
      final secondChild = fixture.controller.add('gesture.default');
      final logicalRect = const Rect.fromLTWH(96, 180, 180, 96);
      fixture.controller.update(
        fixture.controller.nodes.value[firstChild]!.copyWith(rect: logicalRect),
      );
      fixture.controller.update(
        fixture.controller.nodes.value[secondChild]!.copyWith(
          rect: logicalRect,
        ),
      );
      fixture.controller.select(null);
      addTearDown(fixture.dispose);

      await tester.pumpWidget(_TestHarness(child: fixture.canvas()));
      final stage = tester.getRect(find.byKey(const ValueKey('sketch-stage')));
      final childScene = fixture.controller.sceneRectFor(
        fixture.controller.nodes.value[secondChild]!,
      );

      // Attached children retain insertion order inside the one lower artboard.
      await tester.tapAt(stage.topLeft + childScene.center);
      await tester.pump();
      expect(fixture.controller.selectedId.value, secondChild);

      final upper = fixture.controller.addArtboard(
        DesyCanvasArtboard.iPhone15Pro,
      );
      fixture.controller.update(
        fixture.controller.nodes.value[upper]!.copyWith(
          rect: fixture.controller.nodes.value[lower]!.rect,
        ),
      );
      fixture.controller.select(null);
      await tester.pump();

      // The later artboard is above both lower-child visuals and hit layers.
      await tester.tapAt(stage.topLeft + childScene.center);
      await tester.pump();
      expect(fixture.controller.selectedId.value, upper);
    },
  );

  testWidgets(
    'artboard side and corner handles preserve frame aspect and anchoring',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fixture = _CanvasFixture();
      final artboard = fixture.controller.addArtboard(
        DesyCanvasArtboard.iPhone15Pro,
      );
      final initial = fixture.controller.nodes.value[artboard]!;
      fixture.controller.update(
        initial.copyWith(
          rect: Rect.fromLTWH(72, 64, initial.rect.width, initial.rect.height),
        ),
      );
      fixture.controller.select(artboard);
      addTearDown(fixture.dispose);

      await tester.pumpWidget(_TestHarness(child: fixture.canvas()));
      final ratio =
          fixture.controller.nodes.value[artboard]!.rect.width /
          fixture.controller.nodes.value[artboard]!.rect.height;

      var previous = fixture.controller.nodes.value[artboard]!.rect;
      await tester.drag(
        find.byKey(ValueKey('canvas-handle-$artboard-right')),
        const Offset(32, 0),
      );
      await tester.pump();
      var current = fixture.controller.nodes.value[artboard]!.rect;
      expect(current.left, previous.left);
      expect(current.top, previous.top);
      expect(current.width / current.height, closeTo(ratio, 0.0001));

      previous = current;
      await tester.drag(
        find.byKey(ValueKey('canvas-handle-$artboard-bottom')),
        const Offset(0, 32),
      );
      await tester.pump();
      current = fixture.controller.nodes.value[artboard]!.rect;
      expect(current.left, previous.left);
      expect(current.top, previous.top);
      expect(current.width / current.height, closeTo(ratio, 0.0001));

      previous = current;
      await tester.drag(
        find.byKey(ValueKey('canvas-handle-$artboard-bottomRight')),
        const Offset(32, 24),
      );
      await tester.pump();
      current = fixture.controller.nodes.value[artboard]!.rect;
      expect(current.topLeft, previous.topLeft);
      expect(current.width / current.height, closeTo(ratio, 0.0001));
    },
  );

  testWidgets('responsive stage shrink keeps artboard and child reachable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _CanvasFixture();
    final artboard = fixture.controller.addArtboard(
      DesyCanvasArtboard.iPhone15Pro,
    );
    final child = fixture.controller.add('gesture.default');
    fixture.controller.select(null);
    addTearDown(fixture.dispose);

    await tester.pumpWidget(_TestHarness(child: fixture.canvas()));
    await tester.pumpAndSettle();
    final initialArtboard = fixture.controller.nodes.value[artboard]!.rect;
    final initialRatio = initialArtboard.width / initialArtboard.height;
    final logicalChild = fixture.controller.nodes.value[child]!.rect;

    await tester.binding.setSurfaceSize(const Size(580, 700));
    await tester.pumpAndSettle();

    final stage = tester.getRect(find.byKey(const ValueKey('sketch-stage')));
    final stageBounds = Rect.fromLTWH(0, 0, stage.width, stage.height);
    final compactArtboard = fixture.controller.nodes.value[artboard]!.rect;
    final childScene = fixture.controller.sceneRectFor(
      fixture.controller.nodes.value[child]!,
    );
    final childOverlay = tester.getRect(
      find.byKey(ValueKey('canvas-hit-$child')),
    );
    final childVisual = tester.getRect(
      find.byKey(const ValueKey('gesture-visual')),
    );

    expect(_rectContainedBy(stageBounds, compactArtboard), isTrue);
    expect(compactArtboard.width.isFinite, isTrue);
    expect(compactArtboard.height.isFinite, isTrue);
    expect(compactArtboard.width, greaterThanOrEqualTo(0));
    expect(compactArtboard.height, greaterThanOrEqualTo(0));
    expect(
      compactArtboard.width / compactArtboard.height,
      closeTo(initialRatio, 0.0001),
    );
    expect(fixture.controller.nodes.value[child]!.rect, logicalChild);
    expect(_rectContainedBy(stage, childOverlay), isTrue);
    expect(childOverlay.left, closeTo(stage.left + childScene.left, 0.001));
    expect(childOverlay.top, closeTo(stage.top + childScene.top, 0.001));
    expect(childVisual.left, closeTo(childOverlay.left, 0.2));
    expect(childVisual.top, closeTo(childOverlay.top, 0.2));
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

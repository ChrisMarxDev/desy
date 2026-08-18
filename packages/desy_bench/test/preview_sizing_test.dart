import 'dart:ui' show PointerDeviceKind;

import 'package:desy_bench/src/device_preview.dart';
import 'package:desy_bench/src/registry.dart';
import 'package:desy_bench/src/workbench/components_canvas/components_canvas_controller.dart';
import 'package:desy_bench/src/workbench/components_canvas/components_canvas_screen.dart';
import 'package:desy_bench/src/workbench/presentation/collection_canvas.dart';
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

  testWidgets(
    'shared device preview lays out at real geometry before scaling down',
    (tester) async {
      Size? mediaSize;
      EdgeInsets? safeArea;
      double? pixelRatio;
      BoxConstraints? constraints;

      await tester.pumpWidget(
        _TestHarness(
          child: Center(
            child: SizedBox(
              width: 220,
              height: 320,
              child: DesyDevicePreview(
                device: DesyDevicePreset.iPhone15Pro,
                child: LayoutBuilder(
                  builder: (context, value) {
                    constraints = value;
                    final media = MediaQuery.of(context);
                    mediaSize = media.size;
                    safeArea = media.viewPadding;
                    pixelRatio = media.devicePixelRatio;
                    return const SizedBox.expand();
                  },
                ),
              ),
            ),
          ),
        ),
      );

      final profile = Devices.ios.iPhone15Pro;
      expect(mediaSize, profile.screenSize);
      expect(safeArea, profile.safeAreas);
      expect(pixelRatio, profile.pixelRatio);
      expect(constraints!.biggest, profile.screenSize);
      expect(
        tester.getSize(
          find.byKey(const ValueKey('desy-device-frame-iPhone15Pro')),
        ),
        profile.frameSize,
      );
      final frameBox = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('desy-device-frame-iPhone15Pro')),
      );
      final visualTopLeft = frameBox.localToGlobal(Offset.zero);
      final visualBottomRight = frameBox.localToGlobal(
        frameBox.size.bottomRight(Offset.zero),
      );
      final visualSize = visualBottomRight - visualTopLeft;
      expect(visualSize.dx, lessThanOrEqualTo(220));
      expect(visualSize.dy, lessThanOrEqualTo(320));
    },
  );

  testWidgets('fitted previews use a 460 square logical ceiling', (
    tester,
  ) async {
    BoxConstraints? receivedConstraints;

    await tester.pumpWidget(
      _TestHarness(
        child: SizedBox(
          width: 220,
          height: 160,
          child: DesyFittedPreview(
            child: LayoutBuilder(
              builder: (context, constraints) {
                receivedConstraints = constraints;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );

    expect(
      receivedConstraints,
      const BoxConstraints(maxWidth: 460, maxHeight: 460),
    );
  });

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

  testWidgets('drag box supports mouse movement', (tester) async {
    const frameKey = ValueKey('mouse-drag-frame');
    await tester.pumpWidget(
      _TestHarness(
        child: Transform(
          transform: Matrix4.identity(),
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
              onChanged: (_) {},
              child: const ColoredBox(color: Colors.red),
            ),
          ),
        ),
      ),
    );

    final before = tester.getRect(find.byKey(frameKey));
    final gesture = await tester.startGesture(before.center);
    await gesture.moveBy(const Offset(32, 16));
    await gesture.up();
    await tester.pump();

    expect(tester.getRect(find.byKey(frameKey)).topLeft, isNot(before.topLeft));
  });

  testWidgets('collection canvas lets a mouse drag move an item', (
    tester,
  ) async {
    const frameKey = ValueKey('collection-mouse-drag-frame');
    var geometryChanges = 0;
    await tester.pumpWidget(
      _TestHarness(
        child: SizedBox(
          width: 640,
          height: 480,
          child: DesyCollectionCanvas<String>(
            theme: theme,
            title: 'Canvas',
            detailsBuilder: (_, _) => const SizedBox.shrink(),
            initialSelectedItemId: 'item',
            items: [
              DesyCanvasSceneItem(
                id: 'item',
                name: 'Item',
                value: 'item',
                initialRect: const Rect.fromLTWH(60, 200, 120, 80),
                frameKey: frameKey,
                onGeometryChanged: (_) => geometryChanges++,
                previewBuilder: (_, _) => const ColoredBox(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );

    final before = tester.getRect(find.byKey(frameKey));
    final gesture = await tester.startGesture(
      before.center,
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(32, 16));
    await gesture.moveBy(const Offset(1, 1));
    await gesture.up();
    await tester.pump();

    expect(tester.getRect(find.byKey(frameKey)).topLeft, isNot(before.topLeft));
    expect(geometryChanges, greaterThan(0));
  });

  testWidgets('collection canvas reserves a large finite stage around items', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestHarness(
        child: SizedBox(
          width: 640,
          height: 480,
          child: DesyCollectionCanvas<String>(
            theme: theme,
            title: 'Canvas',
            keyPrefix: 'large-canvas',
            detailsBuilder: (_, _) => const SizedBox.shrink(),
            items: [
              DesyCanvasSceneItem(
                id: 'item',
                name: 'Item',
                value: 'item',
                initialRect: const Rect.fromLTWH(60, 200, 120, 80),
                previewBuilder: (_, _) => const ColoredBox(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );

    final stage = tester.getSize(
      find.byKey(const ValueKey('large-canvas-stage')),
    );
    expect(stage.width, greaterThanOrEqualTo(2600));
    expect(stage.height, greaterThanOrEqualTo(2500));
  });

  testWidgets('collection canvas tints its workspace outside the stage', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestHarness(
        child: SizedBox(
          width: 640,
          height: 480,
          child: DesyCollectionCanvas<String>(
            theme: theme,
            title: 'Canvas',
            keyPrefix: 'workspace-canvas',
            detailsBuilder: (_, _) => const SizedBox.shrink(),
            items: [
              DesyCanvasSceneItem(
                id: 'item',
                name: 'Item',
                value: 'item',
                previewBuilder: (_, _) => const ColoredBox(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );

    final workspace = find.byKey(const ValueKey('workspace-canvas-workspace'));
    final workspaceColor = tester.widget<ColoredBox>(workspace).color;
    final context = tester.element(workspace);
    expect(workspaceColor, isNot(context.theme.colors.background));
  });

  testWidgets('collection canvas clamps its minimum zoom to 50 percent', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestHarness(
        child: SizedBox(
          width: 640,
          height: 480,
          child: DesyCollectionCanvas<String>(
            theme: theme,
            title: 'Canvas',
            keyPrefix: 'minimum-zoom',
            zoomDockKeyPrefix: 'minimum-zoom',
            initialZoom: .1,
            detailsBuilder: (_, _) => const SizedBox.shrink(),
            items: [
              DesyCanvasSceneItem(
                id: 'item',
                name: 'Item',
                value: 'item',
                previewBuilder: (_, _) => const ColoredBox(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      tester
          .widget<Semantics>(
            find.byKey(const ValueKey('minimum-zoom-zoom-level')),
          )
          .properties
          .label,
      'Zoom 50 percent',
    );
  });

  testWidgets('trackpad panning preserves the current canvas zoom', (
    tester,
  ) async {
    const frameKey = ValueKey('persistent-zoom-frame');
    await tester.pumpWidget(
      _TestHarness(
        child: SizedBox(
          width: 640,
          height: 480,
          child: DesyCollectionCanvas<String>(
            theme: theme,
            title: 'Canvas',
            keyPrefix: 'persistent-zoom',
            zoomDockKeyPrefix: 'persistent-zoom',
            detailsBuilder: (_, _) => const SizedBox.shrink(),
            items: [
              DesyCanvasSceneItem(
                id: 'item',
                name: 'Item',
                value: 'item',
                frameKey: frameKey,
                previewBuilder: (_, _) => const ColoredBox(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );

    final zoomOut = find.byKey(const ValueKey('persistent-zoom-zoom-out'));
    final zoomLevel = find.byKey(const ValueKey('persistent-zoom-zoom-level'));
    const zoomLabels = [
      'Zoom 85 percent',
      'Zoom 70 percent',
      'Zoom 55 percent',
      'Zoom 50 percent',
    ];
    for (final label in zoomLabels) {
      await tester.tap(zoomOut);
      await tester.pumpAndSettle();
      expect(tester.widget<Semantics>(zoomLevel).properties.label, label);
    }
    expect(
      tester.widget<Semantics>(zoomLevel).properties.label,
      'Zoom 50 percent',
    );

    final trackpad = await tester.createGesture(
      kind: PointerDeviceKind.trackpad,
    );
    final beforePan = tester.getTopLeft(find.byKey(frameKey));
    const focalPoint = Offset(360, 300);
    await trackpad.panZoomStart(focalPoint);
    await trackpad.panZoomUpdate(focalPoint, pan: const Offset(56, 20));
    await trackpad.up();
    await tester.pump();

    expect(tester.getTopLeft(find.byKey(frameKey)), isNot(beforePan));

    expect(
      tester.widget<Semantics>(zoomLevel).properties.label,
      'Zoom 50 percent',
    );
  });

  testWidgets('collection canvas pans only when a mouse drag starts blank', (
    tester,
  ) async {
    const frameKey = ValueKey('collection-blank-pan-frame');
    var geometryChanges = 0;
    await tester.pumpWidget(
      _TestHarness(
        child: SizedBox(
          width: 640,
          height: 480,
          child: DesyCollectionCanvas<String>(
            theme: theme,
            title: 'Canvas',
            detailsBuilder: (_, _) => const SizedBox.shrink(),
            initialSelectedItemId: 'item',
            items: [
              DesyCanvasSceneItem(
                id: 'item',
                name: 'Item',
                value: 'item',
                initialRect: const Rect.fromLTWH(60, 200, 120, 80),
                frameKey: frameKey,
                onGeometryChanged: (_) => geometryChanges++,
                previewBuilder: (_, _) => const ColoredBox(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );

    final before = tester.getRect(find.byKey(frameKey));
    final gesture = await tester.startGesture(
      const Offset(500, 360),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(32, 16));
    await gesture.up();
    await tester.pump();

    expect(tester.getRect(find.byKey(frameKey)).topLeft, isNot(before.topLeft));
    expect(geometryChanges, 0);
  });

  testWidgets('collection canvas routes trackpad movement to the viewport', (
    tester,
  ) async {
    const frameKey = ValueKey('collection-trackpad-frame');
    var geometryChanges = 0;
    await tester.pumpWidget(
      _TestHarness(
        child: SizedBox(
          width: 640,
          height: 480,
          child: DesyCollectionCanvas<String>(
            theme: theme,
            title: 'Canvas',
            detailsBuilder: (_, _) => const SizedBox.shrink(),
            initialSelectedItemId: 'item',
            items: [
              DesyCanvasSceneItem(
                id: 'item',
                name: 'Item',
                value: 'item',
                initialRect: const Rect.fromLTWH(60, 200, 120, 80),
                frameKey: frameKey,
                onGeometryChanged: (_) => geometryChanges++,
                previewBuilder: (_, _) => const ColoredBox(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );

    final before = tester.getRect(find.byKey(frameKey));
    final trackpad = await tester.createGesture(
      kind: PointerDeviceKind.trackpad,
    );
    await trackpad.panZoomStart(before.center);
    await trackpad.panZoomUpdate(before.center, pan: const Offset(0, 80));
    await trackpad.up();
    await tester.pump();

    expect(tester.getRect(find.byKey(frameKey)).topLeft, isNot(before.topLeft));
    expect(geometryChanges, 0);
  });

  testWidgets('drag box does not move while a trackpad scroll starts on it', (
    tester,
  ) async {
    const frameKey = ValueKey('trackpad-scroll-frame');
    var changes = 0;
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
            onChanged: (_) => changes++,
            child: const ColoredBox(color: Colors.red),
          ),
        ),
      ),
    );

    final before = tester.getRect(find.byKey(frameKey));
    final trackpad = await tester.createGesture(
      kind: PointerDeviceKind.trackpad,
    );
    await trackpad.panZoomStart(before.center);
    await trackpad.panZoomUpdate(before.center, pan: const Offset(0, 80));
    await trackpad.up();
    await tester.pump();

    expect(tester.getRect(find.byKey(frameKey)).topLeft, before.topLeft);
    expect(changes, 0);
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

  testWidgets('drag box exposes a double-tap reset gesture', (tester) async {
    var doubleTaps = 0;
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
            contentKey: const ValueKey('double-tap-content'),
            onChanged: (_) {},
            onDoubleTap: () => doubleTaps++,
            child: const ColoredBox(color: Colors.red),
          ),
        ),
      ),
    );

    final content = find.byKey(const ValueKey('double-tap-content'));
    await tester.tap(content);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(content);
    await tester.pumpAndSettle();

    expect(doubleTaps, 1);
  });

  testWidgets('detail presets use an unscaled, freely resizable viewport', (
    tester,
  ) async {
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
              device: session.previewDevice.watch(context),
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

    expect(find.byKey(const ValueKey('responsive-wide-detail')), findsNothing);
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

    session.selectPreviewDevice(DesyDevicePreset.iPhone15Pro);
    await tester.pumpAndSettle();
    final phoneSize = tester.getSize(
      find.byKey(const ValueKey('detail-artboard')),
    );
    expect(
      phoneSize.aspectRatio,
      closeTo(Devices.ios.iPhone15Pro.screenSize.aspectRatio, 0.001),
    );
    expect(
      receivedConstraints!.maxWidth,
      Devices.ios.iPhone15Pro.screenSize.width,
    );
  });

  testWidgets('detail device screens use the active theme background', (
    tester,
  ) async {
    const background = Color(0xFF16324F);
    const deviceTheme = DesyTheme(
      id: 'device-theme',
      name: 'Device theme',
      wrap: _wrap,
      previewBackgroundColor: background,
    );
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(name: 'Test', themes: const [deviceTheme]),
    )..selectPreviewDevice(DesyDevicePreset.iPhone15Pro);
    addTearDown(session.dispose);

    await tester.pumpWidget(
      _TestHarness(
        child: SizedBox(
          width: 560,
          height: 440,
          child: Builder(
            builder: (context) => DesyPreviewCanvas(
              session: session,
              theme: deviceTheme,
              device: session.previewDevice.watch(context),
              toolbar: null,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .widget<ColoredBox>(
            find.byKey(const ValueKey('detail-device-screen-iPhone15Pro')),
          )
          .color,
      background,
    );

    session.selectPreviewDevice(DesyDevicePreset.iPadPro11);
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<ColoredBox>(
            find.byKey(const ValueKey('detail-device-screen-iPadPro11')),
          )
          .color,
      background,
    );
  });

  testWidgets('sketch resize supplies real responsive widget constraints', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final component = DesyStaticComponent(
      id: 'responsive',
      name: 'Responsive',
      instances: {
        'default': (context) => LayoutBuilder(
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
      },
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

    await tester.dragFrom(
      tester.getCenter(
        find.byKey(
          const ValueKey('canvas-resize-responsive.default#0-bottomRight'),
        ),
      ),
      const Offset(160, 80),
    );
    await tester.pump();

    expect(
      controller.nodes.value['responsive.default#0']!.rect.size,
      const Size(384, 204),
    );
    final widePreview = find.descendant(
      of: find.byKey(const ValueKey('responsive.default#0')),
      matching: find.byKey(const ValueKey('responsive-sketch-wide')),
    );
    expect(widePreview, findsOneWidget);
    expect(tester.getSize(widePreview), const Size(384, 204));
    expect(find.text('384 × 204 px'), findsOneWidget);
    expect(find.text('220 × 120 px'), findsNothing);
  });

  testWidgets('self-sizing sketch previews cap their natural frame at 460', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final component = DesyStaticComponent(
      id: 'large-natural-preview',
      name: 'Large natural preview',
      instances: {'default': (_) => const SizedBox(width: 900, height: 700)},
    );
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'Test',
        themes: const [theme],
        components: [component],
      ),
    );
    final controller = DesyComponentsCanvasController();
    final nodeId = controller.add('large-natural-preview.default');
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

    expect(controller.nodes.value[nodeId]!.rect.size, const Size.square(460));
    expect(find.text('460 × 460 px'), findsOneWidget);
  });

  testWidgets('sketch components keep their native tap interactions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var presses = 0;
    final component = DesyStaticComponent(
      id: 'interactive',
      name: 'Interactive',
      instances: {
        'default': (_) => TextButton(
          key: const ValueKey('interactive-sketch-button'),
          onPressed: () => presses++,
          child: const Text('Press demo'),
        ),
      },
    );
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'Test',
        themes: const [theme],
        components: [component],
      ),
    );
    final controller = DesyComponentsCanvasController();
    final nodeId = controller.add('interactive.default');
    controller.select(null);
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

    final placedButton = find.descendant(
      of: find.byKey(ValueKey(nodeId)),
      matching: find.byKey(const ValueKey('interactive-sketch-button')),
    );
    await tester.tap(placedButton);
    await tester.pump();

    expect(presses, 1);
    expect(controller.selectedId.value, nodeId);
  });

  testWidgets('sketch geometry changes do not rebuild live previews', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var previewBuilds = 0;
    final component = DesyStaticComponent(
      id: 'counted',
      name: 'Counted',
      instances: {
        'default': (context) {
          previewBuilds++;
          return const SizedBox(
            key: ValueKey('counted-visual'),
            width: 220,
            height: 120,
          );
        },
      },
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

  testWidgets('a selected small sketch node moves on its first drag', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _CanvasFixture();
    final component = fixture.controller.add('gesture.default');
    final initial = fixture.controller.nodes.value[component]!;
    fixture.controller.update(
      initial.copyWith(
        rect: Rect.fromLTWH(initial.rect.left, initial.rect.top, 32, 24),
      ),
    );
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

    expect(fixture.controller.nodes.value[component]!.rect, before);
    expect(tester.getRect(frame).topLeft, isNot(frameBefore.topLeft));
    expect(tester.getRect(frame).size, frameBefore.size);

    await gesture.up();
    await tester.pump();

    final after = fixture.controller.nodes.value[component]!.rect;
    expect(after.topLeft, isNot(before.topLeft));
    expect(after.size, before.size);
  });

  testWidgets('a palette instance can be dragged into the sketch', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _CanvasFixture();
    addTearDown(fixture.dispose);

    await tester.pumpWidget(_TestHarness(child: fixture.canvas()));
    await tester.pumpAndSettle();
    final source = find.byKey(const ValueKey('palette-drag-gesture.default'));
    final stage = tester.getRect(find.byKey(const ValueKey('sketch-stage')));
    final dropGlobal = stage.topLeft + const Offset(360, 260);
    final gesture = await tester.startGesture(tester.getCenter(source));

    await gesture.moveBy(const Offset(12, 0));
    await tester.pump();
    await gesture.moveTo(dropGlobal);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(fixture.controller.nodes.value, hasLength(1));
    final dropped = fixture.controller.nodes.value.values.single;
    expect(dropped.instanceId, 'gesture.default');
    expect(dropped.rect.center.dx, closeTo(360, .01));
    expect(dropped.rect.center.dy, closeTo(260, .01));
    expect(fixture.controller.selectedId.value, dropped.id);
  });

  testWidgets('arrow keys move the selected sketch component', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _CanvasFixture();
    final component = fixture.controller.add('gesture.default');
    final before = fixture.controller.nodes.value[component]!.rect;
    addTearDown(fixture.dispose);

    await tester.pumpWidget(_TestHarness(child: fixture.canvas()));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(
      fixture.controller.nodes.value[component]!.rect.topLeft,
      before.topLeft + const Offset(8, 0),
    );
  });

  testWidgets('custom grid size controls keyboard movement', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _CanvasFixture();
    final component = fixture.controller.add('gesture.default');
    final before = fixture.controller.nodes.value[component]!.rect;
    addTearDown(fixture.dispose);

    await tester.pumpWidget(_TestHarness(child: fixture.canvas()));
    await tester.enterText(
      find.byKey(const ValueKey('sketch-grid-custom')),
      '12',
    );
    await tester.pump();
    expect(fixture.controller.gridStep.value, 12);

    await tester.tap(find.byKey(ValueKey('canvas-hit-$component')));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(
      fixture.controller.nodes.value[component]!.rect.topLeft,
      before.topLeft + const Offset(12, 0),
    );
  });

  testWidgets('element snapping stays local and paints guides while dragging', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _CanvasFixture();
    final active = fixture.controller.add('gesture.default');
    final target = fixture.controller.add('gesture.default');
    fixture.controller.update(
      fixture.controller.nodes.value[active]!.copyWith(
        rect: const Rect.fromLTWH(100, 100, 80, 60),
      ),
    );
    fixture.controller.update(
      fixture.controller.nodes.value[target]!.copyWith(
        rect: const Rect.fromLTWH(200, 100, 100, 60),
      ),
    );
    fixture.controller.select(active);
    addTearDown(fixture.dispose);

    await tester.pumpWidget(_TestHarness(child: fixture.canvas()));
    final frame = find.byKey(ValueKey(active));
    final beforeFrame = tester.getRect(frame);
    final committedBefore = fixture.controller.nodes.value[active]!.rect;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(ValueKey('canvas-hit-$active'))),
    );

    // The first move crosses Flutter's drag slop; the second is the actual
    // transform proposal and lands three pixels short of the target edge.
    await gesture.moveBy(const Offset(20, 0));
    await gesture.moveBy(const Offset(17, 0));
    await tester.pump();

    expect(fixture.controller.nodes.value[active]!.rect, committedBefore);
    expect(tester.getRect(frame).left, closeTo(beforeFrame.left + 20, 0.01));
    expect(fixture.controller.activeSnapGuides.value, isNotEmpty);
    expect(find.byKey(const ValueKey('sketch-snap-guides')), findsOneWidget);

    await gesture.up();
    await tester.pump();

    expect(fixture.controller.nodes.value[active]!.rect.left, 120);
    expect(fixture.controller.activeSnapGuides.value, isEmpty);
  });

  testWidgets('double tap restores a sketch component normal size', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _CanvasFixture();
    final component = fixture.controller.add('gesture.default');
    final node = fixture.controller.nodes.value[component]!;
    fixture.controller.update(
      node.copyWith(
        rect: Rect.fromLTWH(node.rect.left, node.rect.top, 360, 200),
      ),
    );
    addTearDown(fixture.dispose);

    await tester.pumpWidget(_TestHarness(child: fixture.canvas()));
    final content = find.byKey(ValueKey('canvas-hit-$component'));
    await tester.tap(content);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(content);
    await tester.pumpAndSettle();

    expect(
      fixture.controller.nodes.value[component]!.rect.size,
      const Size(220, 120),
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

  testWidgets('a component added to a bezel renders inside its device screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _CanvasFixture();
    final bezel = fixture.controller.addArtboard(DesyDevicePreset.iPhone15Pro);
    final component = fixture.controller.add('gesture.default');
    fixture.controller.select(component);
    addTearDown(fixture.dispose);

    await tester.pumpWidget(_TestHarness(child: fixture.canvas()));
    expect(fixture.controller.nodes.value[component]!.parentArtboardId, bezel);
    expect(
      find.descendant(
        of: find.byKey(ValueKey('canvas-artboard-screen-$bezel')),
        matching: find.byKey(const ValueKey('gesture-visual')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('artboard children receive the real device media context', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Size? mediaSize;
    final component = DesyStaticComponent(
      id: 'media-aware',
      name: 'Media aware',
      instances: {
        'default': (context) {
          mediaSize = MediaQuery.sizeOf(context);
          return const SizedBox(key: ValueKey('media-aware-visual'));
        },
      },
    );
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'Test',
        themes: const [theme],
        components: [component],
      ),
    );
    final controller = DesyComponentsCanvasController();
    final bezel = controller.addArtboard(DesyDevicePreset.iPhone15Pro);
    final item = controller.add('media-aware.default');
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
    expect(controller.nodes.value[item]!.parentArtboardId, bezel);
    expect(mediaSize, Devices.ios.iPhone15Pro.screenSize);
  });

  testWidgets('flat stack hit testing follows insertion order', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _CanvasFixture();
    final lower = fixture.controller.add('gesture.default');
    final bezel = fixture.controller.addArtboard(DesyDevicePreset.iPhone15Pro);
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
    fixture.controller.detachFromArtboard(upper);
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
    final bezel = fixture.controller.addArtboard(DesyDevicePreset.iPhone15Pro);
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

    await tester.dragFrom(
      tester.getCenter(
        find.byKey(ValueKey('canvas-resize-$bezel-bottomRight')),
      ),
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
    final bezel = fixture.controller.addArtboard(DesyDevicePreset.iPhone15Pro);
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

  static final _component = DesyStaticComponent(
    id: 'gesture',
    name: 'Gesture',
    instances: {
      'default': (context) => const SizedBox(
        key: ValueKey('gesture-visual'),
        width: 220,
        height: 120,
      ),
    },
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

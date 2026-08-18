import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:object_canvas/object_canvas.dart';

void main() {
  testWidgets('object drag previews first and commits once on pointer up', (
    tester,
  ) async {
    final controller = _widgetController();
    await tester.pumpWidget(_host(controller, viewportGestures: true));

    final object = find.byKey(const ValueKey('object-canvas-object-a'));
    final gesture = await tester.startGesture(tester.getCenter(object));
    await gesture.moveBy(const Offset(23, 17));
    await gesture.moveBy(const Offset(11, 7));
    await gesture.moveBy(const Offset(8, 5));
    await tester.pump();

    expect(controller.hasActiveTransform, isTrue);

    expect(
      controller.requireObject('a').geometry.position,
      const Offset(20, 20),
    );
    final previewPosition = controller.geometryFor('a').position;
    expect(previewPosition, isNot(const Offset(20, 20)));
    expect(controller.canUndo, isFalse);

    await gesture.up();
    await tester.pump();

    expect(controller.requireObject('a').geometry.position, previewPosition);
    expect(controller.canUndo, isTrue);
    controller.undo();
    expect(
      controller.requireObject('a').geometry.position,
      const Offset(20, 20),
    );
  });

  testWidgets('only objects with changed render state invoke their builder', (
    tester,
  ) async {
    final builds = <String, int>{};
    final controller = _widgetController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 500,
          height: 400,
          child: ObjectCanvas<Widget>(
            controller: controller,
            objectBuilder: (context, object) {
              builds.update(object.id, (count) => count + 1, ifAbsent: () => 1);
              return object.data;
            },
          ),
        ),
      ),
    );
    expect(builds, {'a': 1, 'b': 1});

    controller.beginTransform(CanvasTransformKind.move, ['a']);
    await tester.pump();
    expect(builds, {'a': 1, 'b': 1});

    controller.previewMoveBy(const Offset(20, 10), snap: false);
    await tester.pump();
    expect(builds, {'a': 2, 'b': 1});

    controller.commitTransform();
    await tester.pump();
    expect(builds, {'a': 2, 'b': 1});

    controller.updateData([
      const CanvasDataValue(
        objectId: 'b',
        data: ColoredBox(color: Color(0xFF16A34A)),
      ),
    ]);
    await tester.pump();
    expect(builds, {'a': 2, 'b': 2});

    controller.selectObjects(['a']);
    await tester.pump();
    expect(builds, {'a': 2, 'b': 2});

    controller.bringObjectsToFront(['a']);
    await tester.pump();
    expect(builds, {'a': 2, 'b': 2});
  });

  testWidgets('changing the object builder updates rendered content', (
    tester,
  ) async {
    final controller = _widgetController();

    Widget host(String label) => Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: 500,
        height: 400,
        child: ObjectCanvas<Widget>(
          controller: controller,
          objectBuilder: (context, object) => Text('$label-${object.id}'),
        ),
      ),
    );

    await tester.pumpWidget(host('before'));
    expect(find.text('before-a'), findsOneWidget);
    expect(find.text('before-b'), findsOneWidget);

    await tester.pumpWidget(host('after'));
    expect(find.text('after-a'), findsOneWidget);
    expect(find.text('after-b'), findsOneWidget);
    expect(find.text('before-a'), findsNothing);
    expect(find.text('before-b'), findsNothing);
  });

  testWidgets('dragging one selected object moves the complete selection', (
    tester,
  ) async {
    final controller = _widgetController();
    controller.selectObjects(['a', 'b']);
    await tester.pumpWidget(_host(controller));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('object-canvas-object-a'))),
    );
    await gesture.moveBy(const Offset(15, 10));
    await gesture.moveBy(const Offset(9, 6));
    await gesture.moveBy(const Offset(7, 5));
    await gesture.moveBy(const Offset(6, 4));
    await tester.pump();

    expect(
      controller.requireObject('a').geometry.position,
      const Offset(20, 20),
    );
    expect(
      controller.requireObject('b').geometry.position,
      const Offset(110, 70),
    );
    final previewA = controller.geometryFor('a').position;
    final previewB = controller.geometryFor('b').position;
    expect(previewA, isNot(const Offset(20, 20)));
    expect(previewB - previewA, const Offset(90, 50));

    await gesture.up();
    await tester.pump();
    expect(controller.lastActionEvent?.action.objectIds, ['a', 'b']);
  });

  testWidgets('trackpad pan does not start marquee selection', (tester) async {
    final controller = _widgetController();
    await tester.pumpWidget(_host(controller, viewportGestures: true));

    final stageTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey('object-canvas-stage-stack')),
    );
    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.trackpad,
    );
    final focalPoint = stageTopLeft + const Offset(295, 195);
    await gesture.panZoomStart(focalPoint);
    await tester.pump();
    await gesture.panZoomUpdate(focalPoint, pan: const Offset(-260, -175));
    await tester.pump();
    await gesture.panZoomEnd();
    await tester.pump();

    expect(controller.selectedObjectIds, isEmpty);
  });

  testWidgets('trackpad pan over a selected object moves the viewport', (
    tester,
  ) async {
    final controller = _widgetController();
    controller.selectObjects(['a']);
    await tester.pumpWidget(_host(controller, viewportGestures: true));

    final matrix = controller.viewportController.value;
    final beforeTranslation = Offset(matrix.storage[12], matrix.storage[13]);
    final beforePosition = controller.requireObject('a').geometry.position;
    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.trackpad,
    );
    final focalPoint = tester.getCenter(
      find.byKey(const ValueKey('object-canvas-object-a')),
    );
    await gesture.panZoomStart(focalPoint);
    await tester.pump();
    await gesture.panZoomUpdate(focalPoint, pan: const Offset(-120, -80));
    await tester.pump();
    await gesture.panZoomEnd();
    await tester.pump();

    expect(controller.requireObject('a').geometry.position, beforePosition);
    expect(controller.hasActiveTransform, isFalse);
    final nextMatrix = controller.viewportController.value;
    expect(
      Offset(nextMatrix.storage[12], nextMatrix.storage[13]),
      isNot(beforeTranslation),
    );
  });

  testWidgets('marquee selection can be disabled by the host', (tester) async {
    final controller = _widgetController();
    await tester.pumpWidget(_host(controller, marqueeSelectionEnabled: false));

    final stageTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey('object-canvas-stage-stack')),
    );
    final gesture = await tester.startGesture(
      stageTopLeft + const Offset(295, 195),
    );
    await gesture.moveBy(const Offset(-260, -175));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(controller.selectedObjectIds, isEmpty);
  });

  testWidgets('drag direction stays in canvas space for a rotated object', (
    tester,
  ) async {
    final controller = ObjectCanvasController<Widget>(
      canvasSize: const Size(300, 200),
      snapConfiguration: CanvasSnapConfiguration(strategies: const []),
      objects: [
        CanvasObject<Widget>(
          id: 'rotated',
          data: const ColoredBox(color: Color(0xFFE11D48)),
          geometry: CanvasObjectGeometry(
            position: const Offset(80, 70),
            size: const Size(60, 40),
            rotation: math.pi,
          ),
        ),
      ],
    );
    await tester.pumpWidget(_host(controller));

    final gesture = await tester.startGesture(
      tester.getCenter(
        find.byKey(const ValueKey('object-canvas-object-rotated')),
      ),
    );
    await gesture.moveBy(const Offset(20, 0));
    await gesture.moveBy(const Offset(30, 0));
    await gesture.moveBy(const Offset(10, 0));
    await tester.pump();
    final firstPreview = controller.geometryFor('rotated').position;

    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    final secondPreview = controller.geometryFor('rotated').position;

    expect(secondPreview.dx, greaterThan(firstPreview.dx));
    expect(secondPreview.dy, closeTo(firstPreview.dy, 0.001));

    await gesture.up();
    await tester.pump();
    expect(
      controller.requireObject('rotated').geometry.position,
      secondPreview,
    );
  });

  testWidgets('a selected object remains draggable between its handles', (
    tester,
  ) async {
    final controller = _widgetController();
    controller.selectObjects(['a']);
    await tester.pumpWidget(_host(controller));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('object-canvas-object-a'))),
    );
    await gesture.moveBy(const Offset(20, 10));
    await gesture.moveBy(const Offset(12, 6));
    await gesture.moveBy(const Offset(8, 4));
    await gesture.moveBy(const Offset(8, 4));
    await tester.pump();

    expect(controller.hasActiveTransform, isTrue);
    expect(
      controller.geometryFor('a').position,
      isNot(controller.requireObject('a').geometry.position),
    );

    await gesture.up();
    await tester.pump();
    expect(controller.canUndo, isTrue);
  });

  testWidgets('layout resize stays available in the object coordinate space', (
    tester,
  ) async {
    final controller = _rotatedWidgetController();
    controller.selectObjects(['rotated']);
    await tester.pumpWidget(_host(controller));

    final start = controller.requireObject('rotated').geometry;
    final handle = find.byKey(
      const ValueKey('object-canvas-resize-rotated-bottom-right'),
    );
    expect(handle, findsOneWidget);
    final gesture = await tester.startGesture(tester.getCenter(handle));
    final step = _rotate(const Offset(12, 9), start.rotation);
    await gesture.moveBy(step);
    await gesture.moveBy(step);
    await gesture.moveBy(step);
    await gesture.moveBy(step);
    await gesture.moveBy(step);
    await tester.pump();

    final preview = controller.geometryFor('rotated');
    expect(controller.hasActiveTransform, isTrue);
    expect(preview.size.width, greaterThan(start.size.width));
    expect(preview.size.height, greaterThan(start.size.height));
    expect(preview.rotation, start.rotation);
    expect(controller.requireObject('rotated').geometry, start);
    expect(controller.canUndo, isFalse);

    await gesture.up();
    await tester.pump();
    expect(controller.requireObject('rotated').geometry, preview);
    expect(controller.canUndo, isTrue);
  });

  testWidgets('shift resize preserves the gesture-start aspect ratio', (
    tester,
  ) async {
    final controller = _rotatedWidgetController();
    controller.selectObjects(['rotated']);
    await tester.pumpWidget(_host(controller));

    final start = controller.requireObject('rotated').geometry;
    final fixedCorner = start.paintCorners.first;
    final handle = find.byKey(
      const ValueKey('object-canvas-resize-rotated-bottom-right'),
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    final gesture = await tester.startGesture(tester.getCenter(handle));
    final step = _rotate(const Offset(12, 2), start.rotation);
    for (var index = 0; index < 4; index++) {
      await gesture.moveBy(step);
    }
    await tester.pump();

    final preview = controller.geometryFor('rotated');
    expect(
      preview.size.width / preview.size.height,
      closeTo(start.size.width / start.size.height, 0.0001),
    );
    expect(
      (preview.paintCorners.first - fixedCorner).distance,
      lessThan(0.001),
    );

    await gesture.up();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(controller.requireObject('rotated').geometry, preview);
  });

  testWidgets('control resize keeps the rotated object centered', (
    tester,
  ) async {
    final controller = _rotatedWidgetController();
    controller.selectObjects(['rotated']);
    await tester.pumpWidget(_host(controller));

    final start = controller.requireObject('rotated').geometry;
    final center = start.paintBounds.center;
    final handle = find.byKey(
      const ValueKey('object-canvas-resize-rotated-bottom-right'),
    );
    final gesture = await tester.startGesture(tester.getCenter(handle));
    final step = _rotate(const Offset(10, 3), start.rotation);
    await gesture.moveBy(step);
    await gesture.moveBy(step);
    await gesture.moveBy(step);
    await gesture.moveBy(step);
    await tester.pump();
    expect(controller.hasActiveTransform, isTrue);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    expect(HardwareKeyboard.instance.isControlPressed, isTrue);
    for (var index = 0; index < 4; index++) {
      await gesture.moveBy(step);
    }
    await tester.pump();

    final preview = controller.geometryFor('rotated');
    expect(preview.size.width, greaterThan(start.size.width));
    expect(preview.size.height, greaterThan(start.size.height));
    expect((preview.paintBounds.center - center).distance, lessThan(0.001));

    await gesture.up();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(controller.requireObject('rotated').geometry, preview);
  });

  testWidgets('shift and control resize preserve ratio around the center', (
    tester,
  ) async {
    final controller = _rotatedWidgetController();
    controller.selectObjects(['rotated']);
    await tester.pumpWidget(_host(controller));

    final start = controller.requireObject('rotated').geometry;
    final center = start.paintBounds.center;
    final handle = find.byKey(
      const ValueKey('object-canvas-resize-rotated-bottom-right'),
    );
    final gesture = await tester.startGesture(tester.getCenter(handle));
    final step = _rotate(const Offset(10, 4), start.rotation);
    for (var index = 0; index < 4; index++) {
      await gesture.moveBy(step);
    }
    await tester.pump();
    expect(controller.hasActiveTransform, isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    for (var index = 0; index < 4; index++) {
      await gesture.moveBy(step);
    }
    await tester.pump();

    final preview = controller.geometryFor('rotated');
    expect(
      preview.size.width / preview.size.height,
      closeTo(start.size.width / start.size.height, 0.0001),
    );
    expect((preview.paintBounds.center - center).distance, lessThan(0.001));

    await gesture.up();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(controller.requireObject('rotated').geometry, preview);
  });

  testWidgets('transform scale stays available after rotation', (tester) async {
    final controller = _rotatedWidgetController();
    controller
      ..setTransformMode(CanvasTransformMode.transformScale)
      ..selectObjects(['rotated']);
    await tester.pumpWidget(_host(controller));

    final start = controller.requireObject('rotated').geometry;
    final fixedCorner = start.paintCorners.first;
    final handle = find.byKey(
      const ValueKey('object-canvas-resize-rotated-bottom-right'),
    );
    final gesture = await tester.startGesture(tester.getCenter(handle));
    final step = _rotate(const Offset(12, 9), start.rotation);
    await gesture.moveBy(step);
    await gesture.moveBy(step);
    await gesture.moveBy(step);
    await gesture.moveBy(step);
    await tester.pump();

    final preview = controller.geometryFor('rotated');
    expect(controller.hasActiveTransform, isTrue);
    expect(preview.scale, greaterThan(start.scale));
    expect(preview.size, start.size);
    expect(
      (preview.paintCorners.first - fixedCorner).distance,
      lessThan(0.001),
    );

    await gesture.up();
    await tester.pump();
    expect(controller.requireObject('rotated').geometry, preview);
  });

  testWidgets('control transform scale keeps the rotated object centered', (
    tester,
  ) async {
    final controller = _rotatedWidgetController();
    controller
      ..setTransformMode(CanvasTransformMode.transformScale)
      ..selectObjects(['rotated']);
    await tester.pumpWidget(_host(controller));

    final start = controller.requireObject('rotated').geometry;
    final center = start.paintBounds.center;
    final handle = find.byKey(
      const ValueKey('object-canvas-resize-rotated-bottom-right'),
    );
    final gesture = await tester.startGesture(tester.getCenter(handle));
    final step = _rotate(const Offset(10, 6), start.rotation);
    await gesture.moveBy(step);
    await gesture.moveBy(step);
    await gesture.moveBy(step);
    await gesture.moveBy(step);
    await tester.pump();
    expect(controller.hasActiveTransform, isTrue);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    expect(HardwareKeyboard.instance.isControlPressed, isTrue);
    for (var index = 0; index < 4; index++) {
      await gesture.moveBy(step);
    }
    await tester.pump();

    final preview = controller.geometryFor('rotated');
    expect(preview.scale, greaterThan(start.scale));
    expect(preview.size, start.size);
    expect((preview.paintBounds.center - center).distance, lessThan(0.001));

    await gesture.up();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(controller.requireObject('rotated').geometry, preview);
  });

  testWidgets('render boundary is finite and excludes editor overlays', (
    tester,
  ) async {
    final controller = ObjectCanvasController<Widget>(
      canvasSize: const Size(120, 80),
      snapConfiguration: CanvasSnapConfiguration(strategies: const []),
      objects: [
        CanvasObject<Widget>(
          id: 'empty',
          data: const SizedBox.expand(),
          geometry: const CanvasObjectGeometry(
            position: Offset(20, 20),
            size: Size(40, 30),
          ),
        ),
      ],
    );
    controller.selectObjects(['empty']);
    await tester.pumpWidget(_host(controller));
    await tester.pumpAndSettle();

    final object = find.byKey(const ValueKey('object-canvas-object-empty'));
    final boundary = find.ancestor(
      of: object,
      matching: find.byType(RepaintBoundary),
    );
    expect(boundary, findsOneWidget);
    expect(tester.getSize(boundary), const Size(120, 80));
    final rotateHandle = find.byKey(
      const ValueKey('object-canvas-rotate-empty'),
    );
    expect(rotateHandle, findsOneWidget);
    expect(find.descendant(of: boundary, matching: rotateHandle), findsNothing);
  });

  testWidgets('overflow policy controls stage and object clipping', (
    tester,
  ) async {
    for (final overflow in CanvasOverflow.values) {
      final controller = ObjectCanvasController<Widget>(
        canvasSize: const Size(120, 80),
        overflow: overflow,
        objects: [
          CanvasObject<Widget>(
            id: 'overflowing',
            data: const ColoredBox(color: Color(0xFFE11D48)),
            geometry: const CanvasObjectGeometry(
              position: Offset(100, 60),
              size: Size(40, 30),
            ),
          ),
        ],
      );
      await tester.pumpWidget(_host(controller));

      final expected = overflow == CanvasOverflow.show
          ? Clip.none
          : Clip.hardEdge;
      expect(
        tester
            .widget<Stack>(
              find.byKey(const ValueKey('object-canvas-stage-stack')),
            )
            .clipBehavior,
        expected,
      );
      expect(
        tester
            .widget<Stack>(
              find.byKey(const ValueKey('object-canvas-content-stack')),
            )
            .clipBehavior,
        expected,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    }
  });

  testWidgets(
    'underlays stay outside export and invisible objects are excluded',
    (tester) async {
      final controller = _widgetController();
      controller.selectObjects(['b']);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 500,
            height: 400,
            child: ObjectCanvas<Widget>(
              controller: controller,
              underlayBuilder: (context, controller) => const ColoredBox(
                key: ValueKey('exported-underlay'),
                color: Color(0xFFFFFFFF),
              ),
              objectVisibility: (object) => object.id != 'b',
              objectBuilder: (context, object) => object.data,
            ),
          ),
        ),
      );

      final visible = find.byKey(const ValueKey('object-canvas-object-a'));
      final hidden = find.byKey(const ValueKey('object-canvas-object-b'));
      final underlay = find.byKey(const ValueKey('exported-underlay'));
      final boundary = find.ancestor(
        of: visible,
        matching: find.byType(RepaintBoundary),
      );

      expect(visible, findsOneWidget);
      expect(hidden, findsNothing);
      expect(underlay, findsOneWidget);
      expect(find.descendant(of: boundary, matching: underlay), findsNothing);
      expect(
        find.byKey(const ValueKey('object-canvas-rotate-b')),
        findsNothing,
      );
    },
  );

  test('rendering requires a mounted ObjectCanvas', () async {
    final controller = ObjectCanvasController<Widget>(
      canvasSize: const Size(120, 80),
    );
    await expectLater(controller.renderToImage(), throwsStateError);
  });

  testWidgets('arrow key nudges the selected array as one undoable action', (
    tester,
  ) async {
    final controller = _widgetController();
    controller.selectObjects(['a', 'b']);
    await tester.pumpWidget(_host(controller, autofocus: true));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(
      controller.requireObject('a').geometry.position,
      const Offset(21, 20),
    );
    expect(
      controller.requireObject('b').geometry.position,
      const Offset(111, 70),
    );
    expect(controller.lastActionEvent?.action.objectIds, ['a', 'b']);
    controller.undo();
    expect(
      controller.requireObject('a').geometry.position,
      const Offset(20, 20),
    );
    expect(
      controller.requireObject('b').geometry.position,
      const Offset(110, 70),
    );
  });
}

ObjectCanvasController<Widget> _widgetController() =>
    ObjectCanvasController<Widget>(
      canvasSize: const Size(300, 200),
      snapConfiguration: CanvasSnapConfiguration(strategies: const []),
      objects: [
        CanvasObject<Widget>(
          id: 'a',
          data: const ColoredBox(color: Color(0xFFE11D48)),
          geometry: const CanvasObjectGeometry(
            position: Offset(20, 20),
            size: Size(50, 40),
          ),
        ),
        CanvasObject<Widget>(
          id: 'b',
          data: const ColoredBox(color: Color(0xFF2563EB)),
          geometry: const CanvasObjectGeometry(
            position: Offset(110, 70),
            size: Size(60, 50),
          ),
        ),
      ],
    );

ObjectCanvasController<Widget> _rotatedWidgetController() =>
    ObjectCanvasController<Widget>(
      canvasSize: const Size(300, 240),
      snapConfiguration: CanvasSnapConfiguration(strategies: const []),
      objects: [
        CanvasObject<Widget>(
          id: 'rotated',
          data: const ColoredBox(color: Color(0xFFE11D48)),
          geometry: const CanvasObjectGeometry(
            position: Offset(100, 80),
            size: Size(80, 60),
            rotation: math.pi / 4,
          ),
        ),
      ],
    );

Offset _rotate(Offset value, double angle) => Offset(
  value.dx * math.cos(angle) - value.dy * math.sin(angle),
  value.dx * math.sin(angle) + value.dy * math.cos(angle),
);

Widget _host(
  ObjectCanvasController<Widget> controller, {
  bool autofocus = false,
  bool viewportGestures = false,
  bool marqueeSelectionEnabled = true,
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: Center(
    child: SizedBox(
      width: 500,
      height: 400,
      child: ObjectCanvas<Widget>.widgets(
        controller: controller,
        autofocus: autofocus,
        panEnabled: viewportGestures,
        scaleEnabled: viewportGestures,
        marqueeSelectionEnabled: marqueeSelectionEnabled,
      ),
    ),
  ),
);

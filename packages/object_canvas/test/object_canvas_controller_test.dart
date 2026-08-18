import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:object_canvas/object_canvas.dart';

void main() {
  group('ObjectCanvasController', () {
    test('uses canvas defaults unless an object overrides them', () {
      final controller = ObjectCanvasController<String>(
        canvasSize: const Size(800, 600),
        defaults: const CanvasObjectDefaults(
          constraints: CanvasObjectConstraints(minSize: Size(40, 30)),
          capabilities: CanvasObjectCapabilities(rotatable: false),
        ),
        objects: [
          _object('default'),
          _object(
            'override',
            constraints: const CanvasObjectConstraints(minSize: Size(8, 8)),
            capabilities: const CanvasObjectCapabilities(rotatable: true),
          ),
        ],
      );

      expect(controller.constraintsFor('default').minSize, const Size(40, 30));
      expect(controller.capabilitiesFor('default').rotatable, isFalse);
      expect(controller.constraintsFor('override').minSize, const Size(8, 8));
      expect(controller.capabilitiesFor('override').rotatable, isTrue);
    });

    test('host selection setter reports effective selection changes', () {
      final selections = <Set<String>>[];
      final controller = ObjectCanvasController<String>(
        canvasSize: const Size(800, 600),
        objects: [_object('a'), _object('b')],
        onSelectionChanged: selections.add,
      );

      controller.setSelectedObjects(['a', 'b']);
      controller.setSelectedObjects(['b', 'a']);

      expect(controller.selectedObjectIds, {'a', 'b'});
      expect(controller.selectedObjects.map((object) => object.id), ['a', 'b']);
      expect(selections, [
        {'a', 'b'},
      ]);
      expect(() => selections.single.add('other'), throwsUnsupportedError);

      controller.removeObjects(['a']);
      expect(controller.selectedObjectIds, {'b'});
      expect(selections.last, {'b'});

      controller.clearSelection();
      expect(selections.last, isEmpty);
    });

    test('disabled multi-selection keeps at most one selected object', () {
      final selections = <Set<String>>[];
      final controller = ObjectCanvasController<String>(
        canvasSize: const Size(800, 600),
        objects: [_object('a'), _object('b')],
        multiSelectionEnabled: false,
        onSelectionChanged: selections.add,
      );

      controller.setSelectedObjects(['a', 'b']);
      expect(controller.selectedObjectIds, {'a'});

      controller.selectObjects(['b'], mode: CanvasSelectionMode.add);
      expect(controller.selectedObjectIds, {'b'});
      expect(selections, [
        {'a'},
        {'b'},
      ]);
    });

    test('multi-object move is draft-only until one commit', () {
      final controller = _controller();
      final events = <CanvasActionEvent<String>>[];
      controller.addListener(() {
        if (controller.lastActionEvent case final event?) {
          if (events.isEmpty || !identical(events.last, event)) {
            events.add(event);
          }
        }
      });

      controller.beginTransform(CanvasTransformKind.move, ['a', 'b']);
      controller.previewMoveBy(const Offset(31, 17), snap: false);

      expect(
        controller.requireObject('a').geometry.position,
        const Offset(10, 10),
      );
      expect(
        controller.requireObject('b').geometry.position,
        const Offset(100, 60),
      );
      expect(controller.geometryFor('a').position, const Offset(41, 27));
      expect(controller.geometryFor('b').position, const Offset(131, 77));
      expect(controller.canUndo, isFalse);
      expect(events, isEmpty);

      controller.commitTransform();

      expect(
        controller.requireObject('a').geometry.position,
        const Offset(41, 27),
      );
      expect(
        controller.requireObject('b').geometry.position,
        const Offset(131, 77),
      );
      expect(controller.canUndo, isTrue);
      expect(events, hasLength(1));
      expect(events.single.phase, CanvasActionPhase.commit);
      expect(events.single.action.objectIds, ['a', 'b']);

      controller.undo();
      expect(
        controller.requireObject('a').geometry.position,
        const Offset(10, 10),
      );
      expect(
        controller.requireObject('b').geometry.position,
        const Offset(100, 60),
      );
      expect(events.last.phase, CanvasActionPhase.undo);

      controller.redo();
      expect(
        controller.requireObject('a').geometry.position,
        const Offset(41, 27),
      );
      expect(
        controller.requireObject('b').geometry.position,
        const Offset(131, 77),
      );
      expect(events.last.phase, CanvasActionPhase.redo);
    });

    test('cancel discards draft without adding history', () {
      final controller = _controller();

      controller.beginTransform(CanvasTransformKind.move, ['a']);
      controller.previewMoveBy(const Offset(20, 30));
      controller.cancelTransform();

      expect(
        controller.geometryFor('a'),
        controller.requireObject('a').geometry,
      );
      expect(
        controller.requireObject('a').geometry.position,
        const Offset(10, 10),
      );
      expect(controller.canUndo, isFalse);
    });

    test('non-move multi-object transforms are rejected in V1', () {
      final controller = _controller();

      expect(
        () => controller.beginTransform(CanvasTransformKind.layoutResize, [
          'a',
          'b',
        ]),
        throwsArgumentError,
      );
      expect(
        () => controller.beginTransform(CanvasTransformKind.rotate, ['a', 'b']),
        throwsArgumentError,
      );
    });

    test('sparse geometry patches preserve fields they do not own', () {
      const before = CanvasObjectGeometry(
        position: Offset(10, 10),
        size: Size(40, 30),
      );
      const moved = CanvasObjectGeometry(
        position: Offset(20, 25),
        size: Size(40, 30),
      );
      const independentlyResized = CanvasObjectGeometry(
        position: Offset(10, 10),
        size: Size(90, 70),
      );
      final patch = CanvasObjectGeometryPatch.between(before, moved);

      expect(patch.position, isNotNull);
      expect(patch.size, isNull);
      expect(
        patch.applyTo(independentlyResized),
        const CanvasObjectGeometry(
          position: Offset(20, 25),
          size: Size(90, 70),
        ),
      );
      expect(
        patch.revertOn(patch.applyTo(independentlyResized)),
        independentlyResized,
      );
    });

    test('array add and remove actions restore exact paint order', () {
      final controller = _controller();
      controller.addObjects([_object('c'), _object('d')], atIndex: 1);

      expect(controller.objects.map((object) => object.id), [
        'a',
        'c',
        'd',
        'b',
      ]);

      controller.removeObjects(['a', 'd']);
      expect(controller.objects.map((object) => object.id), ['c', 'b']);

      controller.undo();
      expect(controller.objects.map((object) => object.id), [
        'a',
        'c',
        'd',
        'b',
      ]);
      controller.undo();
      expect(controller.objects.map((object) => object.id), ['a', 'b']);
    });

    test('z-order helpers preserve runs and are undoable', () {
      final controller = ObjectCanvasController<String>(
        canvasSize: const Size(800, 600),
        objects: [_object('a'), _object('b'), _object('c'), _object('d')],
      );

      controller.bringObjectsToFront(['b', 'c']);
      expect(controller.objects.map((object) => object.id), [
        'a',
        'd',
        'b',
        'c',
      ]);
      controller.undo();

      controller.sendObjectsToBack(['b', 'c']);
      expect(controller.objects.map((object) => object.id), [
        'b',
        'c',
        'a',
        'd',
      ]);
      controller.undo();

      controller.moveObjectsForward(['b', 'c']);
      expect(controller.objects.map((object) => object.id), [
        'a',
        'd',
        'b',
        'c',
      ]);
      controller.undo();

      controller.moveObjectsBackward(['b', 'c']);
      expect(controller.objects.map((object) => object.id), [
        'b',
        'c',
        'a',
        'd',
      ]);
      controller.undo();

      expect(controller.objects.map((object) => object.id), [
        'a',
        'b',
        'c',
        'd',
      ]);
    });

    test(
      'group move clamps its union hull and preserves relative positions',
      () {
        final controller = ObjectCanvasController<String>(
          canvasSize: const Size(200, 120),
          objects: [
            _object(
              'a',
              position: const Offset(10, 10),
              size: const Size(40, 30),
            ),
            _object(
              'b',
              position: const Offset(100, 60),
              size: const Size(50, 40),
            ),
          ],
        );

        controller.beginTransform(CanvasTransformKind.move, ['a', 'b']);
        controller.previewMoveBy(const Offset(100, 100), snap: false);

        expect(controller.geometryFor('a').position, const Offset(60, 30));
        expect(controller.geometryFor('b').position, const Offset(150, 80));
        expect(
          controller.geometryFor('b').position -
              controller.geometryFor('a').position,
          const Offset(90, 50),
        );
      },
    );

    test('clip and show overflow allow movement beyond canvas bounds', () {
      for (final overflow in [CanvasOverflow.clip, CanvasOverflow.show]) {
        final controller = ObjectCanvasController<String>(
          canvasSize: const Size(200, 120),
          overflow: overflow,
          snapConfiguration: CanvasSnapConfiguration(strategies: const []),
          objects: [
            _object('a', position: const Offset(10, 10)),
            _object('b', position: const Offset(100, 60)),
          ],
        );

        controller.beginTransform(CanvasTransformKind.move, ['a', 'b']);
        controller.previewMoveBy(const Offset(150, 100));

        expect(controller.geometryFor('a').position, const Offset(160, 110));
        expect(controller.geometryFor('b').position, const Offset(250, 160));
      }
    });

    test('overflow changes preserve geometry and cancel an active preview', () {
      final controller = _controller();
      controller.beginTransform(CanvasTransformKind.move, ['a']);
      controller.previewMoveBy(const Offset(20, 10), snap: false);

      controller.setOverflow(CanvasOverflow.show);

      expect(controller.overflow, CanvasOverflow.show);
      expect(controller.hasActiveTransform, isFalse);
      expect(
        controller.requireObject('a').geometry.position,
        const Offset(10, 10),
      );
    });

    test('clip overflow keeps snapped resize previews unconstrained', () {
      final controller = ObjectCanvasController<String>(
        canvasSize: const Size(200, 120),
        overflow: CanvasOverflow.clip,
        snapConfiguration: CanvasSnapConfiguration(strategies: const []),
        objects: [_object('a', position: const Offset(10, 10))],
      );
      controller.beginTransform(CanvasTransformKind.layoutResize, ['a']);

      final preview = controller.resolveResizePreview(
        'a',
        const Rect.fromLTWH(10, 10, 240, 30),
        edges: const CanvasResizeEdges(right: true),
      );

      expect(preview, const Rect.fromLTWH(10, 10, 240, 30));
    });

    test('snap targets are indexed on placement, never rebuilt per frame', () {
      final controller = ObjectCanvasController<String>(
        canvasSize: const Size(800, 600),
        objects: [
          _object('moving', position: const Offset(10, 10)),
          _object('target', position: const Offset(200, 10)),
        ],
      );
      final initialRevision = controller.snapIndexRevision;

      controller.beginTransform(CanvasTransformKind.move, ['moving']);
      controller.previewMoveBy(const Offset(147, 0));

      expect(controller.snapIndexRevision, initialRevision);
      expect(controller.geometryFor('moving').paintBounds.right, 200);
      expect(controller.snapGuides, isNotEmpty);
      expect(controller.snapGuides.first.source, CanvasSnapSource.object);
      expect(controller.lastExaminedSnapAnchors, greaterThan(0));
      expect(controller.canUndo, isFalse);

      controller.previewMoveBy(const Offset(148, 0));
      expect(controller.snapIndexRevision, initialRevision);

      controller.commitTransform();
      expect(controller.snapIndexRevision, initialRevision + 1);
      expect(controller.canUndo, isTrue);
    });

    test('history limit counts completed actions exactly', () {
      final controller = ObjectCanvasController<String>(
        canvasSize: const Size(800, 600),
        historyLimit: 2,
        objects: [_object('a', position: const Offset(10, 10))],
      );
      for (final x in [11.0, 12.0, 13.0]) {
        controller.updateGeometries([
          CanvasGeometryValue(
            objectId: 'a',
            geometry: controller
                .requireObject('a')
                .geometry
                .copyWith(position: Offset(x, 10)),
          ),
        ]);
      }

      controller.undo();
      controller.undo();
      expect(
        controller.requireObject('a').geometry.position,
        const Offset(11, 10),
      );
      expect(controller.canUndo, isFalse);
    });

    test('resize snapping uses the prebuilt edge index', () {
      final builder = CanvasSnapIndexBuilder();
      const CanvasObjectSnapStrategy().buildIndex(
        const CanvasSnapScene(
          canvasBounds: Rect.fromLTWH(0, 0, 400, 300),
          objects: [
            CanvasSnapSceneObject(
              id: 'target',
              bounds: Rect.fromLTWH(100, 40, 50, 50),
            ),
          ],
        ),
        builder,
      );
      final result = const CanvasSnapEngine().resolveResize(
        CanvasSnapSession(
          index: builder.build(),
          excludedObjectIds: const {'moving'},
          configuration: CanvasSnapConfiguration(
            strategies: [CanvasObjectSnapStrategy()],
          ),
        ),
        const Rect.fromLTRB(20, 20, 97, 70),
        edges: const CanvasResizeEdges(right: true),
        canvasBounds: const Rect.fromLTWH(0, 0, 400, 300),
        minimumSize: const Size(24, 24),
      );

      expect(result.bounds.right, 100);
      expect(result.bounds.left, 20);
      expect(result.guides.single.source, CanvasSnapSource.object);
    });
  });
}

ObjectCanvasController<String> _controller() => ObjectCanvasController<String>(
  canvasSize: const Size(800, 600),
  objects: [
    _object('a', position: const Offset(10, 10)),
    _object('b', position: const Offset(100, 60)),
  ],
);

CanvasObject<String> _object(
  String id, {
  Offset position = Offset.zero,
  Size size = const Size(40, 30),
  CanvasObjectConstraints? constraints,
  CanvasObjectCapabilities? capabilities,
}) => CanvasObject<String>(
  id: id,
  data: id,
  geometry: CanvasObjectGeometry(position: position, size: size),
  constraints: constraints,
  capabilities: capabilities,
);

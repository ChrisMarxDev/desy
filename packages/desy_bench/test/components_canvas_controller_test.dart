import 'dart:ui';

import 'package:desy_bench/src/workbench/components_canvas/components_canvas_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canvas controller keeps composition state ephemeral and mutable', () {
    final controller = DesyComponentsCanvasController();

    final primary = controller.add(
      'harbor.button.primary.publish-schedule',
      knobValues: const {'label': 'Publish schedule'},
    );
    final card = controller.add('harbor.card.content.north-quay-clear');
    final artboard = controller.addArtboard(DesyCanvasArtboard.iPhone15Pro);
    final duplicatePrimary = controller.add(
      'harbor.button.primary.publish-schedule',
    );

    expect(controller.nodes.value.keys, [
      primary,
      card,
      artboard,
      duplicatePrimary,
    ]);
    expect(controller.selectedId.value, duplicatePrimary);
    expect(duplicatePrimary, isNot(primary));
    expect(controller.nodes.value[artboard]!.isArtboard, isTrue);

    final button = controller.nodes.value[primary]!;
    controller.update(
      button.copyWith(rect: const Rect.fromLTWH(120, 80, 300, 200)),
    );
    expect(controller.nodes.value[primary]!.rect.left, 120);

    controller.setKnob(primary, 'label', 'Save draft');
    expect(controller.nodes.value[primary]!.knobValues['label'], 'Save draft');

    controller.remove(card);
    expect(controller.nodes.value.containsKey(card), isFalse);

    controller.clear();
    expect(controller.nodes.value, isEmpty);
    expect(controller.selectedId.value, isNull);

    controller.dispose();
  });

  test('canvas nodes take an immutable snapshot of knob values', () {
    final values = <String, Object>{'label': 'Publish schedule'};
    final node = DesyCanvasNode.component(
      id: 'node',
      instanceId: 'button.publish',
      rect: const Rect.fromLTWH(0, 0, 100, 40),
      knobValues: values,
    );

    values['label'] = 'Save draft';

    expect(node.knobValues['label'], 'Publish schedule');
    expect(() => node.knobValues['label'] = 'Other', throwsUnsupportedError);
  });

  test('device artboards use physical frame geometry and attach by screen', () {
    final controller = DesyComponentsCanvasController();
    final phone = controller.addArtboard(DesyCanvasArtboard.iPhone15Pro);
    final artboard = controller.nodes.value[phone]!;
    final device = DesyCanvasGeometry.deviceFor(DesyCanvasArtboard.iPhone15Pro);
    final screen = DesyCanvasGeometry.screenSceneRect(artboard);

    expect(device.screenSize, const Size(393, 852));
    expect(device.frameSize, const Size(873, 1792));
    expect(
      artboard.rect.width / artboard.rect.height,
      closeTo(device.frameSize.width / device.frameSize.height, 0.0001),
    );

    final id = controller.add('button.default');
    final child = controller.nodes.value[id]!;
    expect(child.parentArtboardId, phone);
    expect(child.rect.center, device.screenSize.center(Offset.zero));

    controller.updateComponentFromSceneRect(
      child,
      Rect.fromCenter(center: screen.center, width: 80, height: 40),
    );
    expect(controller.nodes.value[id]!.parentArtboardId, phone);
    expect(
      DesyCanvasGeometry.logicalToScene(
        artboard,
        controller.nodes.value[id]!.rect,
      ).center,
      screen.center,
    );

    // The physical bezel is outside the attachment target.
    controller.updateComponentFromSceneRect(
      controller.nodes.value[id]!,
      Rect.fromLTWH(screen.left - 82, screen.top, 80, 40),
    );
    expect(controller.nodes.value[id]!.parentArtboardId, isNull);
    controller.dispose();
  });

  test('artboard removal detaches children at equivalent stage positions', () {
    final controller = DesyComponentsCanvasController();
    final artboardId = controller.addArtboard(DesyCanvasArtboard.iPadPro11);
    final childId = controller.add('card.default');
    final before = controller.sceneRectFor(controller.nodes.value[childId]!);

    controller.remove(artboardId);

    final child = controller.nodes.value[childId]!;
    expect(child.parentArtboardId, isNull);
    expect(child.rect, before);
    controller.dispose();
  });

  test(
    'screen hit testing rejects rounded corners and aspect locks every axis',
    () {
      final controller = DesyComponentsCanvasController();
      final id = controller.addArtboard(DesyCanvasArtboard.iPhone15Pro);
      final artboard = controller.nodes.value[id]!;
      final screen = DesyCanvasGeometry.screenSceneRect(artboard);
      expect(
        DesyCanvasGeometry.screenContains(artboard, screen.center),
        isTrue,
      );
      expect(
        DesyCanvasGeometry.screenContains(artboard, screen.topLeft),
        isFalse,
      );

      final ratio = artboard.rect.width / artboard.rect.height;
      for (final proposal in [
        artboard.rect.inflate(40),
        Rect.fromLTRB(
          artboard.rect.left - 40,
          artboard.rect.top,
          artboard.rect.right,
          artboard.rect.bottom,
        ),
        Rect.fromLTRB(
          artboard.rect.left,
          artboard.rect.top - 40,
          artboard.rect.right,
          artboard.rect.bottom,
        ),
        Rect.fromLTRB(
          artboard.rect.left,
          artboard.rect.top,
          artboard.rect.right + 40,
          artboard.rect.bottom,
        ),
        Rect.fromLTRB(
          artboard.rect.left,
          artboard.rect.top,
          artboard.rect.right,
          artboard.rect.bottom + 40,
        ),
      ]) {
        final locked = DesyCanvasGeometry.lockFrameAspect(artboard, proposal);
        expect(locked.width / locked.height, closeTo(ratio, 0.0001));
      }
      controller.dispose();
    },
  );

  test('new artboards fit a compact stage while retaining frame aspect', () {
    final controller = DesyComponentsCanvasController()
      ..setStageBounds(const Rect.fromLTWH(0, 0, 180, 240));
    final id = controller.addArtboard(DesyCanvasArtboard.iPadPro11);
    final rect = controller.nodes.value[id]!.rect;
    expect(rect.width, lessThanOrEqualTo(164));
    expect(rect.height, lessThanOrEqualTo(224));
    expect(rect.width / rect.height, closeTo(1741 / 2412, 0.0001));
    expect(_isContainedBy(const Rect.fromLTWH(0, 0, 180, 240), rect), isTrue);
    controller.dispose();
  });

  test('aspect-locked frame remains contained at every stage edge', () {
    final controller = DesyComponentsCanvasController();
    final id = controller.addArtboard(DesyCanvasArtboard.iPhone15Pro);
    final artboard = controller.nodes.value[id]!;
    const bounds = Rect.fromLTWH(0, 0, 180, 240);
    final ratio = artboard.rect.width / artboard.rect.height;

    for (final proposal in [
      Rect.fromLTWH(-80, 0, 280, 440),
      Rect.fromLTWH(40, -80, 280, 440),
      Rect.fromLTWH(80, 0, 280, 440),
      Rect.fromLTWH(0, 80, 280, 440),
    ]) {
      final locked = DesyCanvasGeometry.lockFrameAspect(
        artboard,
        proposal,
        clampingRect: bounds,
      );
      expect(_isContainedBy(bounds, locked), isTrue);
      expect(locked.width / locked.height, closeTo(ratio, 0.0001));
    }
    controller.dispose();
  });

  test(
    'aspect-locked resize reduces size at every boundary without moving its stationary edges',
    () {
      final controller = DesyComponentsCanvasController();
      final id = controller.addArtboard(DesyCanvasArtboard.iPhone15Pro);
      final artboard = controller.nodes.value[id]!;
      const bounds = Rect.fromLTWH(0, 0, 500, 600);
      final ratio = DesyCanvasGeometry.deviceFor(
        DesyCanvasArtboard.iPhone15Pro,
      ).frameSize.aspectRatio;
      final current = artboard.copyWith(
        rect: Rect.fromLTWH(200, 180, 300 * ratio, 300),
      );
      final cases = <String, (Rect, bool, bool)>{
        'right': (Rect.fromLTRB(200, 180, 900, 480), false, false),
        'left': (Rect.fromLTRB(-400, 180, 346, 480), true, false),
        'bottom': (Rect.fromLTRB(200, 180, 346, 900), false, false),
        'top': (Rect.fromLTRB(200, -400, 346, 480), false, true),
        'top-left': (Rect.fromLTRB(-400, -400, 346, 480), true, true),
        'top-right': (Rect.fromLTRB(200, -400, 900, 480), false, true),
        'bottom-left': (Rect.fromLTRB(-400, 180, 346, 900), true, false),
        'bottom-right': (Rect.fromLTRB(200, 180, 900, 900), false, false),
      };

      for (final entry in cases.entries) {
        final (proposal, rightAnchored, bottomAnchored) = entry.value;
        final locked = DesyCanvasGeometry.lockFrameAspect(
          current,
          proposal,
          clampingRect: bounds,
        );
        expect(_isContainedBy(bounds, locked), isTrue, reason: entry.key);
        expect(locked.width / locked.height, closeTo(ratio, 0.0001));
        expect(
          rightAnchored ? locked.right : locked.left,
          rightAnchored ? current.rect.right : current.rect.left,
          reason: entry.key,
        );
        expect(
          bottomAnchored ? locked.bottom : locked.top,
          bottomAnchored ? current.rect.bottom : current.rect.top,
          reason: entry.key,
        );
      }
      controller.dispose();
    },
  );

  test(
    'artboard fitting stays finite for zero and transitional stage bounds',
    () {
      for (final bounds in [
        const Rect.fromLTWH(0, 0, 0, 0),
        const Rect.fromLTWH(0, 0, 7, 7),
        const Rect.fromLTWH(0, 0, 4, 120),
        const Rect.fromLTWH(0, 0, 120, 4),
        const Rect.fromLTWH(0, 0, 12, 12),
      ]) {
        final controller = DesyComponentsCanvasController()
          ..setStageBounds(bounds);
        final id = controller.addArtboard(DesyCanvasArtboard.iPhone15Pro);
        final rect = controller.nodes.value[id]!.rect;
        expect(rect.left.isFinite && rect.top.isFinite, isTrue);
        expect(rect.width.isFinite && rect.height.isFinite, isTrue);
        expect(rect.width, greaterThanOrEqualTo(0));
        expect(rect.height, greaterThanOrEqualTo(0));
        expect(
          _isContainedBy(bounds, rect),
          isTrue,
          reason: '$bounds => $rect',
        );
        controller.dispose();
      }
    },
  );

  test('shrinking stage bounds normalizes existing artboards only', () {
    const wide = Rect.fromLTWH(0, 0, 900, 700);
    const compact = Rect.fromLTWH(0, 0, 180, 240);
    final controller = DesyComponentsCanvasController()..setStageBounds(wide);
    final artboardId = controller.addArtboard(DesyCanvasArtboard.iPhone15Pro);
    final childId = controller.add('button.default');
    final logicalChild = controller.nodes.value[childId]!.rect;
    final initial = controller.nodes.value[artboardId]!.rect;
    final ratio = initial.width / initial.height;

    controller.setStageBounds(compact);

    final normalized = controller.nodes.value[artboardId]!.rect;
    expect(_isContainedBy(compact, normalized), isTrue);
    expect(normalized.width.isFinite && normalized.height.isFinite, isTrue);
    expect(normalized.width, greaterThanOrEqualTo(0));
    expect(normalized.height, greaterThanOrEqualTo(0));
    expect(normalized.width / normalized.height, closeTo(ratio, 0.0001));
    expect(controller.nodes.value[childId]!.rect, logicalChild);

    controller.setStageBounds(wide);
    expect(controller.nodes.value[artboardId]!.rect, normalized);
    expect(controller.nodes.value[childId]!.rect, logicalChild);
    controller.dispose();
  });

  test('transient zero bounds preserve existing artboard geometry', () {
    const wide = Rect.fromLTWH(0, 0, 900, 700);
    final controller = DesyComponentsCanvasController()..setStageBounds(wide);
    final artboardId = controller.addArtboard(DesyCanvasArtboard.iPhone15Pro);
    final childId = controller.add('button.default');
    final artboardBefore = controller.nodes.value[artboardId]!;
    final childBefore = controller.nodes.value[childId]!;
    final sceneBefore = controller.sceneRectFor(childBefore);
    final screenBefore = DesyCanvasGeometry.screenSceneRect(artboardBefore);

    controller.setStageBounds(Rect.zero);
    controller.setStageBounds(wide);

    final artboardAfter = controller.nodes.value[artboardId]!;
    final childAfter = controller.nodes.value[childId]!;
    final sceneAfter = controller.sceneRectFor(childAfter);
    expect(artboardAfter.rect, artboardBefore.rect);
    expect(childAfter.rect, childBefore.rect);
    expect(sceneAfter, sceneBefore);
    expect(DesyCanvasGeometry.screenSceneRect(artboardAfter), screenBefore);
    expect(
      DesyCanvasGeometry.screenContains(artboardAfter, screenBefore.center),
      isTrue,
    );

    final zeroController = DesyComponentsCanvasController()
      ..setStageBounds(Rect.zero);
    final zeroId = zeroController.addArtboard(DesyCanvasArtboard.iPhone15Pro);
    final zeroArtboard = zeroController.nodes.value[zeroId]!;
    expect(
      DesyCanvasGeometry.screenContains(zeroArtboard, Offset.zero),
      isFalse,
    );
    final zeroLogical = DesyCanvasGeometry.sceneToLogical(
      zeroArtboard,
      Rect.zero,
    );
    expect(zeroLogical.left.isFinite && zeroLogical.top.isFinite, isTrue);
    expect(zeroLogical.width.isFinite && zeroLogical.height.isFinite, isTrue);

    zeroController.setStageBounds(wide);
    final recovered = zeroController.nodes.value[zeroId]!;
    expect(recovered.rect.width, greaterThan(0));
    expect(recovered.rect.height, greaterThan(0));
    expect(_isContainedBy(wide, recovered.rect), isTrue);
    expect(
      DesyCanvasGeometry.screenContains(
        recovered,
        DesyCanvasGeometry.screenSceneRect(recovered).center,
      ),
      isTrue,
    );
    zeroController.dispose();
    controller.dispose();
  });
}

bool _isContainedBy(Rect bounds, Rect rect) =>
    rect.left >= bounds.left &&
    rect.top >= bounds.top &&
    rect.right <= bounds.right &&
    rect.bottom <= bounds.bottom;

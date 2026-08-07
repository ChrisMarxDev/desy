import 'dart:ui';

import 'package:desy_bench/src/workbench/components_canvas/components_canvas_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canvas controller keeps a flat ephemeral stack', () {
    final controller = DesyComponentsCanvasController();

    final primary = controller.add(
      'acme.button.primary.publish-schedule',
      knobValues: const {'label': 'Publish schedule'},
    );
    final artboard = controller.addArtboard(DesyCanvasArtboard.iPhone15Pro);
    final duplicate = controller.add('acme.button.primary.publish-schedule');

    expect(controller.nodes.value.keys, [primary, artboard, duplicate]);
    expect(controller.selectedId.value, duplicate);
    expect(duplicate, isNot(primary));
    expect(controller.nodes.value[artboard]!.isArtboard, isTrue);

    final button = controller.nodes.value[primary]!;
    controller.update(
      button.copyWith(rect: const Rect.fromLTWH(120, 80, 300, 200)),
    );
    controller.setKnob(primary, 'label', 'Save draft');
    expect(controller.nodes.value[primary]!.rect.left, 120);
    expect(controller.nodes.value[primary]!.knobValues['label'], 'Save draft');

    controller.remove(artboard);
    expect(controller.nodes.value.containsKey(artboard), isFalse);
    expect(controller.nodes.value.containsKey(primary), isTrue);

    controller.clear();
    expect(controller.nodes.value, isEmpty);
    expect(controller.selectedId.value, isNull);
    controller.dispose();
  });

  test('canvas seeds a component node with its declared default size', () {
    final controller = DesyComponentsCanvasController();

    final declared = controller.add(
      'button.declared',
      defaultSize: const Size(300, 48),
    );
    final fallback = controller.add('button.fallback');

    expect(
      controller.nodes.value[declared]!.rect.size,
      const Size(300, 48),
    );
    expect(
      controller.nodes.value[fallback]!.rect.size,
      const Size(220, 120),
    );
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

  test('transient geometry notifies only its node until committed', () {
    final controller = DesyComponentsCanvasController();
    final firstId = controller.add('button.first');
    final secondId = controller.add('button.second');
    final firstSignal = controller.nodeListenable(firstId)!;
    final secondSignal = controller.nodeListenable(secondId)!;
    var firstNotifications = 0;
    var secondNotifications = 0;
    firstSignal.addListener(() => firstNotifications++);
    secondSignal.addListener(() => secondNotifications++);
    final committedBefore = controller.nodes.value;
    final firstBefore = committedBefore[firstId]!;
    final transient = firstBefore.copyWith(
      rect: firstBefore.rect.shift(const Offset(24, 16)),
    );

    controller.updateTransient(transient);

    expect(controller.nodes.value, same(committedBefore));
    expect(controller.nodes.value[firstId]!.rect, firstBefore.rect);
    expect(controller.nodeValue(firstId)!.rect, transient.rect);
    expect(firstNotifications, 1);
    expect(secondNotifications, 0);

    controller.commitInteraction(transient);

    expect(controller.nodes.value, isNot(same(committedBefore)));
    expect(controller.nodes.value[firstId]!.rect, transient.rect);
    expect(controller.nodeValue(firstId)!.rect, transient.rect);
    expect(firstNotifications, 1);
    expect(secondNotifications, 0);
    controller.dispose();
  });

  test('layout presets accept instances only in their declared slots', () {
    final controller = DesyComponentsCanvasController()
      ..setStageBounds(const Rect.fromLTWH(0, 0, 900, 700));
    final layoutId = controller.addLayout(
      DesyCanvasLayoutPreset.singleColumn,
      spacingEntryId: 'space.default',
      spacing: 16,
    );

    final first = controller.add('button.primary');
    final second = controller.add('card.status');
    final third = controller.add('input.search');
    final overflow = controller.add('badge.info');

    expect(controller.nodes.value[layoutId]!.isLayout, isTrue);
    expect(controller.nodes.value[layoutId]!.spacingEntryId, 'space.default');
    expect(controller.nodes.value[first]!.parentLayoutId, layoutId);
    expect(controller.nodes.value[first]!.slotIndex, 0);
    expect(controller.nodes.value[second]!.slotIndex, 1);
    expect(controller.nodes.value[third]!.slotIndex, 2);
    expect(controller.nodes.value[overflow]!.parentLayoutId, isNull);

    controller.setLayoutSpacing(
      layoutId,
      spacingEntryId: 'space.section',
      spacing: 24,
    );
    expect(controller.nodes.value[layoutId]!.spacing, 24);
    expect(controller.nodes.value[layoutId]!.spacingEntryId, 'space.section');

    controller.remove(layoutId);
    expect(controller.nodes.value.containsKey(layoutId), isFalse);
    expect(controller.nodes.value.containsKey(first), isFalse);
    expect(controller.nodes.value.containsKey(second), isFalse);
    expect(controller.nodes.value.containsKey(third), isFalse);
    expect(controller.nodes.value.containsKey(overflow), isTrue);
    controller.dispose();
  });

  test('components and bezels remain independent when they overlap', () {
    final controller = DesyComponentsCanvasController();
    final artboardId = controller.addArtboard(DesyCanvasArtboard.iPhone15Pro);
    final componentId = controller.add('button.default');
    const overlap = Rect.fromLTWH(96, 120, 160, 80);
    controller.update(
      controller.nodes.value[componentId]!.copyWith(rect: overlap),
    );

    final componentBefore = controller.nodes.value[componentId]!.rect;
    final artboard = controller.nodes.value[artboardId]!;
    controller.update(
      artboard.copyWith(rect: artboard.rect.shift(const Offset(80, 40))),
    );

    expect(controller.nodes.value[componentId]!.rect, componentBefore);

    controller.remove(artboardId);
    expect(controller.nodes.value[componentId]!.rect, componentBefore);
    controller.dispose();
  });

  test('device bezels use physical frame aspect', () {
    final controller = DesyComponentsCanvasController();
    final phone = controller.addArtboard(DesyCanvasArtboard.iPhone15Pro);
    final artboard = controller.nodes.value[phone]!;
    final device = DesyCanvasGeometry.deviceFor(DesyCanvasArtboard.iPhone15Pro);

    expect(device.screenSize, const Size(393, 852));
    expect(device.frameSize, const Size(873, 1792));
    expect(
      artboard.rect.size.aspectRatio,
      closeTo(device.frameSize.aspectRatio, 0.0001),
    );
    controller.dispose();
  });

  test('new bezels fit a compact stage while retaining frame aspect', () {
    final controller = DesyComponentsCanvasController()
      ..setStageBounds(const Rect.fromLTWH(0, 0, 180, 240));
    final id = controller.addArtboard(DesyCanvasArtboard.iPadPro11);
    final rect = controller.nodes.value[id]!.rect;
    expect(rect.width, lessThanOrEqualTo(164));
    expect(rect.height, lessThanOrEqualTo(224));
    expect(rect.size.aspectRatio, closeTo(1741 / 2412, 0.0001));
    expect(_isContainedBy(const Rect.fromLTWH(0, 0, 180, 240), rect), isTrue);
    controller.dispose();
  });

  test('aspect-locked bezel remains contained at every stage edge', () {
    final controller = DesyComponentsCanvasController();
    final id = controller.addArtboard(DesyCanvasArtboard.iPhone15Pro);
    final artboard = controller.nodes.value[id]!;
    const bounds = Rect.fromLTWH(0, 0, 180, 240);
    final ratio = artboard.rect.size.aspectRatio;

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
      expect(locked.size.aspectRatio, closeTo(ratio, 0.0001));
    }
    controller.dispose();
  });

  test('bezel fitting stays finite for transitional stage bounds', () {
    for (final bounds in [
      const Rect.fromLTWH(0, 0, 0, 0),
      const Rect.fromLTWH(0, 0, 7, 7),
      const Rect.fromLTWH(0, 0, 4, 120),
      const Rect.fromLTWH(0, 0, 120, 4),
    ]) {
      final controller = DesyComponentsCanvasController()
        ..setStageBounds(bounds);
      final id = controller.addArtboard(DesyCanvasArtboard.iPhone15Pro);
      final rect = controller.nodes.value[id]!.rect;
      expect(rect.left.isFinite && rect.top.isFinite, isTrue);
      expect(rect.width.isFinite && rect.height.isFinite, isTrue);
      expect(_isContainedBy(bounds, rect), isTrue, reason: '$bounds => $rect');
      controller.dispose();
    }
  });

  test('stage shrinking normalizes bezels without moving components', () {
    const wide = Rect.fromLTWH(0, 0, 900, 700);
    const compact = Rect.fromLTWH(0, 0, 180, 240);
    final controller = DesyComponentsCanvasController()..setStageBounds(wide);
    final artboardId = controller.addArtboard(DesyCanvasArtboard.iPhone15Pro);
    final componentId = controller.add('button.default');
    final componentRect = controller.nodes.value[componentId]!.rect;
    final initial = controller.nodes.value[artboardId]!.rect;

    controller.setStageBounds(compact);

    final normalized = controller.nodes.value[artboardId]!.rect;
    expect(_isContainedBy(compact, normalized), isTrue);
    expect(
      normalized.size.aspectRatio,
      closeTo(initial.size.aspectRatio, 0.0001),
    );
    expect(controller.nodes.value[componentId]!.rect, componentRect);

    controller.setStageBounds(wide);
    expect(controller.nodes.value[artboardId]!.rect, normalized);
    expect(controller.nodes.value[componentId]!.rect, componentRect);
    controller.dispose();
  });

  test('transient zero bounds preserve existing bezel geometry', () {
    const wide = Rect.fromLTWH(0, 0, 900, 700);
    final controller = DesyComponentsCanvasController()..setStageBounds(wide);
    final id = controller.addArtboard(DesyCanvasArtboard.iPhone15Pro);
    final before = controller.nodes.value[id]!.rect;

    controller.setStageBounds(Rect.zero);
    controller.setStageBounds(wide);

    expect(controller.nodes.value[id]!.rect, before);
    controller.dispose();
  });
}

bool _isContainedBy(Rect bounds, Rect rect) =>
    rect.left >= bounds.left &&
    rect.top >= bounds.top &&
    rect.right <= bounds.right &&
    rect.bottom <= bounds.bottom;

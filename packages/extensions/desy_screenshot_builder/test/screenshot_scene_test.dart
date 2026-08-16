import 'dart:typed_data';

import 'package:desy_bench/desy_bench.dart';
import 'package:desy_screenshot_builder/src/screenshot_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scene layers are ephemeral, ordered, hideable, and removable', () {
    final registry = _registry();
    final controller = DesyScreenshotSceneController(
      themeId: 'light',
      backgroundColor: Colors.white,
    );
    addTearDown(controller.dispose);

    final first = controller.addWidget(registry.allComponentInstances.single);
    final second = controller.addText(typographyId: 'body', colorId: 'ink');

    expect(controller.layers.map((layer) => layer.id), [first, second]);
    expect(controller.selectedId, second);

    controller.moveBackward(second);
    expect(controller.layers.map((layer) => layer.id), [second, first]);

    controller.toggleHidden(second);
    expect(controller.layerById(second)!.hidden, isTrue);

    controller.remove(first);
    expect(controller.layers.map((layer) => layer.id), [second]);
  });

  test(
    'widget scale changes visual size but preserves logical constraints',
    () {
      final registry = _registry();
      final controller = DesyScreenshotSceneController(themeId: 'light');
      addTearDown(controller.dispose);
      final id = controller.addWidget(registry.allComponentInstances.single);
      final layer = controller.layerById(id)! as DesyScreenshotWidgetLayer;
      final logicalSize = layer.logicalSize;

      controller.setWidgetScale(id, .5);

      expect(layer.scale, .5);
      expect(layer.logicalSize, logicalSize);
      expect(layer.rect.size, logicalSize * .5);
    },
  );

  test('two widget layers retain independent knob values', () {
    final registry = _registry();
    final controller = DesyScreenshotSceneController(themeId: 'light');
    addTearDown(controller.dispose);
    final instance = registry.allComponentInstances.single;
    final first = controller.addWidget(instance);
    final second = controller.addWidget(instance);

    controller.setKnob(first, 'label', 'First');

    final firstLayer =
        controller.layerById(first)! as DesyScreenshotWidgetLayer;
    final secondLayer =
        controller.layerById(second)! as DesyScreenshotWidgetLayer;
    expect(firstLayer.knobValues['label'], 'First');
    expect(secondLayer.knobValues['label'], 'Default');
  });

  test('image and page geometry remain editable logical values', () {
    final controller = DesyScreenshotSceneController(themeId: 'light');
    addTearDown(controller.dispose);
    final id = controller.addImage(
      bytes: Uint8List.fromList([1, 2, 3]),
      name: 'hero.png',
      naturalSize: const Size(800, 400),
    );

    controller.resize(id, const Size(320, 180));
    controller.setCanvasSize(const Size(900, 500));

    expect(controller.layerById(id)!.rect.size, const Size(320, 180));
    expect(controller.canvasSize, const Size(900, 500));
  });
}

DesyRegistry _registry() {
  final component = DesyComponent<({Knob<String> label})>(
    id: 'label',
    name: 'Label',
    defaultSize: const Size(200, 80),
    knobs: (scope) =>
        (label: scope.string('label', name: 'Label', initial: 'Default')),
    build: (context, knobs) => Text(knobs.label.value),
    instances: (knobs) => {'default': const []},
  );
  return DesyRegistry(
    name: 'Test',
    themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
    colors: const [DesyColorEntry(id: 'ink', name: 'Ink', color: Colors.black)],
    fonts: const [
      DesyTypographyEntry(id: 'body', name: 'Body', builder: _buildBody),
    ],
    components: [component],
  );
}

Widget _wrap(BuildContext context, Widget child) => child;
Widget _buildBody(BuildContext context, String text) => Text(text);

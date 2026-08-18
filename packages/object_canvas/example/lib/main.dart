import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:object_canvas/object_canvas.dart';

void main() => runApp(const DemoApp());

sealed class DemoElement {
  const DemoElement();
}

final class DemoText extends DemoElement {
  const DemoText(this.value);
  final String value;
}

final class DemoImage extends DemoElement {
  DemoImage(String base64) : bytes = base64Decode(base64);
  final Uint8List bytes;
}

final class DemoWidget extends DemoElement {
  const DemoWidget(this.child);
  final Widget child;
}

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  late final ObjectCanvasController<DemoElement>
  controller = ObjectCanvasController<DemoElement>(
    canvasSize: const Size(960, 540),
    objects: [
      const CanvasObject(
        id: 'title',
        data: DemoText('A small canvas with a serious API.'),
        geometry: CanvasObjectGeometry(
          position: Offset(72, 64),
          size: Size(560, 72),
        ),
      ),
      CanvasObject(
        id: 'pixel',
        data: DemoImage(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9ZQmcAAAAASUVORK5CYII=',
        ),
        geometry: const CanvasObjectGeometry(
          position: Offset(72, 176),
          size: Size(360, 220),
        ),
      ),
      const CanvasObject(
        id: 'widget',
        data: DemoWidget(
          Card(child: Center(child: Text('Any real Flutter widget'))),
        ),
        geometry: CanvasObjectGeometry(
          position: Offset(520, 176),
          size: Size(300, 180),
          rotation: -0.06,
        ),
      ),
    ],
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: const Color(0xFF2563EB)),
    home: Scaffold(
      body: Row(
        children: [
          Expanded(
            child: ObjectCanvas<DemoElement>(
              controller: controller,
              autofocus: true,
              semanticLabelBuilder: (object) => 'Demo ${object.id}',
              objectBuilder: (context, object) => switch (object.data) {
                DemoText(:final value) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                DemoImage(:final bytes) => Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                ),
                DemoWidget(:final child) => child,
              },
            ),
          ),
          SizedBox(
            width: 260,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) => ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'External controls',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<CanvasTransformMode>(
                    segments: const [
                      ButtonSegment(
                        value: CanvasTransformMode.layoutResize,
                        label: Text('Layout'),
                      ),
                      ButtonSegment(
                        value: CanvasTransformMode.transformScale,
                        label: Text('Scale'),
                      ),
                    ],
                    selected: {controller.transformMode},
                    onSelectionChanged: (value) =>
                        controller.setTransformMode(value.single),
                  ),
                  const SizedBox(height: 16),
                  Text('Selected: ${controller.selectedObjectIds.join(', ')}'),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: controller.canUndo ? controller.undo : null,
                    child: const Text('Undo'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: controller.canRedo ? controller.redo : null,
                    child: const Text('Redo'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

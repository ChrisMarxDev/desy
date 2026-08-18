# object_canvas

A finite, controller-driven Flutter canvas for arranging arbitrary widgets.

`object_canvas` provides the reusable interaction layer behind image editors,
diagram tools, screenshot builders, slide editors, page composers, and other
finite-stage experiences. Your application owns the object data and surrounding
editor UI; the package owns canvas mechanics.

## Features

- Render arbitrary typed data as real Flutter widgets.
- Deny, clip, or visibly show object overflow beyond finite canvas bounds.
- Move, rotate, logically resize, or uniformly scale objects.
- Keep widget layout size separate from paint scale.
- Select by click, modifier click, marquee, or controller API.
- Move multiple selected objects as one undoable action.
- Snap to canvas bounds, object edges and centers, grids, or custom targets.
- Pan and zoom with Flutter's `InteractiveViewer` and
  `TransformationController`.
- Reorder objects with undoable front, back, forward, and backward commands.
- Preview gestures without mutating committed document state.
- Rebuild object content only when its geometry, data, or declared policy
  changes during controller updates.
- Undo and redo typed object, data, geometry, and order changes.
- Render the finite canvas to a `ui.Image` or PNG bytes.
- Customize canvas colors, selection chrome, guides, handles, semantics, and
  object visibility.

The package intentionally does **not** include a sidebar, inspector, toolbar,
file picker, persistence format, or export destination. Those remain host
application concerns.

## Installation

Add `object_canvas` to your `pubspec.yaml`:

```yaml
dependencies:
  object_canvas: ^0.1.0
```

During local development, a path dependency works as well:

```yaml
dependencies:
  object_canvas:
    path: ../object_canvas
```

Then import the public library:

```dart
import 'package:object_canvas/object_canvas.dart';
```

## Quick start

Define application-owned data. It does not need to extend a package class:

```dart
sealed class EditorElement {
  const EditorElement();
}

final class TextElement extends EditorElement {
  const TextElement(this.text);

  final String text;
}
```

Create one controller, populate it with immutable canvas objects, and dispose
it with its owner:

```dart
late final ObjectCanvasController<EditorElement> controller =
    ObjectCanvasController<EditorElement>(
  canvasSize: const Size(1200, 630),
  objects: const [
    CanvasObject(
      id: 'title',
      data: TextElement('Build on a serious canvas.'),
      geometry: CanvasObjectGeometry(
        position: Offset(80, 64),
        size: Size(640, 96),
      ),
    ),
  ],
);

@override
void dispose() {
  controller.dispose();
  super.dispose();
}
```

For host UI that starts from application data, let the controller create and
place the canvas object:

```dart
controller.addObjectData(
  id: 'hero',
  data: ImageElement(bytes),
  size: const Size(360, 240),
  center: dropPointInCanvasCoordinates,
);
```

Render the finite canvas. The builder receives the typed object and its current
preview geometry:

```dart
ObjectCanvas<EditorElement>(
  controller: controller,
  autofocus: true,
  semanticLabelBuilder: (object) => 'Canvas object ${object.id}',
  objectBuilder: (context, object) => switch (object.data) {
    TextElement(:final text) => Align(
      alignment: Alignment.centerLeft,
      child: Text(text),
    ),
  },
)
```

`objectBuilder` remains a plain typed callback, but it runs inside a stable
per-object widget. Controller notifications update an inherited model keyed by
object ID, so a drag preview for one object does not invoke builders for every
other object. Selection and resolved capability changes update only the package
wrapper and reuse the existing content widget. Replacing `objectBuilder`
deliberately rebuilds every object.

If every object already contains a widget, use the convenience constructor:

```dart
final controller = ObjectCanvasController<Widget>(
  canvasSize: const Size(800, 600),
  objects: const [
    CanvasObject(
      id: 'card',
      data: Card(child: Center(child: Text('Any Flutter widget'))),
      geometry: CanvasObjectGeometry(
        position: Offset(80, 80),
        size: Size(320, 180),
      ),
    ),
  ],
);

ObjectCanvas<Widget>.widgets(controller: controller)
```

## The object model

`CanvasObject<T>` combines stable identity, host-owned data, geometry, and
optional per-object policy overrides:

```dart
CanvasObject<ImageElement>(
  id: 'hero-image',
  data: ImageElement(/* application data */),
  geometry: const CanvasObjectGeometry(
    position: Offset(80, 64),
    size: Size(640, 360),
    rotation: 0,             // radians around pivot
    scale: 1,                // paint transform
    pivot: Alignment.center,
  ),
  capabilities: const CanvasObjectCapabilities(
    movable: true,
    resizable: true,
    scalable: true,
    rotatable: true,
  ),
)
```

Geometry fields have distinct jobs:

| Field | Meaning |
| --- | --- |
| `position` | Logical top-left position in canvas coordinates. |
| `size` | Real widget layout size and constraints. |
| `rotation` | Clockwise paint rotation in radians. |
| `scale` | Uniform paint scale; layout constraints stay unchanged. |
| `pivot` | Alignment used as the rotation and scale origin. |

Use `geometry.layoutBounds` for untransformed layout bounds and
`geometry.paintBounds` or `geometry.paintCorners` for transformed geometry.

### Defaults and per-object overrides

Most documents should define constraints and capabilities once on the
controller:

```dart
final controller = ObjectCanvasController<EditorElement>(
  canvasSize: const Size(1200, 630),
  overflow: CanvasOverflow.clip,
  defaults: const CanvasObjectDefaults(
    constraints: CanvasObjectConstraints(
      minSize: Size(24, 24),
      maxSize: Size.infinite,
    ),
    capabilities: CanvasObjectCapabilities(),
  ),
);
```

Set `constraints` or `capabilities` on an individual `CanvasObject` only when
it differs. `CanvasObjectCapabilities.locked()` keeps an object selectable but
disables move, resize, scale, and rotation.

### Overflow

Finite canvases deny overflow by default. Set the controller's `overflow`
policy when a document needs elements to cross the canvas edge:

| Policy | Geometry outside bounds | Painting outside bounds |
| --- | --- | --- |
| `CanvasOverflow.deny` | Direct manipulation is constrained | Clipped |
| `CanvasOverflow.clip` | Allowed | Clipped |
| `CanvasOverflow.show` | Allowed | Visible within the viewport |

Change the policy at runtime with `controller.setOverflow(...)`. The change
preserves object geometry and does not enter undo history. Export remains the
finite canvas size in every mode, so pixels outside its bounds are not included
in PNG output.

## Controller API

`ObjectCanvasController<T>` is the single owner of document, selection,
viewport, preview, snapping, and history state. `ObjectCanvas<T>` is a view over
that controller; it does not accept a competing object list or mutation
callback.

Listen with `AnimatedBuilder`, `ListenableBuilder`, or `addListener` when
building inspectors and scene panels:

```dart
ListenableBuilder(
  listenable: controller,
  builder: (context, child) => Text(
    'Selected: ${controller.selectedObjectIds.join(', ')}',
  ),
)
```

### Add, update, and remove

All document mutation methods accept collections. Each call creates at most one
history entry:

```dart
controller.addObjects([newObject]);

controller.updateGeometries([
  CanvasGeometryValue(
    objectId: 'title',
    geometry: controller.requireObject('title').geometry.copyWith(
      position: const Offset(120, 96),
    ),
  ),
], label: 'Move title');

controller.updateData([
  const CanvasDataValue(
    objectId: 'title',
    data: TextElement('Updated copy'),
  ),
], label: 'Edit title');

controller.removeObjects(['title']);
```

No-op changes are discarded. Operations that require existing objects validate
their IDs before committing a change.

### Selection

Selection can be controlled from the canvas or host UI:

```dart
controller.setSelectedObjects(['title', 'hero-image']);
controller.selectObjects(
  ['caption'],
  mode: CanvasSelectionMode.add,
);
controller.clearSelection();
```

Use `onSelectionChanged` for an external details panel. Set
`multiSelectionEnabled: false` when a host permits only one selected object.

V1 supports multi-object movement. Resize, paint-scale, and rotation handles
operate on one selected object at a time.

### Z-order

The object list is painted back to front: earlier entries are behind later
entries. Each command accepts multiple IDs, preserves their relative order, and
creates one undoable reorder action:

```dart
controller.bringObjectsToFront(['title', 'caption']);
controller.sendObjectsToBack(['background']);
controller.moveObjectsForward(['hero-image']);
controller.moveObjectsBackward(['hero-image']);
```

## Layout resize and transform scale

The active mode decides what the eight resize handles change:

```dart
controller.setTransformMode(CanvasTransformMode.layoutResize);
controller.setTransformMode(CanvasTransformMode.transformScale);
```

- `layoutResize` changes `geometry.size`, so the child receives new Flutter
  layout constraints.
- `transformScale` changes `geometry.scale`, so the child keeps its existing
  layout constraints and is scaled during painting.

The same oriented transform-box implementation handles unrotated and rotated
objects. Rotation never switches to a separate interaction path.

## Ephemeral gestures and history

Pointer movement updates draft geometry only. Committed objects and history are
unchanged until pointer-up:

1. A gesture starts a transform session.
2. Preview frames are exposed through `controller.geometryFor(id)`.
3. Pointer-up commits changed fields as one sparse `CanvasTransformAction`.
4. Cancellation drops the preview without creating history.

Host-defined gestures can use the same contract:

```dart
controller.beginTransform(CanvasTransformKind.move, ['title', 'caption']);
controller.previewMoveBy(const Offset(24, 12));
controller.commitTransform(label: 'Move heading');

// Or discard the draft:
controller.cancelTransform();
```

History is in memory and defaults to 100 actions:

```dart
if (controller.canUndo) controller.undo();
if (controller.canRedo) controller.redo();

final event = controller.lastActionEvent;
```

The implementation uses the `undo` package internally, but dependency types do
not leak into the public API.

## Snapping

Default snapping includes:

- canvas edges and centers;
- object edges and centers;
- an 8 logical-pixel grid.

Snap targets are indexed when stable scene geometry changes. Drag frames query
the frozen index instead of recalculating the scene on every pointer update.
Acquire and release distances are defined in screen pixels and adjusted for the
current viewport scale.

Choose the built-in strategies you need:

```dart
final controller = ObjectCanvasController<EditorElement>(
  canvasSize: const Size(1200, 630),
  snapConfiguration: CanvasSnapConfiguration(
    strategies: const [
      CanvasBoundarySnapStrategy(),
      CanvasObjectSnapStrategy(),
      CanvasGridSnapStrategy(step: 16),
    ],
    acquireDistance: 6,
    releaseDistance: 10,
  ),
);
```

Implement `CanvasSnapStrategy` to add application-specific anchors. Strategies
run when the stable index is built, never during a drag:

```dart
final class BaselineSnapStrategy implements CanvasSnapStrategy {
  const BaselineSnapStrategy(this.y);

  final double y;

  @override
  void buildIndex(CanvasSnapScene scene, CanvasSnapIndexBuilder builder) {
    builder.addLine(
      id: 'baseline',
      axis: CanvasSnapAxis.y,
      coordinate: y,
      spanStart: scene.canvasBounds.left,
      spanEnd: scene.canvasBounds.right,
      source: CanvasSnapSource.custom,
      priority: 5,
      matchesAnyAnchor: true,
    );
  }
}
```

Hold Alt during a pointer move to bypass snapping temporarily.

## Viewport and coordinate conversion

The controller exposes Flutter's native `TransformationController`:

```dart
final canvasPosition = controller.viewportController.toScene(viewportPosition);
controller.viewportController.value = nextCameraMatrix;
```

Configure camera behavior on the widget:

```dart
ObjectCanvas<EditorElement>(
  controller: controller,
  objectBuilder: buildObject,
  minScale: 0.1,
  maxScale: 8,
  panEnabled: true,
  scaleEnabled: true,
  viewportBoundaryMargin: const EdgeInsets.all(1000),
)
```

## Appearance and host integration

`ObjectCanvasStyle` controls the viewport, exported canvas background,
selection frames, snap guides, marquee, and transform handles:

```dart
ObjectCanvas<EditorElement>(
  controller: controller,
  objectBuilder: buildObject,
  style: const ObjectCanvasStyle(
    viewportColor: Color(0xFFF1F3F5),
    canvasColor: Color(0xFFFFFFFF),
    selectionColor: Color(0xFF2563EB),
    guideColor: Color(0xFFF43F5E),
  ),
  underlayBuilder: (context, controller) => const Checkerboard(),
  overlayBuilder: (context, controller) => const CanvasBorder(),
  objectVisibility: (object) => !isHidden(object.id),
  semanticLabelBuilder: (object) => object.id,
)
```

`underlayBuilder` and `overlayBuilder` are stage decorations outside the export
boundary. A filtered object is omitted from rendering, hit testing, marquee
selection, transform handles, and export.

## Rendering images

The controller can capture a mounted canvas:

```dart
await WidgetsBinding.instance.endOfFrame;
final pngBytes = await controller.renderPng(pixelRatio: 2);
```

Or request a `ui.Image`:

```dart
final image = await controller.renderToImage(pixelRatio: 1);
try {
  // Encode, share, or process the image.
} finally {
  image.dispose();
}
```

The render boundary contains the finite `canvasColor` and visible object
widgets. It excludes selection frames, handles, snap guides, marquee,
underlays, overlays, viewport chrome, and host UI. At pixel ratio 1, output
pixels match logical canvas dimensions.

Rendering before an `ObjectCanvas` is mounted throws `StateError`. File names,
downloads, filesystem writes, and share sheets are deliberately host-owned.

## Keyboard and pointer interaction

Set `autofocus: true`, or focus the canvas by clicking an object, to enable
keyboard commands.

| Input | Action |
| --- | --- |
| Click | Select one object. |
| Shift/Ctrl/Cmd + click | Toggle an object in the selection. |
| Drag empty canvas | Marquee select. |
| Shift/Ctrl/Cmd + marquee | Add to the selection. |
| Drag selected object | Move every movable selected object. |
| Shift + resize | Preserve the gesture-start aspect ratio. |
| Ctrl/Cmd + resize | Resize or scale symmetrically around the object center. |
| Shift + Ctrl/Cmd + resize | Preserve ratio while resizing around the center. |
| Alt + move/resize | Bypass snapping for the active gesture. |
| Arrow keys | Nudge movable selected objects by 1 logical pixel. |
| Shift + arrow keys | Nudge by 10 logical pixels. |
| Delete/Backspace | Remove selected objects. |
| Ctrl/Cmd + Z | Undo. |
| Ctrl/Cmd + Shift + Z | Redo. |
| Escape | Cancel the active transform or clear selection. |

## Current scope

Version 0.1 is intentionally focused:

- The canvas is finite; the surrounding editor is not part of the package.
- Multi-selection supports shared movement, not group resize or rotation.
- Scaling is uniform.
- History is ephemeral and is not a persistence format.
- Object data serialization belongs to the host application.
- Export captures Flutter-rendered canvas content; file delivery belongs to the
  host.

## Example

The bundled example mixes text data, image bytes, and arbitrary Flutter widgets
while keeping its property controls outside the canvas:

```sh
cd example
flutter run
```

Its source is in [`example/lib/main.dart`](example/lib/main.dart).

## API documentation

Every exported member has Dartdoc. Missing public API documentation is enforced
by package analysis:

```sh
flutter analyze
flutter test
dart doc
```

See the generated API reference for the complete contracts of
`ObjectCanvasController`, `CanvasObject`, `CanvasObjectGeometry`, canvas
actions, and snapping primitives.

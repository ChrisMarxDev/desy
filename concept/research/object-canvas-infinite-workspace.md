# Infinite workspace support for `object_canvas`

Research date: 2026-08-17

## Recommendation

Add an **unbounded workspace mode**, but do not emulate one with an
`int`-maximum or `double.maxFinite`-sized Flutter box.

The durable model is:

- object geometry remains in signed scene coordinates;
- the camera may pan without a boundary;
- the widget tree renders a finite window around the viewport;
- distant objects are culled or spatially queried;
- large camera translations are periodically rebased internally; and
- exporting an unbounded workspace always requires a finite region.

Keep the current finite mode. It is the right default for artboards and for the
screenshot builder. Unbounded mode then supports whiteboards, diagram editors,
node graphs, mood boards, and multiple-artboard applications without weakening
the finite-canvas contract.

## What Rody Davis's implementation establishes

Rody Davis's [`infinite_canvas`](https://pub.dev/packages/infinite_canvas)
package is based on the same Flutter primitives already used by
`object_canvas`. At repository commit
[`7bbda53`](https://github.com/rodydavis/infinite_canvas/tree/7bbda53ae5fb9941c046c0bc14363f3d3e489f63),
its canvas:

1. uses
   [`InteractiveViewer.builder`](https://github.com/rodydavis/infinite_canvas/blob/7bbda53ae5fb9941c046c0bc14363f3d3e489f63/lib/src/presentation/view/canvas.dart)
   rather than a fixed `InteractiveViewer` child;
2. passes `EdgeInsets.all(double.infinity)` as `boundaryMargin`;
3. converts the builder's visible scene-space `Quad` into an axis-aligned
   viewport rectangle;
4. can filter nodes to those overlapping that rectangle;
5. paints only the visible part of its repeating grid; and
6. converts pointer positions using `TransformationController.toScene`.

These are useful patterns. In particular, Flutter explicitly documents that an
all-infinite
[`InteractiveViewer.boundaryMargin`](https://api.flutter.dev/flutter/widgets/InteractiveViewer/boundaryMargin.html)
means that there are no pan boundaries. Flutter also describes
[`InteractiveViewer.builder`](https://api.flutter.dev/flutter/widgets/InteractiveViewer/InteractiveViewer.builder.html)
as an on-demand child that can change in response to the current transform; its
builder receives the visible viewport as a scene-space `Quad`.

The Rody implementation is not a complete architecture to copy. Its child is a
`SizedBox` whose size is derived from the union of current node bounds, and its
visibility filter scans every node. It also handles selection and movement from
a parent `Listener`. That last detail matters because a standard
[`RenderBox.hitTest`](https://api.flutter.dev/flutter/rendering/RenderBox/hitTest.html)
only descends into children when the pointer is inside the render box's own
finite size. Painting objects outside a tiny anchor with `Clip.none` does not
make their nested `GestureDetector`s hittable. `object_canvas` currently puts
gestures on individual objects, so copying a small-child/overflow technique
would introduce dead interaction regions.

## Why an enormous canvas is the wrong shortcut

Flutter geometry is floating-point geometry. [`Offset`](https://api.flutter.dev/flutter/dart-ui/Offset-class.html),
[`Size`](https://api.flutter.dev/flutter/dart-ui/Size-class.html), and
[`Rect`](https://api.flutter.dev/flutter/dart-ui/Rect-class.html) store
`double` coordinates. An `int` limit is therefore not the canvas's meaningful
limit.

Dart [`double`](https://api.dart.dev/dart-core/double-class.html) values are
IEEE-754 64-bit floating-point numbers. Dart's
[`number representation`](https://dart.dev/resources/language/number-representation)
documentation specifically notes 53 bits of integer precision on the web.
Even before an arithmetic overflow, representable coordinate spacing grows as
the magnitude grows, so small moves and subpixel snapping eventually become
indistinguishable. Flutter's camera matrix uses
[`Matrix4` storage backed by `Float64List`](https://api.flutter.dev/flutter/package-vector_math_vector_math_64/Matrix4/storage.html),
but Flutter does not promise useful rendering precision at arbitrarily large
scene coordinates across all renderer backends.

An actually infinite render size is invalid as concrete box geometry. Flutter
allows infinite constraints as a request to obtain constraints elsewhere, but
documents that they must be made finite before deriving a render-box size; see
[`BoxConstraints.hasInfiniteWidth`](https://api.flutter.dev/flutter/rendering/BoxConstraints/hasInfiniteWidth.html).
`InteractiveViewer(constrained: false)` removes normal constraints from the
child; it does not create an infinite render object.

An enormous finite box also makes full-stage export unusable. Flutter's
[`RenderRepaintBoundary.toImage`](https://api.flutter.dev/flutter/rendering/RenderRepaintBoundary/toImage.html)
creates an uncompressed RGBA image with the render object's dimensions
multiplied by `pixelRatio`. A 1,000,000 by 1,000,000 logical-pixel canvas at
ratio 1 would imply about four terabytes of raw pixels. The workspace may be
unbounded; every raster export must not be.

## Proposed public API

Make the extent a controller-owned domain value, just as document and camera
state are controller-owned today:

```dart
sealed class CanvasWorkspace {
  const CanvasWorkspace();

  const factory CanvasWorkspace.finite(Size size) = FiniteCanvasWorkspace;
  const factory CanvasWorkspace.unbounded() = UnboundedCanvasWorkspace;
}

final controller = ObjectCanvasController<MyData>(
  workspace: const CanvasWorkspace.unbounded(),
  objects: objects,
);
```

Because the package has not been released yet, prefer this clear API over
preserving `required Size canvasSize` as a permanent architectural assumption.
For a softer migration, retain a named finite constructor:

```dart
ObjectCanvasController.finite(
  canvasSize: const Size(1920, 1080),
  objects: objects,
);

ObjectCanvasController.unbounded(
  objects: objects,
);
```

The `ObjectCanvas` widget should continue to receive only the controller and
builders. Workspace mode does not belong as a competing widget parameter.

Add controller coordinate methods before hiding origin rebasing behind the
implementation:

```dart
Offset viewportToScene(Offset viewportPoint);
Offset sceneToViewport(Offset scenePoint);
Rect get contentBounds;
bool get isWorkspaceBounded;
```

Consumers currently can call `controller.viewportController.toScene` and write
its raw matrix. That leaks the local render origin, which an unbounded
implementation must be free to rebase. Keep the transformation controller for
Flutter composition initially, but make the controller conversion methods the
documented stable API. Later camera commands such as `fitRect`, `centerOn`,
`panBy`, and `zoomAt` should also live on `ObjectCanvasController`.

Finite export can keep its convenient whole-canvas API. Unbounded export needs
an explicit finite scene rectangle:

```dart
Future<Uint8List> renderPng({double pixelRatio = 1}); // finite only

Future<Uint8List> renderRegionPng(
  Rect sceneRegion, {
  double pixelRatio = 1,
});
```

Convenience methods can derive a region from `contentBounds` or selected
objects, but they should still delegate to `renderRegionPng`. Empty unbounded
workspaces have no natural export size.

## Rendering and input architecture

Use a finite **render window** inside the unbounded world:

1. `InteractiveViewer.builder` supplies the visible scene `Quad`.
2. Convert it to an axis-aligned scene `Rect` and inflate it by a configurable
   cache extent.
3. Query objects whose rotated paint bounds overlap that rect.
4. Position those objects relative to a nearby local render origin rather than
   their potentially huge world coordinates.
5. Convert all input through `viewportToScene` and hit-test against object
   geometry in scene space, or own a render object that explicitly positions
   and hit-tests the finite visible children.
6. Rebase the local origin and camera translation when they cross a tested
   threshold. Object geometry and undo actions remain in world coordinates, so
   rebasing is not a document mutation and never enters history.

Start with an O(n) viewport-overlap query behind an interface; that matches
Rody's implementation and is adequate for ordinary object counts. The package
can later substitute a spatial index without changing public API:

```dart
abstract interface class CanvasObjectQuery {
  Iterable<String> query(Rect sceneBounds);
}
```

Do not make culling observable through object state. A configurable cache
extent should avoid rapid rebuilds at viewport edges. Because arbitrary
stateful widgets may be supplied, the documentation should state whether
off-screen widget state is disposed; consumers needing durable state must keep
it in `CanvasObject.data`, not in an off-screen widget's `State`.

## Snapping changes

The current snap index is already rebuilt from committed geometry rather than
from every gesture preview. Preserve that behavior:

- object edge/center anchors remain indexed when objects are added, removed,
  or committed after a transform;
- finite canvas edge/center anchors exist only for
  `CanvasWorkspace.finite`;
- an unbounded workspace does not clamp movement or resize to workspace edges;
  and
- finite artboards may contribute their own snap anchors even when the
  surrounding workspace is unbounded.

The current `CanvasGridSnapStrategy` enumerates every grid line across
`canvasBounds` when it builds the stable index. That cannot work for an
unbounded world. Grid snapping must become an analytic O(1) calculation of the
nearest multiple of `step` for each proposed anchor. This is a narrow exception
to the commit-built index rule: it does not rescan or recalculate object
geometry during a drag. If *all* snap candidates must be fully materialized at
gesture start, an infinite grid and an arbitrarily long drag cannot both be
supported.

`CanvasSnapScene.canvasBounds` and the snap-engine clamping arguments should
therefore become nullable or use the workspace value directly. Null means no
outer edge or clamp, not an enormous rectangle.

## Scope and rollout

The smallest safe rollout is:

1. introduce `CanvasWorkspace.finite` and `.unbounded` plus controller-owned
   coordinate conversion;
2. preserve current finite rendering and screenshot export unchanged;
3. implement infinite camera panning, signed coordinates, no outer clamping,
   and analytic grid snapping;
4. add the finite render-window and parent/geometry-based hit testing;
5. add region export; and
6. add origin rebasing and a replaceable spatial query after stress tests define
   useful thresholds.

Tests should cover negative coordinates, panning through empty space, dropping
and selecting far from the origin, transforms after rebasing, snap behavior on
both sides of zero, state disposal under culling, and bounded raster export.
Run precision and interaction tests on CanvasKit/web and at least one Impeller
platform; Dart-level double precision alone is not evidence of renderer-level
behavior.

## Decision

This is a good extensibility investment. The package should describe the
feature as an **unbounded workspace**, not an infinite-size canvas. It expands
the package's use cases without forcing the screenshot builder away from its
finite artboard, and it creates a clean place for future multiple-artboard and
diagram applications.

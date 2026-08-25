# Collection canvas

`DesyCollectionCanvas<T>` is Desy Bench's internal shared workspace primitive
for a collection of real Flutter previews. It is a presentation and interaction
boundary, not a registry model or a serializable editor.

## Ownership

The canvas owns only session-local interaction state:

- independent drag-box geometry, selection, paint order, and camera transform;
- the dot-grid stage, its flat light-grey perimeter, 1024px navigable edge space,
  and a quiet grey workspace outside that boundary,
  blank-stage panning, a 50–250% zoom dock, and optional inspector drawer;
- deterministic three-column placement for items the host has not arranged.

The host owns the domain:

- resolving its typed items from the existing consumer registry;
- each item's real-widget `previewBuilder`;
- the typed `detailsBuilder` callback, including any host-local editing state.

When a host needs to compose a preview with its own surface (for example a
device bezel, capture boundary, or an inspection scope), it may supply
`previewSurfaceBuilder`. The canvas still owns the drag frame, selection,
geometry and camera; the host receives the current geometry plus select/change
callbacks only for that surface. Optional item keys, geometry resolution and
geometry-change callbacks preserve host-level accessibility, sizing, and
session state without forking the canvas.

For authored prototype sequences, `DesyPrototype.canvasPlacement` can supply a
typed `DesyCanvasPlacement(offset, size)`. It determines the first drag-box
frame only, making a vertical iteration flow explicit without persisting later
user moves or creating a separate canvas manifest.

The generic callback is deliberately item-shaped:

```dart
typedef DesyCanvasDetailsBuilder<T> = Widget Function(
  BuildContext context,
  DesyCanvasSceneItem<T> item,
);
```

It lets a host such as Details keep component controls beside the canvas while
Prototypes shows a direction summary, without the canvas importing component
knob state or prototype-specific metadata.

## Current adapters

- `DesyPrototypesScreen` resolves the current session's `DesyPrototype`
  directions, preserves each prototype's annotation scope, and supplies the
  direction-details drawer.
- `DesyDetailScreen` resolves the default component preview and declared
  instances as `_DetailVariant` items. It retains the component's real theme,
  knob values, preview-environment wrapper, preset-sized responsive artboard,
  capture/export boundary, and resizable control sheet while the shared canvas owns the
  stage, drag frames, camera, selection and annotation action bar.

The prototype preview remains an actual consumer builder under the active
consumer theme. It neither constructs a second registry list nor persists
callbacks, widgets, or arrangement data.

## Gesture contract

Each item remains a real `DesyDragBox` backed by `flutter_box_transform`.
Mouse, touch, and stylus drags that begin on an item belong to that item;
blank-stage pointer movement pans the canvas. Drag boxes deliberately exclude
`PointerDeviceKind.trackpad`, so two-finger pan, pinch, and scroll remain
viewport-only—even when the gesture begins over a box.

Real preview children remain pointer-enabled. Flutter's gesture arena decides
whether an interactive consumer control or the surrounding drag frame owns a
gesture: buttons, menus, fields, scrolling, hover, and focus keep their native
behaviour, while drags beginning on non-interactive preview content continue to
move the frame. The canvas does not forward or synthesize consumer gestures.

The canvas uses a `TransformationController` and an `AnimatedBuilder` for the
render transform, so a camera update repaints the stage without rebuilding the
real consumer previews. Flutter's `InteractiveViewer` was evaluated first,
but its public API offers no per-child gesture exclusion or recognizer-team
hook. Nested `TransformableBox` resize handles consequently receive start/end
events but no update. A parent `ScaleGestureRecognizer` has the same conflict.

For this verified gap, the canvas keeps the custom seam narrow: a stage
`Listener` updates the controller for blank-space pointer movement and
trackpad events only. It never forwards, retargets, or interprets an element
drag, and item movement/resizing stays entirely in the dependency's native
recognizers. Focused tests cover item priority, blank-space panning, and
trackpad-only viewport movement.

## Extension rule

A new collection host should only use this canvas when the collection benefits
from direct spatial comparison. It must create immutable `DesyCanvasSceneItem`
values from an existing typed registry query and keep its own controls in
`detailsBuilder`. Specialized boards such as Motion and Measurements remain
specialized when their dedicated interaction conveys more meaning.

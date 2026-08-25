# Object canvas contract

`packages/object_canvas` is a reusable finite-stage Flutter package. It has no
dependency on Desy, Forui, a state manager, persistence, or host-side editor UI.

## Ownership

`ObjectCanvasController<T>` is the only document source of truth. The
`ObjectCanvas<T>` widget receives the controller and a visual `objectBuilder`;
it does not accept a competing object list or mutation callback. For documents
whose data already consists of widgets, `ObjectCanvas<Widget>.widgets` supplies
the builder.

The callback is invoked inside a stable per-object widget rather than directly
from the canvas-wide build. A private inherited model exposes object-ID aspects,
so controller notifications rebuild an object's content only when its geometry,
data, or declared policy changes. Selection and resolved capabilities rebuild
only the package-owned interaction wrapper and retain the same content widget.
Reordering and unrelated object transforms preserve the existing widget element
and state. Replacing the host builder invalidates every object deliberately so
captured host state cannot become stale.

The controller owns ordered objects, selection, viewport transformation,
transform mode, transient transform drafts, snap-index state, and in-memory
history. Host inspectors edit the controller and listen to it. They remain
outside the package.

Hosts can replace the current selection through `setSelectedObjects` and react
to effective changes through `onSelectionChanged`. The callback receives an
unmodifiable ID set and is not called for no-op assignments. `selectedObjects`
resolves those IDs to the current typed canvas objects for inspectors.
Multi-selection is enabled by default; setting `multiSelectionEnabled: false`
keeps selection to at most one selectable object across programmatic, click,
modifier, and marquee selection paths.

## Geometry and transforms

`CanvasObjectGeometry.size` is the child's real layout constraint. Uniform
`scale` and `rotation` are paint transforms around `pivot`; they do not alter
layout size. Controller-wide constraints and capabilities are the default.
Individual objects only declare an override when they differ.

Finite documents also define a controller-owned `CanvasOverflow` policy.
`deny` preserves the default direct-manipulation containment and clips at the
canvas edge. `clip` permits outside geometry but keeps the finite visual crop.
`show` permits outside geometry and paints overflow into the viewport. Changing
the policy is ephemeral editor configuration rather than an undoable document
action, and finite export crops to the canvas in every mode.

`object_canvas` owns one oriented transform-box implementation for every
rotation angle. Eight resize handles and the rotation handle derive from the
same geometry, convert global pointer movement into canvas and object axes, and
feed the same transient controller session. Layout resize changes real widget
constraints; transform scale leaves layout size untouched. Rotating an object
never changes whether either operation is available.

Resize gestures sample keyboard modifiers on every ephemeral frame. Shift
projects layout resizing onto the gesture-start aspect ratio. Ctrl (or Cmd on
macOS) keeps the transformed local center fixed while layout-resizing or
paint-scaling; combining the modifiers applies both rules. Changing a modifier
mid-gesture always recalculates from gesture-start geometry, so it introduces no
cumulative drift or additional history entries.

V1 supports multi-selection for translation only. A selected set moves by one
shared canvas-space delta, preserves relative geometry, snaps its union hull,
and commits one action. Layout resize, transform scale, and rotation require a
single selected object.

## Preview and history

Pointer frames never mutate committed objects. A transform session retains
gesture-start geometry and exposes draft geometry through `geometryFor`. On
release, the controller computes sparse field patches with exact before/after
values and adds one canvas action to the `undo` stack. Add, remove, reorder,
data, and compound actions also accept collections. Cancel and no-op gestures
create no history.

The default history limit is 100 completed actions. Raw `undo` types are not
part of the public package API.

The object list defines back-to-front paint order. Controller commands can move
ID arrays one step forward/backward or directly to the front/back while
preserving their relative order. Every effective z-order change is one
undoable `CanvasReorderAction`.

## Snapping

Snap strategies contribute stable anchors when committed placement, canvas
size, or configuration changes. Drag frames query that frozen sorted index;
they do not rebuild peer geometry. Default strategies cover finite canvas
bounds, object edges and centers, and an 8 px grid. Acquisition and release
distances are defined in screen pixels and converted by viewport scale.

## Rendering boundary

The mounted canvas registers one finite `RepaintBoundary` with the controller.
`renderToImage` and `renderPng` include the configured canvas background and
the consumer's real widgets. Selection frames, handles, snap guides, marquee,
viewport chrome, inspectors, and export destinations are outside that boundary.

The Screenshot Builder is the first proof consumer. It delegates geometry,
selection, camera transforms, move/resize/scale/rotation gestures, snapping,
z-order, undo/redo, and finite-stage PNG rendering to `object_canvas`. Its
Desy-specific registry widgets, image decoding, text styles, palette, scene
list, inspector, page settings, and file export remain in the extension.

Sketch/Canvas V2 remains the next planned proof consumer. Its registry,
artboard, and surrounding editor panels likewise stay in their host package;
only reusable finite-canvas mechanics belong here.

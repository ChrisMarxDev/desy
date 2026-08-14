# Canvas v2 beta

`/canvas` is a separate, registry-derived exploration route. It is deliberately
not a replacement for Atlas, component details, or the existing Sketch canvas.
The beta validates collection-canvas interaction before any broader product
switch.

Its interaction implementation is shared with prototype sessions through the
internal [collection canvas](collection-canvas.md). The component route owns
only component-specific knob state and its controls drawer.

## Current contract

- The canvas reads `DesyRegistry.allComponents` directly. It does not own a
  component catalogue, a folder tree, or a parallel widget list.
- Every component starts in a deterministic three-column scene inside an
  independent drag box. The box renders the consumer's real widget through
  `DesyWidgetPreview` under the active consumer theme; no catalogue card or
  compact preview wrapper sits around it.
- Every item can move, resize independently, overlap, and rise above the
  others when selected. Flutter's `InteractiveViewer` owns the scene camera,
  so blank-space drag and mouse-wheel / trackpad gestures pan the collection
  while pinch and the zoom dock scale it. Reset view returns the camera to its
  initial transform.
- A pointer press or keyboard activation selects exactly one component. The
  selected tile gets the signal-pink outline and an overlay drawer slides in
  from the right with that component's declared `DesyComponentKnobPanel`.
  The drawer never takes layout width from the canvas and can be closed without
  changing the current camera position.
- Knob values are ephemeral and local to this canvas route, keyed by the stable
  component ID. Switching selection preserves each item's experiment and does
  not mutate the Detail screen's inspection session or the immutable registry.

## Deferred intentionally

The beta has no persistence, manifest format, atom collections, or code
generation. Those choices remain in [the generic canvas collections concept](../../concept/features/generic-canvas-collections.html)
until the interaction model has been evaluated in the dogfood workbench.

# Collection canvas

`DesyCollectionCanvas<T>` is Desy Bench's internal shared workspace primitive
for a collection of real Flutter previews. It is a presentation and interaction
boundary, not a registry model or a serializable editor.

## Ownership

The canvas owns only session-local interaction state:

- independent drag-box geometry, selection, paint order, and camera transform;
- the dot-grid stage, Flutter `InteractiveViewer`, zoom dock, and inspector
  drawer;
- deterministic three-column placement for items the host has not arranged.

The host owns the domain:

- resolving its typed items from the existing consumer registry;
- each item's real-widget `previewBuilder`;
- the typed `detailsBuilder` callback, including any host-local editing state.

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

It means a future Detail host can show its component controls while the
Prototypes screen can show a direction summary, without the canvas importing
component knob state or prototype-specific metadata.

## Current adapters

- `DesyPrototypesScreen` resolves the current session's `DesyPrototype`
  directions, preserves each prototype's annotation scope, and supplies the
  direction-details drawer.

The prototype preview remains an actual consumer builder under the active
consumer theme. It neither constructs a second registry list nor persists
callbacks, widgets, or arrangement data.

## Extension rule

A new collection host should only use this canvas when the collection benefits
from direct spatial comparison. It must create immutable `DesyCanvasSceneItem`
values from an existing typed registry query and keep its own controls in
`detailsBuilder`. Specialized boards such as Motion and Measurements remain
specialized when their dedicated interaction conveys more meaning.

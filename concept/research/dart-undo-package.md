# Dart `undo` package for canvas gesture history

Checked: 2026-08-17

## Recommendation

`undo` can represent one completed move, resize, scale, or rotate gesture as one undoable operation. Use it behind a small canvas-owned history adapter, not as part of the public canvas API. During a gesture, keep the changing geometry in transient preview state. When the gesture ends, add exactly one `Change` containing the geometry before the gesture plus closures that apply the final and original geometry.

This distinction matters because `ChangeStack.add()` immediately calls the change's `execute()` method; the package has no public “record an action that has already executed” operation. If every pointer update mutates the committed document, adding history at pointer-up would execute the final state again. Keeping committed and transient gesture state separate lets `add()` perform the one real commit. [Source: current `ChangeStack` implementation](https://github.com/rodydavis/packages.dart/blob/main/packages/undo/lib/src/undo_stack.dart)

```dart
void commitGeometryGesture(
  String id,
  CanvasObjectGeometry before,
  CanvasObjectGeometry after,
) {
  if (before == after) return;

  _history.add(
    Change<CanvasObjectGeometry>(
      before,
      () => _applyCommittedGeometry(id, after),
      (oldGeometry) => _applyCommittedGeometry(id, oldGeometry),
      description: 'Move object',
    ),
  );
}
```

With this structure:

- pointer down captures `before`;
- pointer movement updates only the transient preview;
- pointer up calculates `after` and adds one `Change`;
- `add()` applies `after` and stores that one change;
- `undo()` applies `before`;
- `redo()` calls the execute closure again and applies `after`.

## Current package status

- The current pub.dev release is `1.6.0`, published approximately seven months before this review. It supports Dart and Flutter on all six Flutter platforms and declares no runtime dependencies. [Source: pub.dev package page](https://pub.dev/packages/undo)
- The current repository manifest also declares version `1.6.0`, Dart SDK `^3.5.0`, and no production dependencies. [Source: package `pubspec.yaml`](https://github.com/rodydavis/packages.dart/blob/main/packages/undo/pubspec.yaml)
- The package received a functional/package update in January 2026 and its directory was touched again by workspace maintenance in May 2026. It therefore appears maintained, although it is a very small library with a correspondingly small test surface. [Source: package-scoped commit history](https://github.com/rodydavis/packages.dart/commits/main/packages/undo)
- Version `1.6.0` is Apache-2.0 licensed. Both pub.dev and the package's current license file agree. Older `1.5.0` metadata used MIT, so license conclusions should be tied to the installed version. [Sources: pub.dev metadata](https://pub.dev/packages/undo), [current license](https://github.com/rodydavis/packages.dart/blob/main/packages/undo/LICENSE)

## Exact API and behavior

The current public library exports `Change<T>`, `ChangeStack`, and `SimpleStack<T>`. [Source: generated API index](https://pub.dev/documentation/undo/latest/undo/)

### `Change<T>`

The constructor is effectively:

```dart
Change(
  T oldValue,
  void Function() execute,
  void Function(T oldValue) undo, {
  String description = '',
})
```

`execute()` invokes the stored zero-argument execute closure. `undo()` passes the captured old value to the undo closure. The API is synchronous: both public methods return `void`, and the stored callbacks are `void Function(...)`. [Sources: generated `Change<T>` API](https://pub.dev/documentation/undo/latest/undo/Change-class.html), [current source](https://github.com/rodydavis/packages.dart/blob/main/packages/undo/lib/src/change.dart)

### `ChangeStack`

Relevant surface:

```dart
ChangeStack({int? limit})

bool get canUndo
bool get canRedo
void add<T>(Change<T> change)
void addGroup<T>(List<Change<T>> changes)
void undo()
void redo()
void clearHistory()
```

`add()` executes the change, stores it as a one-item history entry, and clears redo history. `undo()` removes the newest history entry, calls each contained change's `undo()`, and places the entry on the redo queue. `redo()` removes the next redo entry, calls each change's `execute()`, and restores it to history. Adding a new change after an undo clears the redo queue. [Sources: generated `ChangeStack` API](https://pub.dev/documentation/undo/latest/undo/ChangeStack-class.html), [current implementation](https://github.com/rodydavis/packages.dart/blob/main/packages/undo/lib/src/undo_stack.dart)

`SimpleStack<T>` is intended for a single replaceable value. The canvas already needs richer document, selection, transient-interaction, and notification behavior, so it is not the appropriate integration point. [Source: package README](https://pub.dev/packages/undo)

## Grouping and batching

`ChangeStack.addGroup<T>(List<Change<T>>)` stores a list as one history entry, so several changes can be undone/redone through one stack step. The implementation executes group members in list order and also undoes them in list order, not reverse order. It also does not roll back already executed members if a later member throws. [Source: current `ChangeStack` implementation](https://github.com/rodydavis/packages.dart/blob/main/packages/undo/lib/src/undo_stack.dart)

The current README shows `Change.group([...])`, but neither the current `Change<T>` source nor its generated API contains that constructor. Treat `addGroup()` as the actual released grouping API. [Sources: README grouping example](https://pub.dev/packages/undo), [generated `Change<T>` API](https://pub.dev/documentation/undo/latest/undo/Change-class.html), [current `Change<T>` source](https://github.com/rodydavis/packages.dart/blob/main/packages/undo/lib/src/change.dart)

For the canvas, prefer one domain-level `Change<CanvasMutation<T>>` or one snapshot change for a multi-object transform instead of exposing `addGroup()`. That gives the operation one description and lets the controller apply all before/after values coherently. It also avoids depending on the package's group ordering and homogeneous generic-list constraint.

## Controller integration cautions

1. **Keep transient gestures outside committed state.** The package always executes on `add()`. A canvas gesture should therefore preview transient geometry and add one change only at gesture end.
2. **Do not add a history entry per pointer event.** Pointer updates are frames of one user intention, not separate commands. Capture one `before` and one `after` value.
3. **Skip no-op gestures.** If snapped/final geometry equals the starting geometry, do not add a change.
4. **Centralize all state application.** Execute, undo, and redo closures should call the same controller method so indexing, snapping metadata, selection reconciliation, and listener notifications remain consistent.
5. **Wrap notifications.** `ChangeStack` does not extend `ChangeNotifier`; the README's Flutter example wraps it in a controller and explicitly calls `notifyListeners()`. The canvas controller should expose `canUndo`, `canRedo`, `undo()`, and `redo()` and own notification behavior. [Sources: current implementation](https://github.com/rodydavis/packages.dart/blob/main/packages/undo/lib/src/undo_stack.dart), [Flutter integration example](https://pub.dev/packages/undo)
6. **Do not expose package types publicly.** A canvas-owned `CanvasHistory`/`CanvasMutation` boundary preserves the option to replace the dependency and gives the package domain-specific labels, callbacks, and tests.
7. **Test edge behavior locally.** The current package tests focus on `SimpleStack`; they do not exercise grouped changes. The source also exposes `history` and `redos` as the latest group rather than the complete queue, and those getters access an empty queue unsafely. The canvas adapter should rely only on `canUndo`, `canRedo`, `add`, `undo`, `redo`, and `clearHistory`. [Sources: package tests](https://github.com/rodydavis/packages.dart/blob/main/packages/undo/test/undo_test.dart), [stack source](https://github.com/rodydavis/packages.dart/blob/main/packages/undo/lib/src/undo_stack.dart)

## Proposed canvas terminology

Avoid calling the in-progress drag a transaction. A clearer split is:

- **gesture session**: transient, mutable preview from pointer down through pointer up/cancel;
- **canvas mutation**: immutable description of one completed user intention, holding before/after state and a reason such as move, resize, scale, rotate, add, remove, or reorder;
- **history entry**: the single `undo.Change` that applies/reverts that mutation;
- **batch mutation**: one history entry containing several object deltas when the user performs one multi-object action.

This directly matches the requested mental model: a single resizing or moving action becomes an object that can later be undone and redone.

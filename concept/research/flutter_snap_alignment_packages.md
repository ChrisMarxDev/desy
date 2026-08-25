# Flutter element-alignment snapping package research

Research date: 2026-08-09

## Recommendation

Do not adopt a full canvas/board package for Desy's snapping. Desy already owns its registry, canvas state, widget previews, selection, movement, and resize behavior, and already depends on `flutter_box_transform`. Replacing or wrapping those systems with `stack_board_plus`, `fluera_canvas`, `infinite_canvas`, or `diagram_editor` would introduce a parallel scene/controller model for a comparatively small geometry feature.

Build a Desy-owned, pure-Dart geometry engine behind a small interface, informed by the MIT-licensed [`fluera_canvas` `SnapEngine`](https://github.com/Lorencoshametaj/fluera_canvas/blob/main/lib/src/canvas/snap/snap_engine.dart), but do not depend on its unpublished GitHub-main API. Keep rendering, gesture ownership, and state commits outside the engine. Once the API has survived Desy's movement, resize, zoom, hierarchy, and performance tests, it is a credible candidate for extraction into a focused package.

For performance, precompute an immutable index when a gesture starts (and rebuild it when committed scene geometry changes): sorted X coordinates for left/center/right anchors and sorted Y coordinates for top/center/bottom anchors. Each pointer update can binary-search only the tolerance neighborhood, while grid snapping remains constant-time arithmetic. This is a better fit for axis-alignment queries than rescanning every rectangle or introducing a general board dependency. Keep the first implementation swappable so an R-tree or interval index can be introduced only if profiling shows that visibility/overlap filtering dominates.

## Comparison

| Package | Published state | License / compatibility | Snapping | Reusable engine? | Performance evidence / integration fit |
| --- | --- | --- | --- | --- | --- |
| [`stack_board_plus`](https://pub.dev/packages/stack_board_plus) | `0.0.7`, published about 10 months ago; unverified uploader; 25 weekly downloads at research time | MIT; Dart `^3.8.1`; pub.dev lists Android, iOS, Linux, macOS, Windows, but not web. Its [pubspec](https://github.com/M4DGENIUS0/stack_board_plus/blob/main/pubspec.yaml) depends on a drawing board, SVG, shimmer, and vector math. | Optional grid snapping and grid display; no documented element-edge, center, spacing, or smart-guide snapping. Its own [movement guide](https://github.com/M4DGENIUS0/stack_board_plus/blob/main/ENHANCED_MOVEMENT.md) emphasizes free movement and backward-compatible grid snapping. | No. It is a complete board/controller/item model with selection, layers, transforms, export, history, drawing, and custom item types. | Documentation claims `RepaintBoundary`, minimal rebuilds, and 60fps animations, but exposes no spatial index or snap-candidate strategy. It would duplicate Desy's scene and interaction ownership, and its lack of pub.dev web support is a direct problem for the dogfood web build. |
| [`fluera_canvas`](https://pub.dev/packages/fluera_canvas) | pub.dev `0.10.4`, published about 3 months ago, verified publisher; only four published releases and pre-1.0 | MIT; published package requires Dart 3.7 and documents all Flutter platforms, including CanvasKit/WASM web. | Published widget supports configurable grid size, same-axis element edge/center smart guides, screen-space tolerance, and Shift bypass. Its [0.9.0 changelog](https://pub.dev/packages/fluera_canvas/changelog) describes scanning visible selectable nodes and comparing nine anchors per node. | **Published version: no focused engine API documented. GitHub main: yes, but unpublished.** Main is currently labeled `0.16.2` and its [public barrel exports `SnapEngine`](https://github.com/Lorencoshametaj/fluera_canvas/blob/main/lib/fluera_canvas.dart#L44-L45). | The [main-branch engine source](https://github.com/Lorencoshametaj/fluera_canvas/blob/main/lib/src/canvas/snap/snap_engine.dart) is stateless pure geometry, returns snapped bounds plus guides, and is `O(candidates × axes)`. It explicitly leaves candidate retrieval/spatial culling to the caller. The surrounding canvas has an R-tree/spatial index, but adopting the package would also adopt a large scene graph, drawing, persistence, input, and export surface. The published/main version gap and pre-1.0 status make a direct dependency on `SnapEngine` risky. This is the best source reference, not the best dependency. |
| [`flutter_box_transform`](https://pub.dev/packages/flutter_box_transform) | `0.4.7`, published about 15 months ago; established usage; already a Desy dependency | Pub metadata reports Apache-2.0 while the README embeds BSD-3-Clause text, so license metadata should be clarified before redistributing source. Dart 3.0; all Flutter platforms. | No grid, peer-edge, center, spacing, or guide snapping. It provides drag/resize/rotation math, clamping, constraints, flipping, and handles. | Yes for move/resize geometry, not snapping. Its [`BoxTransformer` static API](https://pub.dev/documentation/flutter_box_transform/latest/flutter_box_transform/BoxTransformer-class.html) accepts explicit boxes and pointer positions. | Continue using it for transform mechanics. A Desy snap engine should post-process its proposed `Rect`/`Box` rather than replace it. Adding a second transform widget would split interaction ownership. |
| [`infinite_canvas`](https://pub.dev/packages/infinite_canvas) | `0.0.10`, published about 23 months ago | Apache-2.0; Dart 3.0; all Flutter platforms. | Its [changelog](https://pub.dev/packages/infinite_canvas/changelog) documents optional grid snapping for movement and resize, including choosing the nearer right/bottom edge. No peer-edge, center, spacing, or smart-guide support. | No. It is an `InteractiveViewer`/`CustomMultiChildLayout` canvas with its own nodes, edges, menus, marquee, selection, and controller. | Supports optional visible-only drawing, but documents no snapline index or element-alignment candidate strategy. Stale and duplicates Desy's canvas model. |
| [`snap`](https://pub.dev/packages/snap) | `2.0.0`, published about 5 years ago | MIT; Dart 2.12 null safety; all Flutter platforms. | Snaps one draggable view to configurable pivots on one bound, generally on drag end, with flick/animation. It can target corners and center, but it is not Figma-style peer alignment and draws no smart guides. | No. `SnapController` is a widget/controller bound to `GlobalKey`-measured view and bound widgets. | No spatial indexing; only a view/bound relationship. Stale, gesture-owning, and not suitable for many peer elements. |
| [`diagram_editor`](https://pub.dev/packages/diagram_editor) | `1.0.0`, published about 4 months ago; verified publisher | MIT; Dart 3.5; all Flutter platforms. | Supplies a grid painter, component movement, overlays, and link endpoint alignment. It does **not** document grid snapping or peer element alignment guides; link endpoint alignment is unrelated to element snapping. | No. Complete diagram controller and scene model. | Recent and well-scoped for node diagrams, but still duplicates Desy's canvas/controller/serialization model and does not solve the requested snap behavior. |

## Key finding: `fluera_canvas` is the nearest implementation

The current `fluera_canvas` main branch is unusually close to the desired boundary:

- [`SnapEngine`](https://github.com/Lorencoshametaj/fluera_canvas/blob/main/lib/src/canvas/snap/snap_engine.dart) accepts only dragged bounds, candidate bounds, and active axes. It mutates no state and knows nothing about widgets or a canvas.
- It returns the snapped bounds and world-space guide segments separately, which is the right separation between geometry and painting.
- It supports edge-to-corresponding-edge and center-to-center alignment on X and Y, with the nearest delta winning independently per axis.
- It does not implement grid snapping, cross-edge adjacency, equal-spacing/distribution, rotation-aware oriented bounds, persistent snap locks/hysteresis, or an internal index.
- Its own source says callers should obtain nearby candidates from a spatial index; it then linearly checks those candidates on each pointer update. This is a sound baseline for a culled scene, but not the precomputed snapline design proposed for Desy.

The main-branch README calls smart guides "Figma / TLDraw style," but the code is narrower than full Figma behavior. In particular, only corresponding edges are paired (`left↔left`, `right↔right`, `top↔top`, `bottom↔bottom`) and only one guide per axis is returned. Treat it as a useful reference implementation rather than evidence that all desired alignment behaviors are solved.

## Suggested package boundary for Desy

A future reusable package can remain independent of Flutter widgets and Desy concepts:

```dart
SnapSceneIndex index = SnapSceneIndex.fromTargets(targets);

SnapResult result = engine.resolve(
  proposedBounds: draggedBounds,
  index: index,
  axes: SnapAxes.both,
  grid: const PixelGrid(step: 8),
  toleranceInScreenPixels: 6,
  viewportScale: scale,
  previousLock: activeLock,
);
```

Recommended responsibilities:

- Engine: grid quantization, nearest anchor matching, priority/tie-breaking, snap lock/hysteresis, move/resize axis constraints, and guide descriptors.
- Index: immutable target IDs and sorted X/Y anchor coordinates; exclude the active selection at construction time.
- Desy integration: build the index at gesture start, translate between scene and screen tolerance, apply bounds, commit on gesture end, paint guides, and honor hierarchy/locked/hidden rules.
- Not in the package: Flutter widgets, gesture detectors, controller/history ownership, registry concepts, or a scene graph.

Before extraction, benchmark pointer-update resolution with representative scenes (for example 100, 1,000, and 10,000 elements), and specify tie-breaking and hysteresis in deterministic unit tests. This keeps package extraction an architectural consequence of a stable feature rather than an up-front constraint.

## Sources

- [`stack_board_plus` pub.dev page](https://pub.dev/packages/stack_board_plus), [source repository](https://github.com/M4DGENIUS0/stack_board_plus), [movement guide](https://github.com/M4DGENIUS0/stack_board_plus/blob/main/ENHANCED_MOVEMENT.md), and [pubspec](https://github.com/M4DGENIUS0/stack_board_plus/blob/main/pubspec.yaml)
- [`fluera_canvas` pub.dev page](https://pub.dev/packages/fluera_canvas), [published versions](https://pub.dev/packages/fluera_canvas/versions), [changelog](https://pub.dev/packages/fluera_canvas/changelog), [GitHub main](https://github.com/Lorencoshametaj/fluera_canvas), [public barrel](https://github.com/Lorencoshametaj/fluera_canvas/blob/main/lib/fluera_canvas.dart), and [`SnapEngine` source](https://github.com/Lorencoshametaj/fluera_canvas/blob/main/lib/src/canvas/snap/snap_engine.dart)
- [`flutter_box_transform` pub.dev page](https://pub.dev/packages/flutter_box_transform), [versions](https://pub.dev/packages/flutter_box_transform/versions), [API](https://pub.dev/documentation/flutter_box_transform/latest/flutter_box_transform/), and [repository](https://github.com/hyper-designed/box_transform)
- [`infinite_canvas` pub.dev page](https://pub.dev/packages/infinite_canvas), [versions](https://pub.dev/packages/infinite_canvas/versions), and [changelog](https://pub.dev/packages/infinite_canvas/changelog)
- [`snap` pub.dev page](https://pub.dev/packages/snap), [versions](https://pub.dev/packages/snap/versions), and [API](https://pub.dev/documentation/snap/latest/)
- [`diagram_editor` pub.dev page](https://pub.dev/packages/diagram_editor), [versions](https://pub.dev/packages/diagram_editor/versions), and [API](https://pub.dev/documentation/diagram_editor/latest/diagram_editor/)

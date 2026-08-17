# Flutter object-canvas package landscape

Research date: 2026-08-16

## Executive finding

There is no small, well-maintained Flutter package that already provides the
specific boundary Desy needs: a **finite, externally controlled canvas of
arbitrary Flutter widgets** with stable object IDs, independent logical size
and paint scale, move/resize/rotate, configurable selection chrome, and
Figma-style snapping.

The best foundation is therefore a new high-level package composed from
Flutter's supported primitives, with at most one narrow geometry dependency:

- use Flutter's [`InteractiveViewer`](https://api.flutter.dev/flutter/widgets/InteractiveViewer-class.html)
  and [`TransformationController`](https://api.flutter.dev/flutter/widgets/TransformationController-class.html)
  for the viewport camera;
- use Flutter's [`ScaleUpdateDetails`](https://api.flutter.dev/flutter/gestures/ScaleUpdateDetails-class.html)
  for object translation, uniform/non-uniform scale inputs, rotation, focal
  point movement, and pointer count;
- evaluate the pure-Dart [`box_transform`](https://pub.dev/packages/box_transform)
  package for constrained logical-box movement and resizing, or implement that
  small geometry layer locally; and
- independently implement a replaceable snap engine, informed by the
  MIT-licensed [`fluera_canvas` `SnapEngine`](https://github.com/Lorencoshametaj/fluera_canvas/blob/63b93f16de01f45b2cac526da365b6796b86adc9/lib/src/canvas/snap/snap_engine.dart).

Do **not** base the package on `canvas_editor`, `bounding_box`,
`sticker_editor_plus`, `matrix_gesture_detector_pro`, or `flutter_img_editor`.
They either have the wrong state/API boundary, incomplete transform geometry,
obsolete SDK constraints, or an image-editor UI coupled to their object model.

This recommendation is architectural evidence, not a commitment to a package
name or public API. It also supersedes one detail in the earlier
[`flutter_snap_alignment_packages.md`](./flutter_snap_alignment_packages.md):
the published `flutter_box_transform` 0.4.7 release does **not** provide
rotation.

## Required capability lens

The comparison uses the following interpretation of the proposed package:

1. **Finite canvas:** the editable artboard has explicit logical bounds; the
   package owns nothing outside them.
2. **Arbitrary content:** a caller can render any Flutter widget and attach
   arbitrary typed application data, rather than choose from a closed image,
   text, or shape model.
3. **Coherent state ownership:** one canonical store owns the ordered immutable
   objects. This may be a controller or a parent-controlled list, but the public
   API must not expose both as competing sources of truth during interaction.
4. **Two size operations:** layout resize changes the widget's logical
   constraints; transform scale changes its painted size while retaining the
   logical layout size. These cannot both be represented by a single `Rect`.
5. **Transforms:** movement, logical resize, transform scale, and rotation all
   remain usable under a zoomed/panned camera.
6. **Extensible interaction:** selection, handles, constraints, snapping,
   guides, keyboard policy, and hit testing are replaceable or configurable.

## Recommended building blocks

### Flutter SDK: use for camera, gestures, coordinates, and capture

[`InteractiveViewer`](https://api.flutter.dev/flutter/widgets/InteractiveViewer-class.html)
already supplies viewport pan/zoom, minimum and maximum scale, boundary margin,
clipping, gesture callbacks, and a transformation controller. Its
`constrained: false` mode supports a child larger than the viewport. One
important limitation is documented by Flutter: even with `clipBehavior:
Clip.none`, gestures are received only inside the viewer's original bounds.
That makes it an appropriate camera layer inside the package's canvas boundary,
not an object editor by itself.

[`TransformationController.toScene`](https://api.flutter.dev/flutter/widgets/TransformationController/toScene.html)
is the supported viewport-to-scene coordinate conversion. Keeping camera
conversion here avoids ad hoc global-position offsets of the kind found in
some editor packages.

Flutter's native [`ScaleUpdateDetails`](https://api.flutter.dev/flutter/gestures/ScaleUpdateDetails-class.html)
already exposes focal-point movement, uniform and horizontal/vertical scale,
rotation, and pointer count. That is enough input for object gesture policy;
an additional matrix-gesture package is not justified.

If image export belongs in an integration layer, Flutter's
[`RenderRepaintBoundary.toImage`](https://api.flutter.dev/flutter/rendering/RenderRepaintBoundary/toImage.html)
captures a subtree at an explicit pixel ratio. Export controls, files, and
editor panels should remain outside the reusable canvas boundary.

### `box_transform` / `flutter_box_transform`: narrow resize candidates

[`flutter_box_transform` 0.4.7](https://pub.dev/packages/flutter_box_transform)
is the strongest narrow widget-level dependency examined. Its
[`TransformableBox`](https://pub.dev/documentation/flutter_box_transform/latest/flutter_box_transform/TransformableBox-class.html)
accepts arbitrary widget content, emits `Rect` changes, supports constraints,
clamping, flipping, pointer-device configuration, and customizable/enabled/
visible handles. Its published license is
[`Apache-2.0`](https://pub.dev/packages/flutter_box_transform/license).

There are three decisive limitations:

- Published 0.4.7 has move and resize but **no rotation**. Rotation appears in
  repository `main`, while the published
  [`0.4.7` changelog](https://pub.dev/packages/flutter_box_transform/changelog)
  and public API do not expose it. Do not design against unreleased repository
  behavior.
- Its aspect-preserving "scale" resize mode still changes the logical `Rect`;
  the [resize-mode documentation](https://boxtransform.hyperdesigned.dev/resize_modes)
  does not model paint/transform scale independently of layout size.
- It has no released grid, peer-edge, center, spacing, or guide snapping.

The repository README also embeds stale BSD text while the package license file
and pub.dev license page say Apache-2.0. License decisions should follow the
distributed license file, not that README fragment.

The lower-level [`box_transform`](https://pub.dev/packages/box_transform)
package exposes the constrained movement/resize geometry through
[`BoxTransformer`](https://pub.dev/documentation/box_transform/latest/box_transform/BoxTransformer-class.html)
without imposing selection chrome or controller ownership. It is also
[`Apache-2.0`](https://pub.dev/packages/box_transform/license). This is the
better candidate if the new package should fully own its widget and public API,
although rotation and snapping still remain our responsibility.

### `interactive_viewer_2`: optional camera substitute, not a default

[`interactive_viewer_2` 0.1.0](https://pub.dev/packages/interactive_viewer_2)
adds desktop-wheel behavior, scrollbars, double-tap zoom, alignment for content
that does not cover the viewport, and an extensible viewer implementation. Its
license is
[`BSD-3-Clause`](https://github.com/hlvs-apps/interactive_viewer_2/blob/main/LICENSE).
It edits only the camera, not scene objects. Keep it as a possible adapter and
adopt it only if concrete interaction tests reveal a gap in Flutter's native
viewer; otherwise it would be an unnecessary compatibility layer.

## Landscape comparison

Maintenance and platform statements below are snapshots of each primary
pub.dev page on the research date, not guarantees of future support.

| Package/source | Published state and platforms | What is useful | Why it is not the package foundation | License / reuse verdict |
| --- | --- | --- | --- | --- |
| [`infinity_canvas`](https://pub.dev/packages/infinity_canvas) | `0.11.0`; very new; pub.dev lists all six Flutter platforms | Mixed positioned-widget, painter, and overlay layers; typed IDs; world/screen conversion; camera and item sub-APIs; measurement and culling | Infinite-scene renderer, not an editing core: no selection/resize/rotation handles or snapping. Learn its measurement and controller decomposition; do not depend for the finite editor. | MIT per its [repository license](https://github.com/vento007/infinity_canvas/blob/main/LICENSE); source may be adapted with the notice retained. |
| [`infinite_canvas`](https://pub.dev/packages/infinite_canvas) | `0.0.10`; all six platforms; repository activity was last observed in 2024 | Arbitrary widget children with generic values; single/multi selection, marquee, z-order, camera, and grid snap for move/resize through its [`node`](https://pub.dev/documentation/infinite_canvas/latest/infinite_canvas/InfiniteCanvasNode-class.html) and [`controller`](https://pub.dev/documentation/infinite_canvas/latest/infinite_canvas/InfiniteCanvasController-class.html) APIs | Infinite graph/edge/menu model; mutable controller-owned nodes; no rotation or peer/canvas-edge smart guides. Its source derives identity from `key.toString()`, which is unsuitable for stable domain IDs. Learn selection/marquee/z-order patterns only. | [Apache-2.0](https://github.com/rodydavis/infinite_canvas/blob/main/LICENSE). Copying requires the Apache license/notice/change obligations described below. |
| [`fluera_canvas`](https://pub.dev/packages/fluera_canvas) | Pub.dev `0.10.4`; verified publisher; active repository `main` is materially ahead of the release | Rich selection, transforms, grid snapping and smart guides. The unpublished pure geometry [`SnapEngine`](https://github.com/Lorencoshametaj/fluera_canvas/blob/63b93f16de01f45b2cac526da365b6796b86adc9/lib/src/canvas/snap/snap_engine.dart) returns snapped bounds and separate guide descriptors. | Large drawing/scene/history/persistence/export editor, not arbitrary Flutter widgets. Main/release divergence makes depending on its focused snap API unsafe. The engine is axis-aligned, scans candidates, and does not implement equal-spacing snapping. Learn from the pinned source, then own a focused engine. | [MIT](https://github.com/Lorencoshametaj/fluera_canvas/blob/main/LICENSE); targeted adaptation is legally suitable with copyright/license notice retained. |
| [`flutter_painter_v2`](https://pub.dev/packages/flutter_painter_v2) | `2.1.0+1`; all six platforms; last published about 17 months before this review | Its object domain is close to transform scaling: `ObjectDrawable` has position, rotation angle and scale, with [`TextDrawable`](https://pub.dev/documentation/flutter_painter_v2/latest/flutter_painter_pure/TextDrawable-class.html) and [`ImageDrawable`](https://pub.dev/documentation/flutter_painter_v2/latest/flutter_painter_pure/ImageDrawable-class.html); also useful selection, undo/redo, and alignment-assist ideas | Painter/raster objects rather than arbitrary widgets. It has transform scale but not an independent logical layout-size operation. Learning source only. | [MIT](https://pub.dev/packages/flutter_painter_v2/license); reusable with notice, but the object taxonomy should be rederived for widget content. |
| [`pro_image_editor`](https://pub.dev/packages/pro_image_editor) | Active, mature, all Flutter platforms | Layer taxonomy, text/widget/image layers, ordering, multi-selection, history, helper lines, and a separated [`LayerInteractionManager`](https://pub.dev/documentation/pro_image_editor/latest/features_main_editor_services_layer_interaction_manager/LayerInteractionManager-class.html) | A complete image-editor workflow/UI with image crop/export assumptions and a much larger dependency surface. Useful product reference, wrong boundary and state ownership. | BSD-3-Clause per its [pub.dev license](https://pub.dev/packages/pro_image_editor/license); targeted source study/reuse is possible with the required notice. |
| [`infinite_canvas_viewer`](https://pub.dev/packages/infinite_canvas_viewer) | `0.0.8`; all six platforms; README labels it work in progress | `CanvasController` and `RectTransform(bounds, angle, onNewBounds, child)` are useful API-shape references for arbitrary widgets | Infinite/WIP viewer, no documented smart snapping, and not an externally controlled object collection. Do not depend. | MIT per [pub.dev](https://pub.dev/packages/infinite_canvas_viewer/license); learning only. |
| [`sticker_view`](https://pub.dev/packages/sticker_view) | `0.0.4`; old; pub.dev lists Android and iOS only | Small arbitrary-widget example with move/rotate/resize/delete/z-order and capture | Mobile-only, stale, no smart snapping, and sticker-view state/API rather than a general controlled scene. | MIT per [pub.dev](https://pub.dev/packages/sticker_view/license); low-value learning source. |

## Explicit package audits

### `canvas_editor` 1.0.2 — feature-complete demo, poor foundation

[`canvas_editor` 1.0.2](https://pub.dev/packages/canvas_editor) advertises
arbitrary widget views, move/resize/rotate/flip/zoom, undo/redo, multi-selection,
and screenshot capture across all six Flutter platforms. Its public shape is
imperative: `CanvasEditorView` reports initialization, after which a controller
adds and mutates views. It does not accept an externally controlled immutable
object list or propose typed object changes.

The published source reinforces the mismatch:

- [`editor_view.dart`](https://github.com/niilx/canvas_editor/blob/975ee8281ea4865006481c3bc0939adae3dcd986/lib/src/editor_view.dart)
  stores mutable `ResizableWidget` instances and addresses objects by list
  position;
- [`resizable_widget.dart`](https://github.com/niilx/canvas_editor/blob/975ee8281ea4865006481c3bc0939adae3dcd986/lib/src/resizable_widget.dart)
  exposes its `State` instance to external mutation, creates time-based keys,
  stores transforms as opaque matrices, includes a hard-coded global Y offset,
  and infers the end of a gesture with a timer; and
- the published archive contains only four library files and no tests.

The package was last published roughly 18 months before this review and uses an
unverified uploader. It is [`MIT`](https://github.com/niilx/canvas_editor/blob/975ee8281ea4865006481c3bc0939adae3dcd986/LICENSE),
so copying is legally possible with the notice retained, but its architecture
should not be copied. At most, use it as a UX checklist.

### `bounding_box` 0.1.0 — customizable overlay, incorrect ownership/geometry

[`bounding_box` 0.1.0](https://pub.dev/packages/bounding_box) exposes a mutable
`BoundingBoxController` containing position, size, rotation, enabled state, and
many handle-style fields, plus a full-screen `BoundingBoxOverlay`. Pub.dev lists
all six Flutter platforms; it was the package's first release, about 14 months
before this review. The package has a verified publisher but no linked public
source repository; the exact published source is available in the
[`0.1.0` archive](https://pub.dev/api/archives/bounding_box-0.1.0.tar.gz).

The archive is not a sound geometry reference. Resize handles are visually
rotated, but resize applies global `dx`/`dy` directly to unrotated width,
height, and position instead of inverse-rotating the drag delta. The overlay
also disposes the caller-supplied controller. Domain geometry, selection state,
serialization dependencies, and UI styling are mixed into one mutable
controller. There is no object collection, controlled change event, snapping,
or independent transform scale.

The archive is MIT-licensed, so source reuse is legally possible with its
notice. The implementation quality makes even targeted copying unattractive;
handle placement is simple enough to derive independently and test correctly.

### `sticker_editor_plus` 1.1.2 — closed sticker editor, not arbitrary objects

[`sticker_editor_plus` 1.1.2](https://pub.dev/packages/sticker_editor_plus)
supports Android, iOS, macOS, and web, but not Linux or Windows. It was
published roughly 12 months before this review. Its domain is limited to
mutable text and picture/URL models, bundled toolbars/bottom sheets, JSON
serialization, and a `Get` dependency; it is not an arbitrary widget scene or
a controlled list API.

The published gesture widgets mutate their models directly. The
[`sticker_box.dart`](https://github.com/blossomdiary/sticker_editor_plus/blob/23b523a6f07ca96bfc06e20d1992f3d34324c9a0/lib/src/widgets/sticker_widget/sticker_box.dart)
increments scale by a fixed amount rather than using the native gesture's scale
factor and checks only partial untransformed bounds. The
[`text_box.dart`](https://github.com/blossomdiary/sticker_editor_plus/blob/23b523a6f07ca96bfc06e20d1992f3d34324c9a0/lib/src/widgets/text_widget/text_box.dart)
couples editing, transform, and toolbar behavior. There is no logical resize,
snapping, general selection manager, or canvas-camera abstraction.

The package is
[`MIT`](https://github.com/blossomdiary/sticker_editor_plus/blob/23b523a6f07ca96bfc06e20d1992f3d34324c9a0/LICENSE)
and its source is legally reusable with notice. It is useful only as a simple
sticker-editor UX example; do not depend on or copy its state/gesture design.

### `matrix_gesture_detector_pro` 1.0.0 — obsolete wrapper around native input

[`matrix_gesture_detector_pro` 1.0.0](https://pub.dev/packages/matrix_gesture_detector_pro)
is a single-file wrapper that receives Flutter scale gestures and composes
translation, scale, and rotation into `Matrix4`. It exposes no object,
selection, bounds, constraint, snapping, or canvas semantics, and no gesture-end
callback. Its public model is the opaque matrix that the proposed object API
should intentionally avoid.

It was published about three years before this review and its SDK constraint is
`>=2.18.2 <3.0.0`, making the release incompatible with Dart 3. Pub.dev reports
an unknown license, but the exact published archive and repository contain a
[`BSD-2-Clause` license](https://github.com/zhaolongs/matrix_gesture_detector_pro/blob/032dc85de44baac28c56857b6d30430f55e29fb7/LICENSE).
The code could legally be reused with the notice retained, but Flutter's native
[`ScaleUpdateDetails`](https://api.flutter.dev/flutter/gestures/ScaleUpdateDetails-class.html)
already supplies the required gesture inputs. Do not depend on or copy this
wrapper.

### `flutter_img_editor` 0.0.7 — useful coordinate/history examples only

[`flutter_img_editor` 0.0.7](https://pub.dev/packages/flutter_img_editor) is a
full image editor with crop, free rotation, text overlays, history, toolbars,
and image export. Pub.dev lists Android, iOS, Linux, macOS, and Windows, but not
web. It was published roughly six months before this review by an unverified
uploader.

Its model is one base image plus text layers, not arbitrary widget/image/text
objects on a finite controlled scene. The large mutable controller and image
crop/rotation coordinate assumptions are therefore the wrong package boundary.
Two focused files are nevertheless useful learning sources:

- [`coordinate_transformer.dart`](https://github.com/xinqingaa/image_editor/blob/00c7d28b213539048fb3f6e140f86c9ae726da08/lib/utils/coordinate_transformer.dart)
  makes screen/image coordinate conversion explicit; and
- [`history_manager.dart`](https://github.com/xinqingaa/image_editor/blob/00c7d28b213539048fb3f6e140f86c9ae726da08/lib/controller/history_manager.dart)
  illustrates snapshot-based undo/redo ownership.

It is [`MIT`](https://github.com/xinqingaa/image_editor/blob/00c7d28b213539048fb3f6e140f86c9ae726da08/LICENSE),
so targeted adaptation is possible with notice. Do not copy the full editor or
depend on it for the canvas core.

## Snapping and guide implications

None of the small transform packages supplies the desired smart snapping.
`infinite_canvas` provides only grid snapping; the published
`flutter_box_transform` provides none. `fluera_canvas` has the nearest source
boundary, but its useful pure engine is ahead of its pub.dev release.

The new package should make snapping a geometry strategy, not a behavior buried
in a widget or controller. Evidence from `fluera_canvas` supports a result that
separates corrected geometry from guides. The missing pieces should be explicit
in our contract:

- screen-space tolerance converted through camera scale, so snapping feels
  constant at every zoom;
- candidates supplied by the scene/index rather than discovered through widget
  tree or global-key inspection;
- canvas edge/center, peer edge/center, grid, and later equal-spacing policies;
- deterministic priority/tie-breaking and an active snap lock/hysteresis;
- axis constraints appropriate to move versus individual resize handles; and
- guide descriptors returned to a caller-provided painter/builder.

The existing focused investigation,
[`flutter_snap_alignment_packages.md`](./flutter_snap_alignment_packages.md),
contains the proposed indexed geometry boundary and performance rationale.

## API consequences supported by the research

The evidence favors these boundaries for the forthcoming architecture:

- Public objects should expose stable `id`, position, logical `size`, rotation,
  transform scale, z-order/stack order, and arbitrary typed `data`. Keep
  `Matrix4` as an implementation detail or derived value.
- Content belongs in a caller builder keyed by the object/data type. This keeps
  the core independent of image, text, design-system widget, or application
  persistence models.
- Scene objects should be immutable values. A canonical controller may own the
  ordered collection and publish committed semantic changes, or a controlled
  constructor may propose replacements to its parent; do not make callers
  reconcile both models during a gesture.
- Camera, object selection, and object data are distinct state domains even if
  one public controller exposes them through separate subvalues. Commands such
  as `select`, `zoomToFit`, and `centerOn` should have explicit ownership and
  predictable notification semantics.
- Logical resize and transform scale need distinct gestures/handles and fields.
  Neither a single `Rect` nor a single opaque matrix preserves this distinction.
- Multi-selection can be layered on later if selection is represented as a set
  of IDs and transform geometry operates on an explicit selection hull. It
  should not force graph edges, menus, persistence, inspector panels, or export
  UI into the canvas package.

## License and copying guidance

Package licenses permit reuse but do not erase attribution obligations:

- MIT and BSD-2/BSD-3 source can be modified and redistributed when the
  relevant copyright and license notices are retained.
- Apache-2.0 redistribution requires the license, retention of applicable
  notices, and prominent notices for modified copied files; a dependency is
  cleaner than silently transplanting source.

For any copied implementation, record the exact file, commit/release, and
license in the destination. Prefer documented behavior plus an independent,
well-tested implementation for small geometry algorithms. The safest direct
source-learning candidates here are the pinned MIT `fluera_canvas` snap engine,
the MIT `infinity_canvas` controller/measurement separation, and the targeted
MIT coordinate/history helpers in `flutter_img_editor`. The `canvas_editor`,
`bounding_box`, and `sticker_editor_plus` implementations are legally reusable
but technically poor templates.

## Recommendation to carry into architecture discussion

Build a focused package whose public center is a finite canvas, typed immutable
objects, and one unambiguous state owner. The architecture plan recommends a
controller-owned V1; a future `objects + onObjectChanged` constructor can be a
controller adapter rather than a second simultaneous source of truth. Use
Flutter's native camera and gesture APIs, evaluate pure `box_transform` only
for logical resize geometry, and own rotation, transform scale, selection, and
snapping behind independently testable geometry policies.

The most important early prototype is not another editor UI. It is a testbed
that proves four transforms remain coherent together: camera pan/zoom, object
move, rotation-aware logical resize, and paint scale that does not alter the
widget's logical constraints. Once that contract works with arbitrary real
widgets, image and text adapters become straightforward package clients rather
than special cases in the canvas core.

# Flutter Widget Previewer and Desy preview comparison

Research date: 2026-08-13. This note compares Flutter's first-party Widget
Previewer with the currently declared Desy dogfood preview system. It is
evidence for a later product decision, not an implementation proposal or a
second registry.

Primary external sources are Flutter's [Widget Previewer guide](https://docs.flutter.dev/tools/widget-previewer), the framework [`Preview` API](https://api.flutter.dev/flutter/widget_previews/Preview-class.html), the [`MultiPreview` API](https://api.flutter.dev/flutter/widget_previews/MultiPreview-class.html), and Flutter's [annotation implementation](https://github.com/flutter/flutter/blob/main/packages/flutter/lib/src/widget_previews/widget_previews.dart). The guide says the Previewer is stable as of Flutter 3.47; it should be verified against the selected SDK before treating that as the project's upgrade target.

## What Flutter Widget Previewer provides

Flutter discovers public `@Preview` annotations from
`package:flutter/widget_previews.dart`. Supported entry points are public
top-level or static functions returning `Widget`/`WidgetBuilder`, and public
widget constructors or factories without required parameters. `Preview` itself
is expressly documented as unstable and subject to change. [API reference](https://api.flutter.dev/flutter/widget_previews/Preview-class.html).

The tool starts through `flutter widget-preview start` or supported IDE tabs.
The command serves a web preview environment and caches project builds in
`.widget_preview/`. The environment provides per-preview zoom, brightness
toggle, individual hot restart, a global restart, and search/filtering by
preview name, group, source file, and package. IDEs can additionally filter to
the selected file. [Official guide](https://docs.flutter.dev/tools/widget-previewer).

An annotation can set a name, group, artificial `Size` constraint, text scale,
widget-tree wrapper, Material/Cupertino preview theme, brightness, and
localizations. Multiple annotations—or a custom `MultiPreview`—create a matrix
of configurations. Custom `Preview`/`MultiPreview` annotations can transform
their configurations at runtime, which is useful when annotation constants are
too restrictive. [Preview API](https://api.flutter.dev/flutter/widget_previews/Preview-class.html), [MultiPreview API](https://api.flutter.dev/flutter/widget_previews/MultiPreview-class.html).

## Constraints that matter to Desy

The Previewer is web-built. Native plugins and calls into `dart:io` or
`dart:ffi` are unsupported; transitive dependencies can load, but invoking
those APIs throws. `dart:ui` asset loading must use package asset paths. It
also supports only one project or Pub workspace per IDE session. [Restrictions
and limitations](https://docs.flutter.dev/tools/widget-previewer#restrictions-and-limitations).

The annotation's `size` deliberately applies artificial constraints, and the
tool automatically constrains otherwise unconstrained widgets to roughly half
the previewer viewport. Flutter recommends explicit sizes where possible. That
is useful for isolated source-level specimens, but it is not the same contract
as a faithful responsive artboard. [Official guide](https://docs.flutter.dev/tools/widget-previewer#customize-a-preview).

Annotation callback arguments must be public, static, and constant for code
generation. This restriction does not apply to previews assembled at runtime
in `transform()`. [Preview API](https://api.flutter.dev/flutter/widget_previews/Preview-class.html).

## Current Desy dogfood baseline

The dogfood executable declares themes, atoms, and components in one
`DesyRegistry` at
`packages/desy_design_system/example/lib/src/desy_design_system_registry.dart`.
Each component has a stable ID, real-widget builder, immutable typed knob
schema, optional named instances, and optional named scenarios through
`DesyComponentScenario` in `packages/desy_bench/lib/src/registry.dart`. This
supports Desy's consumer-owned registry and real-widget requirements rather
than annotation discovery.

Its detail canvas already renders the selected consumer theme using
`DesyWidgetPreview`, provides typed knob controls, named scenarios/instances,
zoom/pan, and a responsive drag artboard or an accurate iPhone 15 Pro / iPad
Pro 11 device frame. Responsive previews receive their dimensions from the
artboard; device frames preserve fixed screen, pixel-ratio, platform, and
safe-area geometry before the completed result is scaled down. Relevant code:
`packages/desy_bench/lib/src/workbench/presentation/detail_screen.dart`,
`packages/desy_bench/lib/src/workbench/widget_preview.dart`, and
`packages/desy_bench/lib/src/device_preview.dart`.

Desy additionally applies preview-only text scale, direction, bold text,
high-contrast, and animation settings, plus a semantics/hit-target overlay.
Those controls live in
`packages/desy_bench/lib/src/workbench/workbench_session.dart` and
`packages/desy_bench/lib/src/workbench/presentation/preview_accessibility_overlay.dart`.

| Concern | Flutter Widget Previewer | Existing Desy dogfood preview |
| --- | --- | --- |
| Discovery and inventory | Generated from source annotations; annotation API is unstable. | One immutable consumer registry with stable component IDs and validated paths. |
| Widget context | Wrapper plus Material/Cupertino preview theming. | Consumer-selected `DesyTheme.wrap`, keeping consumer widgets under their real theme. |
| Variants | Repeated annotations or `MultiPreview`; supports configuration matrices. | Typed knobs, named instances, and named real-widget scenarios. |
| Sizing | Annotation `Size` is artificial; unconstrained fallback is tool-defined. | Responsive drag box supplies logical constraints; named devices retain fixed physical/media geometry and scale only after layout. |
| Inspection ergonomics | Source/name/group/package search; IDE selected-file filter; preview-local restart. | Registry navigation, canvas selection, zoom/pan, instances, device presets, accessibility overlay, and typed controls. |
| Runtime boundary | Web preview runtime; native and `dart:io`/`dart:ffi` behavior cannot be exercised. | Flutter-platform-compatible dogfood app; preview runs inside the actual dogfood executable. |

## Useful patterns to evaluate borrowing

1. **Source-oriented narrowing.** Previewer filtering by source file and IDE
   selection is a small, legible bridge between Dart editing and visual review.
   Desy already carries optional `source` metadata on a registry component, so
   any equivalent should derive from that single registry rather than scan
   annotations or create another inventory.

2. **Reusable preview presets.** A consumer-specific custom annotation reduces
   repeated wrapper/theme/localization setup. The analogous Desy opportunity is
   a typed, registry-derived preview preset or matrix that composes its existing
   theme, accessibility, scenario, and device contracts—without replacing
   consumer widgets or duplicating registry declarations.

3. **Configuration matrix language.** `MultiPreview` makes common matrices
   (such as light/dark) concise. Desy can evaluate an explicit declarative
   matrix vocabulary for existing named scenarios, themes, text scales,
   directions, and devices. It should retain stable IDs and typed values rather
   than adopting annotation-only discovery.

4. **Preview-local recovery.** A restart action scoped to one isolated preview
   is a useful inspection affordance when state becomes contaminated. Its value
   is independent of Flutter's web scaffold and can be evaluated for Desy's
   real-app preview tree.

5. **Do not copy artificial constraints as the default.** Flutter's `size`
   parameter is intentionally an artificial constraint, which conflicts with
   Desy's documented real-logical-size-then-scale preview contract. Retaining
   Desy's responsive and device geometry better satisfies Core Principle 8.

6. **Do not make the Widget Previewer the dogfood source of truth.** Its web
   runtime limitations would exclude platform-dependent consumer widgets; its
   annotation discovery would also compete with the declared `DesyRegistry`.
   It is better evaluated as a complementary source-local authoring view than
   as Desy's registry, canvas, or cross-platform preview replacement.

## Evaluation questions before adoption

- Does the Flutter SDK selected for Desy actually include the stable Previewer
  command and `widget_previews` API? The official guide's version statement
  should be checked against that exact SDK.
- Can a narrow dogfood fixture use only public, constant preview declarations
  while preserving the real `DesyDesignSystemScope` and its assets?
- Which previews genuinely benefit from a source-local IDE/browser view, as
  opposed to Desy's registry-first canvas, scenario, device, and accessibility
  review workflows?
- Can any Desy-to-Previewer bridge be generated or hand-authored as a clearly
  disposable evaluation fixture, without making annotations a second component
  catalogue?

The existing `packages/desy_design_system/widgetbook/` experiment shows the
right evaluation boundary: it renders production controls in the real Desy
theme while explicitly remaining outside the canonical registry. A Widget
Previewer comparison should preserve that boundary.

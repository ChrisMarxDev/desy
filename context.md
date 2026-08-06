# Desy Bench — handoff context

This is the durable handoff for the next agent. Treat it as a snapshot of the
product decisions and current implementation, not as a replacement for
[`CORE_PRINCIPLES.md`](CORE_PRINCIPLES.md).

## Product in one sentence

`desy_bench` is an opinionated, very polished Flutter workbench for a design
system a repository already owns. It is Widgetbook-inspired, but its goal is
to help people and agents separate component/system design from composing
screens and applications.

The workbench consumes a consumer-declared registry. It must never become a
second design-system source of truth, a general Figma clone, or a backend
product.

## Repository shape and authority

- `packages/desy_bench/` is the reusable package. Keep it independent of the
  sample's visual language.
- `example/sample_design_system/` is the real integration testbed. It owns the
  Harbor tokens, themes, production sample widgets, and its registry.
- `packages/desy_screenshot_builder/` is a small dummy workspace extension.
  It proves the extension boundary; it is not a finished screenshot product.
- `tools/desy_cli/` is intentionally deferred until the registry API settles.
- `concept/` is historical seed material only. Do not develop it as product
  code. There is no `prototype/` directory in the current workspace.
- `AGENTS.md`, `CORE_PRINCIPLES.md`, the root README, and `docs/` are the
  maintained project context. Read them before changing architecture.
- Root `Taskfile.yml` delegates to nested package/sample Taskfiles. Use it;
  do not add one-off shell instructions to documentation as the primary path.

## Non-negotiable product decisions

1. **One declared system.** A consumer declares one `DesyRegistry`; all
   catalogue, navigation, future validation, screens, and agent guidance
   derive from it.
2. **Consumer ownership.** Themes, tokens, and production widgets remain in
   normal consumer source code. Desy renders them under their real theme;
   it does not recreate them.
3. **Primitive first.** Every registered thing ultimately resolves to a widget
   builder. Colors, typography, numeric values, motion, effects, assets, and
   components are typed conveniences, not a mandatory taxonomy.
4. **Folders are the structure.** `DesyFolder` is recursively nestable and
   structures registry content. `Atoms` is a top-level folder containing
   Colors, Fonts, and later other foundations; it is not a duplicate atom
   entry type. Each folder has a required stable ID; the sample tree is explicit rather
   than inferred from component categories.
5. **Immutable, validated declarations.** `DesyRegistry` and `DesyFolder`
   make defensive immutable copies of their collections. Themes, folders,
   artifacts, showcases, and installed extensions share a unique ID namespace;
   `DesyWorkbenchApp` validates it during startup and fails early on conflicts.
6. **Ask for minimum information.** Derive UI from typed objects and provide
   defaults. Descriptions, source paths, accessibility guidance, scenarios,
   and knobs are optional—not a form every consumer must fill out.
7. **Typed, object-shaped APIs.** Prefer rich domain objects and composable
   primitives over string maps, flag-heavy configuration, or copied lists.
8. **Forui owns bench chrome.** Navigation, panels, controls, workbench
   surfaces, and shell stay Forui. Consumer previews can use any library.
9. **Native text-entry exception.** All editable Desy/sample fields now use
   the central `DesyTextField`, backed by Flutter `TextField`/`EditableText`.
   It uses a transparent `Material` host required by Flutter and deliberately
   omits decorative field chrome. Do not reintroduce `FTextField`.
10. **Real preview sizing.** Render consumer widgets at their intended logical
   dimensions, then scale the completed preview into the available canvas.
   Never make previews look compact by giving the consumer artificial tiny
   constraints.
11. **Local first.** No account, backend, cloud source of truth, or production
    code generation in this first release.
12. **Extensions are typed and narrow.** Workspace extensions get a read-only
    registry/theme helper context, supply only their screen, and do not own a
    second registry or core routing.

The full wording and other decisions are in `CORE_PRINCIPLES.md`. Principle
7 contains the explicit text-editor exception.

## Current public model

- Public entrypoint: `packages/desy_bench/lib/desy_bench.dart`.
- Main public contracts: `DesyRegistry`, `DesyFolder`, `DesyTheme`, primitive
  entries, `DesyComponent`, typed knobs, component instances, and
  `DesyWorkspaceExtension`.
- `DesyFolder` supports nested `children` and recursive `all*` accessors.
- Workbench routes, navigation, atlas, details, and extensions consume the
  public registry directly. Keep that single path; do not introduce adapters
  or copied registry collections.
- All declaration collections are immutable. `DesyWorkbenchApp` calls
  `registry.validate` with extension IDs in `initState`, so duplicate stable
  IDs fail at startup rather than becoming ambiguous navigation.
- `DesyComponentInstance.icon` supplies the icon for component-instance swap
  controls. The selected instance and every option row use it, with a neutral
  component glyph when the consumer omits one.
- `DesyAssetEntry` is media-resource-only. Put consumer-owned still images,
  animated GIFs, videos, and sounds under `Atoms/Assets` using its typed
  constructors; UI glyphs and arbitrary widget builders are not asset entries.
- Component instances are owned by their component. Palette leaves should be
  instances; selecting one reveals the same knob UI used by details/sketch.
- Effects currently mean widget decorators with box shadows. Shaders and
  transform effects are intentionally future work.
- Numeric foundations are represented by typed `DesyNumericEntry` values and a
  dedicated Measurements board. The sample deliberately removed Shape and
  Spacing as separate sidebar sections.
- The optional `icon` parameter/property on workspace extensions controls its
  sidebar icon; Desy supplies a neutral Lucide fallback.

## Workbench routing and layout

- GoRouter is used. Routes use `NoTransitionPage`: route changes must be
  instant, with no page animations.
- Desktop normal routes are mounted in a `ShellRoute` with a collapsible
  sidebar. The shell owns the sidebar; detail pages do not replace it.
- The desktop sidebar expands and collapses with a 180 ms animation. Its
  collapsible groups are Workspace, Catalogue, and AI; Catalogue renders the
  consumer's folder tree (including Atoms and Components). The sidebar is
  intentionally dense because the system will grow. Clicking either a section
  heading or its chevron toggles that section.
- Theme switching is global and reactive. The active theme index rebuilds the
  root `FTheme` and Flutter `Theme`; it is selected from the sidebar's top
  dropdown, not a separate primary workflow.
- The sketch is a child route of Atlas but deliberately does **not** expose the
  normal sidebar. It has its own compact exit affordance/keyboard hint.
- At wide widths, one shared document `SelectionArea` wraps the workbench so
  non-editable text remains globally selectable. At compact widths (<640 px),
  that wrapper is omitted; native text fields retain their own selection
  behavior. The transformable sketch instead uses a disabled selection
  boundary, avoiding selection-registrar assertions without making its canvas
  interaction participate in document selection.
- Global shortcuts traverse the registry-derived navigation tree. Keep all new
  shortcut registration on that central path rather than adding local ad-hoc
  handlers.

## Detail preview and bezels

The relevant code is
`packages/desy_bench/lib/src/workbench/presentation/detail_screen.dart`.

- Detail layout is only a preview plus its controls inspector. The old large
  header (back button, name/category, registry path) was intentionally removed.
  The persistent sidebar provides navigation.
- The preview has a compact in-canvas control strip containing Canvas, iPhone
  15 Pro, and iPad Pro 11. There is no accessibility-debugger/A11y mode; that
  feature was removed deliberately.
- The stage has a dotted background. It is painted *only* by
  `_DottedPreviewPainter`; the background color is supplied by `ColoredBox`.
  Do not add `canvas.drawColor()` to the painter: an earlier CustomPaint
  implementation appeared to paint over the surrounding top controls.
- `LayoutBuilder` is intentionally present in `DesyPreviewCanvas` to bound
  drag and resize to the available canvas. It was briefly removed, but dragging
  became unreliable. Keep a simple bounded version instead of a second nested
  layout system.
- Detail artboards have a hard 8×8 logical minimum. Preserve that floor in any
  future resize implementation.
- A bezel is a `DeviceFrame` centered inside the artboard. Its `screen` uses
  `Align(child: child)` specifically so the registered widget keeps its normal
  intrinsic size instead of expanding to fill the device screen. The full
  device is then scaled down to fit the artboard.
- The detail canvas and the components sketch have separate interaction state.
  The detail stage is ephemeral session state, not a saved screen manifest.

## Components sketch

- The sketch is a composition surface, not a scaffold around each component.
  Selected items use minimal Figma-like bounding boxes and square corner
  handles. Widgets may overlap.
- The palette follows the registry catalogue tree; final leaves are component
  instances. Clicking an instance exposes the canonical shared knob panel in
  the side controls.
- The sketch has sidebar tabs for Assets and the current Canvas stack, a small
  grid, transform controls, and real device artboards. The iPhone 15 Pro
  screen is **393×852** logical pixels; the iPad Pro 11 screen is **834×1194**.
  Their `DeviceFrame` and `screenPath` are the source of bezel geometry, and
  the full frame scales uniformly into the scene without changing its aspect
  ratio.
- A component dropped on a screen attaches only when the pointer is inside its
  transformed `screenPath` (not merely the enclosing rectangle). Attached
  components store device-local logical coordinates, render under that
  device's real `MediaQuery`/safe area, and receive exactly one scene scale.
  Dragging outside the path detaches the component back to stage coordinates.
  During a move, the component keeps one stable interaction subtree and a
  transient scene rectangle; attach/detach ownership commits only on pointer
  up. This lets multi-update mouse drags continue across either screen
  boundary without disposing the active gesture recognizer.
- Device artboard resizing is aspect-locked, keeps the stationary resize edge
  fixed at scene boundaries, and remains safe in compact bounds. Attached
  components belong to their parent artboard's z-order group: local child
  insertion order is retained, while a later artboard stays above an earlier
  one and all of its children.
- When stage bounds first become known or shrink, an existing out-of-bounds
  device artboard is aspect-fit into the available stage. Artboards already
  contained by the stage, and stage growth, are no-ops. This normalization
  preserves each attached child's device-local logical geometry and alignment.
- A transient non-positive stage size after artboards exist preserves the last
  valid stage bounds and the exact artboard/child geometry. A genuinely
  zero-sized initial layout is safe and normalizes on its first positive size;
  coordinate conversion also guards zero and non-finite scene scales.
- Composition state is currently mutable and ephemeral in
  `components_canvas/components_canvas_controller.dart`. It is **not** yet a
  durable serializable manifest. If persistence is added, serialize registry
  IDs, legal slots, and values—not callbacks or app logic.

## Text-input decision (important)

Text input previously used `FTextField` and was visibly broken: caret and
selection were unreliable. The current central replacement is:

- [`DesyTextField`](packages/desy_bench/lib/src/desy_text_field.dart), exported
  from `desy_bench.dart`.
- It owns a persistent `TextEditingController`, supports controlled external
  values without recreating the controller during normal typing, enables
  interactive selection, and uses the platform native context menu/keyboard
  semantics.
- Its visible decoration is deliberately limited to hint text and optional
  prefix/suffix icons. It has no floating label, fill, border, custom padding,
  error line, or theme-colored cursor; labels and validation guidance remain
  accessibility semantics only.
- It is used by Atlas search, font preview text, string knobs, instance-picker
  search, and the sample `SampleTextField`. There should be no `FTextField`
  usages in maintained `.dart` sources.
- A transparent Material ancestor is technically required by Flutter's native
  `TextField`; it is an implementation host only, not a visual Material UI.
- There is a widget test proving the shared control contains a native
  `TextField`/`EditableText` and accepts input.

Manual macOS testing of mouse text selection remains worthwhile after any
future changes to app-level selection/focus behavior, even though the widget
test passes.

## Themes, previews, and visual policy

- A `DesyTheme` can declare `previewBackgroundColor` and optional `isDark`.
  The active theme changes the whole Desy shell and preview context
  reactively—not just an individual preview.
- Atlas cards, detail canvases, and sketch elements measure real consumer
  widgets at their intended logical dimensions (currently 1024 wide where a
  responsive measurement is required), then scale the completed result with a
  `FittedBox` or canvas transform only after the real widget exists.
- Detail/atlas canvas backgrounds should use the active preview background.
- Use Lucide icons (through Forui) for Desy chrome, not Material iconography.
- Do not use Material-looking controls in Desy chrome. The sole approved
  implementation exception is the native text editor described above.

## Extensions and experimental work

- `DesyWorkspaceExtension` is the extension abstraction. It provides an
  ID/name/optional description/optional icon and a `build` method.
- `DesyWorkspaceExtensionContext` exposes the immutable registry, active
  consumer theme, preview helper, component lookup, and instance lookup.
- `desy_screenshot_builder` is installed in the sample as the dummy extension
  and appears under Workspace.
- There is an experimental Showcases surface and experimental catalogue export
  code. Treat both as opt-in demonstrations, not proven product APIs.
- The feature-ranking HTML in `concept/features/` is seed/planning material.
  It includes ranked ideas and notes but is not authoritative implementation.
- AI/Prompt library is a placeholder navigation area. Do not turn it into an
  agentic system before primitive/system workflows are solid.

## Architecture debt and open questions

These are the main things a fresh agent should understand before starting new
feature work:

1. **Sketch persistence/export has not been designed.**
   A future manifest must follow the registry-ID/value rule. Do not store
   Flutter callbacks or arbitrary widgets.
2. **Accessibility inspection is intentionally out.**
   The intrusive `SemanticsDebugger` mode was removed. Accessibility remains a
   scaffold contract (keyboard, selection, semantics), but a future review
   tool needs a calmer, explicit design before it is reintroduced.
3. **CLI is still deferred.**
   Do not build `desy_cli` until the direct registry API and the extension/
   manifest boundaries are stable.
4. **Avoid scope jump to a Figma replacement.**
   The immediate product value is excellent primitives, components, previews,
   themes, knobs, and screen composition—not autonomous app generation.
5. **Seed material must not silently become product truth.**
   If a concept looks useful, port it intentionally into maintained source and
   docs rather than editing `concept/`.

## What was explicitly removed

- The old huge detail header (name, path, back action).
- The visual `SemanticsDebugger` / A11y preview mode and its session state.
- Forui `FTextField` usage in maintained source.
- Separate Shape and Spacing sample navigation sections.
- Route transition animations.

## Verification and runtime workflow

From the repository root, the canonical complete check is:

```sh
task check
task sample:run
```

`task check` runs root analysis and all three test suites. Verified on
2026-08-06: analyzer clean; 53 `desy_bench` tests, 2 screenshot-builder tests,
and 23 sample tests passed (78 total). Root `flutter test` is not equivalent
because it does not express this package-by-package workspace coverage.
Focused commands are
`task bench:test`, `task screenshot_builder:test`, and `task sample:test`.

For direct focused commands, run them inside the relevant package:

```sh
cd packages/desy_bench && flutter test
cd packages/desy_screenshot_builder && flutter test
cd example/sample_design_system && flutter test
```

Treat the native macOS app as the primary runtime target. The current native
smoke commands are:

```sh
cd example/sample_design_system
flutter build macos
flutter run -d macos --route /atlas/sketch
```

Verified runtime record (2026-08-06): the release macOS app built
successfully, and a debug launch directly into `/atlas/sketch` reached its VM
service without Flutter exceptions before a clean shutdown. Simulator tooling
is optional secondary coverage, not the default acceptance path.

## Suggested first move for the next agent

Read `AGENTS.md`, `CORE_PRINCIPLES.md`, this file, and the sample registry.
Then pick one contained concern—preferably a visual smoke test of the
bezel/preview surface or a persistence design—rather than expanding an
experimental boundary prematurely.

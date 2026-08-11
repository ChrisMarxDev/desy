# Desy Bench development

This is the maintained contributor guide. Keep it about implemented behavior;
future ideas belong in issues, not repository documentation.

## Architecture

The consumer's immutable `DesyRegistry` is the single declared source of truth.
Workbench screens read it through the app-wide registry scope and must not copy
its inventory into a second catalogue. Components form one flat list; their
validated slash paths provide navigation structure and registry accessors
provide derived views.

Every registered theme, artifact, prototype session, prototype,
workspace extension, and detail extension needs a stable ID unique in the
shared registry namespace.
Startup validation reports collisions and invalid declarations early.

Consumer previews build the real Flutter widget under the selected consumer
theme. Render at the intended logical dimensions, then scale the completed
preview inside the canvas. Do not force compact constraints onto the widget.

Preview vocabulary and behavior are shared across component details, Sketch,
and registry-declared Prototypes:

- **Canvas** is Desy's workspace around previews; it is not part of the app.
- **Drag box** is the workbench interaction boundary.
- **Responsive viewport** takes its logical dimensions from the drag box.
- **Device screen** uses the selected device's immutable logical viewport and
  media geometry. Desy does not insert `SafeArea`.
- **Bezel** is the visible device frame. The screen and bezel form one device
  preview, clipped at the screen edge and scaled down together when necessary.

Device selection is viewer session state, not serialized prototype data.
Consumer widgets and surface documents own overflow and scrolling; the
workbench never injects either behavior.

`packages/desy_design_system` is the only Desy-owned package that imports Forui
directly. `desy_bench` and packages under `packages/extensions/` consume its
public controls and theme surface. Those public APIs use Flutter and Desy types;
Forui widgets, variants, styles, and controllers remain private implementation
details. Compatibility aliases are migrated incrementally, and new workbench
surfaces must not add another alias or expose an `F*` type. Editable text uses
the centralized native `DesyTextField` exception described in
`CORE_PRINCIPLES.md`.

The Desy theme translates the committed Registry Spine visual language onto
Forui rather than mixing in another Flutter UI package. Primary actions remain
neutral black; `DesyVisualColors.signal` is reserved for focus, selection,
inspection, and annotation; positive green communicates runtime health. Light
workbench surfaces are white with one-pixel neutral structural dividers,
compact radii, and bundled Roboto typography. Screens and extensions consume
these semantic tokens instead of declaring local signal colors.

## Registry organization

Colors, Fonts, Icons, Measurements, Motion, and Effects are optional typed
parameters on `DesyRegistry`, not consumer folder branches. Desy derives the Atoms
section from the non-empty lists and omits it completely when none are supplied.
Numeric primitives use `DesyNumericEntry`; icon glyphs use `DesyIconEntry`.
Their explicit types select specialized boards without folder-name inference.

Components may be direct sidebar destinations. Desy derives their expandable
file tree from paths such as `/inputs/text`. A component is either a typed
bound-record component (`DesyComponent<K>`) or a static catalog
(`DesyStaticComponent`), both implementing `DesyRegistryComponent`. The full
contract is described in
[`docs/concepts/registry-component-contracts.md`](docs/concepts/registry-component-contracts.md);
component contracts, scenarios, and knobs are optional typed metadata, and a
real widget preview is the primitive requirement.

A typed component declares its immutable knob schema and its typed handle record
in one `knobs: (k) => record` callback, supplies one `build(context, knobs)`
used by every preview and instance, and declares `instances` only as stable IDs
plus typed knob overrides. The `widgetInstance` knob references another
registered instance by its registry-scoped `componentId.instanceId`; resolution,
cycle guards, and the missing-instance diagnostic are centralized in
`DesyWidgetResolver`. Ask consumers only for information Desy cannot derive.

The dogfood registry is the only maintained executable inventory:
`packages/desy_design_system/example/lib/src/desy_design_system_registry.dart`.
It must contain purposeful production-like entries, never test fixtures.

## Surface DSL

`DesySurfaceDocument` is the typed, serializable form of the local Desy screen
DSL. Parsing normalizes JSON immediately into immutable row, column, stack,
padding, scroll, spacer, and component nodes. Layout nodes only arrange content; every
visible UI element is a `DesySurfaceComponent` resolved through the active
registry. `DesySurfaceValidator` checks component IDs, named instances, knob
types, legal widget-instance choices, and registry-backed spacing before
`DesySurfacePreview` renders the real widgets under a consumer theme.

Scroll nodes explicitly select `horizontal` or `vertical` behavior and may
request a visible scrollbar. Different-axis nesting is supported for realistic
mocks; same-axis nesting remains renderable but produces a validation warning.

The DSL is a prototyping surface, not an SDUI runtime. Do not add callbacks,
navigation, networking, application state, arbitrary widget declarations, or
a second component catalogue to it.

## Sidebar model

The public sidebar building blocks live in
`packages/desy_design_system/lib/src/desy_sidebar.dart` and are registered under
`Components / Navigation / Sidebar` in the dogfood catalogue.

- `DesySidebarSection` is a named group whose label is non-interactive by
  default. The Components label is the narrow exception: it opens the Atlas
  root. A section may also expose a count and one small setting such as the
  Components grid/tree toggle.
- `DesySidebarItem` is an icon-and-label destination. The `.screen` constructor
  adds a trailing arrow for Workspace destinations that open another screen.
- Ordinary items have no trailing affordance. Their optional `children` retain
  the expandable file-browser tree used by Components.

The workbench sections are Registry, Prototypes, Atoms, and Components.
Prototypes lists consumer-declared sessions containing real Flutter directions.
Atoms lists only non-empty typed lanes; Components retains its file tree.

The planned Registry Spine shell keeps this live navigation visible while the
center moves between Atlas inspection, component details, and prototype
comparison. The shell-owned annotation service targets only explicitly scoped
registry previews and prototype widgets: scaffold chrome and editing controls
are never targets. Annotation handoff remains agent-neutral.

## Extensions

Optional packages live under `packages/extensions/` to keep the core boundary
obvious. Extensions receive typed, read-only registry/theme context and own
only their screen or detail UI and explicit local state.

An opt-in standalone workspace extension replaces the ordinary Desy navigation
for the duration of its route and receives a typed exit callback. This is for a
workflow that needs its own focused shell, not for adding another global
navigation system.

- `desy_screenshot_builder` is an experimental workspace extension proving the
  screen-extension boundary; it is not a persistence format.

Extensions must not import hidden workbench state, mutate routing, introduce a
second registry, or import Forui directly.

## Commands and verification

The root `Taskfile.yml` is the command entry point:

```sh
task pub:get
task dogfood:run_mac
task dogfood:web
task format
task check
```

`task check` runs workspace analysis, the Forui dependency-boundary check, all
six package/application test suites, and a production dogfood web build.
Focused tests are available as `task bench:test`, `task design_system:test`,
`task dogfood:test`, and `task screenshot_builder:test`.

For debug-only widget inspection, run the dogfood app and use
`task simdeck:describe:flutter`. SimDeck is a development companion, not a
runtime dependency or production integration.

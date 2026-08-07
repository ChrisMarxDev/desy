# Desy Bench development

This is the maintained contributor guide. Keep it about implemented behavior;
future ideas belong in issues, not repository documentation.

## Architecture

The consumer's immutable `DesyRegistry` is the single declared source of truth.
Workbench screens read it through the app-wide registry scope and must not copy
its inventory into a second catalogue. Components form one flat list; their
validated slash paths provide navigation structure and registry accessors
provide derived views.

Every registered theme, artifact, showcase, workspace extension, and
detail extension needs a stable ID unique in the shared registry namespace.
Startup validation reports collisions and invalid declarations early.

Consumer previews build the real Flutter widget under the selected consumer
theme. Render at the intended logical dimensions, then scale the completed
preview inside the canvas. Do not force compact constraints onto the widget.

`packages/desy_design_system` is the only Desy-owned package that imports Forui
directly. `desy_bench` and packages under `packages/extensions/` consume its
public controls and theme surface. Editable text uses the centralized native
`DesyTextField` exception described in `CORE_PRINCIPLES.md`.

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

The workbench sections are Workspace, Atoms, Components, and Showcases.
Workspace contains Atlas, Sketch, AI prompts, and installed screen extensions.
Atoms lists only non-empty typed lanes; Components retains its file tree;
Showcases lists compositions.

## Extensions

Optional packages live under `packages/extensions/` to keep the core boundary
obvious. Extensions receive typed, read-only registry/theme context and own
only their screen or detail UI and explicit local state.

- `desy_agent_annotations` collects an entry-scoped comment and sends one typed
  submission to a consumer callback. The consumer owns persistence,
  authentication, and external integrations.
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
five package/application test suites, and a production dogfood web build.
Focused tests are available as `task bench:test`, `task design_system:test`,
`task dogfood:test`, `task agent_annotations:test`, and
`task screenshot_builder:test`.

For debug-only widget inspection, run the dogfood app and use
`task simdeck:describe:flutter`. SimDeck is a development companion, not a
runtime dependency or production integration.

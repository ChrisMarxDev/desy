# How Desy Bench works

Desy Bench is a local Flutter workbench for a design system that lives in the
consumer repository. It does not recreate a system in JSON, screenshots, or a
hosted catalogue. A consuming app declares a `DesyRegistry`; the Bench derives
its Atlas, theme switcher, live playground, and future validation from that
single declaration.

## The working model

```text
Consumer Flutter code
  └─ DesyRegistry
      ├─ themes
      ├─ primitive entries
      ├─ components + contracts
      └─ scenarios, named instances, and knobs
            ↓
       Desy Bench (desy_design_system scaffold)
            ↓
       real themed Flutter previews
```

The workbench consumes that public `DesyRegistry` directly. There is no
adapter layer or second internal catalogue model. The workbench is deliberately
outside the consumer theme: only the preview is wrapped with the selected
`DesyTheme`, so the Bench chrome stays neutral while the inspected widget runs
in its actual production context.

Desy's own chrome is supplied by `packages/desy_design_system`. It centralizes
the Forui dependency, neutral themes, Material bridge, icon vocabulary,
controls, and native text editor. `desy_bench` and Desy-owned extensions import
that package rather than Forui directly; this does not constrain the component
library used by consumer previews.

Registry and folder lists are defensive immutable declarations. Each theme,
folder, artifact, showcase, workspace extension, and detail extension shares
one unique stable ID namespace. `DesyBenchApp` runs
`registry.validate(...)` at startup and rejects duplicate declarations before
creating the workbench session.

## Typed extension boundaries

Workspace extensions own routed screens. Detail extensions are a parallel,
narrower boundary: `DesyDetailExtension` renders in the inspector for one
resolved registry entry and creates no navigation. It receives a read-only
`DesyDetailExtensionContext` containing the same registry object, the active
theme, resolved registry entry, and an optional component declaration. The
host owns placement, heading, lifecycle, validation, and registration-order
rendering; an extension owns only its body and local state.

The host's error isolation is intentionally narrow. It reports and replaces an
extension section only when `appliesTo` or the declaration's `build` callback
throws synchronously. Once that callback returns a widget, later failures from
the widget or its descendants follow Flutter's normal element-level reporting
and `ErrorWidget` replacement. The host does not install a global widget error
boundary, and extensions remain responsible for their own asynchronous errors.

`packages/desy_agent_annotations` proves this boundary with a multiline comment
composer. It snapshots stable entry identity, folder ancestry, optional source
path, active theme ID, comment, and creation time into one immutable
`DesyAgentAnnotation`. The package calls the consumer's required
`DesyAgentAnnotationSubmit` callback and displays its typed receipt. It has no
filesystem, GitHub client, credential, backend, registry mutation, or routing.

The Harbor sample supplies two consumer-side adapter patterns:

- On macOS, a conditionally imported callback uses the sandbox Powerbox to ask
  for a repository directory. It canonicalizes that selection, caches it only
  for the running session, rejects existing symlink path components, and
  atomically publishes Markdown beneath the fixed
  `.desy/agent_annotations/` directory. Cancellation stays retryable; Harbor
  stores no persistent security-scoped bookmark. Pending files are claimed
  exclusively and final filenames use independent random 128-bit tokens,
  providing UUID-style probabilistic uniqueness.
- A hosted deployment can pass its authenticated server-side GitHub issue
  function through `createHostedGitHubIssueSubmit`. The browser receives only
  the public issue URI; repository credentials remain on the server.

## Primitives are typed, but not prescriptive

The registry has thin adapters for the primitive families that need useful
inspection:

- `DesyColorEntry` for swatches, gradients, and any custom color treatment.
- `DesyTypographyEntry` for resolved Flutter text styles and reading specimens.
- `DesyNumericEntry` for spacing, size, radius, duration, layout thresholds,
  and other numeric values, with a unit and optional live specimen.
- `DesyMotionEntry` for a typed `Duration`, `Curve`, and consumer-owned live
  animation specimen. Motion detail pages and the global Motion Atlas supply
  specimens with a workbench-owned `DesyMotionPlaybackScope`: they autoplay by
  default and keep play/pause, loop mode, scrubbing, and playback speed as
  ephemeral Bench state. The Atlas header coordinates one clock while each
  entry retains its declared duration and curve.
- `DesyAssetEntry` for real icons, illustrations, and visual assets.

None requires a consumer to adopt a universal token schema. Every entry either
returns a widget or can be represented by a concise primitive value. Folders
organize entries without changing what they are.

## Components, contracts, and scenarios

`DesyComponent` always supplies the real preview widget. It can optionally add:

- `DesyComponentContract`: documented Dart properties, named child slots, and
  concise composition guidance.
- `DesyComponentScenario`: named real states such as loading, error, empty, or
  delayed. A scenario has its own consumer widget builder.
- Knobs: typed preview controls for strings, booleans, and component instances.
- Named instances: reusable `DesyComponentInstance` declarations containing
  predefined knob values.

The contract is documentation for the real component API; it is not a second
implementation or a schema that generates production code.

## Component-instance knobs

`DesyComponentKnob` is the key compositional control. Its options are stable,
registry-scoped component-instance IDs. A component can therefore expose a
legal slot—such as `SampleCard.trailing`—as a controlled choice between real
status widgets without storing a widget or callback in its knob values. Its
`buildWithKnobs` callback receives a `DesyRegistryWidgetBuilder`, which resolves
the selected ID through the registry and builds that instance from its owning
component's predefined knob settings. The same registry index powers the
searchable swap dialog without creating another widget catalogue.

When an ID cannot be resolved, the widget builder renders an interactive
warning placeholder instead of throwing. Selecting it opens a diagnostic with
the unresolved ID, registry name, and repair guidance, while registry
validation continues to report the broken declaration as a non-blocking
warning. Structurally unsafe declarations, such as duplicate stable IDs or
invalid preset values, still prevent startup.

This keeps the good boundary:

- Desy controls which declared instances can be inspected.
- The consumer controls what each instance renders.
- A future saved composition records stable IDs and serializable knob values,
  never callbacks or arbitrary widget objects.

## Why the product starts with primitives

Good screen and agent output is an effect of a complete system, not a prompt
trick. Desy prioritizes numeric values, typography, semantic colors, motion,
assets, layout, and interaction states before screen composition or agent
workflows. Once these are registered, an agent can query and use a system that
is genuinely constrained and reviewable instead of guessing from a gallery.

## Workbench session and sketching

Bench interaction state is deliberately local to the running app and managed
with `state_beacon`: the active theme, knob values, and preview geometry never
mutate the consumer registry. The Components screen is an
equally temporary sketch surface backed by `flutter_box_transform`; it lets a
person add, move, resize, and inspect real registered widgets together. It is
not a persisted screen format or code generator.

The sketch also offers workbench-owned single-column, split, grid, responsive
card, repeated-row, and form layouts. Each layout exposes a fixed set of legal
slots and uses `DesyNumericEntry.spacing` values from the active registry for
padding and gaps. Selecting a layout and choosing registry instances fills its
open slots; the structure and children remain ephemeral canvas nodes. A minimal
registry without spacing entries still works with a truthful `0 dp` gap rather
than a hidden second spacing scale.

Navigation is URL-addressable through `go_router`. The permanent Forui shell
is a `ShellRoute`, so catalogue and entry-detail routes replace only the
workbench body while keeping navigation available. On desktop, its sidebar
animates between 248 logical pixels and collapsed; body route changes remain
instant. The sidebar has three collapsible groups: **Workspace** (Atlas,
Components, experimental Showcases, and installed extensions), **Catalogue**
(the consumer's used folder tree), and **AI** (the currently empty Prompt
library). Primitive branches stop at folders: individual colors, fonts, icons,
measurements, motion, effects, and assets are browsed in the Atlas rather than
repeated as sidebar leaves. Component leaves remain directly navigable.

The sample enables `simdeck_flutter_inspector` only in debug builds. Start it
with `task sample:run`; it serves the loopback inspector on port 4310. In a
second terminal, use `task simdeck` to open SimDeck or
`task simdeck:describe:flutter` for an agent-readable inspection. `task
simdeck:list` and `task simdeck:status` help diagnose the local setup.

## Harbor Operations sample

The sample application's explicit tree is:

```text
atoms
├─ atoms.colors
├─ atoms.fonts
├─ atoms.measurements
├─ atoms.motion
├─ atoms.effects
└─ atoms.assets
components
├─ components.action
├─ components.feedback
├─ components.input
├─ components.content
├─ components.navigation
├─ components.operations
│  ├─ components.operations.overview
│  │  └─ components.operations.overview.metrics
│  └─ components.operations.planning
│     └─ components.operations.planning.schedule
└─ components.guidance
   └─ components.guidance.states
      └─ components.guidance.states.empty
examples
└─ examples.showcases
```

Its typed numeric entries live under `atoms.measurements`, which routes them
to the Measurements board rather than maintaining separate Shape or Spacing
sidebar sections. The sample also demonstrates two real themes, colors,
typography, declared spacing, motion, icons, production components, contracts, a delayed state
scenario, and a card whose trailing status is selected through a
component-instance knob.

## Agent skills

The repository owns two portable skills under `.agents/skills`:

- `desy` teaches agents to locate the consumer registry, query declarations by
  stable ID or source path, preserve typed contracts, and run focused checks.
- `desy-design-sweep` reviews tokens, components, states, accessibility,
  responsiveness, preview fidelity, and registry quality. Its report labels
  each item as verified evidence, a hypothesis, or a coverage gap and defaults
  to review-only operation.

Both skills work from the public registry and production source. They do not
generate a parallel catalogue, require a backend, or create issues without
explicit authorization.

## Desy's inside-out dogfood catalogue

`packages/desy_design_system/example/` is a second maintained consumer. Its
single `desyDesignSystemRegistry` declares the light/dark workbench themes,
colors, typography, measurements, motion, effect, icon vocabulary, and every
visible component family currently used by Desy: accordion, badge, button,
card, dialog, scaffold, select, sidebar, switch, tabs, tile, native text field,
and keyboard shortcut label.

The dependency direction remains acyclic: `desy_design_system` owns production
widgets without importing Desy Bench; the example app imports both packages and
passes its registry to `DesyBenchApp`. The workbench therefore uses the same
design system it is cataloguing, while Harbor continues to prove that an
external consumer owns its visual language independently.

## Boundaries

Desy Bench is not a Figma replacement, a hosted design-system source of truth,
or a no-code application builder. It does not serialize application callbacks
or business logic, and it does not generate production Dart code from a canvas.
Those limits preserve the repository-owned Flutter code as the authoritative
system.

Manifest persistence, the CLI, and a Desy-owned accessibility inspector remain
deliberately deferred. The screenshot builder is an experimental workspace
extension, not a persisted-manifest implementation. Agent annotation history,
cloud sync, identity, and direct browser-side GitHub authentication are also
outside the detail-extension boundary.

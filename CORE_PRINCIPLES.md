# Desy Bench Core Principles

## 1. One declared system, many consumers

A consuming repository declares its design system once. The Bench, catalogue,
future validation, examples, and generated guidance derive from that registry;
none creates a competing description.

## 2. Consumer-owned, tool-enabled

`desy_bench` supplies neutral registry contracts and the workbench experience.
The consumer owns its tokens, theme wrappers, production widgets, and registry
in normal source control.

## 3. Real widgets in real context

Previews render the actual widgets supplied by the consuming system, wrapped in
the selected consumer theme. The workbench never approximates a component with
a parallel implementation.

## 4. Opinionated structure, open implementation

Desy prescribes a small, typed design-system structure so it can provide
purpose-built tools for Colors, Fonts, Icons, Measurements, Motion, Effects,
and knobless Custom atoms.
Each lane is an optional, separate `DesyRegistry` parameter. A consumer opts in
by supplying entries and an empty lane is absent from the workbench.

Within those lanes, implementation stays open: every registered artifact
ultimately resolves through a builder that returns the consumer's real Flutter
`Widget`. Typed metadata gives Desy enough structure for font specimens,
measurement diagrams, motion playback and scrubbing, and other specialized
surfaces without prescribing the consumer's visual language.

For example, a color entry may use a color-specific builder to offer a useful
scaffold experience, but that builder still returns a widget. Desy-owned UI
must render declared values rather than recreate a consumer's design choices.

## 5. One registry, available throughout the workbench

The active registry is app-wide infrastructure, available to every Desy-owned
surface through a single, explicit access path. Screens, panels, inspectors,
and future extensions resolve components from it instead of receiving copied
lists or maintaining local registries.

The registry must expose stable extension points for both consumer-defined and
user-composed screen entries. A consumer can register a tailored Flutter screen
in code; a Bench user can compose a screen and save a declarative manifest of
registered IDs, legal slots, and serializable values. Both paths resolve
through the same component graph, navigation, previewing, and future validation
rules.

Interactive manifests never serialize callbacks or application logic, and they
are not production Dart-code generation. A future export flow may deliberately
translate a validated manifest, but only as a separate, explicit capability.

Components are one flat registry list. Each component may declare a concise
slash path such as `/inputs/text`; Desy validates and parses that value into an
immutable component path, then derives the navigation tree. Component IDs remain
the durable artifact identity, while paths organize presentation and never form
a second component inventory.

## 6. Local first, useful early

The first release runs in a Flutter repository without a hosted service. The
dogfood executable proves the public integration before adding a CLI, code
generation, cloud collaboration, or a visual editor.

## 7. Forui is Desy's private scaffold engine

All Desy-owned scaffold components—the workbench shell, navigation, panels,
controls, and future studio surfaces—use Forui. This rule applies to Desy Bench
chrome, not to consumer previews: consumers continue to render their actual
production widgets under their own theme and component library.

`packages/desy_design_system` is the single Desy-owned home of that dependency.
The workbench and Desy-owned extensions consume Desy-owned themes, icons,
controls, variants, sizes, callbacks, and controllers rather than importing or
exposing Forui types. Forui may implement those controls internally, but it is
not Desy's public component model. New Desy APIs must not leak an `F*` type, and
existing compatibility aliases are migrated behind owned wrappers before the
Registry Spine shell expands. Its colocated executable declares those real
widgets in one dogfood `DesyRegistry`; that registry is the catalogue inventory,
not a second component list maintained by the package.

Desy's visual language is a deliberate desktop-tooling translation rather than
Forui's defaults used unchanged. The Desy-owned theme keeps structural surfaces
white in the light theme, uses neutral one-pixel dividers and compact radii,
keeps primary actions black, and reserves one signal pink for focus, selection,
inspection, and annotation. Positive green communicates runtime health and hot
reload success. These meanings belong to semantic Desy tokens so workbench
screens and extensions do not create local color vocabularies.

### Native text-entry exception

All Desy-owned editable fields use the centralized `DesyTextField`, which is
built on Flutter's native `TextField` / `EditableText` stack. It takes visual
tokens from the surrounding Desy theme but keeps the platform's reliable caret,
selection, keyboard, and context-menu behaviour. This narrow exception applies
only to editable text; surrounding workbench chrome remains Forui.

## 8. Preview real widgets at a readable scale

The preview canvas renders a component at its intended logical size and then
scales that rendered result down to fit the available Bench surface. Desy must
not simulate a compact preview by passing arbitrary smaller constraints to the
consumer widget; the consumer's true layout remains inspectable while the
workbench controls the presentation scale.

Responsive previews take their logical size from the drag box. A named device
preview instead has an immutable logical screen, device pixel ratio, platform,
and safe-area geometry. Desy draws the screen and bezel at that real geometry,
clips content to the screen, and scales the completed device down as one unit;
it never scales up, inserts `SafeArea`, or adds scrolling for the consumer.
This contract is shared by component details, Sketch artboards, and Prototype
previews.

## 9. Atoms are optional typed registry lanes

Atoms is a built-in workbench section derived from typed `DesyRegistry`
parameters, not a consumer-declared folder. Its known lanes are Colors, Fonts,
Icons, Measurements, Motion, Effects, and Custom. Custom atoms are named,
knobless real-widget instances for foundational visuals that do not fit a
specialized lane; they remain one built-in lane rather than consumer-declared
sidebar branches. Desy may give each typed lane specialized treatment; it never
infers semantics from folder names or contents.

Semantic solid colors are `DesyColorEntry` values backed by Flutter `Color`
objects. Gradients and other paint recipes consume those colors and belong to
their appropriate typed treatment contract rather than the Colors lane; text
specimens are `DesyTypographyEntry` values;
numeric foundations are `DesyNumericEntry` values; motion uses
`DesyMotionEntry`; effects use `DesyEffectEntry`; and glyphs use
`DesyIconEntry`. Every entry may still render a consumer-owned widget. Empty
lanes are omitted, and when all lanes are empty the entire Atoms sidebar section
is omitted.

## 10. Flutter-platform compatible by default

Desy Bench and its dogfood executable run on every platform Flutter supports,
including web, mobile, and desktop. Desy-owned UI adapts its layout and input
affordances to the available space and platform without duplicating the
registry, preview, or workbench experience. Platform-specific behavior is an
explicit, narrowly scoped consumer concern; it must not make the reusable
package or the dogfood app unavailable elsewhere.

## 11. Minimum necessary declaration

A consumer provides only the information Desy cannot reliably derive. Desy
supplies sensible defaults, derives presentation from typed values, and keeps
metadata optional until a consumer needs it. Repeated registry boilerplate is a
design smell, not a cost to pass on to consumers.

This applies to both code and the workbench: never require an input merely
because Desy has a place to store it.

## 12. Object-shaped, typed interfaces

Desy APIs accept the richest appropriate domain object rather than parallel
primitive arguments or loosely typed maps. Concise authoring syntax such as a
component's slash path is normalized immediately into a validated domain object.
Builders derive their available choices and return types from typed objects,
making invalid states difficult to express.

## 13. Compose before configuring

Prefer a small set of composable, typed primitives and widget builders to
broad configuration APIs with many flags. A configuration option belongs only
when it represents a real consumer-domain choice; it must not compensate for a
missing abstraction.

## 14. Progressive disclosure, not progressive obligation

Desy is useful with a minimal registry. Advanced capabilities—knobs,
documentation, screen composition, validation, and manifest persistence—appear
only when the consumer opts in. A simple registered widget must not need to
understand studio-level concepts.

## 15. Accessibility is part of the workbench contract

Desy-owned UI is keyboard-operable, readable at system text scales, and
semantically meaningful. The Bench is a tool for inspecting design systems, so
the scaffold must not exclude people building or reviewing them. Consumer
widgets remain consumer-owned, but Desy must preserve their semantics in its
preview and inspection surfaces wherever Flutter permits.

## 16. Extend through typed workspace boundaries

Desy grows through small, typed workspace extensions before adding capabilities
to the core workbench. An extension declares a screen and receives a read-only
context containing the active consumer registry, preview theme, and Desy
helpers for rendering or resolving declared artifacts. Extensions do not own a
second registry, mutate core routing, or depend on hidden workbench state.

The workbench owns discovery, navigation, lifecycle, and the surrounding
Forui shell; the extension owns only its screen content and explicit local
state. This keeps optional workflows—such as screenshot recipes, release
material, or documentation—installable without increasing the declaration
burden for every consumer.

## 17. Documentation starts with successful use

The root README is the practical front door for users. `dev.md` is the single
maintained contributor guide. Examples must reflect the real registry contracts
and reinforce the single declared system rather than introduce a parallel
configuration path.

`concept/features/index.html` is the sole planning exception: it is the
project's ranked index of unimplemented product work, and every non-trivial
planned feature links to one complete, offline-safe concept artifact there.
Implemented contracts move to `docs/concepts/`; evidence and investigations
belong in `docs/research/`. Do not duplicate roadmap items in agent
instructions, skills, contributor documentation, implementation concepts, or
generated context.

## 18. Dogfood is the maintained product surface

Desy's dogfood catalogue is the canonical executable and integration sample,
not a dumping ground for test fixtures. It must exercise the same public
registry contract that consumers use. Every visible entry must be purposeful,
presentation-ready, correctly typed, and representative of that contract. Do
not ship placeholder labels, generic specimen widgets, duplicate
representations of the same primitive, or test-only artifacts in its registry.

Tests may define deliberately minimal fixtures inside test files. The running
dogfood catalogue must remain clean after every work block, because confusing
sample data looks like confusing Desy behavior and teaches consumers the wrong
API.

## 19. Interface design is part of feature design

Every feature that consumers declare or compose must design its public
authoring interface as a core deliverable, not as follow-up API cleanup. The
interface should make the intended domain model direct to express, preserve
type safety where practical, and make invalid or contradictory declarations
difficult to construct. Internal implementation convenience must not push
stringly typed maps, mutable proxy state, repeated boilerplate, or lifecycle
concerns onto consumers.

## 20. The Registry Spine is the stable product shell

Desy's primary desktop experience keeps the live registry visible on the left
and uses the center for Atlas inspection, component details, and real-Dart
prototype sessions declared by the consumer registry. Prototypes are a
separate registry lane for comparing possible visual directions before a team
decides what belongs in the durable component system; they are not a second
component catalogue or a serialized widget language.

The shell owns one global annotation mode and source-aware feedback dock. It
targets only explicitly scoped consumer content—real registry widgets and
generated prototypes—never Desy scaffold chrome, navigation, or editing
controls. Center modes may change, resize, or collapse secondary panels, but
they do not replace registry or annotation ownership. Desy records source-aware
feedback; users choose the developer, IDE, or coding agent that acts on it.
Every consumer-source edit remains reviewable in the normal repository diff.

## Non-goals for the first release

- Figma replacement or general no-code application builder.
- General-purpose IDE, source browser, or embedded terminal product.
- JSON widget language, Flutter subset, or surface DSL as the core authoring
  medium.
- Hosted design-system source of truth.
- Production Dart-code generation from canvas edits.
- Application business-logic authoring.

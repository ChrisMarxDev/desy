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

## 4. Primitive-first, widget-returning contracts

Desy does not prescribe a design-system taxonomy or visual language. Every
registered artifact ultimately resolves through a simple builder that returns a
Flutter `Widget`. Tokens, colors, atoms, molecules, components, and future
screen definitions are optional convenience adapters over that primitive—not
mandatory models a consuming system must adopt.

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

Folders are first-class, nestable registry structure. They organize existing
primitives without imposing a new taxonomy; Desy surfaces resolve the complete
tree through registry accessors instead of flattening and owning a second list.

## 6. Local first, useful early

The first release runs in a Flutter repository without a hosted service. Build
the package and a representative sample consumer before adding a CLI, code
generation, cloud collaboration, or a visual editor.

## 7. Forui is the Desy scaffold foundation

All Desy-owned scaffold components—the workbench shell, navigation, panels,
controls, and future studio surfaces—use Forui. This rule applies to Desy Bench
chrome, not to consumer previews: consumers continue to render their actual
production widgets under their own theme and component library.

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

## 9. Atoms organize foundational primitives

Atoms is a top-level folder in the registry tree, not a duplicate entry type or
parallel inventory. It contains folders such as Colors, Fonts, and—later—
Spacing and other numeric values. Solid swatches, gradients, and
consumer-supplied color/treatment widgets are all color entries inside
`Atoms/Colors`; they do not also appear as generic atoms. This prevents
duplicated visual inventories while keeping color-specific builders as thin
widget-returning conveniences.

## 10. Flutter-platform compatible by default

Desy Bench and its sample consumer run on every platform Flutter supports,
including web, mobile, and desktop. Desy-owned UI adapts its layout and input
affordances to the available space and platform without duplicating the
registry, preview, or workbench experience. Platform-specific behavior is an
explicit, narrowly scoped consumer concern; it must not make the reusable
package or the sample unavailable elsewhere.

## 11. Minimum necessary declaration

A consumer provides only the information Desy cannot reliably derive. Desy
supplies sensible defaults, derives presentation from typed values, and keeps
metadata optional until a consumer needs it. Repeated registry boilerplate is a
design smell, not a cost to pass on to consumers.

This applies to both code and the workbench: never require an input merely
because Desy has a place to store it.

## 12. Object-shaped, typed interfaces

Desy APIs accept the richest appropriate domain object rather than parallel
primitive arguments, string conventions, or loosely typed maps. Builders
derive their available choices and return types from that object, making valid
usage clear through the type system and autocomplete while making invalid
states difficult to express.

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

The root README is the practical front door for both people and coding agents.
It explains how to install, run, and correctly declare a consumer-owned design
system before describing repository internals or product history. The
repository's Markdown documentation is its wiki: the README gives each topic a
clear entry point and links to focused, maintained documents for deeper
guidance. Examples must reflect the real registry contracts and reinforce the
single declared system rather than introduce a parallel configuration path.

## Non-goals for the first release

- Figma replacement or general no-code application builder.
- Hosted design-system source of truth.
- Production Dart-code generation from canvas edits.
- Application business-logic authoring.

# Desy Bench product direction

## The product

Desy Bench is a local-first, Flutter-native workbench for a repository-owned
design system. It is an opinionated, high-quality Widgetbook-style experience:
fast to browse, precise about the real component contract, and useful for both
humans and coding agents.

## The source of truth

The consuming repository owns one `DesyRegistry`. Desy Bench renders that
registry; it does not duplicate a design system in configuration, screenshots,
or a hosted service. Every preview uses the consumer's actual widget builder
under its selected real theme. The workbench consumes the public registry
directly; declarations are immutable and their shared stable-ID namespace is
validated when the app starts.

## First-release experience

- A polished desktop workbench built from the Forui-backed
  `desy_design_system`, with a searchable Atlas, consumer folder tree, theme
  selection, component inspector, live previews, movable canvas, and knobs.
  Desktop navigation animates between shown and collapsed states; its current
  groups are Workspace, Catalogue, and AI.
- An `Atoms` top-level folder for foundational primitives: Colors (including
  swatches, gradients, and custom visual treatments), Fonts, Measurements,
  Motion, Effects, and Assets. Typed numeric values (spacing, radius, layout
  thresholds, and more) route through Measurements; Atoms is structure, not a
  duplicate entry category, and helpers are conveniences rather than mandatory
  design-system models.
- A complete sample consumer, Harbor Operations, showing themes, semantic
  tokens, a color/treatment atlas, typography, real motion and asset specimens,
  production components, component contracts, named scenarios, and composable
  component-instance knobs.
- A second executable dogfood consumer that declares and manages Desy's own
  themes, foundations, icons, and complete workbench-component inventory through
  the same public `DesyRegistry` contract.

## Extensibility path

The registry is app-wide and exposes typed workspace-extension points. Consumers
may register tailored Flutter screens in code. Bench users may later compose
screens from legal component IDs and save declarative manifests; manifests
contain serializable values and never application callbacks or business logic.
Manifest persistence itself is deliberately not implemented yet.

Agents are a downstream capability, not a competing product surface. Once a
consumer has declared enough primitives, contracts, scenarios, and source links,
Desy can derive focused local queries and task context from that living system.
The repository now ships a project-local `desy` teaching skill and a review-only
`desy-design-sweep` skill. They query source declarations directly, distinguish
verified evidence from hypotheses, and remain portable to consuming projects.
Automated issue creation and hosted agent services remain deferred.

## Deliberate boundaries

Desy Bench is not a Figma replacement, no-code application builder, cloud
source of truth, or automatic production-code generator. A CLI, manifest
persistence, and a Desy-owned accessibility inspector remain deferred until
the registry and workbench workflow have proven stable.

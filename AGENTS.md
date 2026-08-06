# Working in Desy Bench

## Project shape

- `packages/desy_bench/` is the reusable Flutter package. Keep it independent
  of any specific design system.
- `example/sample_design_system/` is a consuming app and the primary integration
  testbed. It owns tokens, components, and the registry it passes to the bench.
- `concept/` and `prototype/` are read-only seed material. Do not evolve them
  as part of product work.
- `tools/desy_cli/` is intentionally deferred until the registry API is stable.

## Design rules

- The consumer registry is the single declared source of truth.
- Keep registry contracts primitive-first: every registered artifact ultimately
  supplies a widget builder. Categories such as colors, tokens, atoms, and
  components are optional Desy adapters, never a required consumer taxonomy.
- Desy-owned workbench surfaces consume the public `DesyRegistry` directly
  through one app-wide access path. Do not copy registry lists into screens or
  introduce an adapter/parallel registry. Code-registered consumer screens and
  user-composed, serializable screen manifests use the same extension point as
  the catalogue; manifests contain IDs, legal slots, and values—not callbacks
  or app logic.
- Use `DesyFolder` to structure registry content recursively. Folders organize
  existing primitives; Desy UI reads the tree or its registry-provided `all*`
  accessors rather than building a competing flat index.
- Every declaration collection is immutable after construction. Give every
  theme, folder, artifact, showcase, and extension a unique, stable ID; the
  workbench validates that shared ID space when it starts.
- Previews must render the consumer's real Flutter widgets under its real theme.
- Build all Desy-owned scaffold UI with Forui. This includes workbench chrome,
  navigation, panels, controls, and studio surfaces; it does not constrain a
  consumer preview's component library.
- Render consumer previews at their intended logical dimensions, then scale the
  result down within the Desy canvas. Do not make a widget look smaller by
  giving it artificial compact constraints.
- Treat Atoms as the top-level structural folder for foundational primitives:
  Colors, Fonts, and future Spacing/Numeric folders. Do not create a duplicate
  Atom entry category: swatches, gradients, and consumer-supplied color widgets
  are color entries under `Atoms/Colors`.
- Route numeric primitives through typed `DesyNumericEntry` declarations and
  the Measurements board; do not recover their meaning from strings or create
  separate Shape/Spacing navigation sections.
- Prefer explicit component contracts and semantic token names over visual
  overrides or loose widget galleries.
- Ask consumers only for information Desy cannot derive. Prefer sensible,
  typed defaults over required metadata and repeated registration boilerplate.
- Shape APIs around rich domain objects, not stringly typed maps or parallel
  primitive arguments. Prefer composable typed primitives to flag-heavy
  configuration surfaces.
- Keep advanced features opt-in: a minimal registry must remain sufficient for
  a useful catalogue. Desy-owned UI must be keyboard-operable, readable at
  system text scales, and semantically meaningful.
- Keep the first release local-first and repository-native: no backend, account,
  or generated production widget code.
- Manifest persistence, a CLI, and an accessibility-inspector mode remain
  intentionally deferred. The screenshot builder is an experimental workspace
  extension, not a persistence format.

## Verification

From the repository root, `task check` is the canonical verification command.
It runs root analysis plus all three test suites, including the experimental
screenshot-builder extension:

```sh
task check
```

`flutter test` at the repository root is not equivalent: it does not express
the workspace's package-by-package test coverage. For focused work, use
`task bench:test`, `task screenshot_builder:test`, or `task sample:test`.

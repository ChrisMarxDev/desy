# Working in Desy Bench

## Project shape

- `packages/desy_bench/` is the reusable Flutter package. Keep it independent
  of any specific design system.
- `packages/desy_design_system/` owns Desy's workbench foundations and UI. It
  is the only Desy-owned package that depends directly on Forui. Its
  `example/` app owns the dogfood registry and is the maintained executable and
  integration testbed.
- `packages/extensions/` contains optional packages that prove narrow extension
  boundaries. They are not part of the core package surface.
- `dev.md` contains the maintained contributor guide.

## Design rules

- The consumer registry is the single declared source of truth.
- Keep registry contracts widget-returning: every registered artifact ultimately
  supplies the consumer's real widget. Colors, Fonts, Icons, Measurements,
  Motion, and Effects are known but optional typed lanes so Desy can provide
  specialized tools without prescribing their visual implementation.
- Desy-owned workbench surfaces consume the public `DesyRegistry` directly
  through one app-wide access path. Do not copy registry lists into screens or
  introduce an adapter/parallel registry. Code-registered consumer screens and
  user-composed, serializable screen manifests use the same extension point as
  the catalogue; manifests contain IDs, legal slots, and values—not callbacks
  or app logic.
- Register components as one flat list and organize them with validated slash
  paths such as `/inputs/text`. Desy derives the file tree from those paths;
  component IDs remain the durable identity and no parallel folder declaration
  belongs in the registry.
- Every declaration collection is immutable after construction. Give every
  theme, artifact, prototype session, and extension a unique, stable ID; the
  workbench validates that shared ID space when it starts.
- Previews must render the consumer's real Flutter widgets under its real theme.
- Build all Desy-owned scaffold UI through Desy-owned controls implemented by
  Forui. This includes workbench chrome, navigation, panels, controls, and
  studio surfaces; it does not constrain a consumer preview's component
  library.
- Use `DesyResizeDivider` for every resizable panel boundary. It owns the one
  visible hairline, pointer hit target, cursor, keyboard control, and semantics;
  never pair it with a separate `Border`, divider `Container`, or resize handle.
- `desy_design_system` owns the Forui dependency and keeps it behind Desy-owned
  widgets, variants, sizes, callbacks, and controllers. Do not add a direct
  Forui import or expose an `F*` type from `desy_bench`, an extension, or a new
  Desy public API. The dogfood app's `DesyRegistry` is the only runtime
  inventory of Desy's exported UI.
- Render consumer previews at their intended logical dimensions, then scale the
  result down within the Desy canvas. Do not make a widget look smaller by
  giving it artificial compact constraints. Responsive previews derive their
  logical size from the drag box. Named device previews keep fixed screen and
  media geometry, clip to the screen, and scale the screen and bezel down
  together without inserting `SafeArea` or scrolling.
- Treat Colors, Fonts, Icons, Measurements, Motion, and Effects as optional,
  typed `DesyRegistry` parameters. They are built-in atom lanes, never
  consumer-declared folder branches or inferred labels.
- Show only non-empty atom lanes in navigation and omit the complete Atoms
  section when all are empty. Individual primitives open from their typed board;
  component entries may remain direct sidebar destinations.
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
It runs root analysis, the Forui dependency-boundary check, all six test
suites, and a production dogfood web compile, including optional extensions:

```sh
task check
```

`flutter test` at the repository root is not equivalent: it does not express
the workspace's package-by-package test coverage. For focused work, use
`task design_system:test`, `task dogfood:test`, `task bench:test`,
`task agent_annotations:test`, `task screenshot_builder:test`, or
`task widget_workshop:test`.

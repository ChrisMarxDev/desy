# Desy Bench

Desy Bench is a local Flutter workbench for the design system already owned by
your repository. Declare your real theme, widgets, and optional visual
explorations once in a `DesyRegistry`; Desy presents and compares them without
creating a parallel catalogue.

## Run the maintained app

The dogfood app is both the executable example and the integration testbed:

```sh
task pub:get
task dogfood:run_mac
```

Use `task dogfood:web` for Chrome or `task dogfood:build:web` for a production
web build. Its registry lives in
[`packages/desy_design_system/example/lib/src/desy_design_system_registry.dart`](packages/desy_design_system/example/lib/src/desy_design_system_registry.dart).

## Add Desy to a design system

Desy is currently consumed as a workspace package:

```yaml
dependencies:
  desy_bench:
    git:
      url: https://github.com/ChrisMarxDev/desy.git
      path: packages/desy_bench
      ref: main
```

This is intentionally pinned to `main` while Desy is still moving quickly.
Release tags will replace it once the package API settles.

Create one registry next to the Flutter theme and widgets it describes. The
smallest useful registry has a theme and one real component:

```dart
import 'package:desy_bench/desy_bench.dart';
import 'package:flutter/material.dart';

final designSystem = DesyRegistry(
  name: 'Acme Design System',
  themes: [
    DesyTheme(
      id: 'acme.light',
      name: 'Light',
      wrap: (context, child) => Theme(
        data: acmeLightTheme,
        child: child,
      ),
    ),
  ],
  components: [
    DesyStaticComponent(
      id: 'button',
      name: 'Button',
      path: '/actions/buttons',
      instances: {
        'default': (_) => const AcmeButton(label: 'Continue'),
      },
    ),
  ],
);

void main() => runApp(DesyBenchApp(registry: designSystem));
```

The theme and button remain consumer-owned. Use stable, unique IDs across the
registry. Previews build the real widget at its intended logical size under its
real theme.

## Compare real Flutter prototype directions

Prototype sessions are ordinary Flutter widget builders. They are for exploring
directions before a team decides what belongs in the durable component system:

```dart
final homepageExploration = DesyPrototypeSession(
  id: 'homepage.exploration',
  name: 'Homepage exploration',
  prototypes: [
    DesyPrototype(
      id: 'homepage.editorial',
      name: 'Editorial direction',
      builder: (_) => const AcmeHomepage(direction: HomepageDirection.editorial),
    ),
    DesyPrototype(
      id: 'homepage.utility',
      name: 'Utility direction',
      builder: (_) => const AcmeHomepage(direction: HomepageDirection.utility),
    ),
  ],
);
```

Add it to the same registry with `prototypes: [homepageExploration]`. Desy
renders each direction under the selected consumer theme and exposes its live
widget anatomy for comparison. It does not require a widget DSL or a second
component catalogue.

## Register a custom atom

For a foundational visual that does not fit Desy's typed Color, Typography,
Measurement, Motion, Effect, or Icon lanes, use a knobless custom atom. It is
made only from named real-widget instances and appears under `Atoms / Custom`:

```dart
DesyCustomAtom(
  id: 'acme.atom.hero-gradient',
  name: 'Hero gradient',
  instances: {
    'default': (_) => const AcmeHeroGradient(),
    'quiet': (_) => const AcmeHeroGradient(quiet: true),
  },
)
```

Add it with `customAtoms: [...]` on the same `DesyRegistry`. Use a static
component instead when the widget is intended to be composed into application
screens rather than serve as a foundation artifact.

## Review annotations in place

Desy can select explicitly scoped consumer widgets, attach source-aware notes,
and keep a local review list without embedding a coding agent. Configure an
optional store and any destinations your repository needs:

```dart
DesyBenchApp(
  registry: designSystem,
  annotations: DesyAnnotationWorkspace(
    store: myAnnotationStore,
    exporters: [myReviewFileExporter, myGitHubExporter],
  ),
)
```

`DesyAnnotationStore` owns local persistence. `DesyAnnotationExporter` receives
one immutable `DesyAnnotationBatch`, with both source-aware Markdown and JSON
representations. The core package supplies an in-memory default and remains
web-safe; filesystem, GitHub, Slack, and agent-specific delivery adapters stay
consumer-owned or optional packages.

## Repository

- `packages/desy_bench/` — registry contracts and reusable workbench.
- `packages/desy_design_system/` — Desy's Forui-based workbench UI and dogfood
  executable.
- `packages/extensions/` — optional experimental packages; these are not part
  of the core workbench path.
- [`dev.md`](dev.md) — the single contributor guide.
- [`CORE_PRINCIPLES.md`](CORE_PRINCIPLES.md) — product and architecture
  decision gate.

Run the complete verification suite with:

```sh
task check
```

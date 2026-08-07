# Desy Bench

Desy Bench is a local Flutter workbench for a design system already owned by
your repository. Declare real themes, primitives, and production widgets once
in a `DesyRegistry`; Desy presents that registry without creating a parallel
catalogue.

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
    path: ../path-to-desy/packages/desy_bench
```

Create one registry next to the Flutter theme and widgets it describes:

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
  colors: [
    DesyColorEntry.swatch(
      id: 'color.brand',
      name: 'Brand',
      color: acmeBrand,
    ),
  ],
  components: [
    DesyComponent(
      id: 'button.primary',
      name: 'Primary button',
      path: '/actions/buttons',
      preview: (context) => const AcmeButton(label: 'Continue'),
    ),
  ],
);

void main() => runApp(DesyBenchApp(registry: designSystem));
```

The theme, color, and button above remain consumer-owned. Use stable, unique
IDs across themes, artifacts, showcases, and extensions. Previews must
build the real widget at its intended logical size under its real theme.

## Repository

- `packages/desy_bench/` — registry contracts and reusable workbench.
- `packages/desy_design_system/` — Desy's Forui-based workbench UI and dogfood
  executable.
- `packages/extensions/` — optional annotation and screenshot-builder packages;
  these are not part of the core.
- [`dev.md`](dev.md) — the single contributor guide.
- [`CORE_PRINCIPLES.md`](CORE_PRINCIPLES.md) — product and architecture
  decision gate.

Run the complete verification suite with:

```sh
task check
```

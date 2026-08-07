# Desy Bench

[![Deploy sample](https://github.com/ChrisMarxDev/desy/actions/workflows/deploy-sample.yml/badge.svg)](https://github.com/ChrisMarxDev/desy/actions/workflows/deploy-sample.yml)

Desy Bench is a local Flutter workbench for the design system already owned by
your repository. Declare your real themes, primitives, and production widgets
once in a `DesyRegistry`; Desy renders and explores that declaration without
creating a second design system.

Use it when you want a useful, inspectable catalogue that stays close to the
Flutter code your product actually ships.

## Start here

Run the independent Harbor consumer to see the normal integration workflow:

```sh
task pub:get
task sample:run
```

Use `task sample:web` for Chrome, or `task sample:web:build` for a production
web build. `task --list` shows every workspace command.

The maintained Harbor sample is deployed at
[desy-bench.web.app](https://desy-bench.web.app). Deployment configuration and
rollback instructions live in
[Firebase Hosting deployment](docs/firebase-hosting.md).

Then read the sample registry at
[`example/sample_design_system/lib/src/sample_registry.dart`](example/sample_design_system/lib/src/sample_registry.dart).
It is the reference implementation: its Flutter widgets and themes remain
consumer-owned; Desy only presents them.

Then run Desy's inside-out dogfood catalogue:

```sh
task dogfood:run_mac
# or
task dogfood:web
```

Its registry at
[`packages/desy_design_system/example/lib/src/desy_design_system_registry.dart`](packages/desy_design_system/example/lib/src/desy_design_system_registry.dart)
lists the themes, foundations, icons, and every exported UI family used by the
workbench. The same `desy_design_system` widgets build Desy Bench itself.

## Add Desy to a Flutter design system

Desy is currently developed as a workspace package. Add the package to the
Flutter application that owns the design system, then declare its system next
to its existing theme and component code.

```yaml
dependencies:
  desy_bench:
    path: ../path-to-desy-bench/packages/desy_bench
```

Create one registry. A minimal registry only needs a name and at least one real
theme; entries are opt-in. Registry and folder collections are immutable, so
declare them once and use stable, unique IDs for every theme, folder, artifact,
showcase, workspace extension, and detail extension. `DesyBenchApp` validates
this shared ID space at startup and reports declaration errors before the
workbench opens.

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
  folders: [
    DesyFolder(
      id: 'atoms',
      name: 'Atoms',
      children: [
        DesyFolder(
          id: 'atoms.colors',
          name: 'Colors',
          colors: [
            DesyColorEntry.swatch(
              id: 'color.brand',
              name: 'Brand',
              color: acmeBrand,
              description: 'Primary actions and active states.',
            ),
          ],
        ),
      ],
    ),
    DesyFolder(
      id: 'components',
      name: 'Components',
      components: [
        DesyComponent(
          id: 'button.primary',
          name: 'Primary button',
          description: 'Use for the page’s primary action.',
          preview: (context) => const AcmeButton(label: 'Continue'),
        ),
      ],
    ),
  ],
);

void main() => runApp(DesyBenchApp(registry: designSystem));
```

`acmeLightTheme`, `acmeBrand`, and `AcmeButton` are yours—not Desy copies or
approximations. The theme wrapper is especially important: it gives every
preview the same inherited theme context as your application.

### Add a registry-entry detail extension

Optional detail extensions render inside a singular registry-entry inspector
and receive a read-only view of that entry, its folders, the registry, the
active theme, and an optional component declaration. The proving
`desy_agent_annotations` package accepts one typed async callback; the consumer
still owns persistence and authentication:

```dart
DesyBenchApp(
  registry: designSystem,
  detailExtensions: [
    DesyAgentAnnotationsExtension(
      onSubmit: (annotation) => myConsumerOwnedSink(annotation),
    ),
  ],
)
```

The Harbor sample asks the user to select a repository through the sandboxed
macOS folder picker, then writes repository Markdown for that running session.
Its hosted-web example adapts an authenticated server-side GitHub issue
function to the same callback; no GitHub token is compiled into the Flutter
application.

The detail host isolates failures thrown synchronously while evaluating an
extension's `appliesTo` method or calling its `build` declaration. After
`build` returns a widget, failures thrown later by that widget or a descendant
follow Flutter's normal element error reporting and `ErrorWidget` behavior.
Async submission and other runtime failures remain extension-owned state.

## Declare a system that remains useful

Build from the smallest truthful declaration. Add only information Desy cannot
derive from the widget itself.

1. Register each real theme with `DesyTheme`.
2. Place foundational values in the top-level `Atoms` folder. Use stable
   nested IDs such as `atoms.colors`, `atoms.fonts`, and
   `atoms.measurements`; register spacing, radius, breakpoints, and other
   measures as typed `DesyNumericEntry` values so Desy routes them to the
   Measurements board. Use nested `DesyFolder`s when they make the consumer
   system easier to browse.
3. Register reusable production widgets with `DesyComponent`. Its `preview`
   must build the real component at normal logical dimensions.
4. Add optional descriptions, accessibility guidance, source paths, contracts,
   scenarios, and typed knobs where they make use or review clearer.
5. Keep IDs stable and unique across themes, folders, artifacts, showcases,
   and extensions. They are the durable references for navigation, validation,
   future manifests, and agent-facing context.

Do not duplicate a token inventory in a screen, turn callbacks or business
logic into registry data, or replace a preview with a compact imitation.
Previews measure the consumer widget at its intended logical dimensions and
scale the completed result to fit the canvas. The registry is the one declared
system; Desy’s workbench state stays temporary and local.

For the complete model—typed primitive entries, component contracts, scenarios,
component-instance knobs, and folders—read [How Desy Bench works](docs/how-desy-works.md).

## Working with agents

Agents should use the same source of truth as people: begin with this README,
then inspect the consumer’s `DesyRegistry`, its real widget code, and the
focused documents below. They should extend the registry with typed, stable
declarations; they must not invent a parallel JSON catalogue, copy registry
lists into screens, or serialize callbacks and application logic.

Two project-local skills make that workflow repeatable:

- [Desy skill](.agents/skills/desy/SKILL.md) explains and changes registries
  through their typed public contracts.
- [Desy design sweep](.agents/skills/desy-design-sweep/SKILL.md) runs a
  review-only audit and separates verified findings, visual hypotheses, and
  coverage gaps.

Copy both skill directories into a consuming repository’s `.agents/skills/`
directory to use the same workflow there. The root [AGENTS.md](AGENTS.md)
contains the compact repository safety rules.

For runtime inspection during development, start the sample in debug mode with
`task sample:run`, then use `task simdeck` or
`task simdeck:describe:flutter` from a second terminal. The inspector is
debug-only and the sample connects to a loopback service; it is not part of a
production integration. See [Flutter debug introspection](docs/flutter-debug-introspection-research.md).

## Documentation wiki

| Need | Read |
| --- | --- |
| Understand the registry, previews, primitives, and components | [How Desy Bench works](docs/how-desy-works.md) |
| Understand scope, product intent, and non-goals | [Product direction](docs/product-direction.md) |
| Use Flutter Inspector or the debug-only SimDeck companion | [Flutter debug introspection](docs/flutter-debug-introspection-research.md) |
| Understand why the CLI is deferred | [CLI roadmap](docs/cli-roadmap.md) |
| Compare the catalogue boundary with Widgetbook | [Widgetbook inspiration](docs/widgetbook-inspiration.md) |
| See a complete runnable consumer | [Sample Design System](example/sample_design_system/README.md) |
| Inspect Desy's own complete UI inventory | [Desy Design System](packages/desy_design_system/README.md) |
| Review the project’s durable design constraints | [Core principles](CORE_PRINCIPLES.md) |

The `docs/` directory is the maintained wiki. `concept/` is historical seed
material and is not the source of current product direction.

## Repository map

- `packages/desy_bench/` — reusable Flutter registry contracts and workbench.
- `packages/desy_design_system/` — Desy's Forui-backed foundations, controls,
  and executable self-catalogue.
- `packages/desy_agent_annotations/` — optional registry-entry detail extension.
- `packages/desy_screenshot_builder/` — optional workspace extension.
- `example/sample_design_system/` — complete consumer integration and primary
  reference implementation.
- `docs/` — maintained wiki and design rationale.
- `tools/desy_cli/` — intentionally deferred until the registry API is stable.

## Verify a change

From the repository root, use the canonical workspace check:

```sh
task check
```

This runs root analysis, the direct-Forui dependency boundary, all six
package/application test suites, and a production Harbor web compile. Root
`flutter test` is not equivalent to
`task check`; for focused test runs, use `task design_system:test`,
`task dogfood:test`, `task bench:test`, `task agent_annotations:test`,
`task screenshot_builder:test`, or `task sample:test`.

On macOS, run `task sample:compile:macos` as the native platform gate for the
repository annotation adapter and the sample's explicit sandbox entitlements.

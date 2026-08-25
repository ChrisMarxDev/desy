# Desy Bench

> ⚠️ ⚠️ **This project is absolutely messy right now.** It is actively being
> reorganized and its APIs can change without notice. Treat `main` and this
> README as the current source of truth.

Desy is a local Flutter workbench for the design system your repository already
owns. Register real themes, tokens, and widgets once; Desy lets your team browse,
compare, and evolve them without creating a second component catalogue.

## Packages

- `packages/desy_core/` — Flutter-native registry contracts and resolution.
- `packages/desy_bench/` — the reusable workbench for a consumer-owned
  registry.
- `packages/desy_design_system/` — Desy's own workbench foundations, including
  the maintained example app.
- `packages/object_canvas/` — reusable canvas geometry and interaction
  primitives.

`packages/extensions/` contains potential future extensions and is not part of
the core product surface.

## Run the maintained example

The dogfood app at `packages/desy_design_system/example/` is the maintained
Desy Bench example and integration testbed. You can first explore the running
[Desy Bench demo](https://desy-bench.web.app) in the browser, then run the same
example locally.

With [Task](https://taskfile.dev/) installed, run this from the repository
root:

```sh
task dogfood:run
```

Otherwise, use Flutter directly:

```sh
cd packages/desy_design_system/example
flutter run
```

> **Why “dogfood”?** This app exercises Desy's own public APIs and real design
> system—the project uses the product it builds.

## Try Desy in your Flutter project

Desy currently ships straight from GitHub. Add `desy_bench` to the consumer
app's `pubspec.yaml`, then run `flutter pub get`:

```yaml
dependencies:
  desy_bench:
    git:
      url: https://github.com/ChrisMarxDev/desy.git
      path: packages/desy_bench
      ref: main
```

You will create one consumer-owned `DesyRegistry` beside the real theme and
widgets it describes, then run the workbench in a local development entry point.
The registry remains the source of truth; Desy only presents the real Flutter
widgets under their real theme.

## Documentation

- [Registry: declare your design system](docs/registry.md)
- [Knobs: portable component inputs](docs/knobs.md)

## Give this prompt to your coding agent

Copy this into the agent working on your Flutter project:

```text
Add the Desy Bench beta to this Flutter project.

Install the Desy beta, then run `flutter pub get`:

dependencies:
  desy_bench:
    git:
      url: https://github.com/ChrisMarxDev/desy.git
      path: packages/desy_bench
      ref: main

Read these current Desy instructions before writing code:
- https://github.com/ChrisMarxDev/desy/blob/main/AGENTS.md
- https://github.com/ChrisMarxDev/desy/blob/main/.agents/skills/desy/references/registry-contracts.md

Then inspect this dogfood registry and implement the same integration pattern for this project’s actual theme, tokens, and widgets:
https://github.com/ChrisMarxDev/desy/blob/main/packages/desy_design_system/example/lib/src/desy_design_system_registry.dart

Create one consumer-owned DesyRegistry that returns this project’s real widgets under its real theme. Keep the existing app and design system as the source of truth; do not make a parallel catalogue or substitute fake preview widgets. Add a practical local development entry point for opening Desy and verify the narrowest relevant checks.

Desy is beta and its APIs are changing. For anything unclear, stop and ask the user before guessing.
```

## Maintainers and contributors

The maintained dogfood app is the executable reference and integration testbed.
Its [registry](https://github.com/ChrisMarxDev/desy/blob/main/packages/desy_design_system/example/lib/src/desy_design_system_registry.dart)
shows a complete real-world declaration. For the source repository, start with
the [contributor guide](concept/dev.md),
[architecture principles](CORE_PRINCIPLES.md), and
[feature index](concept/features/index.html).

Run the complete workspace verification suite with:

```sh
task check
```

# Desy Bench

Desy is a local Flutter workbench for the design system your repository already
owns. Register real themes, tokens, and widgets once; Desy lets your team browse,
compare, and evolve them without creating a second component catalogue.

> **Beta:** Desy is moving quickly. Install from `main`, expect APIs to change,
> and let the current repository guidance take precedence over old examples.

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

## Run it

With [Task](https://taskfile.dev/) installed, launch the maintained dogfood app
from the repository root:

```sh
task dogfood:run
```

Otherwise, run Flutter directly:

```sh
cd packages/desy_design_system/example
flutter run
```

> **Why “dogfood”?** This app exercises Desy's own public APIs and real design
> system—the project uses the product it builds.

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

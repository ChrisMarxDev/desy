# Detective: runtime-inspection research for Desy Bench

Research date: 2026-08-12

## Verdict

Detective is useful inspiration for **a local, debug-only companion that
attaches to a running Flutter VM**, but it is not a dependency or foundation for
Desy's editing model. Its public source is a small Dart CLI that connects a
separate desktop binary to a VM-service URI, exposes `watch <class>` and
`call <class> <function>` commands, and transfers later commands through files.
It does not expose a source-editing API or an open inspector implementation to
reuse. ([CLI source](https://github.com/Norbert515/detective/blob/master/bin/detective.dart),
[launcher](https://github.com/Norbert515/detective/blob/master/lib/src/launcher.dart),
[command bridge](https://github.com/Norbert515/detective/blob/master/lib/src/command_saver.dart))

For Desy, the practical product opportunity is **live, typed preview overrides
of declared registry components**—not mutation/reflection over an arbitrary
running widget tree. A later, optional runtime-inspection overlay/host can make
selecting a real in-app widget and handing its source context to a developer or
agent much more direct.

## What Detective demonstrably does

- It requires the target app to be launched with
  `--vmservice-out-file=detective_connect.txt`, reads that file from the current
  directory, and provides its contents to the Detective desktop process as the
  `CONNECT` environment value. This is an external-development-tool topology,
  not an in-app widget library. ([CLI lines 9–24](https://github.com/Norbert515/detective/blob/master/bin/detective.dart#L9-L24))
- Its supported command vocabulary in the published CLI is `watch <class>` and
  `call <class> <function>`. The latter indicates runtime method invocation;
  neither command establishes arbitrary widget-property editing or Dart-source
  modification. ([CLI lines 30–56](https://github.com/Norbert515/detective/blob/master/bin/detective.dart#L30-L56))
- It launches bundled macOS, Windows, or Linux applications. Follow-up commands
  are written as UUID-named `.detectivecmd` files for the application to detect
  and execute. ([platform launcher](https://github.com/Norbert515/detective/blob/master/lib/src/launcher.dart),
  [file-command protocol](https://github.com/Norbert515/detective/blob/master/lib/src/command_saver.dart#L4-L18))
- The repository itself contains the CLI and the prebuilt desktop payload, but
  not the desktop inspector's Dart source. Its package constraint is
  `>=2.12.0 <3.0.0`, so it is not a viable modern Dart/Flutter package
  dependency without a fork and migration. ([repository tree](https://github.com/Norbert515/detective),
  [pubspec](https://github.com/Norbert515/detective/blob/master/pubspec.yaml#L1-L19))

The last two points mean this research can only claim the public integration
contract above; capabilities rendered inside the closed, bundled desktop app
should not be treated as a product requirement or copied behavior.

## Fit against Desy's contracts

| Concern | Detective pattern | Desy-compatible direction |
| --- | --- | --- |
| Runtime connection | Separate local process reads a VM-service URI. | Useful optional host/DevTools-adapter pattern for debug inspection. |
| Inventory | Targets runtime class names. | Keep the consumer's immutable `DesyRegistry` as the only declared inventory; do not discover a second catalogue. |
| Live editing | Public CLI shows state observation and method calls, not a typed edit schema. | Use each `DesyComponent`'s declared, immutable typed knob schema and `buildWithValues`; the workbench already rebuilds real widgets from live knob values. |
| Source edits | No public source-writing/hot-reload workflow. | Keep source changes external and reviewable; a trusted local host/agent performs any repository edit and requests hot reload. |
| Platform scope | Packaged desktop client only. | Preserve Desy's Flutter-platform-compatible workbench; any desktop host is an opt-in developer tool. |

The registry already has the correct seam for the proposed "live widget
editing" experience: `DesyComponent` declares a typed immutable knob schema
once, then builds the consumer's real widget from a current values map.
([registry component contract](../../packages/desy_bench/lib/src/registry.dart),
[live detail preview](../../packages/desy_bench/lib/src/workbench/presentation/detail_screen.dart))
This deliberately limits edits to values that the component author has said are
meaningful—text, number, boolean, color, legal widget-instance choices, and
events—rather than attempting fragile runtime reflection.

## Recommended next step (not a commitment)

Do **not** integrate or fork Detective. If runtime inspection becomes a ranked
feature, run a small local-first spike with two separate capabilities:

1. Extend the existing component-detail session only as needed so knob changes
   are clearly ephemeral preview overrides, keyed by stable component and knob
   IDs. They must never mutate the immutable registry or generate source.
2. Independently prototype a debug-only overlay plus local host that selects a
   real running consumer widget, records source-aware context/annotations, and
   can ask the resident Flutter tool for hot reload after an explicitly
   user-reviewed external edit.

This borrows Detective's valuable separation of a running app from a local
developer companion, while preserving Desy's core principles: one
consumer-owned registry, real widgets in their real theme, local-first work,
and reviewable source changes.

# Desy dogfood goldens prototype

> PROTOTYPE — throwaway evidence for automatic registry-derived golden tests.

This package answers one question: can a consumer import its `DesyRegistry`
once and immediately derive deterministic golden cases for every component
default, named instance, declared scenario, and theme?

It is deliberately separate from the dogfood application. Nothing under this
package is imported by `desy_bench`, `desy_design_system`, or the executable
catalogue. The prototype depends on `desy_design_system_example` only as a
development-time source of the real dogfood registry.

From the repository root:

```sh
task goldens_prototype:plan
task goldens_prototype:update
task goldens_prototype:verify
```

Each task invokes `flutter test` directly—the Flutter test process is the
headless command runner because it imports and renders the real registry.
`verify` never writes baselines. `update` is the only command that passes
Flutter's explicit golden-update flag.

The maintained consumer bridge is intentionally one registry import and one
call in `test/dogfood_goldens_test.dart`. Generated plan data stays under
`.dart_tool/desy_goldens_prototype/`; PNG baselines live under `test/goldens/`.

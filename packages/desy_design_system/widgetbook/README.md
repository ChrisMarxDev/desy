# Desy Widgetbook comparison

This is a local-only Widgetbook experiment for comparing its authoring and
inspection workflow with Desy. It intentionally renders public, production
widgets from `desy_design_system` inside `DesyDesignSystemScope`, so the
comparison uses Desy's real theme and controls.

It is not a second source of truth: `example/lib/src/desy_design_system_registry.dart`
remains Desy's sole registry. The manually curated use cases here are a narrow
evaluation fixture and must not become a parallel catalogue.

Run it locally with:

```sh
task widgetbook:web
```

## What is included

- Hand-authored Widgetbook folders and use cases for Desy actions, inputs,
  feedback, navigation, surfaces, agent UI, and utilities.
- Per-use-case Widgetbook knobs for labels, variants, sizes, enabled and
  selected states, strings, numeric values, and constrained choices.
- Widgetbook’s viewport, theme, text-scale, alignment, grid, zoom, inspector,
  and experimental semantics add-ons.

Useful comparison points: the manual directory/use-case and knob declarations,
how Widgetbook shares a configured URL, its inspection add-ons, and the amount
of per-component setup required to expose the same real widgets.

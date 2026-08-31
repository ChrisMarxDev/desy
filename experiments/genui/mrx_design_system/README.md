# MRX Design System

`mrx_design_system` owns the reusable Orbit/MRX Flutter theme and widget
primitives. Every widget resolves colours, typography, motion, and spacing
through `OrbitTheme.of(context)`.

`orbit_app` is intentionally separate: it is the local Desy workbench that
registers and previews these real widgets.

## Structure

- `lib/src/orbit_theme.dart` — the single inherited theme, tokens, and core
  widgets.
- `lib/src/genui/atoms/` — one file per individual widget primitive.
- `lib/mrx_design_system.dart` — public package entry point.

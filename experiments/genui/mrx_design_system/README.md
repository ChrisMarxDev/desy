# MRX Design System

`mrx_design_system` owns the reusable Orbit/MRX Flutter theme and widget
primitives. Every widget resolves colours, typography, motion, and spacing
through `OrbitTheme.of(context)`.

`orbit_app` is intentionally separate: it is the local Desy workbench that
registers and previews these real widgets.

## MRX transition

The existing Orbit implementation remains intact while the hand-rolled MRX
system starts in `lib/src/mrx/`. Its foundation is deliberately independent:
one inherited `MrxTheme`, semantic colours, token measurements, typography,
and motion. New MRX widgets will be added there one at a time; Orbit widgets
remain available until their replacements are ready.

## Structure

- `lib/src/orbit_theme.dart` — the single inherited theme, tokens, and core
  widgets.
- `lib/src/genui/atoms/` — one file per individual widget primitive.
- `lib/src/mrx/` — the new hand-rolled MRX foundation and future widgets.
- `lib/mrx_design_system.dart` — public package entry point.

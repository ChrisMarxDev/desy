# MRX design system workbench

`experiments/genui/mrx_design_system/` owns MRX's reusable Flutter theme and
widget primitives. It has no Desy or application dependency. The sibling
`experiments/genui/orbit_app/` package owns the immutable consumer
registry and is the sole local executable: it opens those real widgets in Desy.

## Foundation

MRX has one inherited dark theme: `OrbitThemeData.standard`. Every widget reads
its semantic colors, typography, motion, and measurements through
`OrbitTheme.of(context)`; widget APIs do not accept a second theme object or
parallel token map.

The foundation uses semantic background, foreground, card, popover, primary,
secondary, muted, accent, border, input, ring, destructive, success, warning,
and info roles. The base radius is 10 logical pixels, derived sizes are
6/8/10/14, and spacing uses a compact 4/6/8/12/16/24/32 scale. Motion respects
`MediaQuery.disableAnimationsOf`.

Mix provides reusable surface and pill treatments. The implementation uses
Flutter's native interaction and text-entry primitives rather than Material
controls or custom gesture coordination.

## Package boundary

`mrx_design_system` exports its public theme and widget API from
`lib/mrx_design_system.dart`:

- `lib/src/orbit_theme.dart` contains the inherited theme, tokens, typography,
  motion, and core widgets.
- `lib/src/genui/atoms/` contains one file per individual primitive.

The nested `desy` app only depends on `mrx_design_system`, `desy_core`, and
`desy_bench`. Its `DesyRegistry` remains the declared source of truth for the prototype
catalogue. It currently registers real surface, button, icon-button, badge,
progress, spinner, shortcut-label, overflow-menu, and text-field widgets.

## Verification

Run `task mrx_design_system:analyze` and `task mrx_design_system:test` for the
reusable package. Run `task orbit_app:analyze`, `task orbit_app:test`, and
`task orbit_app:build:web` for the consumer app.

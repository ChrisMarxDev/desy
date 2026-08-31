# MRX design system workbench

`experiments/genui/mrx_design_system/` owns MRX's reusable Flutter theme and
widget primitives. It has no Desy or application dependency. The sibling
`experiments/genui/orbit_app/` package owns the immutable consumer
registry and is the sole local executable: it opens those real widgets in Desy.

## Transition architecture

The existing Orbit implementation remains available without modification while
the hand-rolled MRX system is developed under
`experiments/genui/mrx_design_system/lib/src/mrx/`. `MrxThemeData.standard` is
its initial single dark theme. Every new MRX widget reads semantic colors,
typography, motion, and measurements through `MrxTheme.of(context)`; widget
APIs do not accept a second theme object or parallel token map.

The foundation uses semantic background, foreground, card, popover, primary,
secondary, muted, accent, border, input, ring, destructive, success, warning,
and info roles. The base radius is 10 logical pixels, derived sizes are
6/8/10/14, and spacing uses a compact 4/6/8/12/16/24/32 scale. Motion respects
`MediaQuery.disableAnimationsOf`.

MRX's foundation uses Flutter's inherited-widget and interaction primitives;
new widgets are hand-rolled rather than built by extending the old Orbit
widgets. A widget moves only when its MRX replacement is ready, keeping the
current Orbit API intact throughout the transition.

## Package boundary

`mrx_design_system` exports its public theme and widget API from
`lib/mrx_design_system.dart`:

- `lib/src/orbit_theme.dart` retains the existing Orbit theme, tokens,
  typography, motion, and core widgets.
- `lib/src/genui/atoms/` contains one file per individual primitive.
- `lib/src/mrx/` contains the new MRX theme foundation and future MRX widgets.

The nested `desy` app only depends on `mrx_design_system`, `desy_core`, and
`desy_bench`. Its `DesyRegistry` remains the declared source of truth for the prototype
catalogue. It currently registers real surface, button, icon-button, badge,
progress, spinner, shortcut-label, overflow-menu, and text-field widgets.

## Verification

Run `task mrx_design_system:analyze` and `task mrx_design_system:test` for the
reusable package. Run `task orbit_app:analyze`, `task orbit_app:test`, and
`task orbit_app:build:web` for the consumer app.

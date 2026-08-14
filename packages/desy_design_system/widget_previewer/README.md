# Desy Widget Previewer comparison

This is a small, local-only comparison harness for Flutter's first-party
Widget Previewer. It renders production Desy widgets under their real light and
dark theme scopes. It is intentionally not a `DesyRegistry` and does not
replace the dogfood catalogue.

The checked-in comparison target is Flutter 3.44, whose SDK already provides
the command and annotation API. Flutter documents the Previewer as stable from
Flutter 3.47, so use that SDK or newer for a stable-tool evaluation. From the
repository root, start it with:

```sh
task widget_previewer:start
```

The preview environment is browser/IDE-oriented and writes ignored generated
state to `.widget_preview/`. Its source annotations deliberately demonstrate
only simple, source-local states; use the dogfood catalogue for registry
instances, typed knobs, responsive/device artboards, and accessibility review.

# GenUI exploration

This workspace area contains GenUI work. It lives alongside Desy but is not
part of Desy's core product surface.

- `desy_genui/` is the optional compiler from a consumer-owned
  `DesyRegistry` to a Flutter GenUI catalog.
- `mrx_design_system/` owns the reusable Orbit/MRX Flutter theme and widget
  primitives.
- `orbit_app/` is the consumer app. Its immutable Desy registry previews real
  widgets from `mrx_design_system`.

Use `task genui:*` for the reusable compiler, `task mrx_design_system:*` for
the reusable widgets, and `task orbit_app:*` for the consumer app.

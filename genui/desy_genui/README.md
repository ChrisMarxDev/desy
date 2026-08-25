# desy_genui

`desy_genui` compiles an opted-in `DesyRegistry` into an executable Flutter
GenUI `Catalog`. The registry remains the only widget inventory: the adapter
derives JSON Schema, prompt guidance, named examples, and runtime builders from
the existing component and knob declarations.

```dart
final compiled = DesyGenUiCatalog.compile(registry);
final controller = SurfaceController(catalogs: [compiled.catalog]);
```

Render an A2UI surface under one of the registry's real themes:

```dart
DesyGenUiSurface(
  controller: controller,
  surfaceId: 'assistant-result',
  theme: registry.themes.first,
)
```

## Backend boundary

`compiled.backendArtifact` is JSON-safe and contains:

- the stable catalog ID and consumer version;
- A2UI v0.9 capabilities and the full catalog schema;
- system prompt fragments and materialized named-instance examples;
- the protocol-neutral Desy catalogue export;
- a deterministic SHA-256 digest for compatibility checks.

Serve that artifact to whichever agent backend is under evaluation. The
backend generates A2UI messages; it never receives Flutter callbacks or widget
builders. The client keeps `compiled.catalog`, processes messages with
`SurfaceController`, and sends user action envelopes back to the backend.

Literal values are supported for string, number, boolean, ISO-8601 date-time,
color, single child, and multiple children knobs. Event knobs accept A2UI
actions. Data bindings are intentionally deferred; multi-child slots
deliberately advertise literal lists instead of template bindings.

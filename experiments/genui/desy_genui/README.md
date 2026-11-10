# desy_genui

`desy_genui` compiles an opted-in `DesyRegistry` into an executable A2UI
`CatalogImplementation` for `a2ui_flutter`. The registry remains the only widget
inventory: the adapter derives JSON Schema, prompt guidance, named examples, and
runtime builders from the existing component and knob declarations.

```dart
final compiled = DesyGenUiCatalog.compile(registry);
final processor = MessageProcessor<ComponentImplementation>(
  catalogs: [compiled.catalog],
);
```

Render an A2UI surface under one of the registry's real themes:

```dart
DesyGenUiSurface(
  controller: processor,
  surfaceId: 'assistant-result',
  theme: registry.themes.first,
)
```

The processor creates the surface when the agent's `createSurface` arrives;
until then the widget shows `defaultBuilder`, if given. User actions arrive on
`processor.model.onAction` and errors on `processor.model.onError`.

## Backend boundary

`compiled.backendArtifact` is JSON-safe and contains:

- the stable catalog ID and consumer version;
- the catalog in the A2UI v0.9 inline-capabilities shape, and the full catalog
  document;
- system prompt fragments, also the catalog's `instructions`, and materialized
  named-instance examples;
- the protocol-neutral Desy catalogue export;
- a deterministic SHA-256 digest for compatibility checks.

Serve that artifact to whichever agent backend is under evaluation. The
backend generates A2UI messages; it never receives Flutter callbacks or widget
builders. The client keeps `compiled.catalog`, processes messages with
`MessageProcessor`, and sends user action envelopes (`ActionMessage`) back to
the backend.

Literal values are supported for string, number, boolean, ISO-8601 date-time,
color, single child, and multiple children knobs. Event knobs accept A2UI
actions. Data bindings are intentionally deferred; multi-child slots
deliberately advertise literal lists instead of template bindings.

Each component accepts only the properties its knobs declare. `a2ui_core` reads
a component property named `metadata` as A2UI component metadata, so the agent
cannot set a knob with the ID `metadata`: any value other than
`{"extensions": {...}}` rejects the component, and that value does not reach
the knob.

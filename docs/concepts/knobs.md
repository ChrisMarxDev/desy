# Desy knobs: portable component inputs

Knobs are declared by a consumer in `DesyComponent.knobs`. That one declaration
creates typed values for the real Flutter builder, editable controls in Desy
Bench, named-instance overrides, surface validation, snapshots, and—when
`desy_genui` is used—the agent-facing A2UI JSON schema.

## Portable collections and JSON

Use the narrowest shape that describes the data:

- `k.stringList(...) -> Knob<List<String>>` for ordered text.
- `k.numberList(...) -> Knob<List<double>>` for ordered finite numbers. It
  accepts optional `minimum` and `maximum`, which apply to every item.
- `k.jsonValue(...) -> Knob<Object>` for a decoded JSON root: an object, array,
  string, number, or boolean. A JSON root may not be null.

Each collection is frozen on declaration and again when runtime or agent data
is resolved. `jsonValue` is normalized through JSON encoding/decoding and
deep-frozen; it is never a JSON-formatted Dart string.

```dart
knobs: (k) => (
  labels: k.stringList('labels', initial: const ['Search', 'Invite']),
  values: k.numberList('values', initial: const [38, 26], minimum: 0),
  metadata: k.jsonValue(
    'metadata',
    initial: const {'source': 'workspace', 'fresh': true},
  ),
),
```

## Consumer-owned data models

The portable handoff remains primitive. A consumer may convert values to a
private typed view model at its component boundary:

```dart
data: OrbitChartDatum.zip(
  labels: knobs.labels.value,
  values: knobs.values.value,
),
```

The `zip` helper verifies that the lists have equal lengths. This keeps Dart
records and package-specific types (such as `fl_chart` data) out of the GenUI
contract while keeping real widget code fully typed.

## GenUI mapping

`desy_genui` maps `stringList` to a JSON array of strings, `numberList` to a
JSON array of numbers with any declared per-item bounds, and `jsonValue` to an
unconstrained JSON schema. Incoming GenUI data is validated before the
component builder receives it.

This does not make knobs a general remote-control protocol. Widgets remain
consumer-declared, events remain host-owned intents, and application tools or
network calls remain outside the registry contract.

## Live GenUI data bindings

Scalar, collection, and JSON knobs may use an A2UI data binding instead of a
literal value. The component tree stays fixed while only the bound consumer
widget rebuilds when `updateDataModel` changes its value:

```json
{
  "id": "weekly-chart",
  "component": "orbit.component.bar-chart",
  "title": {"path": "/charts/weekly/title"},
  "labels": {"path": "/charts/weekly/labels"},
  "values": {"path": "/charts/weekly/values"}
}
```

The app, an agent, or a provider stream can then send a narrow update:

```json
{
  "version": "v0.9",
  "updateDataModel": {
    "surfaceId": "orbit-experiment",
    "path": "/charts/weekly/values",
    "value": [24, 31, 18]
  }
}
```

Use bindings for values, not topology: component IDs, child slots, and events
remain literal declarations. The registry still owns the permitted widgets and
the app still owns authentication, provider calls, refresh policy, and action
permissions.

## Bench controls

Desy Bench renders string and number lists as comma-separated values and JSON
as validated JSON text. Live values are local preview state. They never alter
the immutable registry and are not a persistence format.

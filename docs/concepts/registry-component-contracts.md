# Desy component contracts: typed bound-record knobs

This concept doc captures the implemented registry contract for consumer-owned
components, knobs, and named instances. It is the committed successor to the
throwaway `packages/desy_bench/tool/knob_bound_record_prototype.dart` prototype.
The registry interface is the declared source of truth; this document explains
what Desy asks of a consumer and why each decision is that way.

## The problem Desy is solving

A design-system workbench must run the consumer's *real* widgets so its previews
and composition surfaces can never drift from production. To inspect and vary a
component it needs a knob schema; to reuse a component in a composition it needs
stable, named instances. Those must survive an immutable registry, startup
validation, live editing, and eventual serialization — without copying consumer
callbacks or inventing a parallel catalogue.

## The contract in one example

```dart
final activityCard = DesyComponent(
  id: 'trail.activity-card',
  path: '/content/cards',

  // One callback produces the runtime schema AND the typed record K for the
  // other two callbacks. Nothing is declared twice.
  knobs: (k) => (
    title: k.string('title', initial: 'Activity'),
    subtitle: k.string('subtitle', initial: 'Track your activity'),
    enabled: k.boolean('enabled', initial: true),
    trailing: k.widgetInstance('trailing', initial: 'trail.icon.plus'),
  ),

  // The one builder used by the default preview and every named instance.
  build: (context, knobs) => ActivityCard(
    title: knobs.title.value,
    subtitle: knobs.subtitle.value,
    enabled: knobs.enabled.value,
    trailing: knobs.trailing.widget,
  ),

  // A named instance is only a stable ID plus typed knob overrides.
  instances: (knobs) => {
    'runs': [knobs.subtitle('Track your runs')],
    'disabled': [knobs.enabled(false), knobs.trailing('trail.icon.check')],
  },
);
```

### Components are a discriminated family

- `DesyComponent<K>` is a typed component: an immutable knob schema, one real
  builder, and named instances authored purely as knob overrides.
- `DesyStaticComponent` is the minimal member: named instances map directly to
  widget builders and it declares no knobs.
- Both implement `DesyRegistryComponent`, so the flat `components` list on
  `DesyRegistry` stays one list and navigation derives from validated slash
  paths alone.

## Decisions and the reasons behind them

### 1. The `knobs` callback returns a record, declared once

The schema and the typed handles are the same object. A consumer never writes a
separate schema list and then a parallel wiring list; Widgetbook research showed
that duplication drifts. `K` is inferred from the record literal, so the author
gets full autocomplete and return-type checking without any code generation.

`KnobScope` is the authoring surface. It currently offers three primitives:

- `k.string(id, {name?, initial}) -> Knob<String>`
- `k.boolean(id, {name?, initial}) -> Knob<bool>`
- `k.widgetInstance(id, {name?, initial, options?}) -> WidgetInstanceKnob`

The schema's runtime form is an immutable list of `KnobDefinition<Object>`
(used by the workbench knob panel), while the typed handles (`Knob<T>`,
`WidgetInstanceKnob`) keep build and instance code typesafe.

### 2. One `build` serves every preview and every instance

`build(context, knobs)` is the only widget-returning path. A named instance is
resolved by binding that instance's typed overrides into a fresh
`ResolvedKnobScope` and running the same `build`. This is why render fidelity
cannot diverge between the catalogue and a composed instance. The old model's
separate `preview` and `buildWithKnobs` are gone.

### 3. Instances are stable IDs plus typed knob overrides

An instance has no separate widget callback and no parallel value map. It is a
stable ID and a list of `KnobSetting`s (the result of calling a typed handle,
e.g. `knobs.enabled(false)`). The registry-scoped ID is `componentId.instanceId`
(e.g. `trail.activity-card.runs`). That single namespace is what the workbench
sketch palette, instance swapping, catalogue export, and future manifests all
share.

A `widgetInstance` knob references another registered instance by its stable ID
through a typed `DesyInstanceId`. Legal-slot scoping is optional: supply
`options` to restrict the swap picker to a meaningful allow-list, or leave it
empty to allow any registered instance.

### 4. Resolution is centralized and cycle-safe

`registry.widgetBuilder` / `DesyWidgetResolver` is the only bridge back from a
stable ID to the consumer's real widget. It:

- matches the longest component-ID prefix (component IDs may contain dots, as in
  `desy.component.badge`),
- builds nested widget instances without reapplying the selected theme,
- guards against cyclic references,
- renders a clickable diagnostic for unresolved IDs so a broken link stays
  inspectable at runtime, and
- is what registry validation uses to report missing references at startup.

### 5. Declarations stay immutable

Component collections, knob schemas, and instance overrides are frozen at
construction. Workbench state (which instance is selected, live knob edits) is
ephemeral session state, never written back into the consumer declaration and
never serialized. This is what keeps the registry a stable, single source of
truth.

## What a consumer no longer writes

The previous surface — `DesyKnob`, `DesyBooleanKnob`, `DesyStringKnob`,
`DesyComponentKnob`, `DesyKnobValues`, and `DesyComponentInstance` — is removed.
There is no stringly-typed value map and no parallel instance/list representation.

## Compatibility and validation

`DesyRegistry.validate()` reports problems without mutating the registry:
duplicate IDs across the shared namespace (themes, atoms, artifacts, instances,
extensions) and widget-instance references to instances that do not
exist. Unknown references are warnings so the workbench can still load and
expose the diagnostic.

## Status

Implemented and verified by `task check` (analysis, Forui boundary, all five
test suites, and the production dogfood web build). The throwaway prototypes in
`packages/desy_bench/tool/` remain for reference and are not part of the package
surface. Manifest persistence, a CLI, and generated production widget code (from
`CORE_PRINCIPLES.md`) remain deliberately deferred.

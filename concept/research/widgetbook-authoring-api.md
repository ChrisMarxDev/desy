# Widgetbook authoring API: implications for Desy knob prototypes

Research date: 2026-08-07. Sources are limited to Widgetbook's official documentation and the official `widgetbook/widgetbook` repository. Source links are pinned to main commit [`66c1eb2`](https://github.com/widgetbook/widgetbook/tree/66c1eb2f002aab2c90cceddff9f7a84db1959dc2) (2026-06-25).

## Current Widgetbook model

### Use cases and components

The recommended generated form is a top-level `Widget Function(BuildContext)` annotated with `@UseCase`. `name` and the catalogued widget `type` are required; `path`, `designLink`, Cloud knob configurations, and exclusion flags are optional.

```dart
@UseCase(name: 'Primary', type: CoolButton)
Widget primaryButton(BuildContext context) => CoolButton(
  label: context.knobs.string(label: 'Label', initialValue: 'Save'),
);
```

The generator emits a `WidgetbookUseCase(name: ..., builder: primaryButton)` and uses the annotation's `type` to place that use case under a component. It does not generate the knob declarations. Manual authoring remains possible by constructing `WidgetbookUseCase(name:, builder:)` directly.

Sources: [official annotation guide](https://docs.widgetbook.io/use-cases/annotations), [`UseCase` annotation source](https://github.com/widgetbook/widgetbook/blob/66c1eb2f002aab2c90cceddff9f7a84db1959dc2/packages/widgetbook_annotation/lib/src/use_case.dart), [generated use-case expression](https://github.com/widgetbook/widgetbook/blob/66c1eb2f002aab2c90cceddff9f7a84db1959dc2/packages/widgetbook_generator/lib/src/code/widgetbook_use_case_instance.dart), [`WidgetbookUseCase` source](https://github.com/widgetbook/widgetbook/blob/66c1eb2f002aab2c90cceddff9f7a84db1959dc2/packages/widgetbook/lib/src/navigation/nodes/widgetbook_use_case.dart).

### How builders access and register knobs

Use-case builders access a typed `KnobsBuilder` through `context.knobs`. Each call both declares/registers a knob and returns its current typed value directly:

```dart
MyWidget(
  title: context.knobs.string(label: 'Title'),       // String
  enabled: context.knobs.boolean(label: 'Enabled'), // bool
  status: context.knobs.object.dropdown<Status>(
    label: 'Status',
    options: Status.values,
    labelBuilder: (value) => value.name,
  ),                                                 // Status
)
```

Knobs are **dynamically discovered during use-case build**, but only because the author explicitly calls a knob method. Before every build Widgetbook clears the current registry; each call routes through `onKnobAdded`; after the first frame the registry is locked and the panel is notified. There is no generated, reflected, or separately registered knob schema. Labels are string identities and must be unique within a use case.

This produces good local autocomplete and return-type checking (`String`, `bool`, nullable variants, or generic `T`). It does not produce a named, compile-time component configuration object: preset/Cloud configuration still addresses knobs through string labels.

Sources: [knob overview](https://docs.widgetbook.io/knobs/overview), [`KnobsBuilder` source](https://github.com/widgetbook/widgetbook/blob/66c1eb2f002aab2c90cceddff9f7a84db1959dc2/packages/widgetbook/lib/src/knobs/builders/knobs_builder.dart), [runtime discovery lifecycle](https://github.com/widgetbook/widgetbook/blob/66c1eb2f002aab2c90cceddff9f7a84db1959dc2/packages/widgetbook/lib/src/workbench/use_case_builder.dart), [`KnobsRegistry` source](https://github.com/widgetbook/widgetbook/blob/66c1eb2f002aab2c90cceddff9f7a84db1959dc2/packages/widgetbook/lib/src/knobs/knobs_registry.dart).

### Arbitrary objects, widgets, and custom knobs

Object dropdown/segmented knobs are generic over unconstrained `T`; callers provide `List<T> options`, get `T` back, and may customize labels. This can technically select inline `Widget` objects because `Widget` is an object, but Widgetbook documents this as a general object knob—not as a first-class cross-component instance reference. It supplies no built-in registry-instance ID, compatibility contract, or resolver comparable to Desy's widget-instance knob.

```dart
trailing: context.knobs.object.dropdown<Widget>(
  label: 'Trailing',
  options: const [Icon(Icons.add), Icon(Icons.check)],
  labelBuilder: (widget) => widget.key?.toString() ?? widget.runtimeType.toString(),
)
```

Consumers can create a real custom typed knob by subclassing `Knob<T>`, describing its URL/UI fields, parsing those fields back to `T`, and adding a typed extension on `KnobsBuilder`. This is powerful enough to build a consumer-owned registry-reference knob, but that behavior is not provided by Widgetbook itself.

Sources: [object dropdown guide](https://docs.widgetbook.io/knobs/object/dropdown), [`ObjectKnobsBuilder<T>` source](https://github.com/widgetbook/widgetbook/blob/66c1eb2f002aab2c90cceddff9f7a84db1959dc2/packages/widgetbook/lib/src/knobs/builders/object_knobs_builder.dart), [custom knob guide](https://docs.widgetbook.io/knobs/custom-knob).

## Lessons for Desy Prototypes 2 and 4

| Concern | Widgetbook evidence | Desy implication |
| --- | --- | --- |
| Declaration burden | No separate knob list: calls inside the real builder register knobs. | Avoid requiring both a schema and a second independent wiring list. |
| Introspection timing | Knob inventory exists only after the use case builds. | Desy should not copy this lifecycle if Studio/validation must inspect an immutable registry before rendering. |
| Typing | Each call returns a strongly typed value, but labels/presets remain string-addressed. | Preserve Prototype 2/4's typed handles for instances and preset values; Widgetbook's generic `T` validates that typed object knobs are practical. |
| Widget swapping | Generic object knobs can select inline widgets; there is no first-class registered-instance reference. | Keep Desy's explicit widget-instance domain type and registry validation; it is a meaningful capability beyond Widgetbook. |
| Code generation | Generation discovers annotated use-case functions and catalog structure, not constructor parameters or knobs. | Code generation is optional for navigation ergonomics, not necessary to achieve Widgetbook-style knobs. |

**Prototype 2 is the safer base for Desy's public contract.** Its bound record makes the complete knob interface explicit and inspectable while keeping build and named-instance values typed. That better supports Desy's single immutable registry, stable IDs, and validation before rendering (Core Principles 1, 5, 12, and 19).

Prototype 4 is superficially closer to Widgetbook because knob registration happens imperatively while constructing a self-contained authoring object. The Widgetbook source also exposes the cost of that pattern: discovery depends on a build/registration lifecycle and hidden mutable registry state. Prototype 4 additionally requires inheritance, fields, constructor initializers, instance methods, and overrides for every component, which is difficult to justify under minimum necessary declaration and progressive disclosure (Principles 11 and 14).

Recommended direction: retain Prototype 2's immutable typed handles and first-class `WidgetInstanceKnob`, while borrowing Widgetbook's concise fluent names and direct typed values where that does not duplicate declarations. Treat annotation/code generation as an optional later convenience for catalogue discovery, not as the knob model.

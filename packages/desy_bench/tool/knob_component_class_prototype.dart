import 'package:flutter/material.dart';

import 'knob_prototype_widgets.dart';

// THROWAWAY PROTOTYPE 4: SELF-CONTAINED COMPONENT CLASS

// ==========================================================================
// POTENTIAL CONSUMER CODE — the user writes everything above the divider.
// ==========================================================================

final registry = DesyRegistry(
  name: 'Trail design system',
  themes: [DesyTheme(id: 'light', name: 'Light', wrap: _wrapLightTheme)],
  components: [
    trailingIconComponent,
    ClassComponent.define(ActivityComponent.new),
  ],
);

final trailingIconComponent = StaticComponent(
  id: 'trail.icon',
  name: 'Trailing icon',
  path: '/icons/actions',
  instances: [
    StaticInstance(
      id: 'plus',
      name: 'Plus',
      build: (_) => const Icon(Icons.add),
    ),
    StaticInstance(
      id: 'check',
      name: 'Check',
      build: (_) => const Icon(Icons.check),
    ),
  ],
);

final class ActivityComponent extends ComponentClass {
  ActivityComponent(super.knobs)
    : title = knobs.string(id: 'title', name: 'Title', initial: 'Activity'),
      subtitle = knobs.string(
        id: 'subtitle',
        name: 'Subtitle',
        initial: 'Track your activity',
      ),
      enabled = knobs.boolean(id: 'enabled', name: 'Enabled', initial: true),
      trailing = knobs.widgetInstance(
        id: 'trailing',
        name: 'Trailing',
        initial: 'trail.icon.plus',
      ),
      super(
        id: 'trail.activity-card',
        name: 'Activity card',
        path: '/content/cards',
        description: 'Summarises a tracked activity.',
        source: 'lib/components/activity_card.dart',
      );

  final Knob<String> title;
  final Knob<String> subtitle;
  final Knob<bool> enabled;
  final WidgetInstanceKnob trailing;

  HandleInstance running() => HandleInstance(
    id: 'runs',
    name: 'Running',
    values: [
      title('Activity'),
      subtitle('Track your runs'),
      trailing('trail.icon.plus'),
    ],
  );

  HandleInstance disabled() => HandleInstance(
    id: 'disabled',
    name: 'Disabled',
    values: [enabled(false), trailing('trail.icon.check')],
  );

  @override
  List<HandleInstance> get instances => [running(), disabled()];

  // The class owns its interface, instances, and one singular builder.
  @override
  Widget build(BuildContext context) => ActivityCard(
    title: title.value,
    subtitle: subtitle.value,
    enabled: enabled.value,
    trailing: trailing.widget,
  );
}

Widget buildRunningActivity(BuildContext context) =>
    registry.widget(context, const DesyInstanceId('trail.activity-card.runs'));

Widget _wrapLightTheme(BuildContext context, Widget child) => Theme(
  data: ThemeData.light(),
  child: Directionality(textDirection: TextDirection.ltr, child: child),
);

// _______________________________________________
// DESY CODE — a package user would not write anything below this divider.

final class DesyInstanceId {
  const DesyInstanceId(this.value);
  final String value;
}

typedef DesyThemeWrapper = Widget Function(BuildContext context, Widget child);
typedef DesyStaticWidgetBuilder = Widget Function(BuildContext context);

final class DesyTheme {
  const DesyTheme({required this.id, required this.name, required this.wrap});
  final String id;
  final String name;
  final DesyThemeWrapper wrap;
}

abstract interface class DesyRegistryComponent {
  String get id;
  String get name;
  String get path;
  List<String> get instanceIds;
  Widget buildInstance(
    BuildContext context,
    String instanceId,
    DesyWidgetResolver widgets,
  );
}

final class DesyRegistry {
  DesyRegistry({
    required this.name,
    required List<DesyTheme> themes,
    required List<DesyRegistryComponent> components,
  }) : themes = List.unmodifiable(themes),
       components = List.unmodifiable(components);
  final String name;
  final List<DesyTheme> themes;
  final List<DesyRegistryComponent> components;

  Widget widget(BuildContext context, DesyInstanceId id) => themes.first.wrap(
    context,
    DesyWidgetResolver._(this, const {}).build(context, id),
  );

  DesyRegistryComponent? componentFor(DesyInstanceId id) {
    for (final component in components) {
      if (component.instanceIds.any(
        (instanceId) => '${component.id}.$instanceId' == id.value,
      )) {
        return component;
      }
    }
    return null;
  }
}

final class DesyWidgetResolver {
  const DesyWidgetResolver._(this.registry, this.ancestors);
  final DesyRegistry registry;
  final Set<String> ancestors;

  Widget build(BuildContext context, DesyInstanceId id) {
    if (ancestors.contains(id.value)) {
      return _problem('Cyclic registry instance: ${id.value}');
    }
    final component = registry.componentFor(id);
    if (component == null) {
      return _problem('Missing registry instance: ${id.value}');
    }
    final instanceId = id.value.substring(component.id.length + 1);
    return component.buildInstance(
      context,
      instanceId,
      DesyWidgetResolver._(registry, {...ancestors, id.value}),
    );
  }

  Widget _problem(String message) => Container(
    key: ValueKey(message),
    padding: const EdgeInsets.all(8),
    child: Text(message),
  );
}

final class StaticInstance {
  const StaticInstance({
    required this.id,
    required this.name,
    required this.build,
  });
  final String id;
  final String name;
  final DesyStaticWidgetBuilder build;
}

final class StaticComponent implements DesyRegistryComponent {
  StaticComponent({
    required this.id,
    required this.name,
    required this.path,
    required List<StaticInstance> instances,
  }) : instances = List.unmodifiable(instances);
  @override
  final String id;
  @override
  final String name;
  @override
  final String path;
  final List<StaticInstance> instances;
  @override
  List<String> get instanceIds =>
      List.unmodifiable(instances.map((instance) => instance.id));
  @override
  Widget buildInstance(
    BuildContext context,
    String instanceId,
    DesyWidgetResolver widgets,
  ) => instances
      .singleWhere((instance) => instance.id == instanceId)
      .build(context);
}

final class KnobDefinition<T extends Object> {
  const KnobDefinition({
    required this.id,
    required this.name,
    required this.initial,
  });
  final String id;
  final String name;
  final T initial;
}

final class Knob<T extends Object> {
  const Knob._(this.definition, this.value);
  final KnobDefinition<T> definition;
  final T value;
  KnobSetting<T> call(T value) => KnobSetting(definition, value);
}

final class WidgetInstanceKnob {
  const WidgetInstanceKnob._(this.definition, this.value, this.widget);
  final KnobDefinition<DesyInstanceId> definition;
  final DesyInstanceId value;
  final Widget widget;
  KnobSetting<DesyInstanceId> call(String registeredInstanceId) =>
      KnobSetting(definition, DesyInstanceId(registeredInstanceId));
}

abstract interface class KnobSettingBase {
  KnobDefinition<Object> get definition;
  Object get value;
}

final class KnobSetting<T extends Object> implements KnobSettingBase {
  const KnobSetting(this.typedDefinition, this.typedValue);
  final KnobDefinition<T> typedDefinition;
  final T typedValue;
  @override
  KnobDefinition<Object> get definition => typedDefinition;
  @override
  Object get value => typedValue;
}

abstract interface class KnobScope {
  Knob<String> string({
    required String id,
    required String name,
    required String initial,
  });
  Knob<bool> boolean({
    required String id,
    required String name,
    required bool initial,
  });
  WidgetInstanceKnob widgetInstance({
    required String id,
    required String name,
    required String initial,
  });
}

final class DeclarationKnobScope implements KnobScope {
  final List<KnobDefinition<Object>> _definitions = [];
  @override
  Knob<String> string({
    required String id,
    required String name,
    required String initial,
  }) => _register(KnobDefinition(id: id, name: name, initial: initial));
  @override
  Knob<bool> boolean({
    required String id,
    required String name,
    required bool initial,
  }) => _register(KnobDefinition(id: id, name: name, initial: initial));
  @override
  WidgetInstanceKnob widgetInstance({
    required String id,
    required String name,
    required String initial,
  }) {
    final definition = KnobDefinition(
      id: id,
      name: name,
      initial: DesyInstanceId(initial),
    );
    _definitions.add(definition);
    return WidgetInstanceKnob._(
      definition,
      definition.initial,
      const SizedBox.shrink(),
    );
  }

  Knob<T> _register<T extends Object>(KnobDefinition<T> definition) {
    _definitions.add(definition);
    return Knob._(definition, definition.initial);
  }

  List<KnobDefinition<Object>> get definitions =>
      List.unmodifiable(_definitions);
}

final class ResolvedKnobScope implements KnobScope {
  ResolvedKnobScope(
    Iterable<KnobDefinition<Object>> definitions,
    Iterable<KnobSettingBase> overrides,
    this.context,
    this.widgets,
  ) : _definitions = {
        for (final definition in definitions) definition.id: definition,
      },
      _values = {
        for (final definition in definitions) definition: definition.initial,
      } {
    for (final override in overrides) {
      _values[override.definition] = override.value;
    }
  }

  final BuildContext context;
  final DesyWidgetResolver widgets;
  final Map<String, KnobDefinition<Object>> _definitions;
  final Map<KnobDefinition<Object>, Object> _values;
  @override
  Knob<String> string({
    required String id,
    required String name,
    required String initial,
  }) => _resolve(id);
  @override
  Knob<bool> boolean({
    required String id,
    required String name,
    required bool initial,
  }) => _resolve(id);
  @override
  WidgetInstanceKnob widgetInstance({
    required String id,
    required String name,
    required String initial,
  }) {
    final knob = _resolve<DesyInstanceId>(id);
    return WidgetInstanceKnob._(
      knob.definition,
      knob.value,
      widgets.build(context, knob.value),
    );
  }

  Knob<T> _resolve<T extends Object>(String id) {
    final definition = _definitions[id];
    if (definition is! KnobDefinition<T>) {
      throw StateError('Knob $id was not declared as $T.');
    }
    return Knob._(definition, _values[definition]! as T);
  }
}

final class HandleInstance {
  HandleInstance({
    required this.id,
    required this.name,
    Iterable<KnobSettingBase> values = const [],
  }) : values = List.unmodifiable(values);
  final String id;
  final String name;
  final List<KnobSettingBase> values;
}

abstract base class ComponentClass {
  ComponentClass(
    this.knobs, {
    required this.id,
    required this.name,
    required this.path,
    this.description,
    this.source,
  });
  final KnobScope knobs;
  final String id;
  final String name;
  final String path;
  final String? description;
  final String? source;
  List<HandleInstance> get instances;
  Widget build(BuildContext context);
}

final class ClassComponent implements DesyRegistryComponent {
  ClassComponent._({
    required this.definition,
    required this.definitions,
    required ComponentClass Function(KnobScope) create,
  }) : _create = create;

  factory ClassComponent.define(ComponentClass Function(KnobScope) create) {
    final scope = DeclarationKnobScope();
    return ClassComponent._(
      definition: create(scope),
      definitions: scope.definitions,
      create: create,
    );
  }

  final ComponentClass definition;
  final List<KnobDefinition<Object>> definitions;
  final ComponentClass Function(KnobScope) _create;
  @override
  String get id => definition.id;
  @override
  String get name => definition.name;
  @override
  String get path => definition.path;
  @override
  List<String> get instanceIds =>
      List.unmodifiable(definition.instances.map((instance) => instance.id));

  @override
  Widget buildInstance(
    BuildContext context,
    String instanceId,
    DesyWidgetResolver widgets,
  ) {
    final instance = definition.instances.singleWhere(
      (candidate) => candidate.id == instanceId,
    );
    final scope = ResolvedKnobScope(
      definitions,
      instance.values,
      context,
      widgets,
    );
    return _create(scope).build(context);
  }
}

import 'package:flutter/material.dart';

import 'knob_prototype_widgets.dart';

// THROWAWAY FINAL PROTOTYPE: BOUND RECORD OF TYPED KNOB HANDLES
//
// Question: what is the smallest consumer API that gives Desy an immutable,
// dynamically renderable knob schema, typed instance presets, and one builder?

// ==========================================================================
// POTENTIAL CONSUMER CODE — the user writes everything above the divider.
// ==========================================================================

final registry = DesyRegistry(
  name: 'Trail design system',
  themes: [DesyTheme(id: 'light', wrap: _wrapLightTheme)],
  components: [trailingIcons, activityCard],
);

// These are ordinary registered widget instances and can be used by any slot.
final trailingIcons = DesyStaticComponent(
  id: 'trail.icon',
  path: '/icons/actions',
  instances: {
    'plus': (_) => const Icon(Icons.add),
    'check': (_) => const Icon(Icons.check),
  },
);

final activityCard = DesyComponent(
  id: 'trail.activity-card',
  path: '/content/cards',

  // This callback is the runtime schema used to generate the knobs panel.
  // The returned record type is inferred and autocompletes in both callbacks.
  knobs: (k) => (
    title: k.string('title', initial: 'Activity'),
    subtitle: k.string('subtitle', initial: 'Track your activity'),
    enabled: k.boolean('enabled', initial: true),
    trailing: k.widgetInstance('trailing', initial: 'trail.icon.plus'),
  ),

  // Every default, named instance, and live knob edit uses this one builder.
  build: (context, knobs) => ActivityCard(
    title: knobs.title.value,
    subtitle: knobs.subtitle.value,
    enabled: knobs.enabled.value,
    trailing: knobs.trailing.widget,
  ),

  // An instance is only a stable ID plus typed knob overrides.
  instances: (knobs) => {
    'runs': [
      knobs.subtitle('Track your runs'),
      knobs.trailing('trail.icon.plus'),
    ],
    'disabled': [knobs.enabled(false), knobs.trailing('trail.icon.check')],
  },
);

// A screen, extension, or another widget can fetch the composed real widget.
Widget buildRunningActivity(BuildContext context) =>
    registry.widget(context, 'trail.activity-card.runs');

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

enum DesyKnobKind { string, boolean, widgetInstance }

typedef DesyThemeWrapper = Widget Function(BuildContext context, Widget child);

final class DesyTheme {
  const DesyTheme({required this.id, required this.wrap});

  final String id;
  final DesyThemeWrapper wrap;
}

abstract interface class DesyRegistryComponent {
  String get id;
  String get path;
  List<String> get instanceIds;
  List<KnobDefinition<Object>> get knobDefinitions;

  Iterable<DesyInstanceId> referencesFor(String instanceId);

  Widget buildInstance(
    BuildContext context,
    String instanceId,
    DesyWidgetResolver widgets,
  );
}

final class DesyRegistry {
  factory DesyRegistry({
    required String name,
    required List<DesyTheme> themes,
    required List<DesyRegistryComponent> components,
  }) {
    final registry = DesyRegistry._(
      name: name,
      themes: List.unmodifiable(themes),
      components: List.unmodifiable(components),
    );
    registry._validateInstanceGraph();
    return registry;
  }

  const DesyRegistry._({
    required this.name,
    required this.themes,
    required this.components,
  });

  final String name;
  final List<DesyTheme> themes;
  final List<DesyRegistryComponent> components;

  Widget widget(BuildContext context, String registeredInstanceId) =>
      themes.first.wrap(
        context,
        DesyWidgetResolver._(
          this,
          const {},
        ).build(context, DesyInstanceId(registeredInstanceId)),
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

  void _validateInstanceGraph() {
    final graph = <String, List<String>>{};
    for (final component in components) {
      for (final instanceId in component.instanceIds) {
        graph['${component.id}.$instanceId'] = component
            .referencesFor(instanceId)
            .map((reference) => reference.value)
            .toList(growable: false);
      }
    }

    for (final entry in graph.entries) {
      for (final reference in entry.value) {
        if (!graph.containsKey(reference)) {
          throw ArgumentError(
            '${entry.key} references missing registry instance $reference.',
          );
        }
      }
    }

    final visiting = <String>{};
    final visited = <String>{};

    void visit(String id) {
      if (visited.contains(id)) return;
      if (!visiting.add(id)) {
        throw ArgumentError('Cyclic registry instance dependency at $id.');
      }
      for (final reference in graph[id]!) {
        visit(reference);
      }
      visiting.remove(id);
      visited.add(id);
    }

    for (final id in graph.keys) {
      visit(id);
    }
  }
}

/// Resolves nested widget instances without applying the selected theme twice.
/// The runtime guard also covers unsaved knob edits not present at startup.
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
    final localInstanceId = id.value.substring(component.id.length + 1);
    return component.buildInstance(
      context,
      localInstanceId,
      DesyWidgetResolver._(registry, {...ancestors, id.value}),
    );
  }

  Widget _problem(String message) => Container(
    key: ValueKey(message),
    padding: const EdgeInsets.all(8),
    child: Text(message),
  );
}

final class DesyStaticComponent implements DesyRegistryComponent {
  DesyStaticComponent({
    required this.id,
    required this.path,
    required Map<String, WidgetBuilder> instances,
  }) : instances = Map.unmodifiable(instances);

  @override
  final String id;
  @override
  final String path;
  final Map<String, WidgetBuilder> instances;

  @override
  List<String> get instanceIds => List.unmodifiable(instances.keys);

  @override
  List<KnobDefinition<Object>> get knobDefinitions => const [];

  @override
  Iterable<DesyInstanceId> referencesFor(String instanceId) => const [];

  @override
  Widget buildInstance(
    BuildContext context,
    String instanceId,
    DesyWidgetResolver widgets,
  ) => instances[instanceId]!(context);
}

final class KnobDefinition<T extends Object> {
  const KnobDefinition({
    required this.id,
    required this.name,
    required this.kind,
    required this.initial,
  });

  final String id;
  final String name;
  final DesyKnobKind kind;
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
  Knob<String> string(String id, {String? name, required String initial});

  Knob<bool> boolean(String id, {String? name, required bool initial});

  WidgetInstanceKnob widgetInstance(
    String id, {
    String? name,
    required String initial,
  });
}

final class DeclarationKnobScope implements KnobScope {
  final List<KnobDefinition<Object>> _definitions = [];

  @override
  Knob<String> string(String id, {String? name, required String initial}) =>
      _register(
        KnobDefinition(
          id: id,
          name: name ?? _humanize(id),
          kind: DesyKnobKind.string,
          initial: initial,
        ),
      );

  @override
  Knob<bool> boolean(String id, {String? name, required bool initial}) =>
      _register(
        KnobDefinition(
          id: id,
          name: name ?? _humanize(id),
          kind: DesyKnobKind.boolean,
          initial: initial,
        ),
      );

  @override
  WidgetInstanceKnob widgetInstance(
    String id, {
    String? name,
    required String initial,
  }) {
    final definition = KnobDefinition(
      id: id,
      name: name ?? _humanize(id),
      kind: DesyKnobKind.widgetInstance,
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
    if (_definitions.any((existing) => existing.id == definition.id)) {
      throw ArgumentError('Duplicate knob ID ${definition.id}.');
    }
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
  Knob<String> string(String id, {String? name, required String initial}) =>
      _resolve(id);

  @override
  Knob<bool> boolean(String id, {String? name, required bool initial}) =>
      _resolve(id);

  @override
  WidgetInstanceKnob widgetInstance(
    String id, {
    String? name,
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

final class DesyComponent<K> implements DesyRegistryComponent {
  factory DesyComponent({
    required String id,
    required String path,
    required K Function(KnobScope knobs) knobs,
    required Widget Function(BuildContext context, K knobs) build,
    required Map<String, Iterable<KnobSettingBase>> Function(K knobs) instances,
  }) {
    final declaration = DeclarationKnobScope();
    final interface = knobs(declaration);
    final definitions = declaration.definitions;
    final declaredInstances = instances(interface);

    for (final entry in declaredInstances.entries) {
      for (final setting in entry.value) {
        if (!definitions.contains(setting.definition)) {
          throw ArgumentError(
            'Instance ${entry.key} uses a knob from another component.',
          );
        }
      }
    }

    return DesyComponent._(
      id: id,
      path: path,
      knobDefinitions: definitions,
      instances: Map.unmodifiable({
        for (final entry in declaredInstances.entries)
          entry.key: List<KnobSettingBase>.unmodifiable(entry.value),
      }),
      bind: knobs,
      build: build,
    );
  }

  const DesyComponent._({
    required this.id,
    required this.path,
    required this.knobDefinitions,
    required this.instances,
    required K Function(KnobScope knobs) bind,
    required Widget Function(BuildContext context, K knobs) build,
  }) : _bind = bind,
       _build = build;

  @override
  final String id;
  @override
  final String path;
  @override
  final List<KnobDefinition<Object>> knobDefinitions;
  final Map<String, List<KnobSettingBase>> instances;
  final K Function(KnobScope knobs) _bind;
  final Widget Function(BuildContext context, K knobs) _build;

  @override
  List<String> get instanceIds => List.unmodifiable(instances.keys);

  @override
  Iterable<DesyInstanceId> referencesFor(String instanceId) sync* {
    final settings = instances[instanceId]!;
    for (final definition in knobDefinitions) {
      if (definition.kind != DesyKnobKind.widgetInstance) continue;
      var value = definition.initial;
      for (final setting in settings) {
        if (identical(setting.definition, definition)) value = setting.value;
      }
      yield value as DesyInstanceId;
    }
  }

  @override
  Widget buildInstance(
    BuildContext context,
    String instanceId,
    DesyWidgetResolver widgets,
  ) {
    final scope = ResolvedKnobScope(
      knobDefinitions,
      instances[instanceId]!,
      context,
      widgets,
    );
    return _build(context, _bind(scope));
  }
}

String _humanize(String id) {
  final words = id.split(RegExp('[-_]'));
  return words
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

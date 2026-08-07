import 'package:flutter/material.dart';

import 'knob_prototype_widgets.dart';

// THROWAWAY PROTOTYPE 1: PLAIN TYPED CONFIGURATION

// ==========================================================================
// POTENTIAL CONSUMER CODE — the user writes everything above the divider.
// ==========================================================================

final registry = DesyRegistry(
  name: 'Trail design system',
  themes: [DesyTheme(id: 'light', name: 'Light', wrap: _wrapLightTheme)],
  components: [trailingIconComponent, activityComponent],
);

// The widgets available to an instance-swap knob are normal registry entries.
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

final activityComponent = PlainConfigurationComponent<ActivityConfiguration>(
  id: 'trail.activity-card',
  name: 'Activity card',
  path: '/content/cards',
  description: 'Summarises a tracked activity.',
  source: 'lib/components/activity_card.dart',
  // There is one builder for every instance and every knob combination.
  build: (context, configuration, widgets) => ActivityCard(
    title: configuration.title,
    subtitle: configuration.subtitle,
    enabled: configuration.enabled,
    trailing: widgets.build(context, configuration.trailing),
  ),
  instances: const [
    PlainConfigurationInstance(
      id: 'runs',
      name: 'Running',
      configuration: ActivityConfiguration(
        title: 'Activity',
        subtitle: 'Track your runs',
        trailing: DesyInstanceId('trail.icon.plus'),
      ),
    ),
    PlainConfigurationInstance(
      id: 'disabled',
      name: 'Disabled',
      configuration: ActivityConfiguration(
        enabled: false,
        trailing: DesyInstanceId('trail.icon.check'),
      ),
    ),
  ],
);

final class ActivityConfiguration {
  const ActivityConfiguration({
    this.title = 'Activity',
    this.subtitle = 'Track your activity',
    this.enabled = true,
    this.trailing = const DesyInstanceId('trail.icon.plus'),
  });

  final String title;
  final String subtitle;
  final bool enabled;
  final DesyInstanceId trailing;
}

// A consumer can fetch the composed real-widget instance from the registry.
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

  DesyRegistryComponent? componentFor(DesyInstanceId registeredId) {
    for (final component in components) {
      if (component.instanceIds.any(
        (instanceId) => '${component.id}.$instanceId' == registeredId.value,
      )) {
        return component;
      }
    }
    return null;
  }
}

/// Resolves nested registered widgets without applying the theme twice.
/// The same graph can be validated eagerly at registry startup.
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

final class PlainConfigurationInstance<C> {
  const PlainConfigurationInstance({
    required this.id,
    required this.name,
    required this.configuration,
  });

  final String id;
  final String name;
  final C configuration;
}

final class PlainConfigurationComponent<C> implements DesyRegistryComponent {
  PlainConfigurationComponent({
    required this.id,
    required this.name,
    required this.path,
    required this.build,
    required List<PlainConfigurationInstance<C>> instances,
    this.description,
    this.source,
  }) : instances = List.unmodifiable(instances);

  @override
  final String id;
  @override
  final String name;
  @override
  final String path;
  final String? description;
  final String? source;
  final Widget Function(BuildContext, C, DesyWidgetResolver) build;
  final List<PlainConfigurationInstance<C>> instances;

  @override
  List<String> get instanceIds =>
      List.unmodifiable(instances.map((instance) => instance.id));

  @override
  Widget buildInstance(
    BuildContext context,
    String instanceId,
    DesyWidgetResolver widgets,
  ) {
    final configuration = instances
        .singleWhere((instance) => instance.id == instanceId)
        .configuration;
    return build(context, configuration, widgets);
  }
}

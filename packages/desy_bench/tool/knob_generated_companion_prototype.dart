import 'package:flutter/material.dart';

import 'knob_prototype_widgets.dart';

// THROWAWAY PROTOTYPE 3: GENERATED TYPED CONFIGURATION COMPANION

// ==========================================================================
// POTENTIAL CONSUMER CODE — the user writes everything above the divider.
// ==========================================================================

final registry = DesyRegistry(
  name: 'Trail design system',
  themes: [DesyTheme(id: 'light', name: 'Light', wrap: _wrapLightTheme)],
  components: [trailingIconComponent, activityComponent],
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

@desyKnobs
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

  @desyWidgetInstance
  final DesyInstanceId trailing;
}

final activityComponent = ConfigurationComponent<ActivityConfiguration>(
  id: 'trail.activity-card',
  name: 'Activity card',
  path: '/content/cards',
  description: 'Summarises a tracked activity.',
  source: 'lib/components/activity_card.dart',
  schema: ActivityConfigurationDesy.schema,
  build: (context, configuration, widgets) => ActivityCard(
    title: configuration.title,
    subtitle: configuration.subtitle,
    enabled: configuration.enabled,
    trailing: widgets.build(context, configuration.trailing),
  ),
  instances: [
    ConfigurationInstance(
      id: 'runs',
      name: 'Running',
      values: [
        ActivityConfigurationDesy.title('Activity'),
        ActivityConfigurationDesy.subtitle('Track your runs'),
        ActivityConfigurationDesy.trailing('trail.icon.plus'),
      ],
    ),
    ConfigurationInstance(
      id: 'disabled',
      name: 'Disabled',
      values: [
        ActivityConfigurationDesy.enabled(false),
        ActivityConfigurationDesy.trailing('trail.icon.check'),
      ],
    ),
  ],
);

Widget buildRunningActivity(BuildContext context) =>
    registry.widget(context, const DesyInstanceId('trail.activity-card.runs'));

Widget _wrapLightTheme(BuildContext context, Widget child) => Theme(
  data: ThemeData.light(),
  child: Directionality(textDirection: TextDirection.ltr, child: child),
);

// _______________________________________________
// GENERATED + DESY CODE — a package user would not write below this divider.

const desyKnobs = DesyKnobsAnnotation();
const desyWidgetInstance = DesyWidgetInstanceAnnotation();

final class DesyKnobsAnnotation {
  const DesyKnobsAnnotation();
}

final class DesyWidgetInstanceAnnotation {
  const DesyWidgetInstanceAnnotation();
}

final class DesyInstanceId {
  const DesyInstanceId(this.value);
  final String value;
}

/// Representative build_runner output. It preserves every field's exact type.
abstract final class ActivityConfigurationDesy {
  static final title = ConfigurationField<ActivityConfiguration, String>(
    id: 'title',
    name: 'Title',
    write: (configuration, value) => ActivityConfiguration(
      title: value,
      subtitle: configuration.subtitle,
      enabled: configuration.enabled,
      trailing: configuration.trailing,
    ),
  );
  static final subtitle = ConfigurationField<ActivityConfiguration, String>(
    id: 'subtitle',
    name: 'Subtitle',
    write: (configuration, value) => ActivityConfiguration(
      title: configuration.title,
      subtitle: value,
      enabled: configuration.enabled,
      trailing: configuration.trailing,
    ),
  );
  static final enabled = ConfigurationField<ActivityConfiguration, bool>(
    id: 'enabled',
    name: 'Enabled',
    write: (configuration, value) => ActivityConfiguration(
      title: configuration.title,
      subtitle: configuration.subtitle,
      enabled: value,
      trailing: configuration.trailing,
    ),
  );
  static final trailing = WidgetInstanceField<ActivityConfiguration>(
    id: 'trailing',
    name: 'Trailing',
    write: (configuration, value) => ActivityConfiguration(
      title: configuration.title,
      subtitle: configuration.subtitle,
      enabled: configuration.enabled,
      trailing: value,
    ),
  );
  static final schema = ConfigurationSchema<ActivityConfiguration>(
    defaults: const ActivityConfiguration(),
    fields: [title, subtitle, enabled, trailing],
  );
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

abstract interface class ConfigurationFieldBase<C> {
  String get id;
  String get name;
}

abstract base class ConfigurationValueField<C, T extends Object>
    implements ConfigurationFieldBase<C> {
  const ConfigurationValueField({
    required this.id,
    required this.name,
    required C Function(C configuration, T value) write,
  }) : _write = write;
  @override
  final String id;
  @override
  final String name;
  final C Function(C configuration, T value) _write;
  C apply(C configuration, T value) => _write(configuration, value);
}

final class ConfigurationField<C, T extends Object>
    extends ConfigurationValueField<C, T> {
  const ConfigurationField({
    required super.id,
    required super.name,
    required super.write,
  });
  ConfigurationSetting<C, T> call(T value) => ConfigurationSetting(this, value);
}

final class WidgetInstanceField<C>
    extends ConfigurationValueField<C, DesyInstanceId> {
  const WidgetInstanceField({
    required super.id,
    required super.name,
    required super.write,
  });

  ConfigurationSetting<C, DesyInstanceId> call(String registeredInstanceId) =>
      ConfigurationSetting(this, DesyInstanceId(registeredInstanceId));
}

abstract interface class ConfigurationSettingBase<C> {
  C apply(C configuration);
}

final class ConfigurationSetting<C, T extends Object>
    implements ConfigurationSettingBase<C> {
  const ConfigurationSetting(this.field, this.value);
  final ConfigurationValueField<C, T> field;
  final T value;
  @override
  C apply(C configuration) => field.apply(configuration, value);
}

final class ConfigurationSchema<C> {
  ConfigurationSchema({
    required this.defaults,
    required List<ConfigurationFieldBase<C>> fields,
  }) : fields = List.unmodifiable(fields);
  final C defaults;
  final List<ConfigurationFieldBase<C>> fields;
}

final class ConfigurationInstance<C> {
  ConfigurationInstance({
    required this.id,
    required this.name,
    Iterable<ConfigurationSettingBase<C>> values = const [],
  }) : values = List.unmodifiable(values);
  final String id;
  final String name;
  final List<ConfigurationSettingBase<C>> values;
}

final class ConfigurationComponent<C> implements DesyRegistryComponent {
  ConfigurationComponent({
    required this.id,
    required this.name,
    required this.path,
    required this.schema,
    required List<ConfigurationInstance<C>> instances,
    required Widget Function(BuildContext, C, DesyWidgetResolver) build,
    this.description,
    this.source,
  }) : instances = List.unmodifiable(instances),
       _build = build;
  @override
  final String id;
  @override
  final String name;
  @override
  final String path;
  final String? description;
  final String? source;
  final ConfigurationSchema<C> schema;
  final List<ConfigurationInstance<C>> instances;
  final Widget Function(BuildContext, C, DesyWidgetResolver) _build;

  @override
  List<String> get instanceIds =>
      List.unmodifiable(instances.map((instance) => instance.id));

  C configurationFor(String id) {
    final instance = instances.singleWhere((candidate) => candidate.id == id);
    return instance.values.fold(
      schema.defaults,
      (configuration, setting) => setting.apply(configuration),
    );
  }

  @override
  Widget buildInstance(
    BuildContext context,
    String instanceId,
    DesyWidgetResolver widgets,
  ) => _build(context, configurationFor(instanceId), widgets);
}

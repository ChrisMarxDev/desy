import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:desy_bench/desy_bench.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// A real GenUI catalog and its serializable backend contract, both compiled
/// from one consumer-owned [DesyRegistry].
final class DesyGenUiCatalog {
  DesyGenUiCatalog._({
    required this.registry,
    required this.catalog,
    required this.backendArtifact,
    required this.digest,
  });

  /// Compiles the opt-in components in [registry] into GenUI catalog items.
  factory DesyGenUiCatalog.compile(DesyRegistry registry) {
    final config = registry.catalogConfig;
    if (config == null) {
      throw StateError(
        'Add DesyCatalogConfig to the registry before compiling GenUI.',
      );
    }
    final structuralIssues = registry
        .validate()
        .where(
          (issue) => issue.severity == DesyRegistryValidationSeverity.error,
        )
        .toList(growable: false);
    if (structuralIssues.isNotEmpty) {
      throw StateError(
        'Cannot compile an invalid Desy registry: '
        '${structuralIssues.map((issue) => issue.message).join(' ')}',
      );
    }
    if (registry.catalogComponents.isEmpty) {
      throw StateError(
        'A GenUI catalog needs at least one included component.',
      );
    }

    final compiler = _Compiler(registry);
    final prompts = compiler.systemPromptFragments;
    final items = [
      for (final component in registry.catalogComponents)
        compiler.catalogItem(component),
    ];
    final catalogId = '${config.id}@${config.version}';
    final catalog = Catalog(
      items,
      catalogId: catalogId,
      systemPromptFragments: prompts,
    );
    final artifact = <String, Object?>{
      'schemaVersion': 'desy-genui-catalog/0.1',
      'protocol': {'name': 'A2UI', 'version': 'v0.9'},
      'catalog': {
        'id': config.id,
        'version': config.version,
        'catalogId': catalogId,
        'description': ?config.description,
      },
      'capabilities': catalog.toCapabilitiesJson(),
      'fullSchema': catalog.fullSchema.value,
      'systemPromptFragments': prompts,
      'examples': {
        for (final component in registry.catalogComponents)
          component.id: compiler.examplesFor(component),
      },
      'desy': DesyCatalogueExport(registry).toJson(),
    };
    final encoded = jsonEncode(artifact);
    return DesyGenUiCatalog._(
      registry: registry,
      catalog: catalog,
      backendArtifact: _freezeJsonMap(artifact),
      digest: sha256.convert(utf8.encode(encoded)).toString(),
    );
  }

  /// The only source registry used for compilation and runtime widget builds.
  final DesyRegistry registry;

  /// The executable Flutter GenUI catalog.
  final Catalog catalog;

  /// JSON-safe schema, prompt, example, and capability data for an agent host.
  final Map<String, Object?> backendArtifact;

  /// Deterministic SHA-256 of the compact JSON [backendArtifact].
  final String digest;

  /// Encodes [backendArtifact] for storage or transport to an agent backend.
  String toJson({bool pretty = false}) =>
      (pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder())
          .convert(backendArtifact);
}

final class _Compiler {
  _Compiler(this.registry);

  final DesyRegistry registry;

  Set<String> get _catalogComponentIds => {
    for (final component in registry.catalogComponents) component.id,
  };

  List<String> get systemPromptFragments {
    final result = <String>[
      ?registry.catalogConfig?.description,
      'Use only components declared by catalog ${registry.catalogConfig!.id}. '
          'Component IDs are surface-local. Child slots refer to those IDs.',
    ];
    for (final component in registry.catalogComponents) {
      final description = _descriptionFor(component);
      if (description != null) result.add('${component.id}: $description');
    }
    return List.unmodifiable(result);
  }

  CatalogItem catalogItem(DesyRegistryComponent component) {
    final examples = examplesFor(component);
    return CatalogItem(
      name: component.id,
      dataSchema: S.object(
        title: component.name,
        description: _descriptionFor(component),
        properties: {
          for (final knob in component.knobDefinitions)
            knob.id: _schemaFor(knob),
        },
        additionalProperties: false,
      ),
      exampleData: [for (final example in examples) () => jsonEncode(example)],
      widgetBuilder: (itemContext) => _build(component, itemContext),
    );
  }

  Widget _build(
    DesyRegistryComponent component,
    CatalogItemContext itemContext,
  ) {
    final rawData = itemContext.data;
    if (rawData is! Map) {
      throw ArgumentError.value(rawData, 'data', 'Expected component data.');
    }
    final data = <String, Object>{};
    for (final knob in component.knobDefinitions) {
      final value = rawData[knob.id];
      if (value == null) continue;
      data[knob.id] = switch (knob.kind) {
        DesyKnobKind.widgetInstance => _surfaceId(knob, value, itemContext),
        DesyKnobKind.widgetInstances => _surfaceIds(knob, value, itemContext),
        DesyKnobKind.event => DesyEventBinding(value),
        _ => value as Object,
      };
    }

    final resolver = DesyWidgetResolver.withSurfaceChildren(
      registry,
      buildSurfaceChild: (_, id) => itemContext.buildChild(id),
    );
    return component.buildWithValues(
      itemContext.buildContext,
      data,
      widgets: resolver,
      events: _GenUiEventHost(itemContext),
    );
  }

  DesyInstanceId _surfaceId(
    KnobDefinition<Object> knob,
    Object value,
    CatalogItemContext context,
  ) {
    if (value is! String) {
      throw ArgumentError.value(value, knob.id, 'Expected a component ID.');
    }
    _validateChildType(knob, value, context);
    return DesyInstanceId.surface(value);
  }

  DesyInstanceIds _surfaceIds(
    KnobDefinition<Object> knob,
    Object value,
    CatalogItemContext context,
  ) {
    if (value is! List || value.any((element) => element is! String)) {
      throw ArgumentError.value(
        value,
        knob.id,
        'Expected a list of component IDs.',
      );
    }
    final ids = value.cast<String>();
    for (final id in ids) {
      _validateChildType(knob, id, context);
    }
    return DesyInstanceIds(ids.map(DesyInstanceId.surface));
  }

  void _validateChildType(
    KnobDefinition<Object> knob,
    String id,
    CatalogItemContext context,
  ) {
    final child = context.getComponent(id);
    if (child == null) {
      throw ArgumentError.value(id, knob.id, 'Unknown surface component ID.');
    }
    if (knob.options.isEmpty) return;
    final allowedTypes = <String>{
      for (final option in knob.options)
        if (registry.resolveComponentInstance(option) case final instance?)
          if (_catalogComponentIds.contains(instance.component.id))
            instance.component.id,
    };
    if (!allowedTypes.contains(child.type)) {
      throw ArgumentError.value(
        id,
        knob.id,
        'Child must use one of: ${allowedTypes.join(', ')}.',
      );
    }
  }

  Schema _schemaFor(KnobDefinition<Object> knob) {
    final description = knob.description ?? knob.name;
    final Schema schema = switch (knob.kind) {
      DesyKnobKind.string => S.string(description: description),
      DesyKnobKind.number => S.number(
        description: _numberDescription(knob, description),
        minimum: knob.minimum,
        maximum: knob.maximum,
        multipleOf: knob.step,
      ),
      DesyKnobKind.boolean => S.boolean(description: description),
      DesyKnobKind.color => S.integer(
        description: '$description Encoded as a Flutter ARGB integer.',
        minimum: 0,
        maximum: 0xffffffff,
      ),
      DesyKnobKind.widgetInstance => A2uiSchemas.componentReference(
        description: _slotDescription(knob, description),
      ),
      DesyKnobKind.widgetInstances => S.list(
        description: _slotDescription(knob, description),
        items: A2uiSchemas.componentReference(),
      ),
      DesyKnobKind.event => A2uiSchemas.action(description: description),
    };
    if (knob.kind == DesyKnobKind.event) return schema;
    return Schema.fromMap({
      ...schema.value,
      'default': _jsonValue(knob.initial),
    });
  }

  String _numberDescription(KnobDefinition<Object> knob, String description) =>
      knob.unit == null ? description : '$description Unit: ${knob.unit}.';

  String _slotDescription(KnobDefinition<Object> knob, String description) {
    if (knob.options.isEmpty) return description;
    final allowed = <String>{
      for (final option in knob.options)
        if (registry.resolveComponentInstance(option) case final instance?)
          if (_catalogComponentIds.contains(instance.component.id))
            instance.component.id,
    };
    return '$description Allowed component types: ${allowed.join(', ')}.';
  }

  String? _descriptionFor(DesyRegistryComponent component) =>
      component.catalogConfig?.description ?? component.description;

  List<List<Map<String, Object?>>> examplesFor(
    DesyRegistryComponent component,
  ) {
    final instanceIds = component.instanceIds;
    if (instanceIds.isEmpty) {
      return [
        [
          {'id': 'root', 'component': component.id},
        ],
      ];
    }
    final usable = component is DesyStaticComponent
        ? instanceIds.take(1)
        : instanceIds;
    return [
      for (final instanceId in usable)
        _materializeExample(component, instanceId),
    ];
  }

  List<Map<String, Object?>> _materializeExample(
    DesyRegistryComponent root,
    String instanceId,
  ) {
    final components = <Map<String, Object?>>[];
    _materialize(
      root,
      instanceId,
      surfaceId: 'root',
      ancestors: const {},
      output: components,
    );
    return components;
  }

  void _materialize(
    DesyRegistryComponent component,
    String instanceId, {
    required String surfaceId,
    required Set<String> ancestors,
    required List<Map<String, Object?>> output,
  }) {
    final registryId = '${component.id}.$instanceId';
    if (ancestors.contains(registryId)) return;
    final values = component.valuesFor(instanceId);
    final definition = <String, Object?>{
      'id': surfaceId,
      'component': component.id,
    };
    final descendants = <void Function()>[];
    for (final knob in component.knobDefinitions) {
      final value = values[knob.id] ?? knob.initial;
      switch (knob.kind) {
        case DesyKnobKind.widgetInstance:
          final id = value is DesyInstanceId ? value.value : value as String;
          final child = registry.resolveComponentInstance(id);
          if (child == null ||
              !_catalogComponentIds.contains(child.component.id)) {
            continue;
          }
          final childId = '${surfaceId}_${knob.id}';
          definition[knob.id] = childId;
          descendants.add(
            () => _materialize(
              child.component,
              child.instanceId,
              surfaceId: childId,
              ancestors: {...ancestors, registryId},
              output: output,
            ),
          );
        case DesyKnobKind.widgetInstances:
          final ids = value is DesyInstanceIds
              ? value.values.map((id) => id.value).toList()
              : (value as List).cast<String>();
          final childIds = <String>[];
          for (var index = 0; index < ids.length; index++) {
            final child = registry.resolveComponentInstance(ids[index]);
            if (child == null ||
                !_catalogComponentIds.contains(child.component.id)) {
              continue;
            }
            final childId = '${surfaceId}_${knob.id}_$index';
            childIds.add(childId);
            descendants.add(
              () => _materialize(
                child.component,
                child.instanceId,
                surfaceId: childId,
                ancestors: {...ancestors, registryId},
                output: output,
              ),
            );
          }
          definition[knob.id] = childIds;
        case DesyKnobKind.event:
          break;
        case DesyKnobKind.color:
          definition[knob.id] = _jsonValue(value);
        case DesyKnobKind.string:
        case DesyKnobKind.number:
        case DesyKnobKind.boolean:
          definition[knob.id] = value;
      }
    }
    output.add(definition);
    for (final addDescendant in descendants) {
      addDescendant();
    }
  }
}

final class _GenUiEventHost implements DesyEventHost {
  const _GenUiEventHost(this.context);

  final CatalogItemContext context;

  @override
  void emit(DesyEventInvocation invocation) {
    unawaited(_emit(invocation));
  }

  Future<void> _emit(DesyEventInvocation invocation) async {
    try {
      final action = invocation.action;
      if (action is! Map) return;
      final event = action['event'];
      if (event is Map) {
        final name = event['name'];
        if (name is! String) return;
        final rawContext = event['context'];
        final resolved = await resolveContext(
          context.dataContext,
          rawContext is Map ? Map<String, Object?>.from(rawContext) : null,
        );
        context.dispatchEvent(
          UserActionEvent(
            name: name,
            sourceComponentId: context.id,
            context: {...resolved, ...invocation.payload},
          ),
        );
        return;
      }
      final functionCall = action['functionCall'];
      if (functionCall is Map) {
        await context.dataContext
            .resolve(Map<String, Object?>.from(functionCall))
            .drain<void>();
      }
    } catch (error, stack) {
      context.reportError(error, stack);
    }
  }
}

Object? _jsonValue(Object value) => switch (value) {
  Color() => value.toARGB32(),
  DesyInstanceId(:final value) => value,
  DesyInstanceIds(:final values) => [for (final id in values) id.value],
  DesyEventBinding(:final action) => action,
  _ => value,
};

Map<String, Object?> _freezeJsonMap(Map<String, Object?> value) =>
    Map.unmodifiable(jsonDecode(jsonEncode(value)) as Map<String, Object?>);

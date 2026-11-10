import 'dart:async';
import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:crypto/crypto.dart';
import 'package:desy_core/desy_core.dart';
import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart'
    hide ValidationResult;

/// A real A2UI catalog and its serializable backend contract, both compiled
/// from one consumer-owned [DesyRegistry].
final class DesyGenUiCatalog {
  DesyGenUiCatalog._({
    required this.registry,
    required this.catalog,
    required this.backendArtifact,
    required this.digest,
  });

  /// Compiles every registered component in [registry] into A2UI catalog
  /// components.
  factory DesyGenUiCatalog.compile(DesyRegistry registry) {
    final identity = registry.identity;
    if (identity == null) {
      throw StateError(
        'Add DesyRegistryIdentity to the registry before compiling GenUI.',
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
    if (registry.allComponents.isEmpty) {
      throw StateError(
        'A GenUI catalog needs at least one registered component.',
      );
    }

    final compiler = _Compiler(registry);
    final prompts = compiler.systemPromptFragments;
    final components = [
      for (final component in registry.allComponents)
        compiler.component(component),
    ];
    final catalogId = '${identity.id}@${identity.version}';
    final catalog = CatalogImplementation(
      id: catalogId,
      components: components,
      instructions: prompts.join('\n'),
    );
    final artifact = <String, Object?>{
      'schemaVersion': 'desy-genui-catalog/0.1',
      'protocol': {'name': 'A2UI', 'version': 'v0.9'},
      'catalog': {
        'id': identity.id,
        'version': identity.version,
        'catalogId': catalogId,
      },
      'capabilities': catalog.toV09InlineCatalog(),
      'fullSchema': catalog.toJson(),
      'systemPromptFragments': prompts,
      'examples': {
        for (final component in registry.allComponents)
          component.id: compiler.examplesFor(component),
      },
      'desy': DesyRegistrySnapshot(registry).toJson(),
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

  /// The executable Flutter A2UI catalog.
  final CatalogImplementation catalog;

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

  Set<String> get _componentIds => {
    for (final component in registry.allComponents) component.id,
  };

  List<String> get systemPromptFragments {
    final result = <String>[
      'Use only components declared by registry ${registry.identity!.id}. '
          'Component IDs are surface-local. Child slots refer to those IDs.',
    ];
    for (final component in registry.allComponents) {
      final description = _descriptionFor(component);
      if (description != null) result.add('${component.id}: $description');
    }
    return List.unmodifiable(result);
  }

  ComponentImplementation component(DesyRegistryComponent component) {
    return ComponentImplementation(
      name: component.id,
      schema: S.object(
        title: component.name,
        description: _descriptionFor(component),
        properties: {
          for (final knob in component.knobDefinitions)
            knob.id: _schemaFor(knob),
        },
        additionalProperties: false,
      ),
      builder: (context, node, props, buildChild) =>
          _build(component, context, node, props, buildChild),
    );
  }

  // The builder receives each knob already resolved: a2ui_flutter binds the
  // `{"path": ...}` and `{"call": ...}` values the schemas allow, and reruns
  // the builder when one of them changes. A binding without data yet resolves
  // to null, so the knob keeps its declared default until the data arrives.
  Widget _build(
    DesyRegistryComponent component,
    BuildContext context,
    ComponentNode<ComponentImplementation> node,
    ComponentProps props,
    ChildWidgetBuilder buildChild,
  ) {
    final componentContext = node.context!;
    final children = <String, ComponentNode<ComponentImplementation>>{};
    final data = <String, Object>{};
    for (final knob in component.knobDefinitions) {
      // An event knob keeps the raw action rather than its resolved closure,
      // so the event host can merge the consumer's payload into the context.
      final value = knob.kind == DesyKnobKind.event
          ? componentContext.componentModel.properties[knob.id]
          : props.value(knob.id);
      if (value == null) continue;
      data[knob.id] = switch (knob.kind) {
        DesyKnobKind.widgetInstance => _surfaceId(knob, value, children),
        DesyKnobKind.widgetInstances => _surfaceIds(knob, value, children),
        DesyKnobKind.event => DesyEventBinding(value),
        DesyKnobKind.dateTime => _dateTime(knob, value),
        DesyKnobKind.stringList => _stringList(knob, value),
        DesyKnobKind.numberList => _numberList(knob, value),
        DesyKnobKind.jsonValue => _jsonKnobValue(knob, value),
        _ => value,
      };
    }

    final resolver = DesyWidgetResolver.withSurfaceChildren(
      registry,
      buildSurfaceChild: (_, id) => buildChild(children[id]!),
    );
    return component.buildWithValues(
      context,
      data,
      widgets: resolver,
      events: _GenUiEventHost(componentContext),
    );
  }

  DateTime _dateTime(KnobDefinition<Object> knob, Object value) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw ArgumentError.value(value, knob.id, 'Expected an ISO-8601 string.');
  }

  List<String> _stringList(KnobDefinition<Object> knob, Object value) {
    if (value is List && value.every((item) => item is String)) {
      return List<String>.unmodifiable(value.cast<String>());
    }
    throw ArgumentError.value(value, knob.id, 'Expected a list of strings.');
  }

  List<double> _numberList(KnobDefinition<Object> knob, Object value) {
    if (value is List && value.every((item) => item is num)) {
      final result = value.cast<num>().map((item) => item.toDouble()).toList();
      if (result.every(
        (item) =>
            item.isFinite &&
            (knob.minimum == null || item >= knob.minimum!) &&
            (knob.maximum == null || item <= knob.maximum!),
      )) {
        return List<double>.unmodifiable(result);
      }
    }
    throw ArgumentError.value(
      value,
      knob.id,
      'Expected a valid list of numbers.',
    );
  }

  Object _jsonKnobValue(KnobDefinition<Object> knob, Object value) {
    try {
      final decoded = jsonDecode(jsonEncode(value));
      if (decoded == null) {
        throw const FormatException('JSON root must not be null.');
      }
      return _freezeJsonNode(decoded)!;
    } on Object catch (_) {
      throw ArgumentError.value(value, knob.id, 'Expected a JSON value.');
    }
  }

  // a2ui_flutter resolves child references to nodes. [children] collects
  // them by component ID for the resolver's surface child builder.
  DesyInstanceId _surfaceId(
    KnobDefinition<Object> knob,
    Object value,
    Map<String, ComponentNode<ComponentImplementation>> children,
  ) {
    if (value is! ComponentNode<ComponentImplementation>) {
      throw ArgumentError.value(value, knob.id, 'Expected a component ID.');
    }
    _validateChildType(knob, value);
    children[value.componentId] = value;
    return DesyInstanceId.surface(value.componentId);
  }

  DesyInstanceIds _surfaceIds(
    KnobDefinition<Object> knob,
    Object value,
    Map<String, ComponentNode<ComponentImplementation>> children,
  ) {
    if (value is! List ||
        value.any(
          (element) => element is! ComponentNode<ComponentImplementation>,
        )) {
      throw ArgumentError.value(
        value,
        knob.id,
        'Expected a list of component IDs.',
      );
    }
    final nodes = value.cast<ComponentNode<ComponentImplementation>>();
    for (final node in nodes) {
      _validateChildType(knob, node);
      children[node.componentId] = node;
    }
    return DesyInstanceIds(
      nodes.map((node) => DesyInstanceId.surface(node.componentId)),
    );
  }

  void _validateChildType(
    KnobDefinition<Object> knob,
    ComponentNode<ComponentImplementation> child,
  ) {
    if (child.state == NodeState.pending) {
      throw ArgumentError.value(
        child.componentId,
        knob.id,
        'Unknown surface component ID.',
      );
    }
    if (knob.options.isEmpty) return;
    final allowedTypes = <String>{
      for (final option in knob.options)
        if (registry.resolveComponentInstance(option) case final instance?)
          if (_componentIds.contains(instance.component.id))
            instance.component.id,
    };
    if (!allowedTypes.contains(child.type)) {
      throw ArgumentError.value(
        child.componentId,
        knob.id,
        'Child must use one of: ${allowedTypes.join(', ')}.',
      );
    }
  }

  Schema _schemaFor(KnobDefinition<Object> knob) {
    final description = knob.description ?? knob.name;
    final Schema schema = switch (knob.kind) {
      DesyKnobKind.string => _valueOrBinding(S.string(), description),
      DesyKnobKind.choice => _valueOrBinding(
        Schema.fromMap({'type': 'string', 'enum': knob.options}),
        description,
      ),
      DesyKnobKind.number => _valueOrBinding(
        S.number(
          minimum: knob.minimum,
          maximum: knob.maximum,
          multipleOf: knob.step,
        ),
        _numberDescription(knob, description),
      ),
      DesyKnobKind.boolean => _valueOrBinding(S.boolean(), description),
      DesyKnobKind.dateTime => _valueOrBinding(
        S.string(),
        '$description Encoded as an ISO-8601 date-time string.',
      ),
      DesyKnobKind.color => _valueOrBinding(
        S.integer(minimum: 0, maximum: 0xffffffff),
        '$description Encoded as a Flutter ARGB integer.',
      ),
      DesyKnobKind.stringList => _valueOrBinding(
        S.list(items: S.string()),
        description,
      ),
      DesyKnobKind.numberList => _valueOrBinding(
        S.list(
          items: S.number(minimum: knob.minimum, maximum: knob.maximum),
        ),
        _numberDescription(knob, description),
      ),
      DesyKnobKind.jsonValue => _jsonValueOrBinding(description),
      DesyKnobKind.widgetInstance => _describe(
        CommonSchemas.componentId,
        _slotDescription(knob, description),
      ),
      DesyKnobKind.widgetInstances => S.list(
        description: _slotDescription(knob, description),
        items: CommonSchemas.componentId,
      ),
      DesyKnobKind.event => _describe(CommonSchemas.action, description),
    };
    if (knob.kind == DesyKnobKind.event) return schema;
    return Schema.fromMap({
      ...schema.value,
      'default': _jsonValue(knob.initial),
    });
  }

  String _numberDescription(KnobDefinition<Object> knob, String description) =>
      knob.unit == null ? description : '$description Unit: ${knob.unit}.';

  Schema _valueOrBinding(Schema literal, String description) => S.combined(
    oneOf: [literal, CommonSchemas.dataBinding, CommonSchemas.functionCall],
    description: description,
  );

  // Copies keep the `commonTypesRef` marker by which a2ui_core recognizes
  // child references and actions.
  Schema _describe(Schema common, String description) =>
      Schema.fromMap({...common.value, 'description': description});

  // `S.any()` also accepts the binding map, so this needs `anyOf` rather than
  // `oneOf`: a raw JSON object can validly have a `path` key, while a top-level
  // `{path: ...}` remains the explicit reactive binding form.
  Schema _jsonValueOrBinding(String description) => Schema.fromMap({
    'description': description,
    'anyOf': [
      S.any().value,
      CommonSchemas.dataBinding.value,
      CommonSchemas.functionCall.value,
    ],
  });

  String _slotDescription(KnobDefinition<Object> knob, String description) {
    if (knob.options.isEmpty) return description;
    final allowed = <String>{
      for (final option in knob.options)
        if (registry.resolveComponentInstance(option) case final instance?)
          if (_componentIds.contains(instance.component.id))
            instance.component.id,
    };
    return '$description Allowed component types: ${allowed.join(', ')}.';
  }

  String? _descriptionFor(DesyRegistryComponent component) =>
      component.description;

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
          if (child == null || !_componentIds.contains(child.component.id)) {
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
            if (child == null || !_componentIds.contains(child.component.id)) {
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
        // A2UI's catalog examples are flat component graphs, not a data-model
        // fixture format. Collection and JSON knobs therefore use their
        // declared defaults in examples; explicit A2UI updates may still
        // provide them and are validated by the widget builder.
        case DesyKnobKind.stringList:
        case DesyKnobKind.numberList:
        case DesyKnobKind.jsonValue:
          break;
        case DesyKnobKind.color:
          definition[knob.id] = _jsonValue(value);
        case DesyKnobKind.dateTime:
          definition[knob.id] = _jsonValue(value);
        case DesyKnobKind.string:
        case DesyKnobKind.choice:
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

  final ComponentContext context;

  @override
  void emit(DesyEventInvocation invocation) {
    unawaited(_emit(invocation));
  }

  Future<void> _emit(DesyEventInvocation invocation) async {
    try {
      final action = invocation.action;
      if (action is! Map) return;
      // A consumer emits from a user gesture, so functions that require user
      // activation may run.
      final dataContext = context.dataContext.withUserActivation();
      final event = action['event'];
      if (event is Map) {
        final resolved = await dataContext.resolveActionAsync({'event': event});
        final resolvedEvent = resolved?['event'];
        if (resolvedEvent is! Map) return;
        final resolvedContext = resolvedEvent['context'];
        await context.dispatchAction({
          'event': {
            'name': resolvedEvent['name'],
            'context': {
              if (resolvedContext is Map) ...resolvedContext,
              ...invocation.payload,
            },
          },
        });
        return;
      }
      final functionCall = action['functionCall'];
      if (functionCall is Map) {
        await dataContext.evaluateFunctionCall(
          Map<String, Object?>.from(functionCall),
        );
      }
    } catch (error) {
      await context.surface.dispatchError(
        A2uiRendererError(
          code: 'EXECUTION_ERROR',
          surfaceId: context.surface.id,
          message:
              "Event of component '${context.componentModel.id}' failed: "
              '$error',
        ),
      );
    }
  }
}

Object? _jsonValue(Object value) => switch (value) {
  DateTime() => value.toIso8601String(),
  Color() => value.toARGB32(),
  DesyInstanceId(:final value) => value,
  DesyInstanceIds(:final values) => [for (final id in values) id.value],
  DesyEventBinding(:final action) => action,
  _ => value,
};

Map<String, Object?> _freezeJsonMap(Map<String, Object?> value) =>
    Map.unmodifiable(jsonDecode(jsonEncode(value)) as Map<String, Object?>);

Object? _freezeJsonNode(Object? value) {
  return switch (value) {
    null || String() || num() || bool() => value,
    List() => List<Object?>.unmodifiable(value.map(_freezeJsonNode)),
    Map() => Map<String, Object?>.unmodifiable({
      for (final entry in value.entries)
        if (entry.key is String)
          entry.key as String: _freezeJsonNode(entry.value),
    }),
    _ => throw const FormatException('Expected JSON-compatible value.'),
  };
}

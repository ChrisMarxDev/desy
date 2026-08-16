import 'package:flutter/material.dart';

import '../registry.dart';

/// Experimental, JSON-ready description derived from a [DesyRegistry].
///
/// The export deliberately contains only registry-owned metadata and declared
/// capabilities. Widget builders and callbacks remain in consumer code and
/// are never serialized. The schema is a local-first starting point for GenUI
/// tooling, and may change before it is stabilised.
class DesyCatalogueExport {
  /// Creates a derived export for [registry].
  const DesyCatalogueExport(this.registry);

  /// The consumer registry that remains this export's only source of truth.
  final DesyRegistry registry;

  /// Whether this registry explicitly opts into catalogue derivation.
  bool get isEnabled => registry.catalogConfig != null;

  /// A JSON-serializable representation of the declared catalogue.
  Map<String, Object?> toJson() {
    final config = registry.catalogConfig;
    if (config == null) {
      throw StateError(
        'Add DesyCatalogConfig to the registry before exporting a catalogue.',
      );
    }
    return {
      'schemaVersion': '0.2-experimental',
      'catalog': {
        'id': config.id,
        'version': config.version,
        'description': ?config.description,
      },
      'system': {'name': registry.name},
      'themes': [
        for (final theme in registry.themes)
          {
            'id': theme.id,
            'name': theme.name,
            if (theme.description case String description)
              'description': description,
          },
      ],
      'primitives': {
        'tokens': [
          for (final token in registry.allTokens)
            _entry(
              id: token.id,
              name: token.name,
              value: token.value,
              description: token.description,
              extra: {'group': token.group},
            ),
        ],
        'colors': [
          for (final color in registry.allColors)
            _entry(
              id: color.id,
              name: color.name,
              value: color.displayValue,
              description: color.description,
            ),
        ],
        'typography': [
          for (final type in registry.allFonts)
            _entry(
              id: type.id,
              name: type.name,
              value: type.value,
              description: type.description,
              extra: {'sample': type.sample},
            ),
        ],
        'numbers': [
          for (final number in registry.allMeasurements)
            _entry(
              id: number.id,
              name: number.name,
              value: number.value,
              description: number.description,
              extra: {
                'unit': number.unit.label,
                'kind': number.kind.name,
                'axis': number.axis.name,
              },
            ),
        ],
        'motion': [
          for (final motion in registry.allMotion)
            _entry(
              id: motion.id,
              name: motion.name,
              value: motion.displayValue,
              description: motion.description,
              extra: {'intent': motion.intent},
            ),
        ],
        'effects': [
          for (final effect in registry.allEffects)
            _entry(
              id: effect.id,
              name: effect.name,
              value: effect.displayValue,
              description: effect.description,
              extra: {'group': effect.group},
            ),
        ],
        'custom': [
          for (final atom in registry.allCustomAtoms)
            _entry(
              id: atom.id,
              name: atom.name,
              value: atom.defaultInstanceId,
              description: atom.description,
              extra: {'instances': atom.instances.keys.toList(growable: false)},
            ),
        ],
        'icons': [
          for (final icon in registry.allIcons)
            _entry(
              id: icon.id,
              name: icon.name,
              value: icon.value,
              description: icon.description,
              extra: {
                'codePoint': icon.icon.codePoint,
                'fontFamily': icon.icon.fontFamily,
              },
            ),
        ],
        'assets': [
          for (final asset in registry.allAssets)
            _entry(
              id: asset.id,
              name: asset.name,
              value: asset.displayValue,
              description: asset.description,
              extra: {'group': asset.group, 'kind': asset.kind.name},
            ),
        ],
      },
      'components': [
        for (final component in registry.catalogComponents)
          _component(component),
      ],
    };
  }

  Map<String, Object?> _component(DesyRegistryComponent component) => {
    ..._entry(
      id: component.id,
      name: component.name,
      description:
          component.catalogConfig?.description ?? component.description,
      extra: {
        'category': component.category,
        'path': component.path,
        if (component.source case String source) 'source': source,
        if (component.accessibility case String accessibility)
          'accessibility': accessibility,
      },
    ),
    'knobs': [
      for (final definition in component.knobDefinitions) _knob(definition),
    ],
    'instances': [
      for (final instanceId in component.instanceIds)
        _entry(
          id: '${component.id}.$instanceId',
          name: component.instanceLabel(instanceId),
          extra: {
            'kind': 'example',
            'values': _instanceValues(component, instanceId),
          },
        ),
    ],
    if (component.contract case DesyComponentContract contract)
      'contract': {
        if (contract.guidance case String guidance) 'guidance': guidance,
        'properties': [
          for (final property in contract.properties)
            {
              'name': property.name,
              'type': property.type,
              'required': property.required,
              if (property.description case String description)
                'description': description,
            },
        ],
        'slots': [
          for (final slot in contract.slots)
            {
              'name': slot.name,
              'accepts': slot.accepts,
              'required': slot.required,
              if (slot.description case String description)
                'description': description,
            },
        ],
      },
  };

  Map<String, Object?> _knob(KnobDefinition<Object> knob) => {
    'id': knob.id,
    'name': knob.name,
    'description': ?knob.description,
    'kind': switch (knob.kind) {
      DesyKnobKind.boolean => 'boolean',
      DesyKnobKind.string => 'string',
      DesyKnobKind.number => 'number',
      DesyKnobKind.dateTime => 'date-time',
      DesyKnobKind.color => 'color',
      DesyKnobKind.widgetInstance => 'component-instance',
      DesyKnobKind.widgetInstances => 'component-instances',
      DesyKnobKind.event => 'event',
    },
    if (knob.kind != DesyKnobKind.event) 'initial': _knobValue(knob),
    if (knob.options.isNotEmpty) 'options': knob.options,
    'unit': ?knob.unit,
    'step': ?knob.step,
    'minimum': ?knob.minimum,
    'maximum': ?knob.maximum,
  };

  Object _knobValue(KnobDefinition<Object> knob) => switch (knob.initial) {
    DesyInstanceId(:final value) => value,
    DesyInstanceIds(:final values) => [for (final id in values) id.value],
    DateTime() => (knob.initial as DateTime).toIso8601String(),
    Color() => (knob.initial as Color).toARGB32(),
    _ => knob.initial,
  };

  Map<String, Object> _instanceValues(
    DesyRegistryComponent component,
    String instanceId,
  ) {
    final values = component.valuesFor(instanceId);
    return {
      for (final knob in component.knobDefinitions)
        knob.id: switch (knob.kind) {
          DesyKnobKind.dateTime =>
            (values[knob.id]! as DateTime).toIso8601String(),
          DesyKnobKind.color => (values[knob.id]! as Color).toARGB32(),
          _ => values[knob.id]!,
        },
    };
  }

  Map<String, Object?> _entry({
    required String id,
    required String name,
    Object? value,
    String? description,
    Map<String, Object?> extra = const {},
  }) => {
    'id': id,
    'name': name,
    if (value case final Object value) 'value': value,
    if (description case String description) 'description': description,
    ...extra,
  };
}

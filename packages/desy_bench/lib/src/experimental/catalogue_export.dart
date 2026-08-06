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

  /// A JSON-serializable representation of the declared catalogue.
  Map<String, Object?> toJson() => {
    'schemaVersion': '0.1-experimental',
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
            value: color.value,
            description: color.description,
          ),
      ],
      'typography': [
        for (final type in registry.allTypography)
          _entry(
            id: type.id,
            name: type.name,
            value: type.value,
            description: type.description,
            extra: {'sample': type.sample},
          ),
      ],
      'numbers': [
        for (final number in registry.allNumbers)
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
      'assets': [
        for (final asset in registry.allAssets)
          _entry(
            id: asset.id,
            name: asset.name,
            value: asset.value,
            description: asset.description,
            extra: {'group': asset.group},
          ),
      ],
    },
    'components': [
      for (final component in registry.allComponents) _component(component),
    ],
    'showcases': [
      for (final showcase in registry.allShowcases)
        _entry(
          id: showcase.id,
          name: showcase.name,
          description: showcase.description,
        ),
    ],
  };

  Map<String, Object?> _component(DesyComponent component) => {
    ..._entry(
      id: component.id,
      name: component.name,
      description: component.description,
      extra: {
        'category': component.category,
        if (component.source case String source) 'source': source,
        if (component.accessibility case String accessibility)
          'accessibility': accessibility,
      },
    ),
    'knobs': [for (final knob in component.knobs) _knob(knob)],
    'instances': [
      for (final instance in component.instances)
        _entry(
          id: instance.id,
          name: instance.name,
          description: instance.description,
          extra: {'kind': instance.isWidget ? 'widget' : 'preset'},
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

  Map<String, Object?> _knob(DesyKnob<Object> knob) => {
    'id': knob.id,
    'name': knob.name,
    'kind': switch (knob) {
      DesyBooleanKnob() => 'boolean',
      DesyStringKnob() => 'string',
      DesyComponentKnob() => 'component-instance',
      _ => 'unknown',
    },
  };

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

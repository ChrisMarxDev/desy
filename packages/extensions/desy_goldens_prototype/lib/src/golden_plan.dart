import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:desy_core/desy_core.dart';
import 'package:flutter/widgets.dart';

/// The registered form rendered by one automatically derived golden case.
enum DesyGoldenPrototypeVariantKind {
  /// The component's real default preview builder.
  defaultPreview,

  /// One real named instance declared by the component.
  instance,

  /// One real named scenario declared by the component.
  scenario,
}

/// One immutable render case derived directly from a [DesyRegistry].
final class DesyGoldenPrototypeCase {
  const DesyGoldenPrototypeCase._({
    required this.registry,
    required this.component,
    required this.theme,
    required this.variantKind,
    required this.variantId,
    required this.logicalSize,
    required this.frameId,
    this.scenario,
  });

  /// The source registry used to resolve nested component instances.
  final DesyRegistry registry;

  /// The real registered component rendered by this case.
  final DesyRegistryComponent component;

  /// The real registered theme applied by this case.
  final DesyTheme theme;

  /// Whether this case renders the default, a named instance, or a scenario.
  final DesyGoldenPrototypeVariantKind variantKind;

  /// Stable variant ID within [component].
  final String variantId;

  /// Logical Flutter viewport used before rasterization.
  final Size logicalSize;

  /// Stable frame identity used in filenames and receipts.
  final String frameId;

  /// Scenario declaration when [variantKind] is [DesyGoldenPrototypeVariantKind.scenario].
  final DesyComponentScenario? scenario;

  /// Stable case identity independent of declaration order and display names.
  String get id =>
      '${component.id}/$variantSegment/${theme.id}/'
      'frame.$frameId/environment.standard';

  /// Stable filesystem-safe PNG path relative to the prototype test file.
  String get goldenPath =>
      'goldens/${_segment(component.id)}/'
      '${_segment(variantSegment)}/${_segment(theme.id)}/'
      'frame-${_segment(frameId)}.png';

  /// Stable variant path segment used by case IDs and PNG paths.
  String get variantSegment => switch (variantKind) {
    DesyGoldenPrototypeVariantKind.defaultPreview => 'default',
    DesyGoldenPrototypeVariantKind.instance => 'instance.$variantId',
    DesyGoldenPrototypeVariantKind.scenario => 'scenario.$variantId',
  };

  /// Builds the real registry widget once Flutter supplies a build context.
  Widget build(BuildContext context) => switch (variantKind) {
    DesyGoldenPrototypeVariantKind.defaultPreview => component.preview(
      context,
      registry.widgetBuilder,
    ),
    DesyGoldenPrototypeVariantKind.instance => component.buildInstance(
      context,
      variantId,
      registry.widgetBuilder,
    ),
    DesyGoldenPrototypeVariantKind.scenario => scenario!.builder(context),
  };

  /// JSON-safe receipt data for this derived case.
  Map<String, Object?> toJson() => {
    'id': id,
    'componentId': component.id,
    'componentSource': component.source,
    'variantKind': variantKind.name,
    'variantId': variantId,
    'themeId': theme.id,
    'frameId': frameId,
    'logicalSize': {'width': logicalSize.width, 'height': logicalSize.height},
    'devicePixelRatio': 1,
    'goldenPath': goldenPath,
  };
}

/// Canonical automatic capture plan for a complete Desy component registry.
final class DesyGoldenPrototypePlan {
  DesyGoldenPrototypePlan._({
    required this.registry,
    required List<DesyGoldenPrototypeCase> cases,
    required this.digest,
  }) : cases = List.unmodifiable(cases);

  /// Derives every component default, instance, scenario, and theme.
  factory DesyGoldenPrototypePlan.fromRegistry(DesyRegistry registry) {
    final errors = registry
        .validate()
        .where(
          (issue) => issue.severity == DesyRegistryValidationSeverity.error,
        )
        .toList(growable: false);
    if (errors.isNotEmpty) {
      throw StateError(
        'Cannot derive dogfood goldens from an invalid registry: '
        '${errors.map((issue) => issue.message).join(' ')}',
      );
    }

    final components = [...registry.allComponents]
      ..sort((left, right) => left.id.compareTo(right.id));
    final themes = [...registry.themes]
      ..sort((left, right) => left.id.compareTo(right.id));
    final cases = <DesyGoldenPrototypeCase>[];

    for (final component in components) {
      final size = component.defaultSize ?? const Size(800, 720);
      final frameId = component.defaultSize == null ? 'canonical' : 'declared';
      final instanceIds = [...component.instanceIds]..sort();
      final scenarios = [...component.scenarios]
        ..sort((left, right) => left.id.compareTo(right.id));

      for (final theme in themes) {
        cases.add(
          DesyGoldenPrototypeCase._(
            registry: registry,
            component: component,
            theme: theme,
            variantKind: DesyGoldenPrototypeVariantKind.defaultPreview,
            variantId: 'default',
            logicalSize: size,
            frameId: frameId,
          ),
        );
        for (final instanceId in instanceIds) {
          cases.add(
            DesyGoldenPrototypeCase._(
              registry: registry,
              component: component,
              theme: theme,
              variantKind: DesyGoldenPrototypeVariantKind.instance,
              variantId: instanceId,
              logicalSize: size,
              frameId: frameId,
            ),
          );
        }
        for (final scenario in scenarios) {
          cases.add(
            DesyGoldenPrototypeCase._(
              registry: registry,
              component: component,
              theme: theme,
              variantKind: DesyGoldenPrototypeVariantKind.scenario,
              variantId: scenario.id,
              logicalSize: size,
              frameId: frameId,
              scenario: scenario,
            ),
          );
        }
      }
    }

    cases.sort((left, right) => left.id.compareTo(right.id));
    final seen = <String>{};
    for (final goldenCase in cases) {
      if (!seen.add(goldenCase.id)) {
        throw StateError('Duplicate derived golden case: ${goldenCase.id}');
      }
    }

    final canonical = _canonicalJson(registry, cases);
    return DesyGoldenPrototypePlan._(
      registry: registry,
      cases: cases,
      digest: sha256.convert(utf8.encode(canonical)).toString(),
    );
  }

  /// Registry that remains the only component and theme inventory.
  final DesyRegistry registry;

  /// Canonically ordered cases derived from [registry].
  final List<DesyGoldenPrototypeCase> cases;

  /// SHA-256 of the canonical registry-derived case manifest.
  final String digest;

  /// JSON-safe plan receipt including its deterministic digest.
  Map<String, Object?> toJson() => {
    'schemaVersion': 'desy-goldens-prototype/0.1',
    'registry': {
      'name': registry.name,
      'id': registry.identity?.id,
      'version': registry.identity?.version,
    },
    'digest': digest,
    'caseCount': cases.length,
    'cases': [for (final goldenCase in cases) goldenCase.toJson()],
  };
}

String _canonicalJson(
  DesyRegistry registry,
  List<DesyGoldenPrototypeCase> cases,
) => jsonEncode({
  'schemaVersion': 'desy-goldens-prototype/0.1',
  'registry': {
    'name': registry.name,
    'id': registry.identity?.id,
    'version': registry.identity?.version,
  },
  'cases': [for (final goldenCase in cases) goldenCase.toJson()],
});

String _segment(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9._-]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return normalized.isEmpty ? 'unnamed' : normalized;
}

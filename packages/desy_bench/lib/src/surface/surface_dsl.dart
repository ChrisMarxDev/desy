import 'dart:collection';
import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../registry.dart';

/// A local, serializable screen prototype composed from registry components.
///
/// The document describes structure and component configuration only. It never
/// contains widget builders, callbacks, navigation, networking, or application
/// logic. Component IDs and knob values are resolved through a [DesyRegistry].
final class DesySurfaceDocument {
  /// Creates a typed surface document.
  DesySurfaceDocument({
    required this.id,
    required this.root,
    this.version = currentVersion,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'A surface ID cannot be empty.');
    }
    if (version != currentVersion) {
      throw ArgumentError.value(
        version,
        'version',
        'Only surface version $currentVersion is supported.',
      );
    }
  }

  /// Parses a JSON Desy DSL document.
  ///
  /// A top-level list is shorthand for a column surface. A full document uses
  /// `version`, `id`, and `root` fields.
  factory DesySurfaceDocument.parse(String source) {
    Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw FormatException('Invalid Desy surface JSON: ${error.message}');
    }
    return DesySurfaceDocument.fromJson(decoded);
  }

  /// Normalizes JSON-compatible data into a typed surface document.
  factory DesySurfaceDocument.fromJson(Object? json) {
    if (json is List<Object?>) {
      return DesySurfaceDocument(
        id: 'prototype',
        root: DesySurfaceColumn(
          children: _nodes(json, r'$', field: 'children'),
        ),
      );
    }

    final map = _map(json, r'$');
    if (!map.containsKey('root') && !map.containsKey('version')) {
      return DesySurfaceDocument(id: 'prototype', root: _node(map, r'$'));
    }
    _onlyKeys(map, const {'version', 'id', 'root'}, r'$');
    final version = map['version'] ?? currentVersion;
    if (version is! int || version != currentVersion) {
      throw FormatException(
        r'$.version must be the supported integer version 1.',
      );
    }
    final id = map['id'] ?? 'prototype';
    if (id is! String || id.trim().isEmpty) {
      throw FormatException(r'$.id must be a non-empty string.');
    }
    if (!map.containsKey('root')) {
      throw FormatException(r'$.root is required.');
    }
    return DesySurfaceDocument(
      id: id,
      version: version,
      root: _node(map['root'], r'$.root'),
    );
  }

  /// Current DSL schema version.
  static const currentVersion = 1;

  /// Schema version used to parse this document.
  final int version;

  /// Stable local identity chosen by the author.
  final String id;

  /// Root structural or component node.
  final DesySurfaceNode root;

  /// Returns canonical JSON-compatible data for this document.
  Map<String, Object> toJson() => {
    'version': version,
    'id': id,
    'root': root.toJson(),
  };
}

/// One typed node in the Desy screen-prototyping DSL.
sealed class DesySurfaceNode {
  const DesySurfaceNode();

  /// Returns canonical JSON-compatible data for this node.
  Map<String, Object> toJson();
}

/// A real registry component placed in a surface.
final class DesySurfaceComponent extends DesySurfaceNode {
  /// Creates a component reference with optional instance defaults and knobs.
  DesySurfaceComponent({
    required this.component,
    this.instance,
    Map<String, Object> knobs = const {},
  }) : knobs = UnmodifiableMapView({
         for (final entry in knobs.entries)
           entry.key: _freezeJsonValue(entry.value, 'knobs.${entry.key}'),
       }) {
    if (component.trim().isEmpty) {
      throw ArgumentError.value(
        component,
        'component',
        'A component ID cannot be empty.',
      );
    }
    if (instance case final String value when value.trim().isEmpty) {
      throw ArgumentError.value(
        instance,
        'instance',
        'An instance ID cannot be empty.',
      );
    }
    for (final key in knobs.keys) {
      if (key.trim().isEmpty) {
        throw ArgumentError.value(key, 'knobs', 'A knob ID cannot be empty.');
      }
    }
  }

  /// Stable ID of a component in the consumer registry.
  final String component;

  /// Optional named instance whose values provide the starting configuration.
  final String? instance;

  /// Serializable overrides matched against the component's knob schema.
  final Map<String, Object> knobs;

  @override
  Map<String, Object> toJson() => {
    'component': component,
    if (instance case final String value) 'instance': value,
    if (knobs.isNotEmpty) 'knobs': knobs,
  };
}

/// A horizontal structural layout.
final class DesySurfaceRow extends DesySurfaceNode {
  /// Creates a row of surface nodes.
  DesySurfaceRow({
    required List<DesySurfaceNode> children,
    this.gap,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.min,
  }) : children = List.unmodifiable(children) {
    _validateCrossAxisAlignment(crossAxisAlignment);
  }

  /// Ordered nodes rendered horizontally.
  final List<DesySurfaceNode> children;

  /// Optional space inserted between adjacent children.
  final DesySurfaceLength? gap;

  /// Distribution along the horizontal axis.
  final MainAxisAlignment mainAxisAlignment;

  /// Alignment along the vertical axis.
  final CrossAxisAlignment crossAxisAlignment;

  /// Whether the row takes the minimum or maximum horizontal extent.
  final MainAxisSize mainAxisSize;

  @override
  Map<String, Object> toJson() => _flexJson(
    layout: 'row',
    children: children,
    gap: gap,
    mainAxisAlignment: mainAxisAlignment,
    crossAxisAlignment: crossAxisAlignment,
    mainAxisSize: mainAxisSize,
  );
}

/// A vertical structural layout.
final class DesySurfaceColumn extends DesySurfaceNode {
  /// Creates a column of surface nodes.
  DesySurfaceColumn({
    required List<DesySurfaceNode> children,
    this.gap,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.min,
  }) : children = List.unmodifiable(children) {
    _validateCrossAxisAlignment(crossAxisAlignment);
  }

  /// Ordered nodes rendered vertically.
  final List<DesySurfaceNode> children;

  /// Optional space inserted between adjacent children.
  final DesySurfaceLength? gap;

  /// Distribution along the vertical axis.
  final MainAxisAlignment mainAxisAlignment;

  /// Alignment along the horizontal axis.
  final CrossAxisAlignment crossAxisAlignment;

  /// Whether the column takes the minimum or maximum vertical extent.
  final MainAxisSize mainAxisSize;

  @override
  Map<String, Object> toJson() => _flexJson(
    layout: 'column',
    children: children,
    gap: gap,
    mainAxisAlignment: mainAxisAlignment,
    crossAxisAlignment: crossAxisAlignment,
    mainAxisSize: mainAxisSize,
  );
}

/// A structural overlay layout.
final class DesySurfaceStack extends DesySurfaceNode {
  /// Creates a stack of surface nodes.
  DesySurfaceStack({
    required List<DesySurfaceNode> children,
    this.alignment = Alignment.center,
    this.fit = StackFit.loose,
  }) : children = List.unmodifiable(children) {
    if (!_stackAlignments.contains(alignment)) {
      throw ArgumentError.value(
        alignment,
        'alignment',
        'Surface stacks support the nine standard alignments.',
      );
    }
  }

  /// Nodes painted back-to-front.
  final List<DesySurfaceNode> children;

  /// Alignment applied to non-positioned children.
  final Alignment alignment;

  /// How non-positioned children receive constraints.
  final StackFit fit;

  @override
  Map<String, Object> toJson() => {
    'layout': 'stack',
    'children': [for (final child in children) child.toJson()],
    if (alignment != Alignment.center)
      'alignment': _stackAlignmentName(alignment),
    if (fit != StackFit.loose) 'fit': fit.name,
  };
}

/// Structural padding around one child.
final class DesySurfacePadding extends DesySurfaceNode {
  /// Creates padding around [child].
  const DesySurfacePadding({required this.padding, required this.child});

  /// Typed edge values, optionally backed by registry measurements.
  final DesySurfaceInsets padding;

  /// Node placed inside the padding.
  final DesySurfaceNode child;

  @override
  Map<String, Object> toJson() => {
    'layout': 'padding',
    'padding': padding.toJson(),
    'child': child.toJson(),
  };
}

/// A structural scrolling viewport around one child.
///
/// Scrolling is explicit prototype structure. Desy never makes a surface
/// scrollable merely because its content overflows.
final class DesySurfaceScroll extends DesySurfaceNode {
  /// Creates a horizontal or vertical scrolling region.
  const DesySurfaceScroll({
    required this.axis,
    required this.child,
    this.scrollbar = false,
  });

  /// Direction in which the child may exceed the available viewport.
  final Axis axis;

  /// Node laid out inside the scrolling region.
  final DesySurfaceNode child;

  /// Whether Desy draws an interactive scrollbar for this mock.
  final bool scrollbar;

  @override
  Map<String, Object> toJson() => {
    'layout': 'scroll',
    'axis': axis.name,
    'child': child.toJson(),
    if (scrollbar) 'scrollbar': true,
  };
}

/// Empty structural space; it never represents a visual UI element.
final class DesySurfaceSpacer extends DesySurfaceNode {
  /// Creates fixed empty space in one or both axes.
  DesySurfaceSpacer({this.width, this.height}) {
    if (width == null && height == null) {
      throw ArgumentError('A surface spacer needs a width or height.');
    }
  }

  /// Optional horizontal extent.
  final DesySurfaceLength? width;

  /// Optional vertical extent.
  final DesySurfaceLength? height;

  @override
  Map<String, Object> toJson() => {
    'layout': 'spacer',
    if (width case final DesySurfaceLength value) 'width': value.toJson(),
    if (height case final DesySurfaceLength value) 'height': value.toJson(),
  };
}

/// A layout length represented by pixels or a registry measurement ID.
sealed class DesySurfaceLength {
  const DesySurfaceLength();

  /// Creates a non-negative logical-pixel length.
  factory DesySurfaceLength.pixels(num value) {
    final pixels = value.toDouble();
    if (!pixels.isFinite || pixels < 0) {
      throw ArgumentError.value(
        value,
        'value',
        'A surface length must be finite and non-negative.',
      );
    }
    return DesySurfacePixels._(pixels);
  }

  /// References a spacing entry in [DesyRegistry.measurements].
  factory DesySurfaceLength.measurement(String id) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'A measurement ID cannot be empty.');
    }
    return DesySurfaceMeasurement._(id);
  }

  /// JSON representation: a number or a registry measurement ID.
  Object toJson();
}

/// A literal logical-pixel layout length.
final class DesySurfacePixels extends DesySurfaceLength {
  const DesySurfacePixels._(this.value);

  /// Logical Flutter pixels.
  final double value;

  @override
  Object toJson() => value;
}

/// A layout length derived from the registry Measurements lane.
final class DesySurfaceMeasurement extends DesySurfaceLength {
  const DesySurfaceMeasurement._(this.id);

  /// Stable ID of a [DesyNumericKind.spacing] entry.
  final String id;

  @override
  Object toJson() => id;
}

/// Four typed padding edges for a [DesySurfacePadding].
final class DesySurfaceInsets {
  /// Creates independently configured edges.
  const DesySurfaceInsets.only({this.left, this.top, this.right, this.bottom});

  /// Applies one length to every edge.
  const DesySurfaceInsets.all(DesySurfaceLength value)
    : left = value,
      top = value,
      right = value,
      bottom = value;

  /// Applies horizontal and vertical lengths symmetrically.
  const DesySurfaceInsets.symmetric({
    DesySurfaceLength? horizontal,
    DesySurfaceLength? vertical,
  }) : left = horizontal,
       right = horizontal,
       top = vertical,
       bottom = vertical;

  /// Left padding.
  final DesySurfaceLength? left;

  /// Top padding.
  final DesySurfaceLength? top;

  /// Right padding.
  final DesySurfaceLength? right;

  /// Bottom padding.
  final DesySurfaceLength? bottom;

  /// Canonical JSON representation.
  Map<String, Object> toJson() => {
    if (left case final DesySurfaceLength value) 'left': value.toJson(),
    if (top case final DesySurfaceLength value) 'top': value.toJson(),
    if (right case final DesySurfaceLength value) 'right': value.toJson(),
    if (bottom case final DesySurfaceLength value) 'bottom': value.toJson(),
  };
}

/// A registry-backed validation problem in a Desy surface.
final class DesySurfaceValidationIssue {
  /// Creates a validation issue at one JSON-style [path].
  const DesySurfaceValidationIssue({
    required this.path,
    required this.message,
    this.severity = DesySurfaceValidationSeverity.error,
  });

  /// Location in the surface document.
  final String path;

  /// Human-readable repair guidance.
  final String message;

  /// Whether this issue blocks rendering or only flags a risky composition.
  final DesySurfaceValidationSeverity severity;

  /// Whether this issue prevents the surface from rendering safely.
  bool get isError => severity == DesySurfaceValidationSeverity.error;

  @override
  String toString() => '$path: $message';
}

/// Severity of one deterministic surface validation finding.
enum DesySurfaceValidationSeverity {
  /// Non-blocking composition guidance.
  warning,

  /// A finding that prevents safe deterministic rendering.
  error,
}

/// Validates one parsed DSL document against the active consumer registry.
final class DesySurfaceValidator {
  /// Creates a validator that resolves exclusively through [registry].
  const DesySurfaceValidator(this.registry);

  /// Registry that remains the only component and measurement inventory.
  final DesyRegistry registry;

  /// Returns every deterministic validation issue in [surface].
  List<DesySurfaceValidationIssue> validate(DesySurfaceDocument surface) {
    final issues = <DesySurfaceValidationIssue>[];
    _validateNode(surface.root, r'$.root', issues, scrollAncestors: const {});
    return List.unmodifiable(issues);
  }

  void _validateNode(
    DesySurfaceNode node,
    String path,
    List<DesySurfaceValidationIssue> issues, {
    required Set<Axis> scrollAncestors,
  }) {
    switch (node) {
      case DesySurfaceComponent():
        _validateComponent(node, path, issues);
      case DesySurfaceRow():
        _validateLength(
          node.gap,
          '$path.gap',
          issues,
          axis: DesyNumericAxis.horizontal,
        );
        for (final (index, child) in node.children.indexed) {
          _validateNode(
            child,
            '$path.children[$index]',
            issues,
            scrollAncestors: scrollAncestors,
          );
        }
      case DesySurfaceColumn():
        _validateLength(
          node.gap,
          '$path.gap',
          issues,
          axis: DesyNumericAxis.vertical,
        );
        for (final (index, child) in node.children.indexed) {
          _validateNode(
            child,
            '$path.children[$index]',
            issues,
            scrollAncestors: scrollAncestors,
          );
        }
      case DesySurfaceStack():
        for (final (index, child) in node.children.indexed) {
          _validateNode(
            child,
            '$path.children[$index]',
            issues,
            scrollAncestors: scrollAncestors,
          );
        }
      case DesySurfacePadding():
        _validateInsets(node.padding, '$path.padding', issues);
        _validateNode(
          node.child,
          '$path.child',
          issues,
          scrollAncestors: scrollAncestors,
        );
      case DesySurfaceScroll():
        if (scrollAncestors.contains(node.axis)) {
          issues.add(
            DesySurfaceValidationIssue(
              path: '$path.axis',
              message:
                  'Nested ${node.axis.name} scrolling can create ambiguous gestures.',
              severity: DesySurfaceValidationSeverity.warning,
            ),
          );
        }
        _validateNode(
          node.child,
          '$path.child',
          issues,
          scrollAncestors: {...scrollAncestors, node.axis},
        );
      case DesySurfaceSpacer():
        _validateLength(
          node.width,
          '$path.width',
          issues,
          axis: DesyNumericAxis.horizontal,
        );
        _validateLength(
          node.height,
          '$path.height',
          issues,
          axis: DesyNumericAxis.vertical,
        );
    }
  }

  void _validateComponent(
    DesySurfaceComponent node,
    String path,
    List<DesySurfaceValidationIssue> issues,
  ) {
    DesyRegistryComponent? component;
    for (final candidate in registry.allComponents) {
      if (candidate.id == node.component) {
        component = candidate;
        break;
      }
    }
    if (component == null) {
      issues.add(
        DesySurfaceValidationIssue(
          path: '$path.component',
          message: 'Unknown registry component "${node.component}".',
        ),
      );
      return;
    }

    if (node.instance case final String instance
        when !component.instanceIds.contains(instance)) {
      issues.add(
        DesySurfaceValidationIssue(
          path: '$path.instance',
          message: 'Component "${component.id}" has no instance "$instance".',
        ),
      );
    }

    final definitions = {
      for (final definition in component.knobDefinitions)
        definition.id: definition,
    };
    for (final entry in node.knobs.entries) {
      final definition = definitions[entry.key];
      final knobPath = '$path.knobs.${entry.key}';
      if (definition == null) {
        issues.add(
          DesySurfaceValidationIssue(
            path: knobPath,
            message: 'Component "${component.id}" has no knob "${entry.key}".',
          ),
        );
        continue;
      }
      final value = entry.value;
      switch (definition.kind) {
        case DesyKnobKind.string:
          if (value is! String) {
            issues.add(
              DesySurfaceValidationIssue(
                path: knobPath,
                message: 'Expected a string value.',
              ),
            );
          }
        case DesyKnobKind.boolean:
          if (value is! bool) {
            issues.add(
              DesySurfaceValidationIssue(
                path: knobPath,
                message: 'Expected a boolean value.',
              ),
            );
          }
        case DesyKnobKind.widgetInstance:
          if (value is! String) {
            issues.add(
              DesySurfaceValidationIssue(
                path: knobPath,
                message: 'Expected a registered component-instance ID.',
              ),
            );
          } else {
            if (registry.resolveComponentInstance(value) == null) {
              issues.add(
                DesySurfaceValidationIssue(
                  path: knobPath,
                  message: 'Unknown component instance "$value".',
                ),
              );
            }
            if (definition.options.isNotEmpty &&
                !definition.options.contains(value)) {
              issues.add(
                DesySurfaceValidationIssue(
                  path: knobPath,
                  message:
                      'Instance "$value" is not legal for knob '
                      '"${definition.id}".',
                ),
              );
            }
          }
      }
    }
  }

  void _validateInsets(
    DesySurfaceInsets insets,
    String path,
    List<DesySurfaceValidationIssue> issues,
  ) {
    _validateLength(
      insets.left,
      '$path.left',
      issues,
      axis: DesyNumericAxis.horizontal,
    );
    _validateLength(
      insets.top,
      '$path.top',
      issues,
      axis: DesyNumericAxis.vertical,
    );
    _validateLength(
      insets.right,
      '$path.right',
      issues,
      axis: DesyNumericAxis.horizontal,
    );
    _validateLength(
      insets.bottom,
      '$path.bottom',
      issues,
      axis: DesyNumericAxis.vertical,
    );
  }

  void _validateLength(
    DesySurfaceLength? length,
    String path,
    List<DesySurfaceValidationIssue> issues, {
    DesyNumericAxis? axis,
  }) {
    if (length is! DesySurfaceMeasurement) return;
    DesyNumericEntry? measurement;
    for (final candidate in registry.measurements) {
      if (candidate.id == length.id) {
        measurement = candidate;
        break;
      }
    }
    if (measurement == null) {
      issues.add(
        DesySurfaceValidationIssue(
          path: path,
          message: 'Unknown registry measurement "${length.id}".',
        ),
      );
      return;
    }
    if (measurement.kind != DesyNumericKind.spacing) {
      issues.add(
        DesySurfaceValidationIssue(
          path: path,
          message:
              'Measurement "${length.id}" is ${measurement.kind.label}; '
              'surface spacing requires a spacing entry.',
        ),
      );
    }
    if (measurement.unit != DesyNumberUnit.dp &&
        measurement.unit != DesyNumberUnit.unitless) {
      issues.add(
        DesySurfaceValidationIssue(
          path: path,
          message:
              'Measurement "${length.id}" must use logical pixels or be '
              'unitless for layout.',
        ),
      );
    }
    if (!measurement.value.isFinite || measurement.value < 0) {
      issues.add(
        DesySurfaceValidationIssue(
          path: path,
          message:
              'Measurement "${length.id}" must be finite and non-negative '
              'for layout.',
        ),
      );
    }
    if (axis != null &&
        measurement.axis != DesyNumericAxis.both &&
        measurement.axis != axis) {
      issues.add(
        DesySurfaceValidationIssue(
          path: path,
          message:
              'Measurement "${length.id}" is ${measurement.axis.name}; '
              'this layout position is ${axis.name}.',
        ),
      );
    }
  }
}

DesySurfaceNode _node(Object? value, String path) {
  final map = _map(value, path);
  if (map.containsKey('layout')) return _layout(map, path);
  return _component(map, path);
}

DesySurfaceNode _component(Map<String, Object?> map, String path) {
  _onlyKeys(map, const {
    'component',
    'id',
    'instance',
    'knobs',
    'values',
  }, path);
  if (map.containsKey('component') && map.containsKey('id')) {
    throw FormatException('$path must use component or id, not both.');
  }
  final component = map['component'] ?? map['id'];
  if (component is! String || component.trim().isEmpty) {
    throw FormatException(
      '$path.component must be a non-empty registry component ID.',
    );
  }
  final instance = map['instance'];
  if (instance != null && (instance is! String || instance.trim().isEmpty)) {
    throw FormatException('$path.instance must be a non-empty string.');
  }
  if (map.containsKey('knobs') && map.containsKey('values')) {
    throw FormatException('$path must use knobs or values, not both.');
  }
  final knobJson = map['knobs'] ?? map['values'] ?? const <String, Object?>{};
  final knobMap = _map(knobJson, '$path.knobs');
  final knobs = <String, Object>{};
  for (final entry in knobMap.entries) {
    if (entry.value == null) {
      throw FormatException('$path.knobs.${entry.key} cannot be null.');
    }
    knobs[entry.key] = _freezeJsonValue(
      entry.value!,
      '$path.knobs.${entry.key}',
    );
  }
  return DesySurfaceComponent(
    component: component,
    instance: instance as String?,
    knobs: knobs,
  );
}

DesySurfaceNode _layout(Map<String, Object?> map, String path) {
  final layout = map['layout'];
  if (layout is! String) {
    throw FormatException('$path.layout must be a string.');
  }
  return switch (layout) {
    'row' => _row(map, path),
    'column' => _column(map, path),
    'stack' => _stack(map, path),
    'padding' => _padding(map, path),
    'scroll' => _scroll(map, path),
    'spacer' => _spacer(map, path),
    _ => throw FormatException(
      '$path.layout must be row, column, stack, padding, scroll, or spacer.',
    ),
  };
}

DesySurfaceRow _row(Map<String, Object?> map, String path) {
  _onlyKeys(map, _flexKeys, path);
  return DesySurfaceRow(
    children: _childNodes(map, path),
    gap: _optionalLength(map['gap'], '$path.gap'),
    mainAxisAlignment: _mainAlignment(
      map['mainAxisAlignment'],
      '$path.mainAxisAlignment',
    ),
    crossAxisAlignment: _crossAlignment(
      map['crossAxisAlignment'],
      '$path.crossAxisAlignment',
    ),
    mainAxisSize: _mainSize(map['mainAxisSize'], '$path.mainAxisSize'),
  );
}

DesySurfaceColumn _column(Map<String, Object?> map, String path) {
  _onlyKeys(map, _flexKeys, path);
  return DesySurfaceColumn(
    children: _childNodes(map, path),
    gap: _optionalLength(map['gap'], '$path.gap'),
    mainAxisAlignment: _mainAlignment(
      map['mainAxisAlignment'],
      '$path.mainAxisAlignment',
    ),
    crossAxisAlignment: _crossAlignment(
      map['crossAxisAlignment'],
      '$path.crossAxisAlignment',
    ),
    mainAxisSize: _mainSize(map['mainAxisSize'], '$path.mainAxisSize'),
  );
}

const _flexKeys = {
  'layout',
  'children',
  'gap',
  'mainAxisAlignment',
  'crossAxisAlignment',
  'mainAxisSize',
};

DesySurfaceStack _stack(Map<String, Object?> map, String path) {
  _onlyKeys(map, const {'layout', 'children', 'alignment', 'fit'}, path);
  return DesySurfaceStack(
    children: _childNodes(map, path),
    alignment: _stackAlignment(map['alignment'], '$path.alignment'),
    fit: _stackFit(map['fit'], '$path.fit'),
  );
}

DesySurfacePadding _padding(Map<String, Object?> map, String path) {
  _onlyKeys(map, const {'layout', 'padding', 'child'}, path);
  if (!map.containsKey('padding')) {
    throw FormatException('$path.padding is required.');
  }
  if (!map.containsKey('child')) {
    throw FormatException('$path.child is required.');
  }
  return DesySurfacePadding(
    padding: _insets(map['padding'], '$path.padding'),
    child: _node(map['child'], '$path.child'),
  );
}

DesySurfaceScroll _scroll(Map<String, Object?> map, String path) {
  _onlyKeys(map, const {'layout', 'axis', 'child', 'scrollbar'}, path);
  if (!map.containsKey('child')) {
    throw FormatException('$path.child is required.');
  }
  final axis = switch (map['axis']) {
    'horizontal' => Axis.horizontal,
    'vertical' => Axis.vertical,
    _ => throw FormatException('$path.axis must be horizontal or vertical.'),
  };
  final scrollbar = map['scrollbar'] ?? false;
  if (scrollbar is! bool) {
    throw FormatException('$path.scrollbar must be a boolean.');
  }
  return DesySurfaceScroll(
    axis: axis,
    child: _node(map['child'], '$path.child'),
    scrollbar: scrollbar,
  );
}

DesySurfaceSpacer _spacer(Map<String, Object?> map, String path) {
  _onlyKeys(map, const {'layout', 'width', 'height'}, path);
  final width = _optionalLength(map['width'], '$path.width');
  final height = _optionalLength(map['height'], '$path.height');
  if (width == null && height == null) {
    throw FormatException('$path needs a width or height.');
  }
  return DesySurfaceSpacer(width: width, height: height);
}

List<DesySurfaceNode> _childNodes(Map<String, Object?> map, String path) {
  final value = map['children'];
  if (value is! List<Object?>) {
    throw FormatException('$path.children must be a list.');
  }
  return _nodes(value, path, field: 'children');
}

List<DesySurfaceNode> _nodes(
  List<Object?> values,
  String path, {
  required String field,
}) => List.unmodifiable([
  for (final (index, value) in values.indexed)
    _node(value, '$path.$field[$index]'),
]);

DesySurfaceLength? _optionalLength(Object? value, String path) =>
    value == null ? null : _length(value, path);

DesySurfaceLength _length(Object? value, String path) {
  try {
    if (value is num) return DesySurfaceLength.pixels(value);
    if (value is String) return DesySurfaceLength.measurement(value);
  } on ArgumentError catch (error) {
    throw FormatException('$path: ${error.message}');
  }
  throw FormatException(
    '$path must be a non-negative number or registry measurement ID.',
  );
}

DesySurfaceInsets _insets(Object? value, String path) {
  if (value is num || value is String) {
    return DesySurfaceInsets.all(_length(value, path));
  }
  final map = _map(value, path);
  _onlyKeys(map, const {
    'all',
    'horizontal',
    'vertical',
    'left',
    'top',
    'right',
    'bottom',
  }, path);
  final all = _optionalLength(map['all'], '$path.all');
  final horizontal =
      _optionalLength(map['horizontal'], '$path.horizontal') ?? all;
  final vertical = _optionalLength(map['vertical'], '$path.vertical') ?? all;
  return DesySurfaceInsets.only(
    left: _optionalLength(map['left'], '$path.left') ?? horizontal,
    top: _optionalLength(map['top'], '$path.top') ?? vertical,
    right: _optionalLength(map['right'], '$path.right') ?? horizontal,
    bottom: _optionalLength(map['bottom'], '$path.bottom') ?? vertical,
  );
}

MainAxisAlignment _mainAlignment(Object? value, String path) => switch (value) {
  null || 'start' => MainAxisAlignment.start,
  'end' => MainAxisAlignment.end,
  'center' => MainAxisAlignment.center,
  'spaceBetween' => MainAxisAlignment.spaceBetween,
  'spaceAround' => MainAxisAlignment.spaceAround,
  'spaceEvenly' => MainAxisAlignment.spaceEvenly,
  _ => throw FormatException(
    '$path must be start, end, center, spaceBetween, spaceAround, or '
    'spaceEvenly.',
  ),
};

CrossAxisAlignment _crossAlignment(Object? value, String path) =>
    switch (value) {
      null || 'center' => CrossAxisAlignment.center,
      'start' => CrossAxisAlignment.start,
      'end' => CrossAxisAlignment.end,
      'stretch' => CrossAxisAlignment.stretch,
      _ => throw FormatException(
        '$path must be start, end, center, or stretch.',
      ),
    };

MainAxisSize _mainSize(Object? value, String path) => switch (value) {
  null || 'min' => MainAxisSize.min,
  'max' => MainAxisSize.max,
  _ => throw FormatException('$path must be min or max.'),
};

Alignment _stackAlignment(Object? value, String path) => switch (value) {
  null || 'center' => Alignment.center,
  'topStart' => Alignment.topLeft,
  'topCenter' => Alignment.topCenter,
  'topEnd' => Alignment.topRight,
  'centerStart' => Alignment.centerLeft,
  'centerEnd' => Alignment.centerRight,
  'bottomStart' => Alignment.bottomLeft,
  'bottomCenter' => Alignment.bottomCenter,
  'bottomEnd' => Alignment.bottomRight,
  _ => throw FormatException(
    '$path must be topStart, topCenter, topEnd, centerStart, center, '
    'centerEnd, bottomStart, bottomCenter, or bottomEnd.',
  ),
};

StackFit _stackFit(Object? value, String path) => switch (value) {
  null || 'loose' => StackFit.loose,
  'expand' => StackFit.expand,
  'passthrough' => StackFit.passthrough,
  _ => throw FormatException('$path must be loose, expand, or passthrough.'),
};

Map<String, Object?> _map(Object? value, String path) {
  if (value is! Map) {
    throw FormatException('$path must be an object.');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('$path contains a non-string key.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

void _onlyKeys(Map<String, Object?> map, Set<String> allowed, String path) {
  for (final key in map.keys) {
    if (!allowed.contains(key)) {
      throw FormatException('$path contains unsupported field "$key".');
    }
  }
}

Object _freezeJsonValue(Object value, String path) {
  if (value is String || value is bool || value is num) return value;
  if (value is List) {
    return List<Object>.unmodifiable([
      for (final (index, child) in value.indexed)
        if (child == null)
          throw FormatException('$path[$index] cannot be null.')
        else
          _freezeJsonValue(child, '$path[$index]'),
    ]);
  }
  if (value is Map) {
    final map = _map(value, path);
    final frozen = <String, Object>{};
    for (final entry in map.entries) {
      final child = entry.value;
      if (child == null) {
        throw FormatException('$path.${entry.key} cannot be null.');
      }
      frozen[entry.key] = _freezeJsonValue(child, '$path.${entry.key}');
    }
    return Map<String, Object>.unmodifiable(frozen);
  }
  throw FormatException('$path is not a JSON-serializable value.');
}

Map<String, Object> _flexJson({
  required String layout,
  required List<DesySurfaceNode> children,
  required DesySurfaceLength? gap,
  required MainAxisAlignment mainAxisAlignment,
  required CrossAxisAlignment crossAxisAlignment,
  required MainAxisSize mainAxisSize,
}) => {
  'layout': layout,
  'children': [for (final child in children) child.toJson()],
  if (gap case final DesySurfaceLength value) 'gap': value.toJson(),
  if (mainAxisAlignment != MainAxisAlignment.start)
    'mainAxisAlignment': mainAxisAlignment.name,
  if (crossAxisAlignment != CrossAxisAlignment.center)
    'crossAxisAlignment': crossAxisAlignment.name,
  if (mainAxisSize != MainAxisSize.min) 'mainAxisSize': mainAxisSize.name,
};

String _stackAlignmentName(Alignment alignment) => switch (alignment) {
  Alignment.topLeft => 'topStart',
  Alignment.topCenter => 'topCenter',
  Alignment.topRight => 'topEnd',
  Alignment.centerLeft => 'centerStart',
  Alignment.center => 'center',
  Alignment.centerRight => 'centerEnd',
  Alignment.bottomLeft => 'bottomStart',
  Alignment.bottomCenter => 'bottomCenter',
  Alignment.bottomRight => 'bottomEnd',
  _ => throw ArgumentError.value(
    alignment,
    'alignment',
    'Surface stacks support the nine standard alignments.',
  ),
};

final _stackAlignments = List<Alignment>.unmodifiable(const [
  Alignment.topLeft,
  Alignment.topCenter,
  Alignment.topRight,
  Alignment.centerLeft,
  Alignment.center,
  Alignment.centerRight,
  Alignment.bottomLeft,
  Alignment.bottomCenter,
  Alignment.bottomRight,
]);

void _validateCrossAxisAlignment(CrossAxisAlignment alignment) {
  if (alignment == CrossAxisAlignment.baseline) {
    throw ArgumentError.value(
      alignment,
      'crossAxisAlignment',
      'Surface rows and columns do not support baseline alignment.',
    );
  }
}

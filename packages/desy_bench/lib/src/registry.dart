import 'dart:collection';

import 'package:flutter/material.dart';

import 'registry_missing_widget.dart';

/// A built-in, typed atom lane understood by Desy's specialized boards.
enum DesyAtomKind {
  /// Consumer color and visual-treatment entries.
  colors,

  /// Consumer typography entries.
  fonts,

  /// Consumer icon glyph entries.
  icons,

  /// Consumer numeric foundation entries.
  measurements,

  /// Consumer motion entries with playback-aware specimens.
  motion,

  /// Consumer visual-effect entries.
  effects;

  /// Stable ID used by registry-derived navigation.
  String get id => 'desy.atoms.$name';

  /// Human-readable lane name.
  String get label => switch (this) {
    colors => 'Colors',
    fonts => 'Fonts',
    icons => 'Icons',
    measurements => 'Measurements',
    motion => 'Motion',
    effects => 'Effects',
  };

  /// Stable ID of the built-in Atoms navigation section.
  static const rootId = 'desy.atoms';
}

/// The consumer-owned definition rendered by Desy Bench.
class DesyRegistry {
  /// Creates a design-system registry.
  DesyRegistry({
    required this.name,
    required List<DesyTheme> themes,
    List<DesyToken> tokens = const [],
    List<DesyColorEntry> colors = const [],
    List<DesyTypographyEntry> fonts = const [],
    List<DesyNumericEntry> measurements = const [],
    List<DesyMotionEntry> motion = const [],
    List<DesyEffectEntry> effects = const [],
    List<DesyIconEntry> icons = const [],
    List<DesyAssetEntry> assets = const [],
    List<DesyRegistryComponent> components = const [],
    List<DesyShowcase> showcases = const [],
  }) : assert(themes.isNotEmpty, 'A Desy registry needs at least one theme.'),
       themes = List.unmodifiable(themes),
       tokens = List.unmodifiable(tokens),
       colors = List.unmodifiable(colors),
       fonts = List.unmodifiable(fonts),
       measurements = List.unmodifiable(measurements),
       motion = List.unmodifiable(motion),
       effects = List.unmodifiable(effects),
       icons = List.unmodifiable(icons),
       assets = List.unmodifiable(assets),
       components = List.unmodifiable(components),
       showcases = List.unmodifiable(showcases),
       componentGroups = _buildComponentGroups(components);

  /// Human-readable system name.
  final String name;

  /// Theme wrappers supplied by the consumer.
  final List<DesyTheme> themes;

  /// Semantic values used by the consumer system.
  final List<DesyToken> tokens;

  /// Consumer-owned color and visual treatment entries for the color atlas.
  ///
  /// Unlike [tokens], entries may describe gradients or any other visual
  /// treatment in addition to a single color value.
  final List<DesyColorEntry> colors;

  /// Consumer-owned text styles for the specialized Fonts board.
  final List<DesyTypographyEntry> fonts;

  /// Typed numeric primitives for the specialized Measurements board.
  final List<DesyNumericEntry> measurements;

  /// Motion primitives and their live consumer-owned specimens.
  final List<DesyMotionEntry> motion;

  /// Widget decorators such as consumer-owned shadow recipes.
  final List<DesyEffectEntry> effects;

  /// Consumer-owned icon glyphs.
  final List<DesyIconEntry> icons;

  /// Consumer-owned image, GIF, video, and audio resources.
  final List<DesyAssetEntry> assets;

  /// Real consumer widgets available in the catalogue.
  final List<DesyRegistryComponent> components;

  /// Complete consumer-defined examples rendered by the experimental showcase.
  ///
  /// A showcase is optional and remains a normal widget builder: it does not
  /// create a second screen model or ask consumers to duplicate their system.
  final List<DesyShowcase> showcases;

  /// Navigation groups derived from [components] and their normalized paths.
  final List<DesyComponentGroup> componentGroups;

  /// Every declared semantic token.
  List<DesyToken> get allTokens => tokens;

  /// Every visual entry declared for the Colors lane.
  List<DesyColorEntry> get allColors => colors;

  /// Every typography entry declared for the Fonts lane.
  List<DesyTypographyEntry> get allFonts => fonts;

  /// Every numeric primitive declared for the Measurements lane.
  List<DesyNumericEntry> get allMeasurements => measurements;

  /// Every motion primitive declared for the Motion lane.
  List<DesyMotionEntry> get allMotion => motion;

  /// Every widget effect declared for the Effects lane.
  List<DesyEffectEntry> get allEffects => effects;

  /// Every icon primitive declared for the Icons lane.
  List<DesyIconEntry> get allIcons => icons;

  /// Non-empty built-in atom lanes, in stable workbench order.
  List<DesyAtomKind> get atomKinds => List.unmodifiable([
    if (colors.isNotEmpty) DesyAtomKind.colors,
    if (fonts.isNotEmpty) DesyAtomKind.fonts,
    if (icons.isNotEmpty) DesyAtomKind.icons,
    if (measurements.isNotEmpty) DesyAtomKind.measurements,
    if (motion.isNotEmpty) DesyAtomKind.motion,
    if (effects.isNotEmpty) DesyAtomKind.effects,
  ]);

  /// Whether the registry opts into at least one built-in atom lane.
  bool get hasAtoms => atomKinds.isNotEmpty;

  /// Resolved entries for one built-in atom lane.
  List<DesyRegistryEntry> entriesForAtom(DesyAtomKind kind) =>
      List.unmodifiable(
        _entriesFor(
          tokens: const [],
          colors: kind == DesyAtomKind.colors ? colors : const [],
          typography: kind == DesyAtomKind.fonts ? fonts : const [],
          numbers: kind == DesyAtomKind.measurements ? measurements : const [],
          motion: kind == DesyAtomKind.motion ? motion : const [],
          effects: kind == DesyAtomKind.effects ? effects : const [],
          icons: kind == DesyAtomKind.icons ? icons : const [],
          assets: const [],
          components: const [],
          folderIds: [DesyAtomKind.rootId, kind.id],
          folderNames: ['Atoms', kind.label],
          atomKind: kind,
        ),
      );

  /// Finds a built-in atom lane by its stable navigation ID.
  DesyAtomKind? atomKindForId(String id) {
    for (final kind in atomKinds) {
      if (kind.id == id) return kind;
    }
    return null;
  }

  /// Every declared asset primitive.
  List<DesyAssetEntry> get allAssets => assets;

  /// Every declared component.
  List<DesyRegistryComponent> get allComponents => components;

  /// Every experimental showcase declared by this system.
  List<DesyShowcase> get allShowcases => showcases;

  /// Every named component instance declared by this system.
  ///
  /// An instance is owned by its [DesyRegistryComponent] and can be resolved to
  /// the component's real widget. Workbench composition surfaces use these
  /// references for instance swapping instead of maintaining a second widget
  /// gallery.
  List<DesyRegisteredComponentInstance> get allComponentInstances =>
      List.unmodifiable([
        for (final component in allComponents)
          for (final instanceId in component.instanceIds)
            DesyRegisteredComponentInstance(
              registry: this,
              component: component,
              instanceId: instanceId,
            ),
      ]);

  /// Widget resolver used by component builders that expose instance swaps.
  DesyWidgetResolver get widgetBuilder => DesyWidgetResolver(this);

  /// Finds a component instance by its registry-scoped stable ID.
  DesyRegisteredComponentInstance? resolveComponentInstance(String id) {
    for (final instance in allComponentInstances) {
      if (instance.id == id) return instance;
    }
    return null;
  }

  /// Resolves an artifact by its stable ID without maintaining a second index.
  DesyRegistryEntry? resolve(String id) {
    for (final entry in allEntries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  /// A recursive, read-only view of every widget-returning registry artifact.
  List<DesyRegistryEntry> get allEntries => List.unmodifiable([
    ..._rootEntries(),
    for (final kind in atomKinds) ...entriesForAtom(kind),
    for (final component in components) _componentEntry(component),
  ]);

  /// Every derived component group, in stable tree order.
  List<DesyComponentGroup> get allComponentGroups => List.unmodifiable([
    for (final group in componentGroups) ...group.allGroups,
  ]);

  /// Reports declaration problems without mutating the consumer registry.
  List<DesyRegistryValidationIssue> validate({
    Iterable<String> extensionIds = const [],
  }) => DesyRegistryValidator(this, extensionIds: extensionIds).validate();

  List<DesyRegistryEntry> _rootEntries() => _entriesFor(
    tokens: tokens,
    colors: const [],
    typography: const [],
    numbers: const [],
    motion: const [],
    effects: const [],
    icons: const [],
    assets: assets,
    components: const [],
  );

  DesyRegistryEntry _componentEntry(DesyRegistryComponent component) =>
      DesyRegistryEntry(
        id: component.id,
        name: component.name,
        folderIds: component.componentPath.cumulativePaths,
        folderNames: component.componentPath.labels,
        builder: (context) => component.preview(context, widgetBuilder),
        source: component,
        description: component.description,
        component: component,
      );
}

/// A normalized component navigation path.
///
/// Leading, trailing, and repeated slashes are ignored, so `input`, `/input`,
/// `input/`, and `//input//` all resolve to `/input`.
class DesyComponentPath {
  DesyComponentPath._(List<String> segments)
    : segments = List.unmodifiable(segments);

  /// Parses and validates consumer-facing slash syntax.
  factory DesyComponentPath.parse(String value) {
    final trimmed = value.trim();
    final segments = trimmed
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    if (trimmed.isEmpty || (segments.isEmpty && trimmed != '/')) {
      throw ArgumentError.value(value, 'path', 'Use / for the root path.');
    }
    for (final segment in segments) {
      if (segment == '.' || segment == '..' || !_segment.hasMatch(segment)) {
        throw ArgumentError.value(
          value,
          'path',
          'Use lowercase kebab-case segments such as /inputs/text.',
        );
      }
    }
    return DesyComponentPath._(segments);
  }

  static final _segment = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');

  /// Canonical path segments.
  final List<String> segments;

  /// Canonical slash form. Root components use `/`.
  String get value => segments.isEmpty ? '/' : '/${segments.join('/')}';

  /// Human-readable labels derived from the structural slugs.
  List<String> get labels => List.unmodifiable(segments.map(_pathLabel));

  /// Canonical path for each ancestor, from root group to leaf group.
  List<String> get cumulativePaths => List.unmodifiable([
    for (var index = 0; index < segments.length; index++)
      '/${segments.take(index + 1).join('/')}',
  ]);
}

/// One immutable node in the component file tree derived by [DesyRegistry].
class DesyComponentGroup {
  DesyComponentGroup._({
    required this.path,
    required this.name,
    required List<DesyRegistryComponent> components,
    required List<DesyComponentGroup> children,
  }) : components = List.unmodifiable(components),
       children = List.unmodifiable(children);

  /// Canonical slash path and navigation identity.
  final String path;

  /// Display label derived from the final path segment.
  final String name;

  /// Components declared directly at this path.
  final List<DesyRegistryComponent> components;

  /// Nested path groups in first-registration order.
  final List<DesyComponentGroup> children;

  /// This group and all descendants in stable tree order.
  List<DesyComponentGroup> get allGroups => List.unmodifiable([
    this,
    for (final child in children) ...child.allGroups,
  ]);

  /// Every component in this group and its descendants.
  List<DesyRegistryComponent> get allComponents => List.unmodifiable([
    ...components,
    for (final child in children) ...child.allComponents,
  ]);
}

class _MutableComponentGroup {
  _MutableComponentGroup({required this.path, required this.name});

  final String path;
  final String name;
  final components = <DesyRegistryComponent>[];
  final children = <String, _MutableComponentGroup>{};

  DesyComponentGroup freeze() => DesyComponentGroup._(
    path: path,
    name: name,
    components: components,
    children: [for (final child in children.values) child.freeze()],
  );
}

List<DesyComponentGroup> _buildComponentGroups(List<DesyRegistryComponent> components) {
  final roots = <String, _MutableComponentGroup>{};
  for (final component in components) {
    var siblings = roots;
    final segments = component.componentPath.segments;
    for (var index = 0; index < segments.length; index++) {
      final path = '/${segments.take(index + 1).join('/')}';
      final group = siblings.putIfAbsent(
        path,
        () => _MutableComponentGroup(
          path: path,
          name: _pathLabel(segments[index]),
        ),
      );
      if (index == segments.length - 1) group.components.add(component);
      siblings = group.children;
    }
  }
  return List.unmodifiable([for (final root in roots.values) root.freeze()]);
}

String _pathLabel(String segment) {
  final words = segment.split('-');
  final label = words.join(' ');
  return '${label[0].toUpperCase()}${label.substring(1)}';
}

/// Wraps a preview in the consumer's real theme context.
typedef DesyThemeWrapper = Widget Function(BuildContext context, Widget child);

/// A named consumer theme available in the workbench.
class DesyTheme {
  /// Creates a theme option.
  const DesyTheme({
    required this.id,
    required this.name,
    required this.wrap,
    this.description,
    this.previewBackgroundColor,
    this.isDark,
  });

  /// Stable identifier used by saved workbench state in a future release.
  final String id;

  /// Display name.
  final String name;

  /// Applies the consumer's inherited theme context.
  final DesyThemeWrapper wrap;

  /// Optional guidance for choosing the theme.
  final String? description;

  /// Canvas color placed behind this theme's component previews.
  final Color? previewBackgroundColor;

  /// Whether Desy's own scaffold should use its dark Forui theme.
  ///
  /// When omitted, Desy derives a sensible value from [previewBackgroundColor]
  /// and otherwise uses its light scaffold. This affects only Desy-owned
  /// chrome; [wrap] still owns the consumer widget's real theme.
  final bool? isDark;

  /// The resolved scaffold brightness for this consumer theme.
  bool get usesDarkWorkbench =>
      isDark ?? ((previewBackgroundColor?.computeLuminance() ?? 1) < .5);
}

/// A semantic design token displayed by the workbench.
class DesyToken {
  /// Creates a token entry.
  const DesyToken({
    required this.id,
    required this.name,
    required this.builder,
    this.value,
    this.description,
    this.group = 'Tokens',
  });

  /// Stable token identifier.
  final String id;

  /// Human-readable token name.
  final String name;

  /// Renders the consumer's real token specimen.
  final DesyPrimitiveBuilder builder;

  /// Optional concise display value such as `16 dp` or `#6750A4`.
  final String? value;

  /// Optional semantic usage guidance.
  final String? description;

  /// Token category, such as Color, Spacing, or Typography.
  final String group;
}

/// A resolved registry artifact. It references consumer-owned declarations;
/// it never stores a copied registry or recreates a consumer widget.
class DesyRegistryEntry {
  /// Creates one resolved view of a consumer-owned declaration.
  DesyRegistryEntry({
    required this.id,
    required this.name,
    required List<String> folderIds,
    required List<String> folderNames,
    required this.builder,
    required this.source,
    this.description,
    this.value,
    this.component,
    this.typography,
    this.atomKind,
  }) : folderIds = List.unmodifiable(folderIds),
       folderNames = List.unmodifiable(folderNames);

  /// Stable identifier supplied by the consumer.
  final String id;

  /// Human-readable artifact name.
  final String name;

  /// Stable navigation ancestry from root to leaf.
  ///
  /// Typed atoms use Desy's built-in Atoms and lane IDs; folder entries use
  /// consumer-declared folder IDs.
  final List<String> folderIds;

  /// Display names corresponding to [folderIds], from root to leaf.
  final List<String> folderNames;

  /// Stable route segment derived exclusively from [folderIds].
  String get routePath => folderIds.join('/');

  /// Human-readable folder path for display only.
  String get path => folderNames.isEmpty ? 'Root' : folderNames.join(' / ');

  /// Builds the consumer-owned specimen.
  final DesyPrimitiveBuilder builder;

  /// Original typed declaration represented by this view.
  final Object source;

  /// Optional consumer usage guidance.
  final String? description;

  /// Optional concise display value.
  final String? value;

  /// Component declaration when this entry represents a component.
  final DesyRegistryComponent? component;

  /// Typography declaration when this entry represents a text style.
  final DesyTypographyEntry? typography;

  /// Built-in atom lane when this entry is a typed atom.
  final DesyAtomKind? atomKind;
}

/// A non-mutating problem found in a consumer declaration.
class DesyRegistryValidationIssue {
  /// Creates a validation issue for [id].
  const DesyRegistryValidationIssue({
    required this.message,
    required this.id,
    this.severity = DesyRegistryValidationSeverity.error,
  });

  /// Stable identifier associated with the issue.
  final String id;

  /// Human-readable explanation of the problem.
  final String message;

  /// Whether this issue blocks the workbench or remains inspectable in place.
  final DesyRegistryValidationSeverity severity;
}

/// Impact of one registry declaration problem.
enum DesyRegistryValidationSeverity {
  /// The workbench can load and expose the problem through diagnostic UI.
  warning,

  /// The declaration is structurally unsafe and prevents startup.
  error,
}

/// Validates IDs exposed by a [DesyRegistry] without building a competing index.
class DesyRegistryValidator {
  /// Creates a validator for one consumer [registry].
  DesyRegistryValidator(
    this.registry, {
    Iterable<String> extensionIds = const [],
  }) : extensionIds = List.unmodifiable(extensionIds);

  /// Registry inspected by this validator.
  final DesyRegistry registry;

  /// IDs owned by optional workbench extensions sharing this registry space.
  final List<String> extensionIds;

  /// Returns all declaration issues found in [registry].
  List<DesyRegistryValidationIssue> validate() {
    final seen = HashSet<String>();
    final issues = <DesyRegistryValidationIssue>[];
    void add(String id, String kind) {
      if (!seen.add(id)) {
        issues.add(
          DesyRegistryValidationIssue(
            id: id,
            message: 'Duplicate registry ID "$id" ($kind).',
          ),
        );
      }
    }

    for (final theme in registry.themes) {
      add(theme.id, 'theme');
    }
    add(DesyAtomKind.rootId, 'built-in atom section');
    for (final kind in DesyAtomKind.values) {
      add(kind.id, 'built-in atom lane');
    }
    for (final entry in registry.allEntries) {
      add(entry.id, 'artifact');
    }
    for (final instance in registry.allComponentInstances) {
      add(instance.id, 'component instance');
    }
    for (final showcase in registry.allShowcases) {
      add(showcase.id, 'showcase');
    }
    for (final id in extensionIds) {
      add(id, 'extension');
    }
    for (final component in registry.allComponents) {
      for (final instanceId in component.instanceIds) {
        for (final reference in component.referencesFor(instanceId)) {
          if (registry.resolveComponentInstance(reference.value) == null) {
            issues.add(
              DesyRegistryValidationIssue(
                id: reference.value,
                severity: DesyRegistryValidationSeverity.warning,
                message:
                    'Component "${component.id}" instance "$instanceId" '
                    'references unknown component instance "${reference.value}".',
              ),
            );
          }
        }
      }
    }
    return List.unmodifiable(issues);
  }
}

List<DesyRegistryEntry> _entriesFor({
  required List<DesyToken> tokens,
  required List<DesyColorEntry> colors,
  required List<DesyTypographyEntry> typography,
  required List<DesyNumericEntry> numbers,
  required List<DesyMotionEntry> motion,
  required List<DesyEffectEntry> effects,
  required List<DesyIconEntry> icons,
  required List<DesyAssetEntry> assets,
  required List<DesyRegistryComponent> components,
  List<String> folderIds = const [],
  List<String> folderNames = const [],
  DesyAtomKind? atomKind,
}) => [
  for (final token in tokens)
    DesyRegistryEntry(
      id: token.id,
      name: token.name,
      folderIds: folderIds,
      folderNames: folderNames,
      builder: token.builder,
      source: token,
      description: token.description,
      value: token.value,
      atomKind: atomKind,
    ),
  for (final color in colors)
    DesyRegistryEntry(
      id: color.id,
      name: color.name,
      folderIds: folderIds,
      folderNames: folderNames,
      builder: color.builder,
      source: color,
      description: color.description,
      value: color.value,
      atomKind: atomKind,
    ),
  for (final type in typography)
    DesyRegistryEntry(
      id: type.id,
      name: type.name,
      folderIds: folderIds,
      folderNames: folderNames,
      builder: (context) => type.builder(context, type.sample),
      source: type,
      description: type.description,
      value: type.value,
      typography: type,
      atomKind: atomKind,
    ),
  for (final number in numbers)
    DesyRegistryEntry(
      id: number.id,
      name: number.name,
      folderIds: folderIds,
      folderNames: folderNames,
      builder: number.build,
      source: number,
      description: number.description,
      value: number.displayValue,
      atomKind: atomKind,
    ),
  for (final item in motion)
    DesyRegistryEntry(
      id: item.id,
      name: item.name,
      folderIds: folderIds,
      folderNames: folderNames,
      builder: item.builder,
      source: item,
      description: item.description,
      value: item.displayValue,
      atomKind: atomKind,
    ),
  for (final effect in effects)
    DesyRegistryEntry(
      id: effect.id,
      name: effect.name,
      folderIds: folderIds,
      folderNames: folderNames,
      builder: (context) =>
          effect.apply(context, _effectSpecimen(context, effect)),
      source: effect,
      description: effect.description,
      value: effect.displayValue,
      atomKind: atomKind,
    ),
  for (final icon in icons)
    DesyRegistryEntry(
      id: icon.id,
      name: icon.name,
      folderIds: folderIds,
      folderNames: folderNames,
      builder: icon.build,
      source: icon,
      description: icon.description,
      value: icon.value,
      atomKind: atomKind,
    ),
  for (final asset in assets)
    DesyRegistryEntry(
      id: asset.id,
      name: asset.name,
      folderIds: folderIds,
      folderNames: folderNames,
      builder: asset.build,
      source: asset,
      description: asset.description,
      value: asset.displayValue,
      atomKind: atomKind,
    ),
  for (final component in components)
    DesyRegistryEntry(
      id: component.id,
      name: component.name,
      folderIds: folderIds,
      folderNames: folderNames,
      builder: (context) => component.preview(
        context,
        DesyWidgetResolver(_bareRegistry(component)),
      ),
      source: component,
      description: component.description,
      component: component,
      atomKind: atomKind,
    ),
];

// `_entriesFor` is only ever called with `components: const []`, so the
// component branch never observes a themed registry. This helper keeps the
// signature self-contained while preserving the widget-returning contract.
DesyRegistry _bareRegistry(DesyRegistryComponent component) =>
    DesyRegistry(
      name: component.name,
      themes: const [DesyTheme(id: 'bare', name: 'Bare', wrap: _bareTheme)],
      components: [component],
    );

Widget _bareTheme(BuildContext context, Widget child) => child;

Widget _effectSpecimen(BuildContext context, DesyEffectEntry effect) =>
    Container(
      width: 148,
      height: 92,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(effect.displayValue),
    );

/// The unit attached to a [DesyNumericEntry].
enum DesyNumberUnit {
  /// Logical Flutter pixels used for layout dimensions.
  dp('dp'),

  /// Scalable pixels used for text dimensions.
  sp('sp'),

  /// Milliseconds used by motion durations.
  milliseconds('ms'),

  /// A dimensionless numeric value.
  unitless('');

  const DesyNumberUnit(this.label);

  /// Display suffix used by the Atlas.
  final String label;
}

/// The semantic role of a numeric measure.
///
/// A measure stays a lightweight, widget-returning primitive, while its role
/// lets the Bench choose an appropriate comparison specimen without guessing
/// from a folder name or token ID.
enum DesyNumericKind {
  /// Space between or inside real layout elements.
  spacing('Spacing'),

  /// An explicit component, icon, or layout dimension.
  size('Sizing'),

  /// A rounded corner on a real consumer surface.
  radius('Shape'),

  /// A border, divider, or other visible line width.
  stroke('Stroke'),

  /// A responsive layout threshold.
  breakpoint('Layout'),

  /// A blend amount such as disabled or scrim opacity.
  opacity('Opacity'),

  /// A discrete elevation or surface depth.
  elevation('Elevation');

  const DesyNumericKind(this.label);

  /// Short human-readable category shown on the Measurements board.
  final String label;
}

/// The direction a numeric layout measure applies to.
enum DesyNumericAxis {
  /// Applies equally in both layout directions.
  both,

  /// Applies along the horizontal axis.
  horizontal,

  /// Applies along the vertical axis.
  vertical,
}

/// Builder for any consumer-owned primitive specimen.
typedef DesyPrimitiveBuilder = Widget Function(BuildContext context);

/// A typed numeric primitive shown in the Atoms atlas.
///
/// The model intentionally covers spacing, radii, sizes, breakpoints, and
/// similar values without requiring a separate Desy class for every number.
class DesyNumericEntry {
  /// Creates a numeric primitive.
  const DesyNumericEntry({
    required this.id,
    required this.name,
    required this.value,
    this.unit = DesyNumberUnit.dp,
    this.kind = DesyNumericKind.spacing,
    this.axis = DesyNumericAxis.both,
    this.group,
    this.description,
    this.builder,
  });

  /// Creates a spacing value used for padding or gaps.
  const DesyNumericEntry.spacing({
    required String id,
    required String name,
    required double value,
    DesyNumericAxis axis = DesyNumericAxis.both,
    String? description,
    DesyPrimitiveBuilder? builder,
  }) : this(
         id: id,
         name: name,
         value: value,
         kind: DesyNumericKind.spacing,
         axis: axis,
         description: description,
         builder: builder,
       );

  /// Creates a fixed visual dimension such as an icon or control size.
  const DesyNumericEntry.size({
    required String id,
    required String name,
    required double value,
    DesyNumericAxis axis = DesyNumericAxis.both,
    String? description,
    DesyPrimitiveBuilder? builder,
  }) : this(
         id: id,
         name: name,
         value: value,
         kind: DesyNumericKind.size,
         axis: axis,
         description: description,
         builder: builder,
       );

  /// Creates a corner-radius measure.
  const DesyNumericEntry.radius({
    required String id,
    required String name,
    required double value,
    String? description,
    DesyPrimitiveBuilder? builder,
  }) : this(
         id: id,
         name: name,
         value: value,
         kind: DesyNumericKind.radius,
         description: description,
         builder: builder,
       );

  /// Creates a responsive threshold in logical Flutter pixels.
  const DesyNumericEntry.breakpoint({
    required String id,
    required String name,
    required double value,
    String? description,
    DesyPrimitiveBuilder? builder,
  }) : this(
         id: id,
         name: name,
         value: value,
         kind: DesyNumericKind.breakpoint,
         description: description,
         builder: builder,
       );

  /// Stable identifier for the entry.
  final String id;

  /// Human-readable primitive name.
  final String name;

  /// Typed source value.
  final double value;

  /// Unit attached to [value].
  final DesyNumberUnit unit;

  /// Semantic meaning used by measurement-specific workbench surfaces.
  final DesyNumericKind kind;

  /// Layout direction when the measure represents spacing or size.
  final DesyNumericAxis axis;

  /// Optional consumer-facing grouping override.
  ///
  /// New declarations should use [kind]; this escape hatch keeps existing
  /// registries source-compatible without forcing a migration.
  final String? group;

  /// Optional display grouping for measurement-specific views.
  String get displayGroup => group ?? kind.label;

  /// Optional usage guidance.
  final String? description;

  /// Optional real consumer specimen for this value.
  final DesyPrimitiveBuilder? builder;

  /// Concise display value.
  String get displayValue =>
      '${value == value.roundToDouble() ? value.toInt() : value}${unit.label.isEmpty ? '' : ' ${unit.label}'}';

  /// Returns a real consumer specimen when supplied, or a neutral value label.
  Widget build(BuildContext context) =>
      builder?.call(context) ?? Text(displayValue, textAlign: TextAlign.center);
}

/// A named motion primitive and a live consumer-owned animation specimen.
class DesyMotionEntry {
  /// Creates a motion primitive.
  const DesyMotionEntry({
    required this.id,
    required this.name,
    this.duration,
    required this.curve,
    required this.builder,
    this.intent = 'Motion',
    this.description,
  });

  /// Stable identifier for the entry.
  final String id;

  /// Human-readable name.
  final String name;

  /// Optional typed duration used by this motion.
  ///
  /// When omitted, synchronized motion surfaces use their global duration.
  final Duration? duration;

  /// Typed curve used by the consumer.
  final Curve curve;

  /// Real consumer animation specimen.
  final DesyPrimitiveBuilder builder;

  /// Optional display metadata for motion-oriented surfaces.
  final String intent;

  /// Optional usage guidance.
  final String? description;

  /// Concise display value.
  String get displayValue => switch (duration) {
    final duration? => '${duration.inMilliseconds} ms · $curve',
    null => 'Global duration · $curve',
  };
}

/// A consumer-owned icon glyph rendered by Flutter's real icon widget.
class DesyIconEntry {
  /// Creates a typed icon primitive.
  const DesyIconEntry({
    required this.id,
    required this.name,
    required this.icon,
    this.description,
    this.value,
    this.semanticLabel,
    this.size,
  });

  /// Stable identifier for the entry.
  final String id;

  /// Human-readable icon name.
  final String name;

  /// Consumer-owned Flutter glyph.
  final IconData icon;

  /// Optional usage guidance.
  final String? description;

  /// Optional source-facing name such as `FLucideIcons.anchor`.
  final String? value;

  /// Accessible meaning announced by assistive technology.
  final String? semanticLabel;

  /// Optional consumer-specified size in logical pixels.
  ///
  /// When omitted, the selected consumer theme's icon size remains in charge.
  final double? size;

  /// Builds the actual consumer icon under the selected consumer theme.
  Widget build(BuildContext context) =>
      Icon(icon, size: size, semanticLabel: semanticLabel ?? name);
}

/// The media type of a consumer-owned asset resource.
enum DesyAssetKind {
  /// A still image such as a logo or illustration.
  image,

  /// An animated GIF image.
  gif,

  /// A video resource.
  video,

  /// An audio resource such as music, speech, or a sound effect.
  audio,
}

/// A consumer-owned image, GIF, video, or audio resource.
class DesyAssetEntry {
  /// Creates an image asset primitive.
  const DesyAssetEntry.image({
    required this.id,
    required this.name,
    required this.image,
    this.group = 'Assets',
    this.description,
    this.value,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticLabel,
  }) : kind = DesyAssetKind.image,
       source = null;

  /// Creates an animated GIF image asset.
  const DesyAssetEntry.gif({
    required this.id,
    required this.name,
    required this.image,
    this.group = 'GIFs',
    this.description,
    this.value,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticLabel,
  }) : kind = DesyAssetKind.gif,
       source = null;

  /// Creates a video resource entry.
  const DesyAssetEntry.video({
    required this.id,
    required this.name,
    required this.source,
    this.group = 'Videos',
    this.description,
    this.value,
    this.semanticLabel,
  }) : kind = DesyAssetKind.video,
       image = null,
       fit = BoxFit.contain,
       alignment = Alignment.center;

  /// Creates an audio resource entry.
  const DesyAssetEntry.audio({
    required this.id,
    required this.name,
    required this.source,
    this.group = 'Sounds',
    this.description,
    this.value,
    this.semanticLabel,
  }) : kind = DesyAssetKind.audio,
       image = null,
       fit = BoxFit.contain,
       alignment = Alignment.center;

  /// Stable identifier for the entry.
  final String id;

  /// Human-readable name.
  final String name;

  /// The resource's media type.
  final DesyAssetKind kind;

  /// The real image provider for [DesyAssetKind.image] and [DesyAssetKind.gif].
  final ImageProvider<Object>? image;

  /// The resource URI for [DesyAssetKind.video] and [DesyAssetKind.audio].
  final Uri? source;

  /// Optional display metadata for asset-oriented surfaces.
  final String group;

  /// Optional usage guidance.
  final String? description;

  /// Optional concise source value.
  final String? value;

  /// How the image is inscribed into its preview bounds.
  final BoxFit fit;

  /// How the image is aligned within its preview bounds.
  final AlignmentGeometry alignment;

  /// Optional accessibility description for the image.
  final String? semanticLabel;

  /// Concise source metadata shown by catalogue and export surfaces.
  String get displayValue => value ?? source?.toString() ?? kind.name;

  /// Renders images directly and a dependency-free resource card for media.
  Widget build(BuildContext context) => switch (kind) {
    DesyAssetKind.image || DesyAssetKind.gif => Image(
      image: image!,
      fit: fit,
      alignment: alignment,
      semanticLabel: semanticLabel,
      gaplessPlayback: kind == DesyAssetKind.gif,
    ),
    DesyAssetKind.video || DesyAssetKind.audio => Semantics(
      label: semanticLabel ?? '$name ${kind.name} resource',
      child: SizedBox(
        width: 220,
        height: 120,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(kind == DesyAssetKind.video ? 'VIDEO' : 'AUDIO'),
              const SizedBox(height: 8),
              Text(
                source.toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  };
}

/// A typed effect that decorates a widget supplied by the consumer.
///
/// Effects remain intentionally narrow: the first supported effect is a list
/// of [BoxShadow] values. Future shaders and widget transforms can add their
/// own typed constructors without turning this into a loose configuration map.
class DesyEffectEntry {
  /// Creates a box-shadow effect.
  DesyEffectEntry.boxShadow({
    required this.id,
    required this.name,
    required List<BoxShadow> shadows,
    this.group = 'Effects',
    this.description,
  }) : shadows = List.unmodifiable(shadows);

  /// Stable identifier for the effect.
  final String id;

  /// Human-readable name.
  final String name;

  /// The consumer-declared shadows applied to a widget.
  final List<BoxShadow> shadows;

  /// Optional display metadata for effect-oriented surfaces.
  final String group;

  /// Optional usage guidance.
  final String? description;

  /// Applies this effect to [child] without recreating the child widget.
  Widget apply(BuildContext context, Widget child) => DecoratedBox(
    decoration: BoxDecoration(boxShadow: shadows),
    child: child,
  );

  /// Concise display value for workbench presentation.
  String get displayValue =>
      '${shadows.length} box shadow${shadows.length == 1 ? '' : 's'}';
}

/// Builder for a real consumer component preview.
typedef DesyPreviewBuilder = Widget Function(BuildContext context);

/// The typed kinds of knob a component can declare through [KnobScope].
enum DesyKnobKind {
  /// A free-form text value.
  string,

  /// A true/false value.
  boolean,

  /// A stable ID selecting another registered component instance.
  widgetInstance,
}

/// A registry-scoped stable ID for a declared component instance.
final class DesyInstanceId {
  /// Creates a stable registry-scoped instance ID.
  const DesyInstanceId(this.value);

  /// The dotted `componentId.instanceId` value.
  final String value;
}

/// One immutable declaration produced while a component's knobs callback runs.
///
/// It is the runtime schema Desy renders in the knob panel and validates
/// against declared instances.
final class KnobDefinition<T extends Object> {
  /// Creates an immutable knob schema entry.
  const KnobDefinition({
    required this.id,
    required this.name,
    required this.kind,
    required this.initial,
    this.options = const [],
  });

  /// Stable knob identifier within a component.
  final String id;

  /// Visible control label.
  final String name;

  /// The typed knob kind selected for the panel.
  final DesyKnobKind kind;

  /// Initial value used by the default preview.
  final T initial;

  /// Registry-scoped instance IDs legal in this composition slot.
  ///
  /// Widget-instance knobs use this as an explicit legal-slot allow-list so a
  /// swap picker offers only meaningful choices; empty means any registered
  /// instance is allowed.
  final List<String> options;
}

/// A typed handle bound to a [KnobDefinition]; reading [value] yields the knob.
final class Knob<T extends Object> {
  const Knob._(this.definition, this.value);

  /// The declared definition this handle is bound to.
  final KnobDefinition<T> definition;

  /// The currently selected value.
  final T value;

  /// Returns an override for this knob when authoring a named instance.
  KnobSetting<T> call(T value) => KnobSetting(definition, value);
}

/// A typed handle that selects a registered component instance by stable ID.
final class WidgetInstanceKnob {
  const WidgetInstanceKnob._(this.definition, this.value, this.widget);

  /// The declared widget-instance definition.
  final KnobDefinition<DesyInstanceId> definition;

  /// The selected registry-scoped instance ID.
  final DesyInstanceId value;

  /// The resolved real widget for the currently selected instance.
  final Widget widget;

  /// Returns an override selecting [registeredInstanceId] for this slot.
  KnobSetting<DesyInstanceId> call(String registeredInstanceId) =>
      KnobSetting(definition, DesyInstanceId(registeredInstanceId));
}

/// A typed knob override contributed by a named component instance.
abstract interface class KnobSettingBase {
  /// The declared definition this override targets.
  KnobDefinition<Object> get definition;

  /// The override value typed against [definition].
  Object get value;
}

/// A strongly typed [KnobSettingBase] produced by [Knob.call].
final class KnobSetting<T extends Object> implements KnobSettingBase {
  /// Creates a typed override for [typedDefinition] with [typedValue].
  const KnobSetting(this.typedDefinition, this.typedValue);

  /// The declared definition targeted by this override.
  final KnobDefinition<T> typedDefinition;

  /// The override value.
  final T typedValue;

  @override
  KnobDefinition<Object> get definition => typedDefinition;
  @override
  Object get value => typedValue;
}

/// The knob-authoring surface passed to a component's knob and instance
/// declarations. Each call both declares the schema and returns a typed handle.
abstract interface class KnobScope {
  /// Declares a text knob and returns its typed handle.
  Knob<String> string(String id, {String? name, required String initial});

  /// Declares a boolean knob and returns its typed handle.
  Knob<bool> boolean(String id, {String? name, required bool initial});

  /// Declares a component-instance knob and returns its typed handle.
  WidgetInstanceKnob widgetInstance(
    String id, {
    String? name,
    required String initial,
    List<String> options = const [],
  });
}

/// The schema-collecting [KnobScope] used while a component is declared.
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
    List<String> options = const [],
  }) {
    if (initial.isNotEmpty &&
        options.isNotEmpty &&
        !options.contains(initial)) {
      throw ArgumentError.value(
        initial,
        'initial',
        'A widget-instance knob initial value must be one of its options.',
      );
    }
    final definition = KnobDefinition(
      id: id,
      name: name ?? _humanize(id),
      kind: DesyKnobKind.widgetInstance,
      initial: DesyInstanceId(initial),
      options: List.unmodifiable(options),
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

  /// The immutable knob schema gathered during declaration.
  List<KnobDefinition<Object>> get definitions =>
      List.unmodifiable(_definitions);
}

/// A [KnobScope] that resolves declared knob values from a component's default,
/// its named-instance overrides, and live workbench edits.
final class ResolvedKnobScope implements KnobScope {
  /// Builds a resolve scope from [definitions] with [overrides] applied.
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

  /// Context used to resolve widget-instance knobs to their real widgets.
  final BuildContext context;

  /// Resolver that builds referenced component instances.
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
    List<String> options = const [],
  }) {
    final knob = _resolve<DesyInstanceId>(id);
    return WidgetInstanceKnob._(
      knob.definition,
      knob.value,
      widgets.resolve(context, knob.value),
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

/// A property documented by a [DesyComponentContract].
class DesyContractProperty {
  /// Creates a documented property.
  const DesyContractProperty({
    required this.name,
    required this.type,
    this.required = false,
    this.description,
  });

  /// Property name in the consuming component API.
  final String name;

  /// Human-readable Dart type.
  final String type;

  /// Whether consumer code must provide the property.
  final bool required;

  /// Optional usage guidance.
  final String? description;
}

/// A named child region documented by a [DesyComponentContract].
class DesyComponentSlot {
  /// Creates a component slot declaration.
  const DesyComponentSlot({
    required this.name,
    required this.accepts,
    this.required = false,
    this.description,
  });

  /// Slot name in the component API.
  final String name;

  /// Accepted widget or component-instance type.
  final String accepts;

  /// Whether the component requires a value in this slot.
  final bool required;

  /// Optional composition guidance.
  final String? description;
}

/// Optional inspectable metadata for a real consumer component.
class DesyComponentContract {
  /// Creates a component contract.
  DesyComponentContract({
    List<DesyContractProperty> properties = const [],
    List<DesyComponentSlot> slots = const [],
    this.guidance,
  }) : properties = List.unmodifiable(properties),
       slots = List.unmodifiable(slots);

  /// Typed public properties of the consumer component.
  final List<DesyContractProperty> properties;

  /// Named composition regions of the consumer component.
  final List<DesyComponentSlot> slots;

  /// Short guidance that does not belong to a single property or slot.
  final String? guidance;
}

/// A named, real component state supplied by the consumer.
class DesyComponentScenario {
  /// Creates a scenario.
  const DesyComponentScenario({
    required this.id,
    required this.name,
    required this.builder,
    this.description,
  });

  /// Stable scenario identifier within a component.
  final String id;

  /// Human-readable state name.
  final String name;

  /// Builds the real consumer component in this state.
  final DesyPreviewBuilder builder;

  /// Optional explanation of the state.
  final String? description;
}

/// Builds the visual treatment shown by a color atlas entry.
typedef DesyColorBuilder = Widget Function(BuildContext context);

/// A consumer-owned visual entry in the color atlas.
///
/// [builder] is deliberately widget-returning so a system can register a
/// simple swatch, a gradient, or an entirely custom visual token without the
/// Bench inventing a second token model.
class DesyColorEntry {
  /// Creates a color atlas entry from a consumer-supplied widget builder.
  const DesyColorEntry({
    required this.id,
    required this.name,
    required this.builder,
    this.value,
    this.description,
  });

  /// Creates a standard, solid color entry.
  factory DesyColorEntry.swatch({
    required String id,
    required String name,
    required Color color,
    String? value,
    String? description,
  }) => DesyColorEntry(
    id: id,
    name: name,
    value:
        value ??
        '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
    description: description,
    builder: (context) => SizedBox(
      width: 240,
      height: 140,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );

  /// Creates a gradient entry while preserving the consumer's exact gradient.
  factory DesyColorEntry.gradient({
    required String id,
    required String name,
    required Gradient gradient,
    String? value,
    String? description,
  }) => DesyColorEntry(
    id: id,
    name: name,
    value: value,
    description: description,
    builder: (context) => SizedBox(
      width: 240,
      height: 140,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );

  /// Stable identifier for the entry.
  final String id;

  /// Human-readable entry name.
  final String name;

  /// A concise source value, where it is useful to show one.
  final String? value;

  /// Guidance on the visual treatment's intended use.
  final String? description;

  /// Renders the consumer's declared visual treatment.
  final DesyColorBuilder builder;
}

/// Builds a real consumer typography specimen for the supplied text.
typedef DesyTypographyBuilder =
    Widget Function(BuildContext context, String text);

/// A consumer-owned text style shown in the typography atlas.
class DesyTypographyEntry {
  /// Creates a typography atlas entry.
  const DesyTypographyEntry({
    required this.id,
    required this.name,
    required this.builder,
    this.value,
    this.description,
    this.sample = 'Design systems stay clear at a glance.',
  });

  /// Stable identifier for the entry.
  final String id;

  /// Human-readable style name.
  final String name;

  /// Renders the supplied text with the consumer's actual typography widget.
  ///
  /// Keeping text as the only content input prevents non-text specimens from
  /// entering the typography atlas while retaining the widget-returning
  /// contract shared by every Desy primitive.
  final DesyTypographyBuilder builder;

  /// A concise display value such as `22 sp / medium`.
  final String? value;

  /// Guidance on the style's intended use.
  final String? description;

  /// Copy used in the per-style specimen row.
  final String sample;
}

/// A reusable application-facing widget supplied by the consumer system.
///
/// A registered component is either a static catalog mapping
/// ([DesyStaticComponent]) or a typed, bound-record component made from an
/// immutable knob schema and one production builder ([DesyComponent]). Every
/// component ultimately returns the consumer's real widget.
abstract class DesyRegistryComponent {
  /// Stable component identifier.
  String get id;

  /// Human-readable component name.
  String get name;

  /// Normalized navigation path derived from the supplied slash syntax.
  String get path;

  /// Parsed path used to derive the component file tree.
  DesyComponentPath get componentPath;

  /// Optional icon used by Desy navigation and component-picking surfaces.
  IconData? get icon;

  /// Optional intent and usage guidance.
  String? get description;

  /// Catalogue category, such as Atom, Molecule, or Component.
  String get category;

  /// Optional accessibility requirement.
  String? get accessibility;

  /// Consumer-owned source path for navigation and review.
  String? get source;

  /// Recommended starting size for this component on the composition canvas.
  Size? get defaultSize;

  /// Optional inspectable API and slot contract for this real widget.
  DesyComponentContract? get contract;

  /// Named real states that can be inspected alongside the default preview.
  List<DesyComponentScenario> get scenarios;

  /// The immutable knob schema Desy renders in the knob panel.
  List<KnobDefinition<Object>> get knobDefinitions;

  /// Stable IDs of the declared named instances.
  List<String> get instanceIds;

  /// Human-readable label for a declared [instanceId].
  String instanceLabel(String instanceId);

  /// Builds a declared named instance through the consumer's real widget.
  Widget buildInstance(
    BuildContext context,
    String instanceId,
    DesyWidgetResolver widgets,
  );

  /// Builds the real widget from live workbench knob [values].
  Widget buildWithValues(
    BuildContext context,
    Map<String, Object> values, {
    required DesyWidgetResolver widgets,
  });

  /// Builds the default/preview form of the component.
  Widget preview(BuildContext context, DesyWidgetResolver widgets);

  /// Declared knob values for [instanceId]: defaults merged with its overrides.
  Map<String, Object> valuesFor(String instanceId) => {
    for (final definition in knobDefinitions) definition.id: definition.initial,
  };

  /// Registry-scoped instance IDs referenced by this instance's widget knobs.
  Iterable<DesyInstanceId> referencesFor(String instanceId);

  /// The stable registry ID of the default instance, when one is declared.
  String? get defaultInstanceId =>
      instanceIds.isEmpty ? null : '$id.${instanceIds.first}';
}

/// A reusable application-facing widget supplied by the consumer system,
/// declared as a stable ID, an immutable typed knob schema, one real build
/// callback, and named instances authored only as typed knob overrides.
final class DesyComponent<K> extends DesyRegistryComponent {
  /// Creates a typed component without a separate schema/wiring declaration.
  ///
  /// [knobs] runs once at declaration time to produce both the immutable knob
  /// schema and the typed bound record `K` used by [build] and [instances].
  factory DesyComponent({
    required String id,
    required String name,
    String path = '/',
    required K Function(KnobScope scope) knobs,
    required Widget Function(BuildContext context, K knobs) build,
    required Map<String, Iterable<KnobSettingBase>> Function(K knobs) instances,
    IconData? icon,
    String? description,
    String category = 'Components',
    String? accessibility,
    String? source,
    Size? defaultSize,
    DesyComponentContract? contract,
    List<DesyComponentScenario> scenarios = const [],
  }) {
    final declaration = DeclarationKnobScope();
    final interface = knobs(declaration);
    final definitions = declaration.definitions;
    final declaredInstances = instances(interface);
    final definitionsById = {for (final definition in definitions) definition.id: definition};

    final overrides = <String, List<KnobSettingBase>>{};
    for (final MapEntry(key: instanceId, value: settings)
        in declaredInstances.entries) {
      final resolved = List<KnobSettingBase>.unmodifiable(settings);
      for (final setting in resolved) {
        if (!identical(definitionsById[setting.definition.id], setting.definition)) {
          throw ArgumentError(
            'Instance $instanceId uses a knob from another component.',
          );
        }
      }
      overrides[instanceId] = resolved;
    }

    return DesyComponent._(
      id: id,
      name: name,
      componentPath: DesyComponentPath.parse(path),
      icon: icon,
      description: description,
      category: category,
      accessibility: accessibility,
      source: source,
      defaultSize: defaultSize,
      contract: contract,
      scenarios: List.unmodifiable(scenarios),
      knobDefinitions: definitions,
      instances: Map.unmodifiable(overrides),
      bind: knobs,
      build: build,
    );
  }

  DesyComponent._({
    required this.id,
    required this.name,
    required this.componentPath,
    required this.icon,
    required this.description,
    required this.category,
    required this.accessibility,
    required this.source,
    required this.defaultSize,
    required this.contract,
    required this.scenarios,
    required this.knobDefinitions,
    required this.instances,
    required K Function(KnobScope scope) bind,
    required Widget Function(BuildContext context, K knobs) build,
  }) : _bind = bind,
       _build = build;

  @override
  final String id;

  @override
  final String name;

  @override
  final DesyComponentPath componentPath;

  @override
  final IconData? icon;

  @override
  final String? description;

  @override
  final String category;

  @override
  final String? accessibility;

  @override
  final String? source;

  @override
  final Size? defaultSize;

  @override
  final DesyComponentContract? contract;

  @override
  final List<DesyComponentScenario> scenarios;

  @override
  final List<KnobDefinition<Object>> knobDefinitions;

  /// Named instance overrides keyed by stable instance ID.
  final Map<String, List<KnobSettingBase>> instances;

  final K Function(KnobScope scope) _bind;
  final Widget Function(BuildContext context, K knobs) _build;

  @override
  String get path => componentPath.value;

  @override
  List<String> get instanceIds => List.unmodifiable(instances.keys);

  @override
  String instanceLabel(String instanceId) => _humanize(instanceId);

  @override
  Widget buildInstance(
    BuildContext context,
    String instanceId,
    DesyWidgetResolver widgets,
  ) {
    final scope = ResolvedKnobScope(
      knobDefinitions,
      instances[instanceId] ?? const [],
      context,
      widgets,
    );
    return _build(context, _bind(scope));
  }

  @override
  Widget buildWithValues(
    BuildContext context,
    Map<String, Object> values, {
    required DesyWidgetResolver widgets,
  }) {
    final overrides = <KnobSettingBase>[
      for (final definition in knobDefinitions)
        if (values.containsKey(definition.id))
          KnobSetting<Object>(definition, _toSettingValue(definition.kind, values[definition.id]!)),
    ];
    final scope = ResolvedKnobScope(knobDefinitions, overrides, context, widgets);
    return _build(context, _bind(scope));
  }

  @override
  Widget preview(BuildContext context, DesyWidgetResolver widgets) {
    final scope = ResolvedKnobScope(knobDefinitions, const [], context, widgets);
    return _build(context, _bind(scope));
  }

  @override
  Map<String, Object> valuesFor(String instanceId) => {
    for (final definition in knobDefinitions)
      definition.id: _knobValue(definition, definition.initial),
    for (final setting in instances[instanceId] ?? const [])
      setting.definition.id: _knobValue(
        setting.definition,
        setting.value,
      ),
  };

  @override
  Iterable<DesyInstanceId> referencesFor(String instanceId) sync* {
    final settings = instances[instanceId] ?? const [];
    for (final definition in knobDefinitions) {
      if (definition.kind != DesyKnobKind.widgetInstance) continue;
      var current = definition.initial as DesyInstanceId;
      for (final setting in settings) {
        if (definition.id == setting.definition.id) {
          current = setting.value as DesyInstanceId;
        }
      }
      yield current;
    }
  }
}

/// A static component whose named instances map directly to widget builders.
final class DesyStaticComponent extends DesyRegistryComponent {
  /// Creates a catalogue component made of static widget instances.
  DesyStaticComponent({
    required this.id,
    required this.name,
    String path = '/',
    required Map<String, WidgetBuilder> instances,
    this.icon,
    this.description,
    this.category = 'Components',
    this.accessibility,
    this.source,
    this.defaultSize,
    this.contract,
    List<DesyComponentScenario> scenarios = const [],
  }) : componentPath = DesyComponentPath.parse(path),
       instanceBuilders = Map.unmodifiable(instances),
       scenarios = List.unmodifiable(scenarios);

  @override
  final String id;

  @override
  final String name;

  @override
  final DesyComponentPath componentPath;

  @override
  final IconData? icon;

  @override
  final String? description;

  @override
  final String category;

  @override
  final String? accessibility;

  @override
  final String? source;

  @override
  final Size? defaultSize;

  @override
  final DesyComponentContract? contract;

  @override
  final List<DesyComponentScenario> scenarios;

  /// Named widget builders keyed by stable instance ID.
  final Map<String, WidgetBuilder> instanceBuilders;

  @override
  String get path => componentPath.value;

  @override
  List<KnobDefinition<Object>> get knobDefinitions => const [];

  @override
  List<String> get instanceIds => List.unmodifiable(instanceBuilders.keys);

  @override
  String instanceLabel(String instanceId) => _humanize(instanceId);

  @override
  Widget buildInstance(
    BuildContext context,
    String instanceId,
    DesyWidgetResolver widgets,
  ) => instanceBuilders[instanceId]!(context);

  @override
  Widget buildWithValues(
    BuildContext context,
    Map<String, Object> values, {
    required DesyWidgetResolver widgets,
  }) => preview(context, widgets);

  @override
  Widget preview(BuildContext context, DesyWidgetResolver widgets) {
    if (instanceBuilders.isEmpty) {
      return buildDesyMissingRegistryWidget(
        registryName: name,
        instanceId: id,
      );
    }
    return instanceBuilders.values.first(context);
  }

  @override
  Iterable<DesyInstanceId> referencesFor(String instanceId) => const [];
}

/// Resolves registered component instances for instance-swap slots without
/// applying the selected theme twice. Runtime guards also cover live edits not
/// present at startup, rendering a diagnostic for unresolved IDs.
final class DesyWidgetResolver {
  /// Creates a resolver over [registry] with the given resolved [ancestors].
  DesyWidgetResolver(this.registry, [Set<String> ancestors = const {}])
    : _ancestors = ancestors;

  /// Registry this resolver resolves instances against.
  final DesyRegistry registry;
  final Set<String> _ancestors;

  /// Builds the component instance identified by registry-scoped [value].
  Widget build(BuildContext context, String value) =>
      _build(context, DesyInstanceId(value));

  /// Builds the component instance identified by a typed [id].
  Widget resolve(BuildContext context, DesyInstanceId id) => _build(context, id);

  Widget _build(BuildContext context, DesyInstanceId id) {
    if (_ancestors.contains(id.value)) {
      return _problem('Cyclic registry instance: ${id.value}');
    }
    final component = _componentFor(id);
    if (component == null) {
      return buildDesyMissingRegistryWidget(
        registryName: registry.name,
        instanceId: id.value,
      );
    }
    final instanceId = id.value.substring(component.id.length + 1);
    return component.buildInstance(
      context,
      instanceId,
      DesyWidgetResolver(registry, {..._ancestors, id.value}),
    );
  }

  // Component IDs may themselves contain dots (for example a namespaced
  // `desy.component.badge`), so the full component prefix is matched before
  // the remaining suffix is treated as the instance ID.
  DesyRegistryComponent? _componentFor(DesyInstanceId id) {
    DesyRegistryComponent? best;
    for (final component in registry.components) {
      if (!id.value.startsWith('${component.id}.')) continue;
      if (best == null || component.id.length > best.id.length) best = component;
    }
    if (best == null) return null;
    final instanceId = id.value.substring(best.id.length + 1);
    return best.instanceIds.contains(instanceId) ? best : null;
  }

  Widget _problem(String message) => Container(
    key: ValueKey(message),
    padding: const EdgeInsets.all(8),
    child: Text(message),
  );
}

/// An experimental, consumer-owned composition built from real widgets.
///
/// This is a small proving ground for larger system examples. It deliberately
/// stores no screen manifest, callbacks, or app logic beyond the consumer's
/// widget builder. The API may evolve while the extension boundary matures.
class DesyShowcase {
  /// Creates an experimental showcase screen.
  const DesyShowcase({
    required this.id,
    required this.name,
    required this.builder,
    this.description,
  });

  /// Stable identifier for navigation and future derived exports.
  final String id;

  /// Human-readable showcase title.
  final String name;

  /// Builds the actual consumer-owned composition.
  final DesyPreviewBuilder builder;

  /// Optional explanation of the pattern demonstrated.
  final String? description;
}

/// A component instance paired with the component that owns its resolution.
///
/// The workbench can list and resolve these references without asking the
/// consumer to duplicate production widget builders.
class DesyRegisteredComponentInstance {
  /// Creates a resolved reference owned by [component].
  DesyRegisteredComponentInstance({
    required this.registry,
    required this.component,
    required this.instanceId,
  });

  /// Registry that owns and resolves this instance.
  final DesyRegistry registry;

  /// Component that owns the instance's knob contract and production builder.
  final DesyRegistryComponent component;

  /// Stable instance ID within the owning component.
  final String instanceId;

  /// Globally stable identifier for composition and future manifests.
  String get id => '${component.id}.$instanceId';

  /// Human-readable component name.
  String get componentName => component.name;

  /// Human-readable instance label.
  String get name => component.instanceLabel(instanceId);

  /// Builds the actual consumer widget in the component's real context.
  Widget build(BuildContext context, {DesyWidgetResolver? widgets}) =>
      component.buildInstance(
        context,
        instanceId,
        widgets ?? registry.widgetBuilder,
      );
}

String _humanize(String id) {
  final words = id.split(RegExp('[-_]'));
  return words
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

/// Normalizes a knob's declared or overridden value into the value-map form:
/// widget-instance knobs surface their stable ID string, other knobs their value.
Object _knobValue(KnobDefinition<Object> definition, Object value) =>
    value is DesyInstanceId ? value.value : value;

/// Converts a value-map entry back into the typed value a knob setting expects.
Object _toSettingValue(DesyKnobKind kind, Object value) =>
    kind == DesyKnobKind.widgetInstance ? DesyInstanceId(value as String) : value;

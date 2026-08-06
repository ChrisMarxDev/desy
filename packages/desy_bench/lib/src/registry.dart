import 'dart:collection';

import 'package:flutter/material.dart';

/// The consumer-owned definition rendered by Desy Bench.
class DesyRegistry {
  /// Creates a design-system registry.
  DesyRegistry({
    required this.name,
    required List<DesyTheme> themes,
    List<DesyToken> tokens = const [],
    List<DesyColorEntry> colors = const [],
    List<DesyTypographyEntry> typography = const [],
    List<DesyNumericEntry> numbers = const [],
    List<DesyMotionEntry> motion = const [],
    List<DesyEffectEntry> effects = const [],
    List<DesyAssetEntry> assets = const [],
    List<DesyComponent> components = const [],
    List<DesyShowcase> showcases = const [],
    List<DesyFolder> folders = const [],
  }) : assert(themes.isNotEmpty, 'A Desy registry needs at least one theme.'),
       themes = List.unmodifiable(themes),
       tokens = List.unmodifiable(tokens),
       colors = List.unmodifiable(colors),
       typography = List.unmodifiable(typography),
       numbers = List.unmodifiable(numbers),
       motion = List.unmodifiable(motion),
       effects = List.unmodifiable(effects),
       assets = List.unmodifiable(assets),
       components = List.unmodifiable(components),
       showcases = List.unmodifiable(showcases),
       folders = List.unmodifiable(folders);

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

  /// Consumer-owned text styles for the typography atlas.
  final List<DesyTypographyEntry> typography;

  /// Typed numeric primitives such as spacing, radius, and breakpoints.
  final List<DesyNumericEntry> numbers;

  /// Motion primitives and their live consumer-owned specimens.
  final List<DesyMotionEntry> motion;

  /// Widget decorators such as consumer-owned shadow recipes.
  final List<DesyEffectEntry> effects;

  /// Consumer-owned image, GIF, video, and audio resources.
  final List<DesyAssetEntry> assets;

  /// Real consumer widgets available in the catalogue.
  final List<DesyComponent> components;

  /// Complete consumer-defined examples rendered by the experimental showcase.
  ///
  /// A showcase is optional and remains a normal widget builder: it does not
  /// create a second screen model or ask consumers to duplicate their system.
  final List<DesyShowcase> showcases;

  /// Nested registry content, shown as folders in Desy Bench.
  ///
  /// Root-level lists remain available for small systems and backward
  /// compatibility. Desy-owned surfaces should use the `all*` accessors when
  /// they need the complete, recursively declared system.
  final List<DesyFolder> folders;

  /// Every token declared at the root or inside a folder.
  List<DesyToken> get allTokens => List.unmodifiable([
    ...tokens,
    for (final folder in folders) ...folder.allTokens,
  ]);

  /// Every visual entry declared at the root or inside a folder.
  List<DesyColorEntry> get allColors => List.unmodifiable([
    ...colors,
    for (final folder in folders) ...folder.allColors,
  ]);

  /// Every typography entry declared at the root or inside a folder.
  List<DesyTypographyEntry> get allTypography => List.unmodifiable([
    ...typography,
    for (final folder in folders) ...folder.allTypography,
  ]);

  /// Every numeric primitive declared at the root or inside a folder.
  List<DesyNumericEntry> get allNumbers => List.unmodifiable([
    ...numbers,
    for (final folder in folders) ...folder.allNumbers,
  ]);

  /// Every motion primitive declared at the root or inside a folder.
  List<DesyMotionEntry> get allMotion => List.unmodifiable([
    ...motion,
    for (final folder in folders) ...folder.allMotion,
  ]);

  /// Every widget effect declared at the root or inside a folder.
  List<DesyEffectEntry> get allEffects => List.unmodifiable([
    ...effects,
    for (final folder in folders) ...folder.allEffects,
  ]);

  /// Every asset primitive declared at the root or inside a folder.
  List<DesyAssetEntry> get allAssets => List.unmodifiable([
    ...assets,
    for (final folder in folders) ...folder.allAssets,
  ]);

  /// Every component declared at the root or inside a folder.
  List<DesyComponent> get allComponents => List.unmodifiable([
    ...components,
    for (final folder in folders) ...folder.allComponents,
  ]);

  /// Every experimental showcase declared by this system.
  List<DesyShowcase> get allShowcases => List.unmodifiable([
    ...showcases,
    for (final folder in folders) ...folder.allShowcases,
  ]);

  /// Every named component instance declared by this system.
  ///
  /// An instance is owned by its [DesyComponent] and can be resolved to the
  /// component's real widget. Workbench composition surfaces use these
  /// references for instance swapping instead of maintaining a second widget
  /// gallery.
  List<DesyRegisteredComponentInstance> get allComponentInstances =>
      List.unmodifiable([
        for (final component in allComponents)
          for (final instance in component.instances)
            DesyRegisteredComponentInstance(
              component: component,
              instance: instance,
            ),
      ]);

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
    for (final folder in folders)
      ...folder.entries(folderIds: [folder.id], folderNames: [folder.name]),
  ]);

  /// Every declared folder, in stable tree order.
  List<DesyFolder> get allFolders =>
      List.unmodifiable([for (final folder in folders) ...folder.allFolders]);

  /// Reports declaration problems without mutating the consumer registry.
  List<DesyRegistryValidationIssue> validate({
    Iterable<String> extensionIds = const [],
  }) => DesyRegistryValidator(this, extensionIds: extensionIds).validate();

  List<DesyRegistryEntry> _rootEntries() => _entriesFor(
    tokens: tokens,
    colors: colors,
    typography: typography,
    numbers: numbers,
    motion: motion,
    effects: effects,
    assets: assets,
    components: components,
  );
}

/// A named, nestable registry branch.
///
/// Folders are structural only: they do not introduce a new design-system
/// taxonomy. Their children remain the same widget-returning Desy primitives.
class DesyFolder {
  /// Creates a folder and its optional nested registry content.
  DesyFolder({
    required this.id,
    required this.name,
    this.description,
    List<DesyToken> tokens = const [],
    List<DesyColorEntry> colors = const [],
    List<DesyTypographyEntry> typography = const [],
    List<DesyNumericEntry> numbers = const [],
    List<DesyMotionEntry> motion = const [],
    List<DesyEffectEntry> effects = const [],
    List<DesyAssetEntry> assets = const [],
    List<DesyComponent> components = const [],
    List<DesyShowcase> showcases = const [],
    List<DesyFolder> children = const [],
  }) : tokens = List.unmodifiable(tokens),
       colors = List.unmodifiable(colors),
       typography = List.unmodifiable(typography),
       numbers = List.unmodifiable(numbers),
       motion = List.unmodifiable(motion),
       effects = List.unmodifiable(effects),
       assets = List.unmodifiable(assets),
       components = List.unmodifiable(components),
       showcases = List.unmodifiable(showcases),
       children = List.unmodifiable(children);

  /// Stable folder identifier.
  final String id;

  /// Display name used by navigation.
  final String name;

  /// Optional explanation of the folder's purpose.
  final String? description;

  /// Tokens directly declared by this folder.
  final List<DesyToken> tokens;

  /// Visual entries directly declared by this folder.
  final List<DesyColorEntry> colors;

  /// Typography entries directly declared by this folder.
  final List<DesyTypographyEntry> typography;

  /// Numeric primitives directly declared by this folder.
  final List<DesyNumericEntry> numbers;

  /// Motion primitives directly declared by this folder.
  final List<DesyMotionEntry> motion;

  /// Widget effects directly declared by this folder.
  final List<DesyEffectEntry> effects;

  /// Asset primitives directly declared by this folder.
  final List<DesyAssetEntry> assets;

  /// Components directly declared by this folder.
  final List<DesyComponent> components;

  /// Complete consumer examples declared in this branch.
  final List<DesyShowcase> showcases;

  /// Nested branches of this folder.
  final List<DesyFolder> children;

  /// Every token in this branch, including descendants.
  List<DesyToken> get allTokens => List.unmodifiable([
    ...tokens,
    for (final folder in children) ...folder.allTokens,
  ]);

  /// Every visual entry in this branch, including descendants.
  List<DesyColorEntry> get allColors => List.unmodifiable([
    ...colors,
    for (final folder in children) ...folder.allColors,
  ]);

  /// Every typography entry in this branch, including descendants.
  List<DesyTypographyEntry> get allTypography => List.unmodifiable([
    ...typography,
    for (final folder in children) ...folder.allTypography,
  ]);

  /// Every numeric primitive in this branch, including descendants.
  List<DesyNumericEntry> get allNumbers => List.unmodifiable([
    ...numbers,
    for (final folder in children) ...folder.allNumbers,
  ]);

  /// Every motion primitive in this branch, including descendants.
  List<DesyMotionEntry> get allMotion => List.unmodifiable([
    ...motion,
    for (final folder in children) ...folder.allMotion,
  ]);

  /// Every widget effect in this branch, including descendants.
  List<DesyEffectEntry> get allEffects => List.unmodifiable([
    ...effects,
    for (final folder in children) ...folder.allEffects,
  ]);

  /// Every asset primitive in this branch, including descendants.
  List<DesyAssetEntry> get allAssets => List.unmodifiable([
    ...assets,
    for (final folder in children) ...folder.allAssets,
  ]);

  /// Every component in this branch, including descendants.
  List<DesyComponent> get allComponents => List.unmodifiable([
    ...components,
    for (final folder in children) ...folder.allComponents,
  ]);

  /// Every showcase in this branch, including descendants.
  List<DesyShowcase> get allShowcases => List.unmodifiable([
    ...showcases,
    for (final folder in children) ...folder.allShowcases,
  ]);

  /// Every folder in this branch, including this folder.
  List<DesyFolder> get allFolders => List.unmodifiable([
    this,
    for (final child in children) ...child.allFolders,
  ]);

  /// Direct artifacts declared by this folder.
  List<DesyRegistryEntry> directEntries({
    required List<String> folderIds,
    required List<String> folderNames,
  }) => List.unmodifiable(
    _entriesFor(
      tokens: tokens,
      colors: colors,
      typography: typography,
      numbers: numbers,
      motion: motion,
      effects: effects,
      assets: assets,
      components: components,
      folderIds: folderIds,
      folderNames: folderNames,
    ),
  );

  /// Direct and nested artifacts with stable folder ancestry.
  List<DesyRegistryEntry> entries({
    required List<String> folderIds,
    required List<String> folderNames,
  }) => List.unmodifiable([
    ...directEntries(folderIds: folderIds, folderNames: folderNames),
    for (final child in children)
      ...child.entries(
        folderIds: [...folderIds, child.id],
        folderNames: [...folderNames, child.name],
      ),
  ]);
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
  }) : folderIds = List.unmodifiable(folderIds),
       folderNames = List.unmodifiable(folderNames);

  /// Stable identifier supplied by the consumer.
  final String id;

  /// Human-readable artifact name.
  final String name;

  /// Stable IDs of the folders containing this artifact, from root to leaf.
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
  final DesyComponent? component;

  /// Typography declaration when this entry represents a text style.
  final DesyTypographyEntry? typography;
}

/// A non-mutating problem found in a consumer declaration.
class DesyRegistryValidationIssue {
  /// Creates a validation issue for [id].
  const DesyRegistryValidationIssue({required this.message, required this.id});

  /// Stable identifier associated with the issue.
  final String id;

  /// Human-readable explanation of the problem.
  final String message;
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
    for (final folder in registry.allFolders) {
      add(folder.id, 'folder');
    }
    for (final entry in registry.allEntries) {
      add(entry.id, 'artifact');
    }
    for (final showcase in registry.allShowcases) {
      add(showcase.id, 'showcase');
    }
    for (final id in extensionIds) {
      add(id, 'extension');
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
  required List<DesyAssetEntry> assets,
  required List<DesyComponent> components,
  List<String> folderIds = const [],
  List<String> folderNames = const [],
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
    ),
  for (final type in typography)
    DesyRegistryEntry(
      id: type.id,
      name: type.name,
      folderIds: folderIds,
      folderNames: folderNames,
      builder: (context) => Text(type.sample, style: type.style(context)),
      source: type,
      description: type.description,
      value: type.value,
      typography: type,
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
    ),
  for (final component in components)
    DesyRegistryEntry(
      id: component.id,
      name: component.name,
      folderIds: folderIds,
      folderNames: folderNames,
      builder: component.preview,
      source: component,
      description: component.description,
      component: component,
    ),
];

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
    required this.duration,
    required this.curve,
    required this.builder,
    this.intent = 'Motion',
    this.description,
  });

  /// Stable identifier for the entry.
  final String id;

  /// Human-readable name.
  final String name;

  /// Typed duration used by the consumer.
  final Duration duration;

  /// Typed curve used by the consumer.
  final Curve curve;

  /// Real consumer animation specimen.
  final DesyPrimitiveBuilder builder;

  /// Optional display metadata for motion-oriented surfaces.
  final String intent;

  /// Optional usage guidance.
  final String? description;

  /// Concise display value.
  String get displayValue => '${duration.inMilliseconds} ms · $curve';
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

/// Builds a real consumer component from the current workbench knob values.
typedef DesyKnobPreviewBuilder =
    Widget Function(BuildContext context, DesyKnobValues values);

/// Values currently selected for a component's declared knobs.
class DesyKnobValues {
  /// Creates values for one component preview.
  DesyKnobValues([Map<String, Object> values = const {}])
    : _values = Map.unmodifiable(values);

  final Map<String, Object> _values;

  /// Whether a value was explicitly supplied for [id].
  bool contains(String id) => _values.containsKey(id);

  /// Returns the strongly typed value stored for [id].
  T value<T extends Object>(String id) => _values[id]! as T;

  /// Returns an immutable view for adapters that need to merge values.
  Map<String, Object> get entries => Map.unmodifiable(_values);

  /// Returns these values with [overrides] taking precedence.
  DesyKnobValues merge(DesyKnobValues overrides) =>
      DesyKnobValues({..._values, ...overrides._values});

  /// Returns a boolean knob value.
  bool boolean(String id) => _values[id]! as bool;

  /// Returns a string knob value.
  String string(String id) => _values[id]! as String;

  /// Returns a selected, real component instance knob value.
  DesyComponentInstance component(String id) =>
      _values[id]! as DesyComponentInstance;
}

/// A serializable control declared by a component contract.
abstract class DesyKnob<T extends Object> {
  /// Creates a knob.
  const DesyKnob({required this.id, required this.name, required this.initial});

  /// Stable knob identifier within a component.
  final String id;

  /// Visible control label.
  final String name;

  /// Initial value used by the preview.
  final T initial;
}

/// A true/false component knob.
class DesyBooleanKnob extends DesyKnob<bool> {
  /// Creates a boolean knob.
  const DesyBooleanKnob({
    required super.id,
    required super.name,
    required super.initial,
  });
}

/// A text component knob.
class DesyStringKnob extends DesyKnob<String> {
  /// Creates a string knob.
  const DesyStringKnob({
    required super.id,
    required super.name,
    required super.initial,
  });
}

/// A real consumer widget offered as a composable knob value.
///
/// Instances make composition visible without serialising widgets or callbacks:
/// the consumer owns each builder and the knob stores only its declared choice.
class DesyComponentInstance {
  /// Creates a named, ready-made widget that a component slot can accept.
  ///
  /// Use [DesyComponentInstance.preset] for an instance that belongs to a
  /// component and is derived from that component's knobs.
  DesyComponentInstance.widget({
    required this.id,
    required this.name,
    required this.builder,
    this.icon,
    this.description,
  }) : knobValues = DesyKnobValues();

  /// Creates a named combination of a component's declared knob values.
  ///
  /// The owning [DesyComponent] resolves this preset through
  /// [DesyComponent.buildInstance], so consumers declare values once instead
  /// of duplicating production widget builders.
  DesyComponentInstance.preset({
    required this.id,
    required this.name,
    this.icon,
    this.description,
    DesyKnobValues? knobValues,
  }) : builder = null,
       knobValues = knobValues ?? DesyKnobValues();

  /// Stable identifier within the owning component or component-instance knob.
  final String id;

  /// Human-readable option name.
  final String name;

  /// Optional icon used when this instance is offered as a swap choice.
  final IconData? icon;

  /// Builds the actual consumer widget placed in a component slot.
  ///
  /// This is available on [widget] instances. Presets are instead resolved by
  /// their owning component, which owns the production widget builder.
  final DesyPreviewBuilder? builder;

  /// Optional explanation of the intended composition.
  final String? description;

  /// Declared knob values for a [preset] instance.
  final DesyKnobValues knobValues;

  /// Whether this instance can be used directly as a component-slot value.
  bool get isWidget => builder != null;

  /// Builds this instance for a component slot.
  ///
  /// Only widget instances are valid [DesyComponentKnob] options. A descriptive
  /// error keeps an accidental preset-only value from silently rendering an
  /// unrelated fallback widget.
  Widget build(BuildContext context) {
    final slotBuilder = builder;
    if (slotBuilder == null) {
      throw StateError(
        'Instance "$id" is a component preset and needs its owning component '
        'to be resolved before it can fill a widget slot.',
      );
    }
    return slotBuilder(context);
  }
}

/// A typed knob that selects one of several real consumer component instances.
class DesyComponentKnob extends DesyKnob<DesyComponentInstance> {
  /// Creates a component-instance knob.
  DesyComponentKnob({
    required super.id,
    required super.name,
    required super.initial,
    required List<DesyComponentInstance> options,
  }) : options = List.unmodifiable(options) {
    if (this.options.isEmpty) {
      throw ArgumentError.value(
        options,
        'options',
        'A component knob needs an option.',
      );
    }
    if (this.options.any((option) => !option.isWidget)) {
      throw ArgumentError.value(
        options,
        'options',
        'A component knob can only contain widget instances.',
      );
    }
    if (!initial.isWidget) {
      throw ArgumentError.value(
        initial,
        'initial',
        'A component knob initial value must be a widget instance.',
      );
    }
    if (!this.options.any((option) => option.id == initial.id)) {
      throw ArgumentError.value(
        initial,
        'initial',
        'A component knob initial value must be one of its options.',
      );
    }
  }

  /// Real widget instances the consumer allows in this composition slot.
  final List<DesyComponentInstance> options;
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

/// Resolves one of the consumer's real text styles under the active theme.
typedef DesyTextStyleBuilder = TextStyle Function(BuildContext context);

/// A consumer-owned text style shown in the typography atlas.
class DesyTypographyEntry {
  /// Creates a typography atlas entry.
  const DesyTypographyEntry({
    required this.id,
    required this.name,
    required this.style,
    this.value,
    this.description,
    this.sample = 'Harbor schedules are clear at a glance.',
  });

  /// Stable identifier for the entry.
  final String id;

  /// Human-readable style name.
  final String name;

  /// Resolves the actual consumer style in the selected theme.
  final DesyTextStyleBuilder style;

  /// A concise display value such as `22 sp / medium`.
  final String? value;

  /// Guidance on the style's intended use.
  final String? description;

  /// Copy used in the per-style specimen row.
  final String sample;
}

/// A reusable application-facing widget supplied by the consumer system.
class DesyComponent {
  /// Creates a catalogue component.
  DesyComponent({
    required this.id,
    required this.name,
    required this.preview,
    this.description,
    this.category = 'Components',
    this.accessibility,
    this.source,
    List<DesyKnob<Object>> knobs = const [],
    this.buildWithKnobs,
    List<DesyComponentInstance> instances = const [],
    this.contract,
    List<DesyComponentScenario> scenarios = const [],
  }) : knobs = List.unmodifiable(knobs),
       instances = List.unmodifiable(instances),
       scenarios = List.unmodifiable(scenarios);

  /// Stable component identifier.
  final String id;

  /// Display name.
  final String name;

  /// Renders the consumer's production widget.
  final DesyPreviewBuilder preview;

  /// Optional intent and usage guidance.
  final String? description;

  /// Catalogue category, such as Atom, Molecule, or Component.
  final String category;

  /// Optional accessibility requirement.
  final String? accessibility;

  /// Consumer-owned source path for navigation and review.
  final String? source;

  /// Controls exposed by this component's live preview.
  final List<DesyKnob<Object>> knobs;

  /// Builds the production component using declared [knobs].
  final DesyKnobPreviewBuilder? buildWithKnobs;

  /// Named, inspectable combinations of this component's declared knobs.
  ///
  /// Instances are optional. They become reusable choices for future screen
  /// composition and component-slot swapping through
  /// [DesyRegistry.allComponentInstances].
  final List<DesyComponentInstance> instances;

  /// Resolves [instance] through this component's production builder.
  ///
  /// A component without a knob builder can still expose a widget instance;
  /// otherwise its normal [preview] is used. This keeps minimal component
  /// registrations free from extra boilerplate.
  Widget buildInstance(BuildContext context, DesyComponentInstance instance) {
    final builder = buildWithKnobs;
    if (builder != null) {
      return builder(
        context,
        DesyKnobValues({
          for (final knob in knobs) knob.id: knob.initial,
        }).merge(instance.knobValues),
      );
    }
    return instance.builder?.call(context) ?? preview(context);
  }

  /// Optional inspectable API and slot contract for this real widget.
  final DesyComponentContract? contract;

  /// Named real states that can be inspected alongside the default preview.
  final List<DesyComponentScenario> scenarios;
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
/// The workbench can list these references in a search dialog and turn one
/// into a slot-compatible instance with [asSlotOption] without making the
/// consumer duplicate its widget builders.
class DesyRegisteredComponentInstance {
  /// Creates a resolved reference owned by [component].
  const DesyRegisteredComponentInstance({
    required this.component,
    required this.instance,
  });

  /// Component that owns the instance's knob contract and production builder.
  final DesyComponent component;

  /// Consumer-declared named instance.
  final DesyComponentInstance instance;

  /// Globally stable identifier for composition and future manifests.
  String get id => '${component.id}.${instance.id}';

  /// Human-readable component name.
  String get componentName => component.name;

  /// Builds the actual consumer widget in the component's real context.
  Widget build(BuildContext context) =>
      component.buildInstance(context, instance);

  /// Converts this registered instance into a valid value for a component slot.
  ///
  /// The returned object carries the original globally stable [id] and defers
  /// widget construction to the owning component.
  DesyComponentInstance asSlotOption() => DesyComponentInstance.widget(
    id: id,
    name: '${component.name} · ${instance.name}',
    description: instance.description,
    builder: build,
  );
}

// The consumer-owned registry graph is Desy's Flutter-native core contract.
import 'dart:collection';

import 'package:flutter/material.dart';

import 'registry_missing_widget.dart';

/// Stable identity for one complete consumer registry.
///
/// It is optional because local workbench use and golden tests need no
/// portable identity. A capability that crosses a repository or process
/// boundary, such as GenUI, requires it and still derives from the complete
/// registry rather than from a second catalogue declaration.
final class DesyRegistryIdentity {
  /// Creates a portable identity for one registry.
  const DesyRegistryIdentity({required this.id, required this.version});

  /// Stable external identity for this registry.
  final String id;

  /// Consumer-owned compatibility version for portable artifacts.
  final String version;
}

/// Optional authored context for the design system represented by a registry.
///
/// Inventory facts and runtime status remain derived by Desy. This profile
/// contains only the purpose, principles, and references that code cannot
/// reliably infer.
final class DesySystemProfile {
  /// Creates an immutable system profile.
  DesySystemProfile({
    required this.id,
    this.summary,
    this.purpose,
    this.heroAssetId,
    List<DesySystemPrinciple> principles = const [],
    List<DesySystemLink> links = const [],
  }) : principles = List.unmodifiable(principles),
       links = List.unmodifiable(links);

  /// Stable identity shared with every other registry declaration.
  final String id;

  /// A short introduction suitable for the registry Home header.
  final String? summary;

  /// Why this system exists and who it serves.
  final String? purpose;

  /// Optional reference to one existing [DesyAssetEntry].
  final String? heroAssetId;

  /// Consumer-authored principles that guide system decisions.
  final List<DesySystemPrinciple> principles;

  /// Useful source, documentation, support, and release destinations.
  final List<DesySystemLink> links;
}

/// One stable design-system principle.
final class DesySystemPrinciple {
  /// Creates a principle with concise operational guidance.
  const DesySystemPrinciple({
    required this.id,
    required this.title,
    required this.guidance,
  });

  /// Stable identity shared with every other registry declaration.
  final String id;

  /// Human-readable principle name.
  final String title;

  /// The behavior or decision this principle asks teams to preserve.
  final String guidance;
}

/// The purpose of a system-profile link.
enum DesySystemLinkRole {
  /// Consumer-owned source repository.
  source,

  /// Maintained system documentation.
  documentation,

  /// Support or contribution destination.
  support,

  /// Release notes or change history.
  releases,

  /// Another useful system destination.
  other;

  /// Human-readable role label.
  String get label => switch (this) {
    source => 'Source',
    documentation => 'Documentation',
    support => 'Support',
    releases => 'Releases',
    other => 'Link',
  };
}

/// One typed external or repository-relative system reference.
final class DesySystemLink {
  /// Creates a system link.
  const DesySystemLink({
    required this.id,
    required this.label,
    required this.uri,
    this.role = DesySystemLinkRole.other,
  });

  /// Stable identity shared with every other registry declaration.
  final String id;

  /// Concise action label.
  final String label;

  /// Destination opened by the workbench.
  final Uri uri;

  /// Semantic purpose used to organize links without parsing labels.
  final DesySystemLinkRole role;
}

/// A built-in, typed atom lane understood by Desy's specialized boards.
enum DesyAtomKind {
  /// Consumer solid-color entries.
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
  effects,

  /// Consumer-owned visual and media resources.
  assets,

  /// Consumer-defined foundational widget instances outside typed lanes.
  custom;

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
    assets => 'Assets',
    custom => 'Custom',
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
    this.identity,
    this.systemProfile,
    List<DesyToken> tokens = const [],
    List<DesyColorEntry> colors = const [],
    List<DesyTypographyEntry> fonts = const [],
    List<DesyNumericEntry> measurements = const [],
    List<DesyMotionEntry> motion = const [],
    List<DesyEffectEntry> effects = const [],
    List<DesyCustomAtom> customAtoms = const [],
    List<DesyIconEntry> icons = const [],
    List<DesyAssetEntry> assets = const [],
    List<DesyRegistryComponent> components = const [],
    List<DesyPrototypeSession> prototypes = const [],
  }) : assert(themes.isNotEmpty, 'A Desy registry needs at least one theme.'),
       themes = List.unmodifiable(themes),
       tokens = List.unmodifiable(tokens),
       colors = List.unmodifiable(colors),
       fonts = List.unmodifiable(fonts),
       measurements = List.unmodifiable(measurements),
       motion = List.unmodifiable(motion),
       effects = List.unmodifiable(effects),
       customAtoms = List.unmodifiable(customAtoms),
       icons = List.unmodifiable(icons),
       assets = List.unmodifiable(assets),
       components = List.unmodifiable(components),
       prototypes = List.unmodifiable(prototypes),
       componentGroups = _buildComponentGroups(components);

  /// Human-readable system name.
  final String name;

  /// Optional portable identity for this complete registry.
  final DesyRegistryIdentity? identity;

  /// Optional consumer-authored context for the registry Home surface.
  final DesySystemProfile? systemProfile;

  /// Theme wrappers supplied by the consumer.
  final List<DesyTheme> themes;

  /// Semantic values used by the consumer system.
  final List<DesyToken> tokens;

  /// Consumer-owned semantic solid colors for the specialized Colors board.
  final List<DesyColorEntry> colors;

  /// Consumer-owned text styles for the specialized Fonts board.
  final List<DesyTypographyEntry> fonts;

  /// Typed numeric primitives for the specialized Measurements board.
  final List<DesyNumericEntry> measurements;

  /// Motion primitives and their live consumer-owned specimens.
  final List<DesyMotionEntry> motion;

  /// Widget decorators such as consumer-owned shadow recipes.
  final List<DesyEffectEntry> effects;

  /// Knobless consumer-owned widget instances in Desy's Custom Atom lane.
  final List<DesyCustomAtom> customAtoms;

  /// Consumer-owned icon glyphs.
  final List<DesyIconEntry> icons;

  /// Consumer-owned packaged image resources.
  final List<DesyAssetEntry> assets;

  /// Real consumer widgets available in the catalogue.
  final List<DesyRegistryComponent> components;

  /// Consumer-owned visual explorations that remain ordinary Flutter code.
  ///
  /// Prototype sessions sit alongside the declared system rather than inside
  /// its component tree. They let a team compare real widget directions before
  /// deciding what belongs in the durable registry.
  final List<DesyPrototypeSession> prototypes;

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

  /// Every consumer-defined custom atom.
  List<DesyCustomAtom> get allCustomAtoms => customAtoms;

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
    if (assets.isNotEmpty) DesyAtomKind.assets,
    if (customAtoms.isNotEmpty) DesyAtomKind.custom,
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
          customAtoms: kind == DesyAtomKind.custom ? customAtoms : const [],
          icons: kind == DesyAtomKind.icons ? icons : const [],
          assets: kind == DesyAtomKind.assets ? assets : const [],
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

  /// Resolves an asset entry by stable ID.
  DesyAssetEntry? asset(String id) {
    for (final asset in assets) {
      if (asset.id == id) return asset;
    }
    return null;
  }

  /// The optional Home hero resolved through the authoritative asset list.
  DesyAssetEntry? get systemHeroAsset {
    final id = systemProfile?.heroAssetId;
    return id == null ? null : asset(id);
  }

  /// Every declared component.
  List<DesyRegistryComponent> get allComponents => components;

  /// Every consumer-declared visual exploration session.
  List<DesyPrototypeSession> get allPrototypes => prototypes;

  /// Finds one prototype session by its stable registry ID.
  DesyPrototypeSession? prototypeSession(String id) {
    for (final session in prototypes) {
      if (session.id == id) return session;
    }
    return null;
  }

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

  /// Every registry widget that can be inserted into a widget-instance slot.
  ///
  /// This is derived from the consumer registry at read time: named component
  /// instances retain their production builders and typed icon entries become
  /// real [Icon] widgets. Composition controls use this one inventory rather
  /// than maintaining a separate picker catalogue.
  List<DesyRegisteredWidgetInstance> get allComponentInstancesWithIcons =>
      List.unmodifiable([
        for (final instance in allComponentInstances)
          DesyRegisteredWidgetInstance.component(instance),
        for (final icon in allIcons) DesyRegisteredWidgetInstance.icon(icon),
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

  /// Finds a component instance or typed icon that can fill a widget slot.
  DesyRegisteredWidgetInstance? resolveWidgetInstance(String id) {
    for (final instance in allComponentInstancesWithIcons) {
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
    customAtoms: const [],
    icons: const [],
    assets: const [],
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

List<DesyComponentGroup> _buildComponentGroups(
  List<DesyRegistryComponent> components,
) {
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
    this.isDark = false,
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
  /// Defaults to `false`. Canvas colors never infer workbench brightness;
  /// consumers opt into dark Desy chrome explicitly. This affects only
  /// Desy-owned chrome; [wrap] still owns the consumer widget's real theme.
  final bool isDark;

  /// The resolved scaffold brightness for this consumer theme.
  bool get usesDarkWorkbench => isDark;
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

/// A consumer-defined foundational visual built from named static instances.
///
/// Use this for atom-like artifacts that Desy cannot classify as color, type,
/// measurement, motion, effect, or icon. A custom atom intentionally has no
/// knobs: each visible form is an explicit, consumer-owned widget instance.
class DesyCustomAtom {
  /// Creates one knobless custom atom with one or more named widget instances.
  DesyCustomAtom({
    required this.id,
    required this.name,
    required Map<String, WidgetBuilder> instances,
    this.description,
  }) : instances = Map.unmodifiable(instances) {
    if (instances.isEmpty) {
      throw ArgumentError.value(
        instances,
        'instances',
        'A custom atom needs at least one named widget instance.',
      );
    }
  }

  /// Stable registry identifier.
  final String id;

  /// Human-readable atom name.
  final String name;

  /// Named real widget instances supplied by the consumer.
  final Map<String, WidgetBuilder> instances;

  /// Optional guidance on the atom's semantic role.
  final String? description;

  /// The first declared instance, used as the compact Atom preview.
  String get defaultInstanceId => instances.keys.first;

  /// Builds the compact preview from the first declared real widget instance.
  Widget preview(BuildContext context) => instances.values.first(context);

  /// Builds a particular declared real widget instance.
  Widget buildInstance(BuildContext context, String instanceId) {
    final builder = instances[instanceId];
    if (builder == null) {
      throw ArgumentError.value(
        instanceId,
        'instanceId',
        'Unknown custom atom instance for "$id".',
      );
    }
    return builder(context);
  }
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

    if (registry.identity case final identity?) {
      if (identity.id.trim().isEmpty) {
        issues.add(
          const DesyRegistryValidationIssue(
            id: 'registry',
            message: 'Registry identity ID must not be empty.',
          ),
        );
      }
      if (identity.version.trim().isEmpty) {
        issues.add(
          DesyRegistryValidationIssue(
            id: identity.id,
            message: 'Registry identity version must not be empty.',
          ),
        );
      }
    }

    if (registry.systemProfile case final profile?) {
      add(profile.id, 'system profile');
      for (final principle in profile.principles) {
        add(principle.id, 'system principle');
      }
      for (final link in profile.links) {
        add(link.id, 'system link');
      }
      if (profile.heroAssetId case final heroId?) {
        if (registry.asset(heroId) == null) {
          issues.add(
            DesyRegistryValidationIssue(
              id: heroId,
              severity: DesyRegistryValidationSeverity.warning,
              message:
                  'System profile "${profile.id}" references unknown hero asset "$heroId".',
            ),
          );
        }
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
    for (final prototypeSession in registry.allPrototypes) {
      add(prototypeSession.id, 'prototype session');
      for (final prototype in prototypeSession.prototypes) {
        add(prototype.id, 'prototype');
      }
    }
    for (final id in extensionIds) {
      add(id, 'extension');
    }
    for (final motion in registry.allMotion) {
      for (final instance in motion.instances) {
        if (registry.resolveComponentInstance(instance.value) != null) {
          continue;
        }
        issues.add(
          DesyRegistryValidationIssue(
            id: instance.value,
            severity: DesyRegistryValidationSeverity.warning,
            message:
                'Motion "${motion.id}" references '
                'unknown component instance "${instance.value}".',
          ),
        );
      }
    }
    for (final component in registry.allComponents) {
      final contextsByReference = <String, List<String>>{};
      void recordReference(DesyInstanceId reference, String context) {
        final contexts = contextsByReference.putIfAbsent(
          reference.value,
          () => [],
        );
        if (!contexts.contains(context)) contexts.add(context);
      }

      for (final definition in component.knobDefinitions) {
        switch (definition.kind) {
          case DesyKnobKind.widgetInstance:
            recordReference(
              definition.initial as DesyInstanceId,
              'default preview',
            );
            break;
          case DesyKnobKind.widgetInstances:
            for (final reference
                in (definition.initial as DesyInstanceIds).values) {
              recordReference(reference, 'default preview');
            }
            break;
          case DesyKnobKind.string:
          case DesyKnobKind.choice:
          case DesyKnobKind.number:
          case DesyKnobKind.boolean:
          case DesyKnobKind.dateTime:
          case DesyKnobKind.color:
          case DesyKnobKind.event:
            break;
        }
        if (definition.kind == DesyKnobKind.widgetInstance ||
            definition.kind == DesyKnobKind.widgetInstances) {
          for (final option in definition.options) {
            recordReference(
              DesyInstanceId(option),
              'knob "${definition.id}" option',
            );
          }
        }
      }
      for (final instanceId in component.instanceIds) {
        for (final reference in component.referencesFor(instanceId)) {
          recordReference(reference, 'instance "$instanceId"');
        }
      }
      for (final entry in contextsByReference.entries) {
        if (registry.resolveWidgetInstance(entry.key) == null) {
          issues.add(
            DesyRegistryValidationIssue(
              id: entry.key,
              severity: DesyRegistryValidationSeverity.warning,
              message:
                  'Component "${component.id}" ${entry.value.join(' and ')} '
                  'references unknown registered widget "${entry.key}".',
            ),
          );
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
  required List<DesyCustomAtom> customAtoms,
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
      builder: color.build,
      source: color,
      description: color.description,
      value: color.displayValue,
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
      builder: item.buildDefault,
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
  for (final atom in customAtoms)
    DesyRegistryEntry(
      id: atom.id,
      name: atom.name,
      folderIds: folderIds,
      folderNames: folderNames,
      builder: atom.preview,
      source: atom,
      description: atom.description,
      value: atom.defaultInstanceId,
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
DesyRegistry _bareRegistry(DesyRegistryComponent component) => DesyRegistry(
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

/// Builds a motion treatment around its supplied child specimen.
typedef DesyMotionBuilder =
    Widget Function(BuildContext context, Widget child, Duration duration);

/// Builds a transition between two real consumer widgets.
///
/// Registered motion surfaces supply the current pair; the consumer keeps
/// ownership of the visual transition and can read [DesyMotionPlaybackScope]
/// for the scrubbed timeline.
typedef DesyMotionTransitionBuilder =
    Widget Function(
      BuildContext context,
      Widget first,
      Widget second,
      Duration duration,
    );

/// A named motion primitive and a live consumer-owned animation specimen.
class DesyMotionEntry {
  /// Creates a motion primitive.
  DesyMotionEntry({
    required this.id,
    required this.name,
    required this.duration,
    required this.curve,
    required this.builder,
    List<DesyInstanceId> instances = const [],
    this.transitionBuilder,
    this.intent = 'Motion',
    this.description,
  }) : instances = List.unmodifiable(instances) {
    if (duration <= Duration.zero) {
      throw ArgumentError.value(
        duration,
        'duration',
        'A motion duration must be greater than zero.',
      );
    }
    final seenIds = <String>{};
    for (final instance in this.instances) {
      if (instance.value.trim().isEmpty) {
        throw ArgumentError.value(
          instance,
          'instances',
          'A motion instance needs a non-empty ID.',
        );
      }
      if (!seenIds.add(instance.value)) {
        throw ArgumentError.value(
          instance,
          'instances',
          'Motion instance IDs must be unique within "$id".',
        );
      }
    }
  }

  /// Stable identifier for the entry.
  final String id;

  /// Human-readable name.
  final String name;

  /// Intended duration for one forward pass of this motion.
  ///
  /// Desy uses this as the initial detail playback duration and passes it to
  /// the consumer builders so the preview reflects the declared treatment.
  final Duration duration;

  /// Typed curve used by the consumer.
  final Curve curve;

  /// Real consumer animation treatment, wrapped around a supplied child.
  final DesyMotionBuilder builder;

  /// Optional consumer-owned transition treatment for a pair of widgets.
  final DesyMotionTransitionBuilder? transitionBuilder;

  /// Whether this motion offers a two-widget transition preview.
  bool get supportsTransition => transitionBuilder != null;

  /// Registry-owned instances used by this animation, in display order.
  ///
  /// These are declaration data, not a user-selectable preview control. When
  /// no instances are declared, Desy supplies two Flutter-logo containers so
  /// every motion remains inspectable.
  final List<DesyInstanceId> instances;

  /// Builds the registry-declared instances, or Desy's two fallback specimens.
  List<Widget> buildInstances(
    BuildContext context, {
    DesyWidgetResolver? widgets,
  }) {
    if (instances.isEmpty) {
      return const [
        _DesyMotionFallbackSpecimen.first(),
        _DesyMotionFallbackSpecimen.second(),
      ];
    }
    return [
      for (final instance in instances)
        widgets?.resolve(context, instance) ??
            buildDesyMissingRegistryWidget(
              registryName: 'Motion instance',
              instanceId: instance.value,
            ),
    ];
  }

  /// Builds the default motion preview for simple registry surfaces.
  Widget buildDefault(BuildContext context, {DesyWidgetResolver? widgets}) =>
      builder(
        context,
        buildInstances(context, widgets: widgets).first,
        duration,
      );

  /// Builds [child] with the consumer-owned motion treatment.
  ///
  /// [previewDuration] lets the detail playback control supply a local
  /// override without changing the immutable declared [duration].
  Widget build(
    BuildContext context,
    Widget child, {
    Duration? previewDuration,
  }) => builder(context, child, previewDuration ?? duration);

  /// Builds a consumer-owned transition from [first] to [second].
  ///
  /// A regular one-child treatment remains useful when no transition was
  /// declared, so the fallback animates the incoming child.
  Widget buildTransition(
    BuildContext context,
    Widget first,
    Widget second, {
    Duration? previewDuration,
  }) =>
      transitionBuilder?.call(
        context,
        first,
        second,
        previewDuration ?? duration,
      ) ??
      builder(context, second, previewDuration ?? duration);

  /// Optional display metadata for motion-oriented surfaces.
  final String intent;

  /// Optional usage guidance.
  final String? description;

  /// Concise display value.
  String get displayValue => '${duration.inMilliseconds} ms · $curve';
}

class _DesyMotionFallbackSpecimen extends StatelessWidget {
  const _DesyMotionFallbackSpecimen._(this.color, {super.key});

  const _DesyMotionFallbackSpecimen.first()
    : this._(
        const Color(0xFF54C5F8),
        key: const ValueKey('motion-fallback-first'),
      );

  const _DesyMotionFallbackSpecimen.second()
    : this._(
        const Color(0xFF7257D9),
        key: const ValueKey('motion-fallback-second'),
      );

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 116,
    height: 116,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const FlutterLogo(size: 56, style: FlutterLogoStyle.markOnly),
  );
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

/// A packaged image that consumers make available through the workbench.
///
/// Its deliberately small contract is a stable ID, filename, Flutter bundle
/// key, and a short note explaining when the resource is appropriate. Desy
/// reads the declared bundle key for previews, clipboard copy, and downloads.
final class DesyAssetEntry {
  /// Creates a packaged image asset declaration.
  const DesyAssetEntry({
    required this.id,
    required this.fileName,
    required this.assetKey,
    required this.description,
  });

  /// Stable identity for links from profiles, extensions, and consumer code.
  final String id;

  /// Filename offered to people downloading the resource.
  final String fileName;

  /// Catalogue label derived directly from [fileName].
  String get name => fileName;

  /// Flutter asset key declared in the consumer application's pubspec.
  final String assetKey;

  /// Concise explanation of when this image is appropriate.
  final String description;

  /// Catalogue value derived directly from [assetKey].
  String get displayValue => assetKey;

  /// MIME type inferred from [fileName] for browser downloads.
  String get mimeType {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'svg' => 'image/svg+xml',
      _ => 'application/octet-stream',
    };
  }

  /// Renders the real bundled image using its native Flutter asset key.
  Widget build(BuildContext context) => Image.asset(
    assetKey,
    fit: BoxFit.contain,
    semanticLabel: fileName,
    errorBuilder: (_, _, _) => const SizedBox.shrink(),
  );
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

  /// One value from a finite ordered list of strings.
  choice,

  /// A finite numeric value with an explicit presentation range.
  number,

  /// A true/false value.
  boolean,

  /// A literal Flutter [DateTime].
  dateTime,

  /// A literal Flutter [Color].
  color,

  /// A stable ID selecting another registered component instance.
  widgetInstance,

  /// An ordered list of registered component instances.
  widgetInstances,

  /// An action emitted by the real component widget.
  event,
}

/// The namespace in which a component-instance reference is resolved.
enum DesyInstanceScope {
  /// A named instance declared by the consumer registry.
  registry,

  /// A component ID owned by an external, live surface.
  surface,
}

/// A stable ID for either a registry instance or a live surface component.
final class DesyInstanceId {
  /// Creates a stable registry-scoped instance ID.
  const DesyInstanceId(this.value) : scope = DesyInstanceScope.registry;

  /// Creates an ID resolved by an external live-surface child builder.
  const DesyInstanceId.surface(this.value) : scope = DesyInstanceScope.surface;

  /// The registry instance ID or live surface component ID.
  final String value;

  /// The namespace that owns [value].
  final DesyInstanceScope scope;
}

/// An immutable ordered selection of registered component instances.
final class DesyInstanceIds {
  /// Creates an immutable instance selection.
  DesyInstanceIds(Iterable<DesyInstanceId> values)
    : values = List.unmodifiable(values);

  /// Selected instance IDs in render order.
  final List<DesyInstanceId> values;
}

/// The opaque action descriptor supplied by an agent-protocol adapter.
///
/// Desy intentionally does not prescribe the descriptor shape. An adapter can
/// store a protocol action ID, a JSON object, or another serializable value.
final class DesyEventBinding {
  /// Creates an event binding for [action].
  const DesyEventBinding([this.action]);

  /// Adapter-owned action descriptor, or null for an unbound preview event.
  final Object? action;
}

/// One event invocation emitted by a component built from catalogue values.
final class DesyEventInvocation {
  /// Creates an immutable invocation.
  DesyEventInvocation({
    required this.knobId,
    required this.action,
    Map<String, Object?> payload = const {},
  }) : payload = Map.unmodifiable(payload);

  /// Stable event-knob ID within the component.
  final String knobId;

  /// Opaque adapter-owned action descriptor.
  final Object? action;

  /// Optional consumer-owned JSON-shaped event data.
  final Map<String, Object?> payload;
}

/// Receives protocol-neutral component event invocations.
abstract interface class DesyEventHost {
  /// Handles one emitted event.
  void emit(DesyEventInvocation invocation);
}

/// Safe event host used by previews that are not attached to an agent runtime.
final class DesyNoopEventHost implements DesyEventHost {
  /// Creates the shared no-op event host.
  const DesyNoopEventHost();

  @override
  void emit(DesyEventInvocation invocation) {}
}

/// One immutable declaration produced while a component's knobs callback runs.
///
/// It is the runtime schema Desy renders in the knob panel and validates
/// against declared instances.
final class KnobDefinition<T extends Object> {
  /// Creates an immutable knob schema entry.
  KnobDefinition({
    required this.id,
    required this.name,
    required this.kind,
    required this.initial,
    this.description,
    List<String> options = const [],
    this.unit,
    this.step,
    this.minimum,
    this.maximum,
  }) : assert(
         kind != DesyKnobKind.number ||
             (unit != null &&
                 step != null &&
                 minimum != null &&
                 maximum != null &&
                 minimum <= maximum &&
                 step > 0),
       ),
       options = List.unmodifiable(options);

  /// Stable knob identifier within a component.
  final String id;

  /// Visible control label.
  final String name;

  /// The typed knob kind selected for the panel.
  final DesyKnobKind kind;

  /// Initial value used by the default preview.
  final T initial;

  /// Optional guidance for humans and catalogue-consuming agents.
  final String? description;

  /// Unit shown beside a numeric value, such as `px`.
  final String? unit;

  /// The amount applied by each numeric step control.
  final double? step;

  /// Inclusive lower bound for a numeric knob.
  final double? minimum;

  /// Inclusive upper bound for a numeric knob.
  final double? maximum;

  /// Legal values for a finite choice or preferred widget-slot choices.
  ///
  /// Choice knobs require a non-empty list. Widget-instance knobs use this as
  /// a preferred section at the top of the picker; the complete registry
  /// inventory remains available below it.
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

/// A typed handle that selects a registered widget by stable ID.
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

/// A typed handle selecting multiple registered widgets.
final class WidgetInstancesKnob {
  const WidgetInstancesKnob._(this.definition, this.value, this.widgets);

  /// The declared multi-instance definition.
  final KnobDefinition<DesyInstanceIds> definition;

  /// Selected registry-scoped instance IDs in render order.
  final DesyInstanceIds value;

  /// Resolved real widgets in the same order as [value].
  final List<Widget> widgets;

  /// Returns an override selecting [registeredInstanceIds] for this slot.
  KnobSetting<DesyInstanceIds> call(Iterable<String> registeredInstanceIds) =>
      KnobSetting(
        definition,
        DesyInstanceIds(registeredInstanceIds.map(DesyInstanceId.new)),
      );
}

/// A typed component event that forwards invocations through [DesyEventHost].
final class DesyEventKnob {
  const DesyEventKnob._(this.definition, this.binding, this._host);

  /// The declared event definition.
  final KnobDefinition<DesyEventBinding> definition;

  /// The adapter-owned binding active for this component build.
  final DesyEventBinding binding;

  final DesyEventHost _host;

  /// Emits this event with optional JSON-shaped [payload].
  void emit([Map<String, Object?> payload = const {}]) => _host.emit(
    DesyEventInvocation(
      knobId: definition.id,
      action: binding.action,
      payload: payload,
    ),
  );
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
  Knob<String> string(
    String id, {
    String? name,
    String? description,
    required String initial,
  });

  /// Declares a finite string choice rendered as a dropdown.
  ///
  /// When [initial] is omitted, the first declared option is selected.
  Knob<String> choice(
    String id, {
    String? name,
    String? description,
    required List<String> options,
    String? initial,
  });

  /// Declares a numeric knob and returns its typed handle.
  Knob<double> number(
    String id, {
    String? name,
    String? description,
    required double initial,
    required String unit,
    required double step,
    double minimum = 0,
    double maximum = 999,
  });

  /// Declares a boolean knob and returns its typed handle.
  Knob<bool> boolean(
    String id, {
    String? name,
    String? description,
    required bool initial,
  });

  /// Declares a literal [DateTime] knob.
  Knob<DateTime> dateTime(
    String id, {
    String? name,
    String? description,
    required DateTime initial,
  });

  /// Declares a literal [Color] knob.
  Knob<Color> color(
    String id, {
    String? name,
    String? description,
    required Color initial,
  });

  /// Declares a widget-instance knob and returns its typed handle.
  WidgetInstanceKnob widgetInstance(
    String id, {
    String? name,
    String? description,
    required String initial,
    List<String> options = const [],
  });

  /// Declares an ordered multi-widget knob and returns its typed handle.
  WidgetInstancesKnob widgetInstances(
    String id, {
    String? name,
    String? description,
    List<String> initial = const [],
    List<String> options = const [],
  });

  /// Declares an event emitted by the component's real widget.
  DesyEventKnob event(String id, {String? name, String? description});
}

/// The schema-collecting [KnobScope] used while a component is declared.
final class DeclarationKnobScope implements KnobScope {
  final List<KnobDefinition<Object>> _definitions = [];

  @override
  Knob<String> string(
    String id, {
    String? name,
    String? description,
    required String initial,
  }) => _register(
    KnobDefinition(
      id: id,
      name: name ?? _humanize(id),
      kind: DesyKnobKind.string,
      initial: initial,
      description: description,
    ),
  );

  @override
  Knob<String> choice(
    String id, {
    String? name,
    String? description,
    required List<String> options,
    String? initial,
  }) {
    if (options.isEmpty) {
      throw ArgumentError.value(
        options,
        'options',
        'A choice knob must declare at least one option.',
      );
    }
    if (options.any((option) => option.isEmpty)) {
      throw ArgumentError.value(
        options,
        'options',
        'Choice knob options must not be empty.',
      );
    }
    if (options.toSet().length != options.length) {
      throw ArgumentError.value(
        options,
        'options',
        'Choice knob options must be unique.',
      );
    }
    final selected = initial ?? options.first;
    if (!options.contains(selected)) {
      throw ArgumentError.value(
        selected,
        'initial',
        'A choice knob initial value must be one of its options.',
      );
    }
    return _register(
      KnobDefinition(
        id: id,
        name: name ?? _humanize(id),
        kind: DesyKnobKind.choice,
        initial: selected,
        description: description,
        options: options,
      ),
    );
  }

  @override
  Knob<double> number(
    String id, {
    String? name,
    String? description,
    required double initial,
    required String unit,
    required double step,
    double minimum = 0,
    double maximum = 999,
  }) => _register(
    KnobDefinition(
      id: id,
      name: name ?? _humanize(id),
      kind: DesyKnobKind.number,
      initial: initial,
      description: description,
      unit: unit,
      step: step,
      minimum: minimum,
      maximum: maximum,
    ),
  );

  @override
  Knob<bool> boolean(
    String id, {
    String? name,
    String? description,
    required bool initial,
  }) => _register(
    KnobDefinition(
      id: id,
      name: name ?? _humanize(id),
      kind: DesyKnobKind.boolean,
      initial: initial,
      description: description,
    ),
  );

  @override
  Knob<DateTime> dateTime(
    String id, {
    String? name,
    String? description,
    required DateTime initial,
  }) => _register(
    KnobDefinition(
      id: id,
      name: name ?? _humanize(id),
      kind: DesyKnobKind.dateTime,
      initial: initial,
      description: description,
    ),
  );

  @override
  Knob<Color> color(
    String id, {
    String? name,
    String? description,
    required Color initial,
  }) => _register(
    KnobDefinition(
      id: id,
      name: name ?? _humanize(id),
      kind: DesyKnobKind.color,
      initial: initial,
      description: description,
    ),
  );

  @override
  WidgetInstanceKnob widgetInstance(
    String id, {
    String? name,
    String? description,
    required String initial,
    List<String> options = const [],
  }) {
    if (options.toSet().length != options.length) {
      throw ArgumentError.value(
        options,
        'options',
        'Widget-instance knob options must be unique.',
      );
    }
    final definition = KnobDefinition(
      id: id,
      name: name ?? _humanize(id),
      kind: DesyKnobKind.widgetInstance,
      initial: DesyInstanceId(initial),
      description: description,
      options: options,
    );
    _addDefinition(definition);
    return WidgetInstanceKnob._(
      definition,
      definition.initial,
      const SizedBox.shrink(),
    );
  }

  @override
  WidgetInstancesKnob widgetInstances(
    String id, {
    String? name,
    String? description,
    List<String> initial = const [],
    List<String> options = const [],
  }) {
    _validateInstanceIds(options, optionKind: 'Widget-instances');
    final definition = KnobDefinition(
      id: id,
      name: name ?? _humanize(id),
      kind: DesyKnobKind.widgetInstances,
      initial: DesyInstanceIds(initial.map(DesyInstanceId.new)),
      description: description,
      options: options,
    );
    _addDefinition(definition);
    return WidgetInstancesKnob._(definition, definition.initial, const []);
  }

  @override
  DesyEventKnob event(String id, {String? name, String? description}) {
    final definition = KnobDefinition(
      id: id,
      name: name ?? _humanize(id),
      kind: DesyKnobKind.event,
      initial: const DesyEventBinding(),
      description: description,
    );
    _addDefinition(definition);
    return DesyEventKnob._(
      definition,
      definition.initial,
      const DesyNoopEventHost(),
    );
  }

  Knob<T> _register<T extends Object>(KnobDefinition<T> definition) {
    _addDefinition(definition);
    return Knob._(definition, definition.initial);
  }

  void _addDefinition(KnobDefinition<Object> definition) {
    if (_definitions.any((existing) => existing.id == definition.id)) {
      throw ArgumentError('Duplicate knob ID ${definition.id}.');
    }
    _definitions.add(definition);
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
    this.events,
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

  /// Host receiving events emitted by the built component.
  final DesyEventHost events;
  final Map<String, KnobDefinition<Object>> _definitions;
  final Map<KnobDefinition<Object>, Object> _values;

  @override
  Knob<String> string(
    String id, {
    String? name,
    String? description,
    required String initial,
  }) => _resolve(id);

  @override
  Knob<String> choice(
    String id, {
    String? name,
    String? description,
    required List<String> options,
    String? initial,
  }) => _resolve(id);

  @override
  Knob<double> number(
    String id, {
    String? name,
    String? description,
    required double initial,
    required String unit,
    required double step,
    double minimum = 0,
    double maximum = 999,
  }) => _resolve(id);

  @override
  Knob<bool> boolean(
    String id, {
    String? name,
    String? description,
    required bool initial,
  }) => _resolve(id);

  @override
  Knob<DateTime> dateTime(
    String id, {
    String? name,
    String? description,
    required DateTime initial,
  }) => _resolve(id);

  @override
  Knob<Color> color(
    String id, {
    String? name,
    String? description,
    required Color initial,
  }) => _resolve(id);

  @override
  WidgetInstanceKnob widgetInstance(
    String id, {
    String? name,
    String? description,
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

  @override
  WidgetInstancesKnob widgetInstances(
    String id, {
    String? name,
    String? description,
    List<String> initial = const [],
    List<String> options = const [],
  }) {
    final knob = _resolve<DesyInstanceIds>(id);
    return WidgetInstancesKnob._(
      knob.definition,
      knob.value,
      List.unmodifiable(
        knob.value.values.map((value) => widgets.resolve(context, value)),
      ),
    );
  }

  @override
  DesyEventKnob event(String id, {String? name, String? description}) {
    final knob = _resolve<DesyEventBinding>(id);
    return DesyEventKnob._(knob.definition, knob.value, events);
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

/// A consumer-owned, semantic solid color in the color atlas.
///
/// Colors are deliberately literal [Color] values. Gradients, shaders, and
/// other paint recipes consume colors but are separate visual treatments; they
/// do not belong in the Colors atom lane.
class DesyColorEntry {
  /// Creates a solid color entry.
  const DesyColorEntry({
    required this.id,
    required this.name,
    required this.color,
    this.description,
  });

  /// Stable identifier for the entry.
  final String id;

  /// Human-readable entry name.
  final String name;

  /// The literal Flutter color this semantic entry resolves to.
  final Color color;

  /// Guidance on the visual treatment's intended use.
  final String? description;

  /// A canonical ARGB representation suitable for display and copy actions.
  String get displayValue =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

  /// Renders this literal color for generic registry preview surfaces.
  Widget build(BuildContext context) => SizedBox(
    width: 240,
    height: 140,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          displayValue,
          key: ValueKey('desy-color-hex-$id'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
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
    DesyWidgetResolver widgets, {
    DesyEventHost events = const DesyNoopEventHost(),
  });

  /// Builds the real widget from live workbench knob [values].
  Widget buildWithValues(
    BuildContext context,
    Map<String, Object> values, {
    required DesyWidgetResolver widgets,
    DesyEventHost events = const DesyNoopEventHost(),
  });

  /// Builds the default/preview form of the component.
  Widget preview(
    BuildContext context,
    DesyWidgetResolver widgets, {
    DesyEventHost events = const DesyNoopEventHost(),
  });

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
  ///
  /// [instances] is optional. Omit it when the component has no named preset
  /// instances; the component's default preview remains available.
  factory DesyComponent({
    required String id,
    required String name,
    String path = '/',
    required K Function(KnobScope scope) knobs,
    required Widget Function(BuildContext context, K knobs) build,
    Map<String, Iterable<KnobSettingBase>> Function(K knobs)? instances,
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
    final declaredInstances =
        instances?.call(interface) ??
        const <String, Iterable<KnobSettingBase>>{};
    final definitionsById = {
      for (final definition in definitions) definition.id: definition,
    };

    final overrides = <String, List<KnobSettingBase>>{};
    for (final MapEntry(key: instanceId, value: settings)
        in declaredInstances.entries) {
      final resolved = List<KnobSettingBase>.unmodifiable(settings);
      final usedDefinitions = <KnobDefinition<Object>>{};
      for (final setting in resolved) {
        if (!identical(
          definitionsById[setting.definition.id],
          setting.definition,
        )) {
          throw ArgumentError(
            'Instance $instanceId uses a knob from another component.',
          );
        }
        if (!usedDefinitions.add(setting.definition)) {
          throw ArgumentError(
            'Instance $instanceId overrides knob '
            '${setting.definition.id} more than once.',
          );
        }
        _validateChoiceOption(
          setting.definition,
          setting.value,
          argumentName: 'instances[$instanceId]',
        );
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
    DesyWidgetResolver widgets, {
    DesyEventHost events = const DesyNoopEventHost(),
  }) {
    final scope = ResolvedKnobScope(
      knobDefinitions,
      instances[instanceId] ?? const [],
      context,
      widgets.withEvents(events),
      events,
    );
    return _build(context, _bind(scope));
  }

  @override
  Widget buildWithValues(
    BuildContext context,
    Map<String, Object> values, {
    required DesyWidgetResolver widgets,
    DesyEventHost events = const DesyNoopEventHost(),
  }) {
    final overrides = <KnobSettingBase>[
      for (final definition in knobDefinitions)
        if (values.containsKey(definition.id))
          KnobSetting<Object>(
            definition,
            _toSettingValue(definition, values[definition.id]!),
          ),
    ];
    final scope = ResolvedKnobScope(
      knobDefinitions,
      overrides,
      context,
      widgets.withEvents(events),
      events,
    );
    return _build(context, _bind(scope));
  }

  @override
  Widget preview(
    BuildContext context,
    DesyWidgetResolver widgets, {
    DesyEventHost events = const DesyNoopEventHost(),
  }) {
    final scope = ResolvedKnobScope(
      knobDefinitions,
      const [],
      context,
      widgets.withEvents(events),
      events,
    );
    return _build(context, _bind(scope));
  }

  @override
  Map<String, Object> valuesFor(String instanceId) => {
    for (final definition in knobDefinitions)
      definition.id: _knobValue(definition, definition.initial),
    for (final setting in instances[instanceId] ?? const [])
      setting.definition.id: _knobValue(setting.definition, setting.value),
  };

  @override
  Iterable<DesyInstanceId> referencesFor(String instanceId) sync* {
    final settings = instances[instanceId] ?? const [];
    for (final definition in knobDefinitions) {
      switch (definition.kind) {
        case DesyKnobKind.widgetInstance:
          var current = definition.initial as DesyInstanceId;
          for (final setting in settings) {
            if (definition.id == setting.definition.id) {
              current = setting.value as DesyInstanceId;
            }
          }
          yield current;
        case DesyKnobKind.widgetInstances:
          var current = definition.initial as DesyInstanceIds;
          for (final setting in settings) {
            if (definition.id == setting.definition.id) {
              current = setting.value as DesyInstanceIds;
            }
          }
          yield* current.values;
        case DesyKnobKind.string:
        case DesyKnobKind.choice:
        case DesyKnobKind.number:
        case DesyKnobKind.boolean:
        case DesyKnobKind.dateTime:
        case DesyKnobKind.color:
        case DesyKnobKind.event:
          break;
      }
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
    DesyWidgetResolver widgets, {
    DesyEventHost events = const DesyNoopEventHost(),
  }) => instanceBuilders[instanceId]!(context);

  @override
  Widget buildWithValues(
    BuildContext context,
    Map<String, Object> values, {
    required DesyWidgetResolver widgets,
    DesyEventHost events = const DesyNoopEventHost(),
  }) => preview(context, widgets, events: events);

  @override
  Widget preview(
    BuildContext context,
    DesyWidgetResolver widgets, {
    DesyEventHost events = const DesyNoopEventHost(),
  }) {
    if (instanceBuilders.isEmpty) {
      return buildDesyMissingRegistryWidget(registryName: name, instanceId: id);
    }
    return instanceBuilders.values.first(context);
  }

  @override
  Iterable<DesyInstanceId> referencesFor(String instanceId) => const [];
}

/// Resolves registered widget instances for instance-swap slots without
/// applying the selected theme twice. Runtime guards also cover live edits not
/// present at startup, rendering a diagnostic for unresolved IDs.
final class DesyWidgetResolver {
  /// Creates a resolver over [registry] with the given resolved [ancestors].
  DesyWidgetResolver(this.registry, [Set<String> ancestors = const {}])
    : _ancestors = ancestors,
      events = const DesyNoopEventHost(),
      _surfaceChildBuilder = null;

  DesyWidgetResolver._(
    this.registry,
    this._ancestors,
    this.events,
    this._surfaceChildBuilder,
  );

  /// Creates a resolver that can compose externally owned surface children.
  ///
  /// Registry-scoped IDs keep using Desy's normal instance resolver. Only
  /// [DesyInstanceId.surface] values are delegated to [buildSurfaceChild].
  DesyWidgetResolver.withSurfaceChildren(
    this.registry, {
    required Widget Function(BuildContext context, String id) buildSurfaceChild,
  }) : _ancestors = const {},
       events = const DesyNoopEventHost(),
       _surfaceChildBuilder = buildSurfaceChild;

  /// Registry this resolver resolves instances against.
  final DesyRegistry registry;

  /// Event host propagated to nested component instances.
  final DesyEventHost events;
  final Set<String> _ancestors;
  final Widget Function(BuildContext context, String id)? _surfaceChildBuilder;

  /// Returns an equivalent resolver that propagates [events] to descendants.
  DesyWidgetResolver withEvents(DesyEventHost events) =>
      identical(this.events, events)
      ? this
      : DesyWidgetResolver._(
          registry,
          _ancestors,
          events,
          _surfaceChildBuilder,
        );

  /// Builds the registered widget identified by registry-scoped [value].
  Widget build(BuildContext context, String value) =>
      _build(context, DesyInstanceId(value));

  /// Builds the registered widget identified by a typed [id].
  Widget resolve(BuildContext context, DesyInstanceId id) =>
      _build(context, id);

  Widget _build(BuildContext context, DesyInstanceId id) {
    if (id.scope == DesyInstanceScope.surface) {
      final builder = _surfaceChildBuilder;
      if (builder == null) {
        return _problem('No live surface resolver for: ${id.value}');
      }
      return builder(context, id.value);
    }
    final icon = _iconFor(id);
    if (icon != null) return icon.build(context);
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
      DesyWidgetResolver._(
        registry,
        {..._ancestors, id.value},
        events,
        _surfaceChildBuilder,
      ),
      events: events,
    );
  }

  DesyIconEntry? _iconFor(DesyInstanceId id) {
    for (final icon in registry.allIcons) {
      if (icon.id == id.value) return icon;
    }
    return null;
  }

  // Component IDs may themselves contain dots (for example a namespaced
  // `desy.component.badge`), so the full component prefix is matched before
  // the remaining suffix is treated as the instance ID.
  DesyRegistryComponent? _componentFor(DesyInstanceId id) {
    DesyRegistryComponent? best;
    for (final component in registry.components) {
      if (!id.value.startsWith('${component.id}.')) {
        continue;
      }
      if (best == null || component.id.length > best.id.length) {
        best = component;
      }
    }
    if (best == null) {
      return null;
    }
    final instanceId = id.value.substring(best.id.length + 1);
    return best.instanceIds.contains(instanceId) ? best : null;
  }

  Widget _problem(String message) => Container(
    key: ValueKey(message),
    padding: const EdgeInsets.all(8),
    child: Text(message),
  );
}

/// A repository-owned session for comparing visual directions before they are
/// accepted as regular design-system components.
class DesyPrototypeSession {
  /// Creates an immutable collection of real Flutter prototype widgets.
  factory DesyPrototypeSession({
    required String id,
    required String name,
    required List<DesyPrototype> prototypes,
    String? description,
  }) => DesyPrototypeSession._(
    id: id,
    name: name,
    prototypes: List.unmodifiable(prototypes),
    description: description,
  );

  const DesyPrototypeSession._({
    required this.id,
    required this.name,
    required this.prototypes,
    this.description,
  });

  /// Stable registry identity for this exploration.
  final String id;

  /// Short name shown in the Prototypes sidebar section.
  final String name;

  /// The comparable directions in this session.
  final List<DesyPrototype> prototypes;

  /// Optional framing for the exploration.
  final String? description;
}

/// One real Flutter direction inside a [DesyPrototypeSession].
class DesyPrototype {
  /// Creates one named prototype backed by a normal Flutter widget builder.
  const DesyPrototype({
    required this.id,
    required this.name,
    required this.builder,
    this.description,
    this.canvasPlacement,
  });

  /// Stable identity used by annotations and future review artifacts.
  final String id;

  /// Human-readable direction name.
  final String name;

  /// Builds the actual repository-owned widget under the active consumer
  /// theme; it is never a serializable widget DSL.
  final DesyPreviewBuilder builder;

  /// Optional explanation of the visual decision being explored.
  final String? description;

  /// Optional starting frame when this direction opens in a collection canvas.
  ///
  /// This is a consumer-declared reading order, not persisted user
  /// arrangement. Omit it to use the canvas's deterministic default grid.
  final DesyCanvasPlacement? canvasPlacement;
}

/// A consumer-declared initial frame for a real preview on a Desy canvas.
///
/// Canvas interaction remains local to the workbench. This value merely gives
/// an authored comparison session a useful first arrangement and logical size.
@immutable
class DesyCanvasPlacement {
  /// Creates an initial frame from a top-left logical [offset] and [size].
  const DesyCanvasPlacement({required this.offset, required this.size});

  /// Top-left canvas coordinate in logical pixels.
  final Offset offset;

  /// Logical constraints supplied to the real preview on first render.
  final Size size;

  /// The initial drag-box rectangle derived from [offset] and [size].
  Rect get rect => offset & size;
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
  Widget build(BuildContext context, {DesyWidgetResolver? widgets}) => component
      .buildInstance(context, instanceId, widgets ?? registry.widgetBuilder);
}

/// A component instance or icon entry that can fill a widget-instance knob.
///
/// It deliberately keeps the original registry declaration attached instead
/// of copying widget builders into a picker-specific model.
class DesyRegisteredWidgetInstance {
  /// Wraps a named component instance.
  const DesyRegisteredWidgetInstance.component(this.componentInstance)
    : iconEntry = null;

  /// Wraps a typed icon entry, which resolves as Flutter's real [Icon].
  const DesyRegisteredWidgetInstance.icon(this.iconEntry)
    : componentInstance = null;

  /// The underlying component instance, when this is a component candidate.
  final DesyRegisteredComponentInstance? componentInstance;

  /// The underlying icon entry, when this is an icon candidate.
  final DesyIconEntry? iconEntry;

  /// Stable ID used by widget-instance knobs.
  String get id => componentInstance?.id ?? iconEntry!.id;

  /// Human-readable label in a composition picker.
  String get name => componentInstance?.name ?? iconEntry!.name;

  /// Optional visual glyph for a picker row.
  IconData? get icon => componentInstance?.component.icon ?? iconEntry?.icon;

  /// Optional consumer-authored usage guidance.
  String? get description =>
      componentInstance?.component.description ?? iconEntry?.description;

  /// Whether this candidate resolves to a typed icon primitive.
  bool get isIcon => iconEntry != null;
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
    switch (value) {
      DesyInstanceId() => value.value,
      DesyInstanceIds() => [for (final id in value.values) id.value],
      DesyEventBinding() => value.action ?? const <String, Object?>{},
      _ => value,
    };

/// Converts a value-map entry back into the typed value a knob setting expects.
Object _toSettingValue(KnobDefinition<Object> definition, Object value) {
  switch (definition.kind) {
    case DesyKnobKind.string:
      if (value is String) return value;
    case DesyKnobKind.choice:
      if (value is String && definition.options.contains(value)) return value;
    case DesyKnobKind.number:
      if (value is num) {
        final number = value.toDouble();
        if (number >= definition.minimum! && number <= definition.maximum!) {
          return number;
        }
      }
    case DesyKnobKind.boolean:
      if (value is bool) return value;
    case DesyKnobKind.dateTime:
      if (value is DateTime) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
    case DesyKnobKind.color:
      if (value is Color) return value;
      if (value is int) return Color(value);
    case DesyKnobKind.widgetInstance:
      if (value is DesyInstanceId) {
        return value;
      }
      if (value is String) {
        final id = DesyInstanceId(value);
        return id;
      }
    case DesyKnobKind.widgetInstances:
      if (value is DesyInstanceIds) {
        return value;
      }
      if (value is Iterable && value.every((item) => item is String)) {
        final ids = DesyInstanceIds(
          value.cast<String>().map(DesyInstanceId.new),
        );
        return ids;
      }
    case DesyKnobKind.event:
      return value is DesyEventBinding ? value : DesyEventBinding(value);
  }
  throw ArgumentError.value(
    value,
    definition.id,
    'Expected a ${definition.kind.name} knob value.',
  );
}

void _validateChoiceOption(
  KnobDefinition<Object> definition,
  Object value, {
  required String argumentName,
}) {
  if (definition.kind != DesyKnobKind.choice) return;
  if (value is! String || !definition.options.contains(value)) {
    throw ArgumentError.value(
      value,
      argumentName,
      'Choice knob values must be included in its options.',
    );
  }
}

void _validateInstanceIds(List<String> options, {required String optionKind}) {
  if (options.toSet().length != options.length) {
    throw ArgumentError.value(
      options,
      'options',
      '$optionKind knob options must be unique.',
    );
  }
}

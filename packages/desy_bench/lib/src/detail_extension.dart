import 'package:flutter/foundation.dart' show immutable, nonVirtual;
import 'package:flutter/widgets.dart';

import 'registry.dart';

/// Optional content mounted inside a component's detail inspector.
///
/// Desy owns placement, section chrome, and lifecycle. An extension supplies
/// only its component-scoped body and may keep ordinary widget-local state.
/// Identity and declaration metadata live in final, non-virtual base storage.
/// Custom subtypes supply them to the const base constructor and cannot replace
/// them with getters derived from mutable collaborators.
@immutable
abstract class DesyDetailExtension {
  /// Creates a detail extension through a small typed declaration.
  const factory DesyDetailExtension.builder({
    required String id,
    required String name,
    String? description,
    DesyDetailExtensionPredicate? appliesTo,
    required DesyDetailExtensionBuilder builder,
  }) = _BuiltDesyDetailExtension;

  /// Creates an extension subtype with custom behavior.
  const DesyDetailExtension({
    required this.id,
    required this.name,
    this.description,
  });

  /// Stable identifier shared with every registry and extension declaration.
  @nonVirtual
  final String id;

  /// Human-readable section heading rendered by the detail host.
  @nonVirtual
  final String name;

  /// Optional section guidance rendered by the detail host.
  @nonVirtual
  final String? description;

  /// Whether this extension should appear for the resolved component.
  ///
  /// Desy's host isolates and reports exceptions thrown synchronously by this
  /// call. It does not intercept failures from widgets returned later by
  /// [build].
  bool appliesTo(DesyDetailExtensionContext context) => true;

  /// Builds the body below Desy's host-owned heading and description.
  ///
  /// Desy's host isolates and reports an exception only when this callback
  /// throws synchronously before returning a widget. Failures thrown later by
  /// that widget or one of its descendants follow Flutter's normal element
  /// error reporting and [ErrorWidget] behavior.
  Widget build(BuildContext context, DesyDetailExtensionContext extension);
}

/// The body builder used by [DesyDetailExtension.builder].
typedef DesyDetailExtensionBuilder =
    Widget Function(BuildContext context, DesyDetailExtensionContext extension);

/// The applicability predicate used by [DesyDetailExtension.builder].
typedef DesyDetailExtensionPredicate =
    bool Function(DesyDetailExtensionContext extension);

@immutable
class _BuiltDesyDetailExtension extends DesyDetailExtension {
  const _BuiltDesyDetailExtension({
    required super.id,
    required super.name,
    required this.builder,
    super.description,
    DesyDetailExtensionPredicate? appliesTo,
  }) : _appliesTo = appliesTo;

  final DesyDetailExtensionPredicate? _appliesTo;
  final DesyDetailExtensionBuilder builder;

  @override
  bool appliesTo(DesyDetailExtensionContext context) =>
      _appliesTo?.call(context) ?? true;

  @override
  Widget build(BuildContext context, DesyDetailExtensionContext extension) =>
      builder(context, extension);
}

/// Read-only component identity and preview context for one detail extension.
///
/// This deliberately exposes no workbench session, router, Beacons, knob map,
/// or panel controller. The context is recreated when the active theme changes.
@immutable
class DesyDetailExtensionContext {
  /// Creates context for one validated component entry.
  ///
  /// [entry] must resolve a component. The component is derived here rather
  /// than accepted separately, so callers cannot construct mismatched target
  /// identity.
  factory DesyDetailExtensionContext({
    required DesyRegistry registry,
    required DesyTheme activeTheme,
    required DesyRegistryEntry entry,
  }) {
    final component = entry.component;
    if (component == null) {
      throw ArgumentError.value(
        entry,
        'entry',
        'A detail extension context requires a resolved component entry.',
      );
    }
    return DesyDetailExtensionContext._(
      registry: registry,
      activeTheme: activeTheme,
      entry: entry,
      component: component,
    );
  }

  const DesyDetailExtensionContext._({
    required this.registry,
    required this.activeTheme,
    required this.entry,
    required this.component,
  });

  /// The consumer-owned registry; extensions must treat it as immutable.
  final DesyRegistry registry;

  /// The consumer theme currently active in Desy Bench.
  final DesyTheme activeTheme;

  /// The resolved registry entry currently open in the detail inspector.
  final DesyRegistryEntry entry;

  /// The non-null component declaration represented by [entry].
  final DesyComponent component;
}

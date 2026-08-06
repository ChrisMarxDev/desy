import 'package:flutter/widgets.dart';

import 'registry.dart';

/// An optional, typed screen mounted below Workspace in Desy Bench.
///
/// Extensions are deliberately UI-only at this boundary. Desy owns routing and
/// the workbench shell, while an extension supplies a single screen that is
/// derived from the consumer-owned registry.
abstract class DesyWorkspaceExtension {
  /// Creates a custom extension through a small typed declaration.
  ///
  /// [icon] is optional. When omitted, Desy uses a neutral Lucide icon in the
  /// Workspace sidebar so an extension never needs to declare presentation
  /// metadata merely to become navigable.
  factory DesyWorkspaceExtension.builder({
    required String id,
    required String name,
    String? description,
    IconData? icon,
    required DesyWorkspaceExtensionBuilder builder,
  }) = _BuiltDesyWorkspaceExtension;

  /// Creates an extension subtype with custom behavior.
  const DesyWorkspaceExtension();

  /// Stable route-safe identifier for this extension.
  String get id;

  /// Human-readable label used in Workspace navigation.
  String get name;

  /// Optional icon used by Desy's navigation shell.
  ///
  /// Desy renders a neutral Lucide fallback when this is omitted.
  IconData? get icon => null;

  /// Optional concise explanation shown by extension-owned UI.
  String? get description => null;

  /// Builds this extension's workspace screen.
  Widget build(BuildContext context, DesyWorkspaceExtensionContext extension);
}

/// The screen builder used by [DesyWorkspaceExtension.builder].
typedef DesyWorkspaceExtensionBuilder =
    Widget Function(
      BuildContext context,
      DesyWorkspaceExtensionContext extension,
    );

class _BuiltDesyWorkspaceExtension extends DesyWorkspaceExtension {
  const _BuiltDesyWorkspaceExtension({
    required this.id,
    required this.name,
    required this.builder,
    this.description,
    this.icon,
  });

  @override
  final String id;

  @override
  final String name;

  @override
  final String? description;

  @override
  final IconData? icon;

  final DesyWorkspaceExtensionBuilder builder;

  @override
  Widget build(BuildContext context, DesyWorkspaceExtensionContext extension) =>
      builder(context, extension);
}

/// Read-only registry access and common rendering helpers for an extension.
///
/// It is recreated when the active preview theme changes, so extension screens
/// can derive their output from the same context as the rest of the bench.
class DesyWorkspaceExtensionContext {
  /// Creates a context for one rendered extension screen.
  const DesyWorkspaceExtensionContext({
    required this.registry,
    required this.activeTheme,
  });

  /// The consumer-owned registry; extensions must treat it as immutable.
  final DesyRegistry registry;

  /// The consumer theme currently active in Desy Bench.
  final DesyTheme activeTheme;

  /// Renders a real consumer widget below the active consumer theme wrapper.
  Widget preview(WidgetBuilder builder) => Builder(
    builder: (context) => activeTheme.wrap(context, Builder(builder: builder)),
  );

  /// Finds a declared component by its stable registry identifier.
  DesyComponent? component(String id) {
    for (final component in registry.allComponents) {
      if (component.id == id) return component;
    }
    return null;
  }

  /// Finds a named component instance by its registry-scoped identifier.
  DesyRegisteredComponentInstance? componentInstance(String id) {
    for (final instance in registry.allComponentInstances) {
      if (instance.id == id) return instance;
    }
    return null;
  }
}

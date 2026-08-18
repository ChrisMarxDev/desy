import 'package:flutter/widgets.dart';

import 'registry.dart';
import 'workbench/workbench_annotation.dart';
import 'workspace_focus.dart';

/// An optional, typed screen exposed as a top-level destination in Desy Bench.
///
/// Extensions are deliberately UI-only at this boundary. Desy owns routing and
/// the workbench shell, while an extension supplies one screen derived from
/// the consumer-owned registry.
abstract class DesyWorkspaceExtension {
  /// Creates a custom extension through a small typed declaration.
  ///
  /// [icon] is optional. When omitted, Desy uses a neutral Lucide icon in the
  /// workbench sidebar so an extension never needs to declare presentation
  /// metadata merely to become navigable.
  factory DesyWorkspaceExtension.builder({
    required String id,
    required String name,
    String? description,
    IconData? icon,
    DesyWorkspaceExtensionPresentation presentation =
        DesyWorkspaceExtensionPresentation.workbench,
    required DesyWorkspaceExtensionBuilder builder,
  }) => _BuiltDesyWorkspaceExtension(
    id: id,
    name: name,
    description: description,
    icon: icon,
    presentation: presentation,
    builder: builder,
  );

  /// Creates an extension subtype with custom behavior.
  const DesyWorkspaceExtension();

  /// Stable route-safe identifier for this extension.
  String get id;

  /// Human-readable label used in top-level workbench navigation.
  String get name;

  /// Optional icon used by Desy's navigation shell.
  ///
  /// Desy renders a neutral Lucide fallback when this is omitted.
  IconData? get icon => null;

  /// Optional concise explanation shown by extension-owned UI.
  String? get description => null;

  /// A compact, repository-native conversation shown in the sidebar footer.
  ///
  /// This is deliberately descriptive rather than a persistence API. The
  /// extension remains the owner of its session state while the workbench can
  /// present the current conversation consistently beside the registry.
  DesyWorkspaceSessionSummary? get currentSession => null;

  /// Whether this screen keeps or replaces the ordinary workbench navigation.
  DesyWorkspaceExtensionPresentation get presentation =>
      DesyWorkspaceExtensionPresentation.workbench;

  /// Builds this extension's workspace screen.
  Widget build(BuildContext context, DesyWorkspaceExtensionContext extension);

  /// Releases extension-owned local resources when the workbench closes.
  ///
  /// Most declarative extensions have nothing to release. A local agent
  /// runtime may override this rather than making a routed screen own a
  /// process that must survive navigation.
  void dispose() {}

  /// Starts a fresh local agent conversation when feedback originates from a
  /// declared registry artifact rather than the active Workshop.
  ///
  /// The default keeps non-agent extensions declarative. Agent extensions may
  /// clear their own resumable process state without exposing it to the shell.
  void startNewAgentSession() {}
}

/// The one active conversation associated with a workspace extension.
///
/// Past-session persistence is intentionally outside this small shell
/// contract. A future repository-backed history can add entries without
/// changing how the workbench identifies the live session.
class DesyWorkspaceSessionSummary {
  /// Creates a compact live-session description.
  const DesyWorkspaceSessionSummary({
    required this.title,
    required this.subtitle,
  });

  /// Short, human-readable conversation title.
  final String title;

  /// Repository or workflow context beneath [title].
  final String subtitle;
}

/// The screen builder used by [DesyWorkspaceExtension.builder].
typedef DesyWorkspaceExtensionBuilder =
    Widget Function(
      BuildContext context,
      DesyWorkspaceExtensionContext extension,
    );

/// How a workspace extension is presented by the Desy shell.
enum DesyWorkspaceExtensionPresentation {
  /// Keep Desy's global sidebar around the extension screen.
  workbench,

  /// Give the extension the complete content area so it can own its workflow.
  standalone,
}

class _BuiltDesyWorkspaceExtension extends DesyWorkspaceExtension {
  _BuiltDesyWorkspaceExtension({
    required this.id,
    required this.name,
    required this.builder,
    this.description,
    this.icon,
    this.presentation = DesyWorkspaceExtensionPresentation.workbench,
  });

  @override
  final String id;

  @override
  final String name;

  @override
  final String? description;

  @override
  final IconData? icon;

  @override
  final DesyWorkspaceExtensionPresentation presentation;

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
    this.focus,
    this.workbenchAnnotations = const [],
    this.pendingAgentRequest = '',
    this.onPendingAgentRequestConsumed,
    this.onExit,
  });

  /// The consumer-owned registry; extensions must treat it as immutable.
  final DesyRegistry registry;

  /// The consumer theme currently active in Desy Bench.
  final DesyTheme activeTheme;

  /// Stable current workbench context resolved from the same live registry.
  final DesyWorkspaceFocus? focus;

  /// Global shell feedback committed during the current local workbench
  /// session. Extensions receive immutable values, never mutable shell state.
  final List<DesyWorkbenchAnnotation> workbenchAnnotations;

  /// Ephemeral first request supplied by the Registry Spine home state.
  final String pendingAgentRequest;

  /// Clears [pendingAgentRequest] after an extension adopts it.
  final VoidCallback? onPendingAgentRequestConsumed;

  /// Shared structured hand-off for a local coding-agent runtime.
  ///
  /// Extensions receive a fallback focus only when they are rendered outside
  /// the standard workbench shell, which keeps their minimal test harnesses
  /// and custom hosts useful without introducing a second registry source.
  DesyWorkspaceAgentBrief get agentBrief => DesyWorkspaceAgentBrief(
    focus:
        focus ??
        DesyWorkspaceFocus.resolve(
          registry: registry,
          activeTheme: activeTheme,
          route: 'extension',
        ),
    annotations: workbenchAnnotations,
  );

  /// Returns from a standalone extension to the ordinary Desy workspace.
  final VoidCallback? onExit;

  /// Renders a real consumer widget below the active consumer theme wrapper.
  Widget preview(WidgetBuilder builder) => Builder(
    builder: (context) => activeTheme.wrap(context, Builder(builder: builder)),
  );

  /// Finds a declared component by its stable registry identifier.
  DesyRegistryComponent? component(String id) {
    for (final component in registry.allComponents) {
      if (component.id == id) return component;
    }
    return null;
  }

  /// Finds a named component instance by its registry-scoped identifier.
  DesyRegisteredComponentInstance? componentInstance(String id) {
    return registry.resolveComponentInstance(id);
  }
}

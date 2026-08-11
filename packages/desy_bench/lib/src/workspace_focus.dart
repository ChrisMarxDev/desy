import 'registry.dart';
import 'workbench/workbench_annotation.dart';

/// Read-only context for the artifact currently being considered in Desy.
///
/// A focus is derived from the live registry and route; it never mirrors the
/// registry in another mutable catalogue. It is safe to pass to workspace
/// extensions and local coding-agent runtimes.
class DesyWorkspaceFocus {
  /// Creates a resolved focus for one workbench surface.
  const DesyWorkspaceFocus({
    required this.route,
    required this.registryName,
    required this.themeId,
    required this.themeName,
    this.artifact,
  });

  /// Current routed workbench surface.
  final String route;

  /// Consumer registry that remains authoritative for this work.
  final String registryName;

  /// Stable active consumer-theme ID.
  final String themeId;

  /// Human-readable active consumer-theme name.
  final String themeName;

  /// Resolved registry artifact, if the route addresses one.
  final DesyWorkspaceArtifactFocus? artifact;

  /// A short human-readable summary for an agent rail.
  String get summary => artifact == null
      ? '$registryName · $themeName'
      : '${artifact!.name} · $themeName';

  /// Builds focus from the app-wide consumer registry and current route.
  factory DesyWorkspaceFocus.resolve({
    required DesyRegistry registry,
    required DesyTheme activeTheme,
    required String route,
    String? artifactId,
  }) {
    final entry = artifactId == null ? null : registry.resolve(artifactId);
    return DesyWorkspaceFocus(
      route: route,
      registryName: registry.name,
      themeId: activeTheme.id,
      themeName: activeTheme.name,
      artifact: entry == null
          ? null
          : DesyWorkspaceArtifactFocus.fromEntry(entry),
    );
  }
}

/// The small, stable artifact slice that a coding agent needs for orientation.
class DesyWorkspaceArtifactFocus {
  /// Creates resolved registry-artifact context.
  const DesyWorkspaceArtifactFocus({
    required this.id,
    required this.name,
    required this.path,
    this.description,
  });

  /// Stable registry identity.
  final String id;

  /// Human-readable registry name.
  final String name;

  /// Canonical registry path.
  final String path;

  /// Optional consumer-provided intent or description.
  final String? description;

  /// Resolves the stable presentation fields from a live registry entry.
  factory DesyWorkspaceArtifactFocus.fromEntry(DesyRegistryEntry entry) =>
      DesyWorkspaceArtifactFocus(
        id: entry.id,
        name: entry.name,
        path: entry.component?.componentPath.value ?? entry.path,
        description: entry.component?.description,
      );
}

/// Deterministic context sent with every local coding-agent turn.
///
/// The compact [summary] belongs in the UI; [toMarkdown] is intentionally
/// explicit and stable enough to copy into logs, prompts, or a later CLI.
class DesyWorkspaceAgentBrief {
  /// Creates one immutable agent hand-off.
  const DesyWorkspaceAgentBrief({
    required this.focus,
    required this.annotations,
  });

  /// Current live registry and route focus.
  final DesyWorkspaceFocus focus;

  /// Shell-owned committed feedback for the active local session.
  final List<DesyWorkbenchAnnotation> annotations;

  /// One-line summary for a conversation rail.
  String get summary => focus.summary;

  /// Renders a predictable, concise context preface for a coding agent.
  String toMarkdown() => [
    'Desy workspace brief:',
    '- Registry: ${focus.registryName}',
    '- Route: ${focus.route}',
    '- Theme: ${focus.themeName} (${focus.themeId})',
    if (focus.artifact case final artifact?) ...[
      '- Focused registry artifact: ${artifact.id} — ${artifact.name}',
      '- Registry path: ${artifact.path}',
      if (artifact.description case final description?)
        '- Declared intent: $description',
    ] else
      '- Focused registry artifact: none',
    '- Committed annotations: ${annotations.length}',
  ].join('\n');
}

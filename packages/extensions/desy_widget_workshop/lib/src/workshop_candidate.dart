import 'package:flutter/widgets.dart';

/// One ordinary Flutter implementation shown in a Desy workshop.
class DesyWorkshopCandidate {
  /// Creates a candidate with stable feedback identity and a real widget.
  factory DesyWorkshopCandidate({
    required String id,
    required String title,
    required String description,
    required WidgetBuilder builder,
    List<DesyWorkshopCandidateComponent> components = const [],
  }) => DesyWorkshopCandidate._(
    id: id,
    title: title,
    description: description,
    builder: builder,
    components: List.unmodifiable(components),
  );

  const DesyWorkshopCandidate._({
    required this.id,
    required this.title,
    required this.description,
    required this.builder,
    required this.components,
  });

  /// Stable identity carried through selection and agent feedback.
  final String id;

  /// Short name for this design direction.
  final String title;

  /// Concise explanation of what makes this direction distinct.
  final String description;

  /// Builds the actual Flutter widget under the active consumer theme.
  final WidgetBuilder builder;

  /// Constituent parts explored after this direction has been selected.
  ///
  /// The Workshop deliberately hides these during wide exploration. Registry
  /// parts resolve through Desy's live knob-aware widget resolver; prototype
  /// parts remain ordinary repository-owned Flutter builders.
  final List<DesyWorkshopCandidateComponent> components;
}

/// One constituent part of a selected Workshop proposal.
@immutable
class DesyWorkshopCandidateComponent {
  /// Creates a new Flutter part that is still being prototyped.
  const DesyWorkshopCandidateComponent.prototype({
    required this.id,
    required this.title,
    required this.description,
    required WidgetBuilder prototypeBuilder,
  }) : builder = prototypeBuilder,
       registryInstanceId = null;

  /// References an existing component instance from the live Desy registry.
  ///
  /// Its name, widget, knob composition, and source of truth all remain owned
  /// by the registry. Workshop declarations store only the stable instance ID.
  const DesyWorkshopCandidateComponent.registry({required String instanceId})
    : id = instanceId,
      title = null,
      description = null,
      builder = null,
      registryInstanceId = instanceId;

  /// Stable identity within the selected proposal.
  final String id;

  /// Human-readable name for a new prototype part.
  final String? title;

  /// Purpose of a new prototype part.
  final String? description;

  /// Real Flutter builder for a new prototype part.
  final WidgetBuilder? builder;

  /// Stable registry-scoped component instance ID for an existing part.
  final String? registryInstanceId;

  /// Whether this part resolves from the consumer's live registry.
  bool get isInRegistry => registryInstanceId != null;
}

/// Returns the current hot-reloadable candidate declarations.
typedef DesyWorkshopCandidatesBuilder = List<DesyWorkshopCandidate> Function();

/// Debug-time Dart creation site reported by Flutter's widget inspector.
@immutable
class DesyWorkshopSourceLocation {
  /// Creates a source anchor using one-based line and column numbers.
  const DesyWorkshopSourceLocation({
    required this.uri,
    required this.line,
    required this.column,
    this.name,
  }) : assert(line > 0),
       assert(column > 0);

  /// Parses Flutter Inspector's `creationLocation` JSON payload.
  factory DesyWorkshopSourceLocation.fromInspectorJson(
    Map<Object?, Object?> json,
  ) {
    final file = json['file'];
    final line = json['line'];
    final column = json['column'];
    if (file is! String || line is! int || column is! int) {
      throw const FormatException('Invalid Flutter creation location.');
    }
    return DesyWorkshopSourceLocation(
      uri: Uri.parse(file),
      line: line,
      column: column,
      name: json['name'] as String?,
    );
  }

  /// Source URI supplied by Flutter, normally an absolute `file:` URI.
  final Uri uri;

  /// One-based Dart source line.
  final int line;

  /// One-based Dart source column.
  final int column;

  /// Optional compiler-reported parameter or function name.
  final String? name;

  /// Full path or URI suitable for coding-agent context.
  String get sourcePath => uri.scheme == 'file' ? uri.toFilePath() : '$uri';

  /// Compact source anchor suitable for the Workshop UI.
  String get displayLabel {
    final segments = uri.pathSegments;
    final fileName = segments.isEmpty ? sourcePath : segments.last;
    return '$fileName:$line:$column';
  }

  /// Complete source anchor used for best-effort widget identity.
  String get reference => '$sourcePath:$line:$column';
}

/// One exact widget instance selected inside a Workshop candidate preview.
@immutable
class DesyWorkshopWidgetTarget {
  /// Creates inspected-widget context for feedback and coding-agent prompts.
  const DesyWorkshopWidgetTarget({
    required this.candidateId,
    required this.widgetType,
    required this.widgetPath,
    required this.description,
    required this.bounds,
    this.sourceLocation,
    this.widgetKey,
  });

  /// Candidate containing the selected widget.
  final String candidateId;

  /// Runtime type of the nearest locally created widget.
  final String widgetType;

  /// Best-effort locally created widget ancestry within the preview.
  final String widgetPath;

  /// Concise semantic description, such as `Text("Continue")`.
  final String description;

  /// Logical bounds within the candidate preview.
  final Rect bounds;

  /// Debug-time Dart creation site, when Flutter reports one.
  final DesyWorkshopSourceLocation? sourceLocation;

  /// Explicit Flutter key, when the selected widget declares one.
  final String? widgetKey;

  /// Human-readable identity led by semantics instead of widget ancestry.
  String get displayLabel =>
      description == widgetType ? widgetType : description;

  /// Ephemeral identity used to group feedback during this Workshop session.
  String get feedbackId => [
    candidateId,
    if (widgetKey case final key?) 'key=$key',
    if (sourceLocation case final location?) location.reference else widgetPath,
    description,
    bounds.left.round(),
    bounds.top.round(),
  ].join(':');
}

/// One locally committed annotation attached to an inspected widget.
@immutable
class DesyWorkshopAnnotation {
  /// Creates a structured annotation for a coding-agent iteration.
  const DesyWorkshopAnnotation({
    required this.id,
    required this.target,
    required this.comment,
  });

  /// Monotonic identity within the current Workshop session.
  final int id;

  /// Exact widget context captured when this annotation was committed.
  final DesyWorkshopWidgetTarget target;

  /// Human feedback attached to [target].
  final String comment;
}

/// Repository-owned inputs needed by the local hot-reload workshop.
class DesyWidgetWorkshopConfiguration {
  /// Creates a repository-native workshop configuration.
  const DesyWidgetWorkshopConfiguration({
    required this.projectDirectory,
    required this.candidateSourcePath,
    required this.candidates,
    this.flutterPidFile = 'build/desy_workshop_hot_reload.pid',
    this.codexExecutable = 'codex',
    this.initialPrompt = '',
  });

  /// Working directory used for the local coding-agent process.
  final String projectDirectory;

  /// Repository-relative Dart proposal entry point used for hot reload.
  ///
  /// This locates the current Workshop candidates; it does not restrict the
  /// coding agent from updating the consumer's actual design-system files.
  final String candidateSourcePath;

  /// PID file written by the resident Flutter tool.
  final String flutterPidFile;

  /// Codex CLI executable launched by the local Workshop runtime.
  ///
  /// The default resolves `codex` from the Desy process environment. A custom
  /// path is useful for installations that do not expose it on that PATH.
  final String codexExecutable;

  /// Supplies candidates from normal Dart code on every rebuild.
  final DesyWorkshopCandidatesBuilder candidates;

  /// Initial request shown in a newly opened workshop.
  final String initialPrompt;
}

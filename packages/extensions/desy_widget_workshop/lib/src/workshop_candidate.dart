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

  /// Stable identity named in agent feedback.
  final String id;

  /// Short name for this design direction.
  final String title;

  /// Concise explanation of what makes this direction distinct.
  final String description;

  /// Builds the actual Flutter widget under the active consumer theme.
  final WidgetBuilder builder;

  /// Constituent parts explored after this direction becomes the only proposal.
  ///
  /// The Workshop deliberately hides these during wide exploration. Registry
  /// parts resolve through Desy's live knob-aware widget resolver; prototype
  /// parts remain ordinary repository-owned Flutter builders.
  final List<DesyWorkshopCandidateComponent> components;
}

/// One constituent part of a Workshop proposal that has been narrowed to.
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

  /// Stable identity within the proposal.
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

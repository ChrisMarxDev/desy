import 'package:flutter/widgets.dart';

/// One ordinary Flutter implementation shown in a Desy workshop.
class DesyWorkshopCandidate {
  /// Creates a candidate with stable feedback identity and a real widget.
  const DesyWorkshopCandidate({
    required this.id,
    required this.title,
    required this.description,
    required this.builder,
  });

  /// Stable identity carried through selection and agent feedback.
  final String id;

  /// Short name for this design direction.
  final String title;

  /// Concise explanation of what makes this direction distinct.
  final String description;

  /// Builds the actual Flutter widget under the active consumer theme.
  final WidgetBuilder builder;
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
    this.initialPrompt =
        'Create another implementation that develops the strongest selected '
        'direction.',
  });

  /// Working directory used for the local coding-agent process.
  final String projectDirectory;

  /// Repository-relative Dart file the agent is allowed to edit.
  final String candidateSourcePath;

  /// PID file written by the resident Flutter tool.
  final String flutterPidFile;

  /// Supplies candidates from normal Dart code on every rebuild.
  final DesyWorkshopCandidatesBuilder candidates;

  /// Initial request shown in a newly opened workshop.
  final String initialPrompt;
}

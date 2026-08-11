import 'package:flutter/foundation.dart';
import 'package:desy_bench/desy_bench.dart';

import 'workshop_candidate.dart';
import 'workshop_runtime_stub.dart'
    if (dart.library.io) 'workshop_runtime_io.dart'
    as platform;

/// Creates the platform implementation without making the UI platform-specific.
DesyWorkshopRuntime createDesyWorkshopRuntime(
  DesyWidgetWorkshopConfiguration configuration,
) => platform.createDesyWorkshopRuntime(configuration);

/// Local process and hot-reload boundary used by the Workshop UI.
abstract class DesyWorkshopRuntime extends ChangeNotifier {
  /// Creates a runtime with the repository configuration it must respect.
  DesyWorkshopRuntime(this.configuration);

  /// Repository and source boundary for this runtime.
  final DesyWidgetWorkshopConfiguration configuration;

  /// Whether the current platform can launch a local coding agent.
  bool get supported;

  /// Whether a coding-agent process is active.
  bool get running;

  /// Current user request.
  String get prompt;

  /// Human-readable activity for the current session.
  List<String> get logs;

  /// Persisted Codex thread continued by subsequent Workshop turns.
  String? get sessionId;

  /// Whether the current request may be submitted.
  bool get canRun => supported && !running && prompt.trim().isNotEmpty;

  /// Updates the next request.
  void setPrompt(String value);

  /// Clears the resumable coding-agent conversation for a distinct registry
  /// feedback thread. The active process, if any, is never interrupted.
  void startNewSession();

  /// Runs the coding agent with the numbered proposal context.
  Future<void> run({
    required List<DesyWorkshopCandidate> candidates,
    required DesyWorkspaceAgentBrief agentBrief,
  });

  /// Signals the resident Flutter tool to hot reload.
  Future<void> requestHotReload();

  /// Records that Flutter completed a reload and preserved the workshop.
  void noteReloadCompleted(int count);

  /// Stops the active coding-agent process when supported.
  void cancel();
}

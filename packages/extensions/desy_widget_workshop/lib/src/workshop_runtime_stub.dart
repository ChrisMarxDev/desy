import 'workshop_candidate.dart';
import 'workshop_runtime.dart';

/// Creates a preview-only runtime on platforms without local processes.
DesyWorkshopRuntime createDesyWorkshopRuntime(
  DesyWidgetWorkshopConfiguration configuration,
) => _UnsupportedWorkshopRuntime(configuration);

class _UnsupportedWorkshopRuntime extends DesyWorkshopRuntime {
  _UnsupportedWorkshopRuntime(super.configuration)
    : _prompt = configuration.initialPrompt;

  final List<String> _logs = const [
    'The live coding runtime is available in the Desy macOS development app.',
    'Registry previews remain available on this platform.',
  ];
  String _prompt;

  @override
  bool get supported => false;

  @override
  bool get running => false;

  @override
  String get prompt => _prompt;

  @override
  List<String> get logs => _logs;

  @override
  String? get sessionId => null;

  @override
  void setPrompt(String value) {
    _prompt = value;
    notifyListeners();
  }

  @override
  Future<void> run({
    required List<DesyWorkshopCandidate> candidates,
    required Set<String> selectedCandidateIds,
    required List<DesyWorkshopAnnotation> annotations,
  }) async {}

  @override
  Future<void> requestHotReload() async {}

  @override
  void noteReloadCompleted(int count) {}

  @override
  void cancel() {}
}

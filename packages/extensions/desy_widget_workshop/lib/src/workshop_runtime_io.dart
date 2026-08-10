import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'workshop_candidate.dart';
import 'workshop_runtime.dart';

/// Creates the local-process runtime on Dart IO platforms.
DesyWorkshopRuntime createDesyWorkshopRuntime(
  DesyWidgetWorkshopConfiguration configuration,
) => _IoWorkshopRuntime(configuration);

class _IoWorkshopRuntime extends DesyWorkshopRuntime {
  _IoWorkshopRuntime(super.configuration)
    : _prompt = configuration.initialPrompt {
    _append('Ready. Select implementations and describe the next iteration.');
  }

  final _logs = <String>[];
  final _stderrTail = <String>[];
  Process? _process;
  String? _sessionId;
  late String _prompt;
  var _running = false;
  var _disposed = false;

  @override
  bool get supported => Platform.isMacOS || Platform.isLinux;

  @override
  bool get running => _running;

  @override
  String get prompt => _prompt;

  @override
  List<String> get logs => List.unmodifiable(_logs);

  @override
  String? get sessionId => _sessionId;

  @override
  void setPrompt(String value) {
    _prompt = value;
    _notify();
  }

  @override
  Future<void> run({
    required List<DesyWorkshopCandidate> candidates,
    required Set<String> selectedCandidateIds,
    required List<DesyWorkshopAnnotation> annotations,
  }) async {
    if (!canRun) return;

    final request = _prompt.trim();
    final selected = candidates
        .where((candidate) => selectedCandidateIds.contains(candidate.id))
        .toList(growable: false);
    final rejected = selected.isEmpty
        ? const <DesyWorkshopCandidate>[]
        : candidates
              .where(
                (candidate) => !selectedCandidateIds.contains(candidate.id),
              )
              .toList(growable: false);
    final continuingSession = _sessionId != null;
    _running = true;
    _stderrTail.clear();
    _append(continuingSession ? r'$ codex exec resume …' : r'$ codex exec …');
    _append(
      selected.isEmpty
          ? 'Selected context: none'
          : 'Selected context: ${selected.map((item) => item.title).join(', ')}',
    );
    _append('Request: $request');
    if (annotations.isNotEmpty) {
      _append('${annotations.length} committed widget annotations attached.');
    }

    try {
      final process = await Process.start(
        configuration.codexExecutable,
        _codexArguments(_sessionId),
        workingDirectory: configuration.projectDirectory,
      );
      if (_disposed) {
        process.kill();
        return;
      }

      _process = process;
      _prompt = '';
      _notify();
      process.stdin.write(
        _agentPrompt(
          request: request,
          selected: selected,
          rejected: rejected,
          annotations: annotations,
        ),
      );
      await process.stdin.close();

      final outputDone = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach(_handleCodexEvent);
      final errorDone = process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach(_captureStderr);
      final exitCode = await process.exitCode;
      await Future.wait([outputDone, errorDone]);
      if (_disposed) return;

      _process = null;
      _running = false;
      _append('Codex exited with code $exitCode.');
      if (exitCode == 0) {
        if (_sessionId == null) {
          _append(
            'Codex did not return a conversation ID; the next feedback will '
            'start a new conversation.',
          );
        }
        await requestHotReload();
      } else {
        for (final line in _stderrTail) {
          _append('stderr: $line');
        }
        if (exitCode == 126 ||
            _stderrTail.any(
              (line) => line.contains('Operation not permitted'),
            )) {
          _append(
            'Codex was blocked by the macOS host. Launch a Debug/Profile '
            'dogfood build with `task dogfood:run_mac`; Release builds stay '
            'sandboxed.',
          );
        }
      }
    } on ProcessException catch (error) {
      _process = null;
      _running = false;
      _append('Could not launch Codex: ${error.message}');
      _append(
        'Make sure `${configuration.codexExecutable}` exists and can be '
        'launched by the Desy process.',
      );
    } on Object catch (error) {
      _process = null;
      _running = false;
      _append('Could not run Codex: $error');
    }
  }

  @override
  Future<void> requestHotReload() async {
    final pidFile = File(_resolvePath(configuration.flutterPidFile));
    try {
      final value = (await pidFile.readAsString()).trim();
      final flutterToolPid = int.tryParse(value);
      if (flutterToolPid == null) {
        _append('Invalid Flutter PID file: $value');
        return;
      }
      final sent = Process.killPid(flutterToolPid, ProcessSignal.sigusr1);
      _append(
        sent
            ? 'Sent hot reload to Flutter tool $flutterToolPid…'
            : 'Flutter tool $flutterToolPid did not accept the reload signal.',
      );
    } on FileSystemException {
      _append(
        'No reload controller found. Start Desy with '
        '`task dogfood:run_mac`.',
      );
    }
  }

  String _resolvePath(String path) {
    if (path.startsWith('/')) return path;
    return '${configuration.projectDirectory}/$path';
  }

  @override
  void noteReloadCompleted(int count) {
    _append('Hot reload $count completed; workshop state was preserved.');
  }

  @override
  void cancel() {
    final process = _process;
    if (process == null) return;
    _append('Stopping Codex process ${process.pid}…');
    process.kill(ProcessSignal.sigterm);
  }

  String _agentPrompt({
    required String request,
    required List<DesyWorkshopCandidate> selected,
    required List<DesyWorkshopCandidate> rejected,
    required List<DesyWorkshopAnnotation> annotations,
  }) {
    final selectedContext = selected.isEmpty
        ? '''No implementation was selected. This is the wide exploration phase. Keep or create distinct top-level candidates and do not add constituent `components` yet.'''
        : [
            'The user selected these implementations as context:',
            for (final candidate in selected) ...[
              '- ${candidate.id} — ${candidate.title}: ${candidate.description}',
              for (final component in candidate.components)
                _componentContextLine(component),
            ],
            'Preserve a stable ID when a direction remains conceptually the same.',
            if (rejected.isNotEmpty)
              'Rejected candidate IDs to remove: ${rejected.map((candidate) => candidate.id).join(', ')}.',
            'Delete every `DesyWorkshopCandidate` that is not selected, together with proposal-only widgets, helpers, and imports that are no longer reachable. Do not merely hide rejected implementations. Never delete registry components or unrelated production code.',
            if (selected.length == 1)
              '''This is now the deep component phase. Work only on the selected candidate and its constituent `components`. New parts use `DesyWorkshopCandidateComponent.prototype(..., prototypeBuilder: builder)`; parts that already exist in the live registry must use `DesyWorkshopCandidateComponent.registry(instanceId: '<component-id>.<instance-id>')` so Desy resolves the real widget through `registry.widgetBuilder`. Never copy or rebuild an existing registry component inside the candidate file.'''
            else
              '''More than one implementation remains selected, so the direction is not final. Prune unselected candidates but do not add or expand constituent `components` until exactly one candidate is selected.''',
          ].join('\n');
    final source = configuration.candidateSourcePath;
    final annotationContext = annotations.isEmpty
        ? 'The user did not commit any widget-specific annotations.'
        : [
            'The user committed these widget-specific annotations:',
            for (final annotation in annotations)
              ..._annotationContextLines(annotation),
            'Apply every annotation to its exact widget target. Preserve unrelated production widgets and selected candidates.',
          ].join('\n');
    return '''You are working in a Flutter repository that consumes Desy. Use the Workshop to iterate on proposals and, when requested, move the selected direction into the consumer's actual design system.

The hot-reloadable proposal entry point is $source, but it is not an edit boundary. Inspect and edit any project files needed to implement the request. Follow the repository's guidance and existing architecture. Reuse the consumer's real tokens, components, theme, and registry; do not create a parallel design-system catalogue. When promoting a selected proposal, integrate it into the existing design-system source, update its real registry declaration and focused tests when appropriate, and keep the Workshop proposals useful for the next iteration. Preserve unrelated work. Do not edit generated or vendored files, add dependencies without a clear need, or run long-lived commands. Treat the selections and complete annotation list in this turn as the authoritative current Workshop state.

$selectedContext

$annotationContext

Implement this main Workshop request together with the annotations above:
$request

After editing, format every changed Dart file and run the narrowest relevant analysis or test command that completes promptly.
Then briefly summarize the proposals and actual design-system files that changed.''';
  }

  String _componentContextLine(DesyWorkshopCandidateComponent component) {
    final registryId = component.registryInstanceId;
    return registryId == null
        ? '  - Prototype component ${component.id}: ${component.title} — ${component.description}'
        : '  - Registry component instance: $registryId';
  }

  List<String> _annotationContextLines(DesyWorkshopAnnotation annotation) {
    final target = annotation.target;
    final location = target.sourceLocation;
    final sourceReference = location == null
        ? null
        : _sourceReference(location);
    final sourceLine = location == null ? null : _sourceLine(location);
    return [
      '${annotation.id}. ${annotation.comment}',
      '   Candidate ID: ${target.candidateId}',
      '   Widget: ${target.displayLabel}',
      if (sourceReference != null) '   Source: $sourceReference',
      if (target.widgetKey case final key?) '   Flutter key: $key',
      if (sourceLine != null) '   Source line: $sourceLine',
      '   Widget type: ${target.widgetType}',
      '   Fallback ancestry: ${target.widgetPath}',
      '   Fallback local bounds: left ${target.bounds.left.toStringAsFixed(1)}, top ${target.bounds.top.toStringAsFixed(1)}, width ${target.bounds.width.toStringAsFixed(1)}, height ${target.bounds.height.toStringAsFixed(1)}',
    ];
  }

  String _sourceReference(DesyWorkshopSourceLocation location) {
    final relative = _projectRelativeSourcePath(location);
    return '${relative ?? location.sourcePath}:${location.line}:${location.column}';
  }

  String? _sourceLine(DesyWorkshopSourceLocation location) {
    if (_projectRelativeSourcePath(location) == null) return null;
    try {
      final lines = File(location.sourcePath).readAsLinesSync();
      if (location.line > lines.length) return null;
      final line = lines[location.line - 1].trimRight();
      if (line.isEmpty) return null;
      return line.length <= 180 ? line : '${line.substring(0, 177)}…';
    } on FileSystemException {
      return null;
    }
  }

  String? _projectRelativeSourcePath(DesyWorkshopSourceLocation location) {
    if (location.uri.scheme != 'file') return null;
    final projectRoot = Directory(configuration.projectDirectory).absolute.path;
    final sourcePath = File(location.sourcePath).absolute.path;
    final prefix = '$projectRoot${Platform.pathSeparator}';
    if (!sourcePath.startsWith(prefix)) return null;
    return sourcePath.substring(prefix.length);
  }

  void _handleCodexEvent(String line) {
    try {
      final event = jsonDecode(line) as Map<String, dynamic>;
      final type = event['type'];
      if (type == 'thread.started') {
        final wasContinuing = _sessionId != null;
        final threadId = event['thread_id'];
        if (threadId is String && threadId.trim().isNotEmpty) {
          _sessionId = threadId;
        }
        _append(
          wasContinuing
              ? 'Codex conversation resumed.'
              : 'Codex conversation started.',
        );
        return;
      }
      if (type == 'turn.started') {
        _append('Planning and editing…');
        return;
      }
      if (type == 'turn.failed' || type == 'error') {
        _append('Codex error: ${event['error'] ?? event['message'] ?? line}');
        return;
      }
      if (type != 'item.started' && type != 'item.completed') return;

      final item = event['item'];
      if (item is! Map<String, dynamic>) return;
      final itemType = item['type'];
      if (itemType == 'agent_message' && type == 'item.completed') {
        final message = item['text'];
        if (message is String && message.trim().isNotEmpty) {
          _append(message.trim());
        }
      } else if (itemType == 'command_execution' && type == 'item.started') {
        final command = item['command'];
        if (command is String) _append(r'$ ' + _compact(command));
      } else if (itemType == 'command_execution' && type == 'item.completed') {
        final exitCode = item['exit_code'];
        if (exitCode is int && exitCode != 0) {
          _append('Command failed with code $exitCode.');
        }
      } else if (itemType == 'file_change' && type == 'item.completed') {
        _append('Updated the candidate source.');
      }
    } on FormatException {
      _captureStderr(line);
    }
  }

  void _captureStderr(String line) {
    if (line.trim().isEmpty) return;
    _stderrTail.add(line);
    if (_stderrTail.length > 8) _stderrTail.removeAt(0);
  }

  String _compact(String value) {
    final oneLine = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return oneLine.length <= 100 ? oneLine : '${oneLine.substring(0, 97)}…';
  }

  void _append(String line) {
    if (_disposed) return;
    _logs.add(line);
    if (_logs.length > 160) _logs.removeRange(0, _logs.length - 160);
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _process?.kill(ProcessSignal.sigterm);
    _process = null;
    super.dispose();
  }
}

List<String> _codexArguments(String? sessionId) => [
  'exec',
  '--approve-for-me',
  '--color',
  'never',
  '--json',
  if (sessionId != null) ...['resume', sessionId],
  '-',
];

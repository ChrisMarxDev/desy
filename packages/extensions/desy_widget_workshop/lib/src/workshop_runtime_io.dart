import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desy_bench/desy_bench.dart';

import 'workshop_candidate.dart';
import 'workshop_runtime.dart';

/// Creates the local-process runtime on Dart IO platforms.
DesyWorkshopRuntime createDesyWorkshopRuntime(
  DesyWidgetWorkshopConfiguration configuration,
) => _IoWorkshopRuntime(configuration);

class _IoWorkshopRuntime extends DesyWorkshopRuntime {
  _IoWorkshopRuntime(super.configuration)
    : _prompt = configuration.initialPrompt {
    _append('Ready. Describe the next iteration in plain language.');
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
  void startNewSession() {
    if (_running || _disposed) return;
    _sessionId = null;
    _logs
      ..clear()
      ..add('Started a new Workshop conversation from registry feedback.');
    _notify();
  }

  @override
  Future<void> run({
    required List<DesyWorkshopCandidate> candidates,
    required DesyWorkspaceAgentBrief agentBrief,
  }) async {
    if (!canRun) return;
    final request = _prompt.trim();
    final continuingSession = _sessionId != null;
    _running = true;
    _stderrTail.clear();
    _append(continuingSession ? r'$ codex exec resume …' : r'$ codex exec …');
    _append('Current proposal context: ${candidates.length} proposals.');
    _append('Request: $request');
    if (agentBrief.annotations.isNotEmpty) {
      _append(
        '${agentBrief.annotations.length} global workbench annotations attached.',
      );
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
          candidates: candidates,
          agentBrief: agentBrief,
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
    required List<DesyWorkshopCandidate> candidates,
    required DesyWorkspaceAgentBrief agentBrief,
  }) {
    final candidateContext = [
      'Current proposals (refer to their number, id, or title in plain text):',
      for (final (index, candidate) in candidates.indexed) ...[
        '${index + 1}. ${candidate.id} — ${candidate.title}: ${candidate.description}',
        for (final component in candidate.components)
          _componentContextLine(component),
      ],
      'Interpret the user request as the sole decision about which proposals to '
          'keep, compare, alter, or remove. Do not infer a chosen direction '
          'from the workbench UI. Retain multiple requested directions so the '
          'user can compare them. When the user clearly chooses one direction, '
          'remove obsolete proposal-only code and then deepen that remaining '
          'candidate through its `components`. Never delete registry components '
          'or unrelated production code.',
    ].join('\n');
    final source = configuration.candidateSourcePath;
    final workbenchAnnotationContext = agentBrief.annotations.isEmpty
        ? 'The user did not commit any global workbench annotations.'
        : [
            'The user committed these global workbench annotations as JSON:',
            '```json',
            const JsonEncoder.withIndent(
              '  ',
            ).convert(DesyAnnotationBatch(agentBrief.annotations).toJson()),
            '```',
            'Apply every relevant annotation. Treat source evidence as a strong target and do not silently reinterpret an ambiguous target.',
          ].join('\n');
    return '''You are working in a Flutter repository that consumes Desy. Use the Workshop to iterate on proposals and, when requested, move the selected direction into the consumer's actual design system.

The hot-reloadable proposal entry point is $source, but it is not an edit boundary. Inspect and edit any project files needed to implement the request. Follow the repository's guidance and existing architecture. Reuse the consumer's real tokens, components, theme, and registry; do not create a parallel design-system catalogue. If the user asks to evolve a real component, update its ordinary source, registry declaration, and focused tests when appropriate. Preserve unrelated work. Do not edit generated or vendored files, add dependencies without a clear need, or run long-lived commands. Treat the current proposals, complete annotation list, and the user's text as the authoritative Workshop state.

Hot-reload discipline: prefer changing build methods and literals. During a normal Workshop turn, preserve every existing widget class's fields and constructor shape. When a structural change is needed, introduce a new helper or versioned widget, point the active builder at it, and leave the old type in the source until a planned restart cleanup. Do not remove fields from an existing const widget class or change an existing widget's constructor shape during a normal Workshop turn; those edits require a hot restart. If a true restructure is necessary, say so clearly in your summary rather than pretending reload succeeded.

${agentBrief.toMarkdown()}

$candidateContext

$workbenchAnnotationContext

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

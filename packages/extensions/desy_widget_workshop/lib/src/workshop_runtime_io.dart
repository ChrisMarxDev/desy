import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'workshop_candidate.dart';
import 'workshop_runtime.dart';

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
  void setPrompt(String value) {
    _prompt = value;
    _notify();
  }

  @override
  Future<void> run({
    required List<DesyWorkshopCandidate> candidates,
    required Set<String> selectedCandidateIds,
  }) async {
    if (!canRun) return;

    final selected = candidates
        .where((candidate) => selectedCandidateIds.contains(candidate.id))
        .toList(growable: false);
    _running = true;
    _logs.clear();
    _stderrTail.clear();
    _append(r'$ codex exec …');
    _append(
      selected.isEmpty
          ? 'Selected context: none'
          : 'Selected context: ${selected.map((item) => item.title).join(', ')}',
    );
    _append('Request: ${_prompt.trim()}');

    try {
      final process = await Process.start(
        'codex',
        const [
          'exec',
          '--approve-for-me',
          '--ephemeral',
          '--color',
          'never',
          '--json',
          '-',
        ],
        workingDirectory: configuration.projectDirectory,
        runInShell: true,
      );
      if (_disposed) {
        process.kill();
        return;
      }

      _process = process;
      process.stdin.write(
        _agentPrompt(request: _prompt.trim(), selected: selected),
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
        await requestHotReload();
      } else {
        for (final line in _stderrTail) {
          _append('stderr: $line');
        }
      }
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
  }) {
    final selectedContext = selected.isEmpty
        ? 'No implementation was selected. Use the written request as the direction.'
        : [
            'The user selected these implementations as context:',
            for (final candidate in selected)
              '- ${candidate.id} — ${candidate.title}: ${candidate.description}',
            'Preserve a stable ID when a direction remains conceptually the same.',
          ].join('\n');
    final source = configuration.candidateSourcePath;
    return '''You are editing Desy's isolated Flutter widget workshop.

Edit only $source. Do not modify, create, rename, or delete any other file. Keep the public candidate-builder function signature unchanged so the running Desy app can hot reload it. Return multiple real Flutter candidates with stable IDs, short titles, useful descriptions, and WidgetBuilder values. Do not add dependencies or run long-lived commands.

$selectedContext

Implement this request:
$request

After editing, run: dart format $source
Then briefly summarize which candidates changed or were added.''';
  }

  void _handleCodexEvent(String line) {
    try {
      final event = jsonDecode(line) as Map<String, dynamic>;
      final type = event['type'];
      if (type == 'thread.started') {
        _append('Codex session started.');
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
      } else if (itemType == 'command_execution' &&
          type == 'item.completed' &&
          item['exit_code'] case final int exitCode when exitCode != 0) {
        _append('Command failed with code $exitCode.');
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

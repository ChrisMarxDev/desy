// ignore_for_file: public_member_api_docs, curly_braces_in_flow_control_structures, use_null_aware_elements

import 'dart:async';
import 'dart:convert';
import 'dart:io';

final class CodexAppServerEvent {
  const CodexAppServerEvent({required this.method, required this.params});
  final String method;
  final Map<String, Object?> params;
}

final class CodexAppServerException implements Exception {
  const CodexAppServerException(this.message, {this.code});
  final String message;
  final int? code;
  @override
  String toString() =>
      'Codex app-server error${code == null ? '' : ' ($code)'}: $message';
}

/// A minimal client for Codex's stable app-server JSON-RPC framing.
final class CodexAppServerClient {
  CodexAppServerClient._(this._writeLine, this._onClose, Stream<String> lines) {
    _subscription = lines.listen(
      _handleLine,
      onError: _events.addError,
      onDone: _finish,
    );
  }

  static Future<CodexAppServerClient> start({
    String executable = 'codex',
  }) async {
    final process = await Process.start(executable, const ['app-server']);
    return CodexAppServerClient._(
      process.stdin.writeln,
      () => process.kill(),
      process.stdout.transform(utf8.decoder).transform(const LineSplitter()),
    );
  }

  factory CodexAppServerClient.fromLines({
    required Stream<String> lines,
    required void Function(String line) writeLine,
    void Function()? onClose,
  }) => CodexAppServerClient._(writeLine, onClose ?? () {}, lines);

  final void Function(String line) _writeLine;
  final void Function() _onClose;
  final _events = StreamController<CodexAppServerEvent>.broadcast();
  final _pending = <int, Completer<Map<String, Object?>>>{};
  late final StreamSubscription<String> _subscription;
  var _nextId = 1;
  var _closed = false;

  Stream<CodexAppServerEvent> get events => _events.stream;

  Future<void> initialize({
    required String name,
    required String version,
  }) async {
    await request('initialize', {
      'clientInfo': {'name': name, 'title': name, 'version': version},
    });
    notify('initialized');
  }

  /// Starts an ephemeral local-agent thread with tool access confined to the
  /// current workspace.
  ///
  /// `never` is intentional: this lightweight client does not yet expose an
  /// interactive approval UI for app-server requests. Codex may use the tools
  /// configured in the user's local Codex installation, but filesystem writes
  /// remain confined to the workspace rather than receiving full disk access.
  Future<String> startThread({String? model}) async {
    final result = await request('thread/start', {
      if (model != null) 'model': model,
      'ephemeral': true,
      'approvalPolicy': 'never',
      'sandbox': 'workspace-write',
    });
    final thread = result['thread'];
    if (thread is! Map || thread['id'] is! String)
      throw const CodexAppServerException(
        'thread/start returned no thread id.',
      );
    return thread['id']! as String;
  }

  Future<String> startTurn({
    required String threadId,
    required String text,
    required Map<String, Object?> outputSchema,
  }) async {
    final result = await request('turn/start', {
      'threadId': threadId,
      'input': [
        {'type': 'text', 'text': text},
      ],
      'outputSchema': outputSchema,
    });
    final turn = result['turn'];
    if (turn is! Map || turn['id'] is! String)
      throw const CodexAppServerException('turn/start returned no turn id.');
    return turn['id']! as String;
  }

  Future<Map<String, Object?>> request(
    String method,
    Map<String, Object?> params,
  ) {
    if (_closed) throw StateError('Codex app-server client is closed.');
    final id = _nextId++;
    final completer = Completer<Map<String, Object?>>();
    _pending[id] = completer;
    _writeLine(jsonEncode({'method': method, 'id': id, 'params': params}));
    return completer.future;
  }

  void notify(String method, [Map<String, Object?> params = const {}]) {
    if (!_closed) _writeLine(jsonEncode({'method': method, 'params': params}));
  }

  void _handleLine(String line) {
    if (line.trim().isEmpty) return;
    final decoded = jsonDecode(line);
    if (decoded is! Map) return;
    final message = Map<String, Object?>.from(decoded);
    final id = message['id'];
    final pending = id is int ? _pending.remove(id) : null;
    if (pending != null) {
      final error = message['error'];
      if (error is Map) {
        pending.completeError(
          CodexAppServerException(
            error['message'] as String? ?? 'Unknown error.',
            code: error['code'] as int?,
          ),
        );
      } else {
        pending.complete(
          Map<String, Object?>.from(message['result'] as Map? ?? const {}),
        );
      }
      return;
    }
    final method = message['method'];
    if (method is String)
      _events.add(
        CodexAppServerEvent(
          method: method,
          params: Map<String, Object?>.from(
            message['params'] as Map? ?? const {},
          ),
        ),
      );
  }

  void _finish() {
    for (final pending in _pending.values) {
      pending.completeError(
        const CodexAppServerException('Codex app-server stopped.'),
      );
    }
    _pending.clear();
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _subscription.cancel();
    _finish();
    await _events.close();
    _onClose();
  }
}

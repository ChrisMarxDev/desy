// ignore_for_file: public_member_api_docs

import 'dart:async';

final class CodexAppServerEvent {
  const CodexAppServerEvent({required this.method, required this.params});
  final String method;
  final Map<String, Object?> params;
}

final class CodexAppServerException implements Exception {
  const CodexAppServerException(this.message, {this.code});
  final String message;
  final int? code;
}

/// Web/mobile compile-time stub. Local process execution is desktop-only.
final class CodexAppServerClient {
  static Future<CodexAppServerClient> start({String executable = 'codex'}) =>
      Future.error(
        UnsupportedError(
          'Local Codex app-server requires a Dart VM desktop target.',
        ),
      );
  factory CodexAppServerClient.fromLines({
    required Stream<String> lines,
    required void Function(String) writeLine,
    void Function()? onClose,
  }) => throw UnsupportedError(
    'Local Codex app-server requires a Dart VM desktop target.',
  );
  Stream<CodexAppServerEvent> get events => const Stream.empty();
  Future<void> initialize({required String name, required String version}) =>
      Future.error(UnsupportedError('Unsupported on this platform.'));
  Future<String> startThread({String? model}) =>
      Future.error(UnsupportedError('Unsupported on this platform.'));
  Future<String> startTurn({
    required String threadId,
    required String text,
    required Map<String, Object?> outputSchema,
  }) => Future.error(UnsupportedError('Unsupported on this platform.'));
  Future<void> close() async {}
}

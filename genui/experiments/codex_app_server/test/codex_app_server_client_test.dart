import 'dart:async';
import 'dart:convert';

import 'package:codex_app_server/codex_app_server.dart';
import 'package:test/test.dart';

void main() {
  test('initializes and correlates JSON-RPC responses', () async {
    final lines = StreamController<String>();
    final sent = <Map<String, Object?>>[];
    final client = CodexAppServerClient.fromLines(
      lines: lines.stream,
      writeLine: (line) =>
          sent.add(Map<String, Object?>.from(jsonDecode(line) as Map)),
    );
    final initializing = client.initialize(
      name: 'genui_codex',
      version: '0.0.1',
    );
    lines.add(jsonEncode({'id': 1, 'result': {}}));
    await initializing;
    expect(sent.map((message) => message['method']), [
      'initialize',
      'initialized',
    ]);
    await client.close();
    await lines.close();
  });

  test(
    'starts a workspace-write thread with non-interactive approvals',
    () async {
      final lines = StreamController<String>();
      final sent = <Map<String, Object?>>[];
      final client = CodexAppServerClient.fromLines(
        lines: lines.stream,
        writeLine: (line) =>
            sent.add(Map<String, Object?>.from(jsonDecode(line) as Map)),
      );

      final starting = client.startThread(model: 'gpt-5.4');
      lines.add(
        jsonEncode({
          'id': 1,
          'result': {
            'thread': {'id': 'thread-1'},
          },
        }),
      );

      expect(await starting, 'thread-1');
      expect(sent.single, {
        'method': 'thread/start',
        'id': 1,
        'params': {
          'model': 'gpt-5.4',
          'ephemeral': true,
          'approvalPolicy': 'never',
          'sandbox': 'workspace-write',
        },
      });
      await client.close();
      await lines.close();
    },
  );
}

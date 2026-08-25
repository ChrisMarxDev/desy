import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart' as a2ui;
import 'package:genui/genui.dart';
import 'package:genui_codex/genui_codex.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes a constrained A2UI response envelope', () {
    final messages = CodexGenUiDriver.decodeA2uiMessages(
      jsonEncode({
        'a2ui': jsonEncode({
          'messages': [
            {
              'deleteSurface': {'surfaceId': 'preview'},
            },
          ],
        }),
      }),
    );
    expect(messages.single.toJson()['deleteSurface'], {'surfaceId': 'preview'});
  });

  test('decodes a direct canonical A2UI operation', () {
    final messages = CodexGenUiDriver.decodeA2uiMessages(
      jsonEncode({
        'a2ui': jsonEncode({
          'version': 'v0.9',
          'deleteSurface': {'surfaceId': 'preview'},
        }),
      }),
    );

    expect(messages.single.toJson()['deleteSurface'], {'surfaceId': 'preview'});
  });

  test('ignores client actions echoed beside surface operations', () {
    final messages = CodexGenUiDriver.decodeA2uiMessages(
      jsonEncode({
        'a2ui': jsonEncode({
          'messages': [
            {
              'action': {
                'name': 'continue',
                'surfaceId': 'preview',
                'sourceComponentId': 'button',
              },
            },
            {
              'updateComponents': {
                'surfaceId': 'preview',
                'components': [
                  {'id': 'root', 'component': 'Text', 'text': 'Updated'},
                ],
              },
            },
          ],
        }),
      }),
    );

    expect(messages, hasLength(1));
    expect(messages.single.toJson(), contains('updateComponents'));
  });

  test(
    'streams the unwrapped A2UI value through GenUI transport parsing',
    () async {
      final transport = A2uiTransportAdapter();
      final decoder = CodexA2uiEnvelopeDecoder();
      final emitted = <a2ui.A2uiMessage>[];
      final messages = transport.incomingMessages.listen(emitted.add);
      final outer = jsonEncode({
        'a2ui': jsonEncode({
          'version': 'v0.9',
          'deleteSurface': {'surfaceId': 'preview'},
        }),
      });

      for (var index = 0; index < outer.length; index += 5) {
        decoder.addChunk(
          outer.substring(
            index,
            index + 5 < outer.length ? index + 5 : outer.length,
          ),
          transport.addChunk,
        );
      }
      decoder.finish();
      await Future<void>.delayed(Duration.zero);

      expect(emitted.single.toJson()['deleteSurface'], {
        'surfaceId': 'preview',
      });
      await messages.cancel();
      transport.dispose();
    },
  );
}

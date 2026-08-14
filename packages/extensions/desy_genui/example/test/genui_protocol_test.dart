import 'dart:convert';

import 'package:desy_genui_example/genui_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('A2UI action becomes a JSON-safe continuation turn', () {
    final action = GenUiAction.fromInteraction(
      jsonEncode({
        'version': 'v0.9',
        'action': {
          'name': 'update_cards',
          'sourceComponentId': 'root_composer',
          'timestamp': '2026-08-12T20:52:52.250',
          'context': {'text': 'What happens if I send this ???'},
          'surfaceId': 'dogfood-agent-demo',
        },
      }),
    );
    final turn = GenUiActionTurn(
      action: action,
      currentSurface: const [
        {'id': 'root', 'component': 'desy.component.card'},
      ],
    );

    expect(turn.toJson(), {
      'type': 'ui_action',
      'action': {
        'name': 'update_cards',
        'sourceComponentId': 'root_composer',
        'timestamp': '2026-08-12T20:52:52.250',
        'context': {'text': 'What happens if I send this ???'},
        'surfaceId': 'dogfood-agent-demo',
      },
      'currentSurface': [
        {'id': 'root', 'component': 'desy.component.card'},
      ],
    });
  });

  test('invalid interaction envelopes are rejected before forwarding', () {
    expect(
      () => GenUiAction.fromInteraction(
        jsonEncode({
          'version': 'v0.9',
          'error': {'message': 'not an action'},
        }),
      ),
      throwsFormatException,
    );
  });
}

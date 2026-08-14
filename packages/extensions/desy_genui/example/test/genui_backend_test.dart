import 'dart:convert';

import 'package:desy_design_system_example/desy_design_system_example.dart';
import 'package:desy_genui/desy_genui.dart';
import 'package:desy_genui_example/genui_backend.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('sends the compiled catalog and parses generated components', () async {
    final catalog = DesyGenUiCatalog.compile(desyDesignSystemRegistry);
    final httpClient = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url, Uri.parse('http://agent.test/generate'));
      final body = jsonDecode(request.body) as Map<String, Object?>;
      expect(body['turn'], {'type': 'prompt', 'text': 'Build a card'});
      expect(body['catalogDigest'], catalog.digest);
      expect(body['catalog'], catalog.backendArtifact);
      return http.Response(
        jsonEncode({
          'model': 'gpt-test',
          'responseId': 'resp-test',
          'components': [
            {
              'id': 'root',
              'component': 'desy.component.card',
              'title': 'Generated',
              'body': 'From the dogfood registry',
              'showBody': true,
            },
          ],
        }),
        200,
        headers: const {'content-type': 'application/json'},
      );
    });
    final backend = OpenAiGenUiBackend(
      endpoint: Uri.parse('http://agent.test'),
      httpClient: httpClient,
    );

    final result = await backend.respond(
      turn: GenUiPromptTurn('Build a card'),
      catalog: catalog,
    );

    expect(result.model, 'gpt-test');
    expect(result.responseId, 'resp-test');
    expect(result.components.single['id'], 'root');
    backend.close();
    httpClient.close();
  });

  test('sends a typed UI action with the current surface', () async {
    final catalog = DesyGenUiCatalog.compile(desyDesignSystemRegistry);
    final action = GenUiAction(
      name: 'update_cards',
      sourceComponentId: 'root_composer',
      surfaceId: 'dogfood-agent-demo',
      timestamp: '2026-08-12T20:52:52.250',
      context: const {'text': 'Show active cards'},
    );
    final currentSurface = <Map<String, Object?>>[
      {
        'id': 'root',
        'component': 'desy.component.card',
        'title': 'Current card',
      },
    ];
    final httpClient = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, Object?>;
      expect(body['turn'], {
        'type': 'ui_action',
        'action': action.toJson(),
        'currentSurface': currentSurface,
      });
      return http.Response(
        jsonEncode({
          'model': 'gpt-test',
          'responseId': 'resp-action',
          'components': [
            {
              'id': 'root',
              'component': 'desy.component.card',
              'title': 'Updated card',
            },
          ],
        }),
        200,
      );
    });
    final backend = OpenAiGenUiBackend(
      endpoint: Uri.parse('http://agent.test'),
      httpClient: httpClient,
    );

    final result = await backend.respond(
      turn: GenUiActionTurn(action: action, currentSurface: currentSurface),
      catalog: catalog,
    );

    expect(result.responseId, 'resp-action');
    expect(result.components.single['title'], 'Updated card');
    backend.close();
    httpClient.close();
  });

  test('parses the A2UI interaction envelope into a typed action', () {
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

    expect(action.name, 'update_cards');
    expect(action.sourceComponentId, 'root_composer');
    expect(action.context['text'], 'What happens if I send this ???');
  });

  test('rejects a successful response without an A2UI root', () async {
    final httpClient = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'components': [
            {'id': 'orphan', 'component': 'desy.component.card'},
          ],
        }),
        200,
      ),
    );
    final backend = OpenAiGenUiBackend(httpClient: httpClient);

    await expectLater(
      backend.respond(
        turn: GenUiPromptTurn('Build something'),
        catalog: DesyGenUiCatalog.compile(desyDesignSystemRegistry),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('no root'),
        ),
      ),
    );
    backend.close();
    httpClient.close();
  });
}

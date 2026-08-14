import 'dart:convert';

import 'package:desy_genui/desy_genui.dart';
import 'package:http/http.dart' as http;

import 'genui_protocol.dart';

export 'genui_protocol.dart';

/// A generated flat A2UI component tree returned by an agent backend.
final class GeneratedSurface {
  /// Creates a validated generated surface result.
  const GeneratedSurface({
    required this.components,
    required this.model,
    required this.responseId,
  });

  /// Flat A2UI component definitions, including one `root` component.
  final List<Map<String, Object?>> components;

  /// Provider model that produced the result.
  final String model;

  /// Provider response identifier useful for debugging.
  final String responseId;
}

/// Provider-neutral boundary used by the Flutter sample.
abstract interface class GenUiBackend {
  /// Responds to a text or generated-surface [turn] using [catalog].
  Future<GeneratedSurface> respond({
    required GenUiTurn turn,
    required DesyGenUiCatalog catalog,
  });

  /// Releases resources owned by this backend client.
  void close();
}

/// Calls the local development server that owns the OpenAI API key.
final class OpenAiGenUiBackend implements GenUiBackend {
  /// Creates a client for the local development server.
  OpenAiGenUiBackend({Uri? endpoint, http.Client? httpClient})
    : endpoint = endpoint ?? Uri.parse(_defaultEndpoint),
      _httpClient = httpClient ?? http.Client(),
      _ownsClient = httpClient == null;

  static const _defaultEndpoint = String.fromEnvironment(
    'GENUI_SERVER_URL',
    defaultValue: 'http://localhost:8787',
  );

  /// Base URL of the local agent server.
  final Uri endpoint;
  final http.Client _httpClient;
  final bool _ownsClient;

  @override
  Future<GeneratedSurface> respond({
    required GenUiTurn turn,
    required DesyGenUiCatalog catalog,
  }) async {
    final response = await _httpClient.post(
      endpoint.resolve('/generate'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'turn': turn.toJson(),
        'catalogDigest': catalog.digest,
        'catalog': catalog.backendArtifact,
      }),
    );
    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw StateError(
        'GenUI server returned HTTP ${response.statusCode} with invalid JSON.',
      );
    }
    if (decoded is! Map) {
      throw StateError('GenUI server returned an invalid response object.');
    }
    final body = Map<String, Object?>.from(decoded);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        body['error'] is String
            ? body['error']! as String
            : 'GenUI server failed with HTTP ${response.statusCode}.',
      );
    }

    final rawComponents = body['components'];
    if (rawComponents is! List || rawComponents.isEmpty) {
      throw StateError('GenUI server returned no A2UI components.');
    }
    final components = <Map<String, Object?>>[];
    for (final rawComponent in rawComponents) {
      if (rawComponent is! Map) {
        throw StateError('GenUI server returned an invalid component.');
      }
      components.add(Map<String, Object?>.from(rawComponent));
    }
    if (!components.any((component) => component['id'] == 'root')) {
      throw StateError('Generated A2UI surface has no root component.');
    }

    return GeneratedSurface(
      components: List.unmodifiable(components),
      model: body['model'] as String? ?? 'unknown',
      responseId: body['responseId'] as String? ?? 'unknown',
    );
  }

  @override
  void close() {
    if (_ownsClient) _httpClient.close();
  }
}

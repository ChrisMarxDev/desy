import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desy_genui_example/genui_protocol.dart';

const _openAiResponsesUri = 'https://api.openai.com/v1/responses';

Future<void> main() async {
  final environment = <String, String>{
    ..._readDotEnv(File('.env')),
    ...Platform.environment,
  };
  final apiKey = environment['OPENAI_API_KEY']?.trim() ?? '';
  if (apiKey.isEmpty) {
    stderr.writeln(
      'OPENAI_API_KEY is missing. Copy .env.example to .env and add the key.',
    );
    exitCode = 64;
    return;
  }
  final model = environment['OPENAI_MODEL']?.trim().isNotEmpty == true
      ? environment['OPENAI_MODEL']!.trim()
      : 'gpt-5-mini';
  final port = int.tryParse(environment['GENUI_SERVER_PORT'] ?? '') ?? 8787;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  final openAiClient = HttpClient();

  stdout.writeln('Desy GenUI server listening on http://localhost:$port');
  stdout.writeln('OpenAI model: $model');
  await for (final request in server) {
    unawaited(
      _handleRequest(
        request,
        apiKey: apiKey,
        model: model,
        openAiClient: openAiClient,
      ),
    );
  }
}

Future<void> _handleRequest(
  HttpRequest request, {
  required String apiKey,
  required String model,
  required HttpClient openAiClient,
}) async {
  _addCorsHeaders(request.response);
  if (request.method == 'OPTIONS') {
    request.response.statusCode = HttpStatus.noContent;
    await request.response.close();
    return;
  }
  if (request.method == 'GET' && request.uri.path == '/health') {
    await _writeJson(request.response, HttpStatus.ok, {
      'status': 'ok',
      'provider': 'openai',
      'model': model,
    });
    return;
  }
  if (request.method != 'POST' || request.uri.path != '/generate') {
    await _writeJson(request.response, HttpStatus.notFound, {
      'error': 'Use POST /generate.',
    });
    return;
  }

  try {
    final body = await utf8.decoder.bind(request).join();
    final decoded = jsonDecode(body);
    if (decoded is! Map) throw const FormatException('Expected an object.');
    final input = Map<String, Object?>.from(decoded);
    final rawCatalog = input['catalog'];
    if (rawCatalog is! Map) {
      throw const FormatException('catalog must be an object.');
    }
    final catalog = Map<String, Object?>.from(rawCatalog);
    final turn = _parseTurn(input['turn']);
    if (turn case final GenUiActionTurn actionTurn) {
      _validateComponentEnvelope(actionTurn.currentSurface, catalog);
    }
    final outputSchema = _buildOutputSchema(catalog);
    final openAiResponse = await _createOpenAiResponse(
      openAiClient,
      apiKey: apiKey,
      model: model,
      input: _modelInputForTurn(turn),
      instructions: _buildInstructions(catalog),
      outputSchema: outputSchema,
    );
    final outputText = _extractOutputText(openAiResponse);
    final generated = jsonDecode(outputText);
    if (generated is! Map) {
      throw const FormatException('Model output must be a JSON object.');
    }
    final rawComponents = generated['components'];
    if (rawComponents is! List || rawComponents.isEmpty) {
      throw const FormatException('Model output contains no components.');
    }
    final components = <Map<String, Object?>>[];
    for (final rawComponent in rawComponents) {
      if (rawComponent is! Map) {
        throw const FormatException('Model returned a malformed component.');
      }
      final component = Map<String, Object?>.from(rawComponent)
        ..removeWhere((_, value) => value == null);
      components.add(component);
    }
    _validateComponentEnvelope(components, catalog);
    await _writeJson(request.response, HttpStatus.ok, {
      'components': components,
      'model': openAiResponse['model'] ?? model,
      'responseId': openAiResponse['id'] ?? 'unknown',
      'catalogDigest': input['catalogDigest'],
    });
  } on FormatException catch (error) {
    await _writeJson(request.response, HttpStatus.badRequest, {
      'error': error.message,
    });
  } on OpenAiException catch (error) {
    await _writeJson(request.response, error.statusCode, {
      'error': error.message,
    });
  } on Object catch (error, stack) {
    stderr.writeln('Generation failed: $error\n$stack');
    await _writeJson(request.response, HttpStatus.internalServerError, {
      'error': 'Generation failed: $error',
    });
  }
}

Future<Map<String, Object?>> _createOpenAiResponse(
  HttpClient client, {
  required String apiKey,
  required String model,
  required String input,
  required String instructions,
  required Map<String, Object?> outputSchema,
}) async {
  final request = await client.postUrl(Uri.parse(_openAiResponsesUri));
  request.headers
    ..contentType = ContentType.json
    ..set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
  request.write(
    jsonEncode({
      'model': model,
      'instructions': instructions,
      'input': input,
      'text': {
        'format': {
          'type': 'json_schema',
          'name': 'desy_a2ui_surface',
          'strict': true,
          'schema': outputSchema,
        },
      },
      'max_output_tokens': 4000,
      'store': false,
    }),
  );
  final response = await request.close();
  final responseBody = await utf8.decoder.bind(response).join();
  final Object? decoded;
  try {
    decoded = jsonDecode(responseBody);
  } on FormatException {
    throw OpenAiException(
      HttpStatus.badGateway,
      'OpenAI returned invalid JSON (HTTP ${response.statusCode}).',
    );
  }
  if (decoded is! Map) {
    throw OpenAiException(
      HttpStatus.badGateway,
      'OpenAI returned an invalid response object.',
    );
  }
  final result = Map<String, Object?>.from(decoded);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    final rawError = result['error'];
    final error = rawError is Map ? rawError['message'] : null;
    throw OpenAiException(
      response.statusCode,
      error is String ? error : 'OpenAI request failed.',
    );
  }
  return result;
}

GenUiTurn _parseTurn(Object? rawTurn) {
  if (rawTurn is! Map) {
    throw const FormatException('turn must be an object.');
  }
  final turn = Map<String, Object?>.from(rawTurn);
  return switch (turn['type']) {
    'prompt' => switch (turn['text']) {
      final String text when text.trim().isNotEmpty => GenUiPromptTurn(text),
      _ => throw const FormatException(
        'prompt turn text must be a non-empty string.',
      ),
    },
    'ui_action' => _parseActionTurn(turn),
    _ => throw const FormatException('Unsupported GenUI turn type.'),
  };
}

GenUiActionTurn _parseActionTurn(Map<String, Object?> turn) {
  final rawAction = turn['action'];
  final rawSurface = turn['currentSurface'];
  if (rawAction is! Map) {
    throw const FormatException('ui_action turn requires an action object.');
  }
  if (rawSurface is! List || rawSurface.isEmpty) {
    throw const FormatException(
      'ui_action turn requires the current component surface.',
    );
  }
  final surface = <Map<String, Object?>>[];
  for (final rawComponent in rawSurface) {
    if (rawComponent is! Map) {
      throw const FormatException(
        'ui_action currentSurface contains an invalid component.',
      );
    }
    surface.add(Map<String, Object?>.from(rawComponent));
  }
  return GenUiActionTurn(
    action: GenUiAction.fromJson(Map<String, Object?>.from(rawAction)),
    currentSurface: surface,
  );
}

String _modelInputForTurn(GenUiTurn turn) => switch (turn) {
  GenUiPromptTurn(:final text) => text,
  GenUiActionTurn() =>
    '''
The user interacted with the current generated surface. Respond to this
structured UI action by returning the complete next A2UI surface.

${jsonEncode(turn.toJson())}
''',
};

String _extractOutputText(Map<String, Object?> response) {
  final output = response['output'];
  if (output is List) {
    for (final rawItem in output) {
      if (rawItem is! Map || rawItem['type'] != 'message') continue;
      final content = rawItem['content'];
      if (content is! List) continue;
      for (final rawPart in content) {
        if (rawPart is Map && rawPart['type'] == 'output_text') {
          final text = rawPart['text'];
          if (text is String && text.isNotEmpty) return text;
        }
        if (rawPart is Map && rawPart['type'] == 'refusal') {
          throw OpenAiException(
            HttpStatus.unprocessableEntity,
            rawPart['refusal'] as String? ?? 'OpenAI refused the request.',
          );
        }
      }
    }
  }
  throw OpenAiException(
    HttpStatus.badGateway,
    'OpenAI returned no generated UI output.',
  );
}

Map<String, Object?> _buildOutputSchema(Map<String, Object?> catalog) {
  final rawCapabilities = catalog['capabilities'];
  if (rawCapabilities is! Map || rawCapabilities['components'] is! Map) {
    throw const FormatException('Catalog capabilities are missing components.');
  }
  final components = Map<String, Object?>.from(
    rawCapabilities['components']! as Map,
  );
  if (components.isEmpty) {
    throw const FormatException('Catalog contains no components.');
  }
  final componentSchemas = <Map<String, Object?>>[];
  for (final entry in components.entries) {
    final rawDefinition = entry.value;
    if (rawDefinition is! Map) continue;
    final definition = Map<String, Object?>.from(rawDefinition);
    final rawProperties = definition['properties'];
    final properties = rawProperties is Map
        ? Map<String, Object?>.from(rawProperties)
        : const <String, Object?>{};
    final outputProperties = <String, Object?>{
      'id': {
        'type': 'string',
        'description': 'Unique surface-local component ID.',
      },
      'component': {'type': 'string', 'const': entry.key},
      for (final property in properties.entries)
        property.key: {
          'anyOf': [
            _cleanPropertySchema(property.value),
            {'type': 'null'},
          ],
        },
    };
    componentSchemas.add({
      'type': 'object',
      if (definition['description'] case final String description)
        'description': description,
      'properties': outputProperties,
      'required': outputProperties.keys.toList(),
      'additionalProperties': false,
    });
  }
  return {
    'type': 'object',
    'properties': {
      'components': {
        'type': 'array',
        'description':
            'Complete flat A2UI tree. It must contain exactly one id root.',
        'minItems': 1,
        'items': {'anyOf': componentSchemas},
      },
    },
    'required': ['components'],
    'additionalProperties': false,
  };
}

Object _cleanPropertySchema(Object? rawSchema) {
  if (rawSchema is! Map) return const {'type': 'string'};
  final schema = Map<String, Object?>.from(rawSchema);
  final reference = schema[r'$ref'];
  if (reference is String && reference.endsWith(r'#/$defs/Action')) {
    return const {
      'type': 'object',
      'properties': {
        'event': {
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
          },
          'required': ['name'],
          'additionalProperties': false,
        },
      },
      'required': ['event'],
      'additionalProperties': false,
    };
  }
  const supported = {
    'type',
    'description',
    'enum',
    'const',
    'minimum',
    'maximum',
    'multipleOf',
    'minItems',
    'maxItems',
    'minLength',
    'maxLength',
  };
  final cleaned = <String, Object?>{
    for (final entry in schema.entries)
      if (supported.contains(entry.key)) entry.key: entry.value,
  };
  if (schema['items'] case final items?) {
    cleaned['items'] = _cleanPropertySchema(items);
  }
  if (cleaned.isEmpty) cleaned['type'] = 'string';
  return cleaned;
}

String _buildInstructions(Map<String, Object?> catalog) {
  final catalogInfo = catalog['catalog'];
  final prompts = catalog['systemPromptFragments'];
  final examples = catalog['examples'];
  return '''
You generate a complete, renderable A2UI v0.9 component tree for a Flutter app.
The response schema is authoritative. Follow these additional graph rules:
- Input is either a direct user prompt or a structured ui_action continuation.
- For ui_action input, use its action context and currentSurface to produce the
  complete next surface. Preserve still-relevant content and state.
- Use only component types in the supplied catalog.
- Include exactly one component whose id is "root".
- Component IDs are unique within the surface.
- A single-child property is another component's ID.
- A multi-child property is an ordered list of component IDs.
- Every referenced child ID exists in the same response.
- Do not reference root as a child and do not create cycles.
- Keep visible copy concise and useful.
- For an interactive event, use a short semantic event name.

Catalog:
${jsonEncode(catalogInfo)}

Catalog guidance:
${jsonEncode(prompts)}

Valid materialized examples:
${jsonEncode(examples)}
''';
}

void _validateComponentEnvelope(
  List<Map<String, Object?>> components,
  Map<String, Object?> catalog,
) {
  final rawCapabilities = catalog['capabilities']! as Map;
  final knownTypes = (rawCapabilities['components']! as Map).keys.toSet();
  final ids = <String>{};
  final typesById = <String, String>{};
  var rootCount = 0;
  for (final component in components) {
    final id = component['id'];
    final type = component['component'];
    if (id is! String || id.isEmpty || !ids.add(id)) {
      throw const FormatException(
        'Component IDs must be non-empty and unique.',
      );
    }
    if (id == 'root') rootCount++;
    if (type is! String || !knownTypes.contains(type)) {
      throw FormatException('Unknown generated component type: $type.');
    }
    typesById[id] = type;
  }
  if (rootCount != 1) {
    throw const FormatException('Generated UI must contain exactly one root.');
  }

  final knobsByType = _knobsByComponentType(catalog);
  final edges = <String, Set<String>>{for (final id in ids) id: <String>{}};
  for (final component in components) {
    final id = component['id']! as String;
    final type = component['component']! as String;
    for (final knob in knobsByType[type] ?? const <Map<String, Object?>>[]) {
      final knobId = knob['id'];
      final kind = knob['kind'];
      if (knobId is! String || !component.containsKey(knobId)) continue;
      final value = component[knobId];
      final references = switch (kind) {
        'component-instance' when value is String => [value],
        'component-instances' when value is List => value.whereType<String>(),
        _ => const <String>[],
      };
      final allowedTypes = _allowedComponentTypes(knob, knownTypes);
      for (final childId in references) {
        final childType = typesById[childId];
        if (childType == null) {
          throw FormatException(
            'Component $id references missing child $childId.',
          );
        }
        if (allowedTypes.isNotEmpty && !allowedTypes.contains(childType)) {
          throw FormatException(
            'Component $id cannot use $childType in slot $knobId.',
          );
        }
        edges[id]!.add(childId);
      }
    }
  }

  final visiting = <String>{};
  final reachable = <String>{};
  void visit(String id) {
    if (visiting.contains(id)) {
      throw FormatException(
        'Generated component graph contains a cycle at $id.',
      );
    }
    if (!reachable.add(id)) return;
    visiting.add(id);
    for (final childId in edges[id]!) {
      visit(childId);
    }
    visiting.remove(id);
  }

  visit('root');
  if (reachable.length != ids.length) {
    final orphanIds = ids.difference(reachable).join(', ');
    throw FormatException('Generated component graph has orphans: $orphanIds.');
  }
}

Map<String, List<Map<String, Object?>>> _knobsByComponentType(
  Map<String, Object?> catalog,
) {
  final rawDesy = catalog['desy'];
  if (rawDesy is! Map || rawDesy['components'] is! List) return const {};
  final result = <String, List<Map<String, Object?>>>{};
  for (final rawComponent in rawDesy['components']! as List) {
    if (rawComponent is! Map || rawComponent['id'] is! String) continue;
    final rawKnobs = rawComponent['knobs'];
    result[rawComponent['id']! as String] = rawKnobs is List
        ? [
            for (final rawKnob in rawKnobs)
              if (rawKnob is Map) Map<String, Object?>.from(rawKnob),
          ]
        : const [];
  }
  return result;
}

Set<String> _allowedComponentTypes(
  Map<String, Object?> knob,
  Set<Object?> knownTypes,
) {
  final options = knob['options'];
  if (options is! List || options.isEmpty) return const {};
  final orderedTypes = knownTypes.whereType<String>().toList()
    ..sort((left, right) => right.length.compareTo(left.length));
  return {
    for (final option in options.whereType<String>())
      for (final type in orderedTypes)
        if (option == type || option.startsWith('$type.')) type,
  };
}

Map<String, String> _readDotEnv(File file) {
  if (!file.existsSync()) return const {};
  final result = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final separator = trimmed.indexOf('=');
    if (separator <= 0) continue;
    final key = trimmed.substring(0, separator).trim();
    var value = trimmed.substring(separator + 1).trim();
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      value = value.substring(1, value.length - 1);
    }
    result[key] = value;
  }
  return result;
}

void _addCorsHeaders(HttpResponse response) {
  response.headers
    ..set('access-control-allow-origin', '*')
    ..set('access-control-allow-methods', 'GET, POST, OPTIONS')
    ..set('access-control-allow-headers', 'content-type');
}

Future<void> _writeJson(
  HttpResponse response,
  int statusCode,
  Map<String, Object?> body,
) async {
  response
    ..statusCode = statusCode
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body));
  await response.close();
}

final class OpenAiException implements Exception {
  const OpenAiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

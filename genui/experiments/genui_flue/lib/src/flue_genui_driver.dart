import 'dart:async';
import 'dart:convert';

import 'package:genui/genui.dart';
import 'package:http/http.dart' as http;

/// A non-UI event from Flue that a host app can show in its normal chat or
/// tool-activity UI. These events must not be sent to GenUI's A2UI parser.
final class FlueGenUiTelemetry {
  /// Creates one non-A2UI event emitted by Flue.
  const FlueGenUiTelemetry({required this.type, required this.payload});

  /// Flue update type, such as `tool-input` or `message-delta`.
  final String type;

  /// The original JSON-safe Flue update payload.
  final Map<String, Object?> payload;
}

/// One decoded event from Flue's native server-sent event stream.
final class FlueSseEvent {
  /// Creates one decoded SSE frame.
  const FlueSseEvent({required this.name, required this.data});

  /// The SSE event name.
  final String name;

  /// The complete SSE data payload, joined according to the SSE convention.
  final String data;
}

/// Connects a Flutter GenUI [Conversation] to a native Flue agent endpoint.
///
/// The endpoint is the route mounted by Flue's `createAgentRouter`, including
/// a stable caller-owned conversation ID, such as
/// `http://localhost:5173/agents/orbit/workspace-1`.
///
/// This deliberately talks Flue's public HTTP/SSE protocol directly. The
/// TypeScript Flue agent remains responsible for model selection, tools,
/// credentials, and authorization; this Dart driver only forwards the one
/// A2UI text lane to [A2uiTransportAdapter].
final class FlueGenUiDriver {
  FlueGenUiDriver._({
    required this.endpoint,
    required this.systemPrompt,
    required http.Client httpClient,
    required this.ownsHttpClient,
  }) : _httpClient = httpClient {
    transport = A2uiTransportAdapter(onSend: send);
  }

  /// Starts a driver for a catalog-constrained GenUI conversation.
  factory FlueGenUiDriver.start({
    required Uri endpoint,
    required Catalog catalog,
    Iterable<String> systemPromptFragments = const [],
    http.Client? httpClient,
  }) {
    final prompt = PromptBuilder.chat(
      catalog: catalog,
      systemPromptFragments: systemPromptFragments.toList(growable: false),
    );
    return FlueGenUiDriver._(
      endpoint: endpoint,
      systemPrompt: prompt.systemPromptJoined(),
      httpClient: httpClient ?? http.Client(),
      ownsHttpClient: httpClient == null,
    );
  }

  /// Native Flue conversation endpoint, not a generic server base URL.
  final Uri endpoint;

  /// Prompt material derived from the Flutter catalog and app instructions.
  final String systemPrompt;
  final http.Client _httpClient;

  /// Whether this driver must close its HTTP client during [close].
  final bool ownsHttpClient;

  /// Connect this to [Conversation]. It consumes only A2UI text deltas.
  late final A2uiTransportAdapter transport;

  final StreamController<FlueGenUiTelemetry> _telemetry =
      StreamController<FlueGenUiTelemetry>.broadcast();

  /// Tool, reasoning, and diagnostic lifecycle events from Flue.
  Stream<FlueGenUiTelemetry> get telemetry => _telemetry.stream;

  /// Admits [message] to Flue, then streams its A2UI response until settled.
  Future<void> send(ChatMessage message) async {
    final admission = await _admit(message);
    final updatesUri = endpoint.replace(
      queryParameters: {
        'view': 'updates',
        'offset': admission.offset,
        'live': 'sse',
      },
    );
    final request = http.Request('GET', updatesUri)
      ..headers['accept'] = 'text/event-stream';
    final response = await _httpClient.send(request);
    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw StateError(
        'Flue updates stream failed: HTTP ${response.statusCode} $body',
      );
    }
    await _consumeUpdates(response.stream, admission.submissionId);
  }

  Future<_FlueAdmission> _admit(ChatMessage message) async {
    final response = await _httpClient.post(
      endpoint,
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({'kind': 'user', 'body': _promptFor(message.text)}),
    );
    final decoded = _decodeObject(response.body, 'Flue admission');
    if (response.statusCode != 202) {
      throw StateError(
        'Flue admission failed: HTTP ${response.statusCode} '
        '${decoded['error'] ?? response.body}',
      );
    }
    final offset = decoded['offset'];
    final submissionId = decoded['submissionId'];
    if (offset is! String || submissionId is! String) {
      throw StateError('Flue admission omitted offset or submissionId.');
    }
    return _FlueAdmission(offset: offset, submissionId: submissionId);
  }

  String _promptFor(String userText) =>
      '''
$systemPrompt

You are answering the user turn below through a Flutter GenUI surface. Use
available application tools when they are useful. Your final text output must
contain only valid, ordered A2UI messages for the catalog above: no markdown,
no prose, and no reasoning. Tool and reasoning progress is delivered separately
by Flue and is never A2UI.

User turn:
$userText
''';

  Future<void> _consumeUpdates(
    Stream<List<int>> bytes,
    String submissionId,
  ) async {
    await for (final event in decodeFlueSse(
      bytes.transform(utf8.decoder).transform(const LineSplitter()),
    )) {
      if (event.name != 'data') continue;
      final decoded = jsonDecode(event.data);
      if (decoded is! List) {
        throw StateError('Flue data event was not an update array.');
      }
      for (final rawChunk in decoded) {
        if (rawChunk is! Map) continue;
        final chunk = Map<String, Object?>.from(rawChunk);
        final type = chunk['type'];
        if (type == 'message-delta') {
          final kind = chunk['kind'];
          final delta = chunk['delta'];
          if (kind == 'text' && delta is String) {
            transport.addChunk(delta);
          } else {
            _emitTelemetry(chunk);
          }
          continue;
        }
        if (type == 'submission-settled' &&
            chunk['submissionId'] == submissionId) {
          final outcome = chunk['outcome'];
          if (outcome != 'completed') {
            throw StateError(
              'Flue turn settled as $outcome: ${chunk['error']}',
            );
          }
          return;
        }
        _emitTelemetry(chunk);
      }
    }
    throw StateError(
      'Flue SSE stream ended before the submitted turn settled.',
    );
  }

  void _emitTelemetry(Map<String, Object?> chunk) {
    final type = chunk['type'];
    _telemetry.add(
      FlueGenUiTelemetry(
        type: type is String ? type : 'unknown',
        payload: Map.unmodifiable(chunk),
      ),
    );
  }

  /// Decodes Flue's event-stream framing, without interpreting its payload.
  static Stream<FlueSseEvent> decodeFlueSse(Stream<String> lines) async* {
    var eventName = 'message';
    final data = <String>[];

    FlueSseEvent? takeEvent() {
      if (data.isEmpty) return null;
      final event = FlueSseEvent(name: eventName, data: data.join('\n'));
      eventName = 'message';
      data.clear();
      return event;
    }

    await for (final line in lines) {
      if (line.isEmpty) {
        final event = takeEvent();
        if (event != null) yield event;
        continue;
      }
      if (line.startsWith('event:')) {
        eventName = line.substring('event:'.length).trim();
      } else if (line.startsWith('data:')) {
        data.add(line.substring('data:'.length).trimLeft());
      }
    }
    final event = takeEvent();
    if (event != null) yield event;
  }

  static Map<String, Object?> _decodeObject(String source, String context) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) throw StateError('$context was not a JSON object.');
    return Map<String, Object?>.from(decoded);
  }

  /// Releases the transport, telemetry stream, and optional HTTP client.
  Future<void> close() async {
    transport.dispose();
    await _telemetry.close();
    if (ownsHttpClient) _httpClient.close();
  }
}

final class _FlueAdmission {
  const _FlueAdmission({required this.offset, required this.submissionId});

  final String offset;
  final String submissionId;
}

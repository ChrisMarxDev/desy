// ignore_for_file: public_member_api_docs, curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart' as a2ui;
import 'package:codex_app_server/codex_app_server.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// A local Codex-backed transport that emits only validated A2UI messages.
final class CodexGenUiDriver {
  CodexGenUiDriver._({
    required this.client,
    required this.catalog,
    required this.threadId,
    required this.instructions,
  }) {
    transport = A2uiTransportAdapter(onSend: send);
    _events = client.events.listen(_handleEvent);
  }

  static Future<CodexGenUiDriver> start({
    required Catalog catalog,
    required String instructions,
    String? model,
    String executable = 'codex',
  }) async {
    final client = await CodexAppServerClient.start(executable: executable);
    await client.initialize(name: 'genui_codex', version: '0.0.1');
    final threadId = await client.startThread(model: model);
    return CodexGenUiDriver._(
      client: client,
      catalog: catalog,
      threadId: threadId,
      instructions: instructions,
    );
  }

  final CodexAppServerClient client;
  final Catalog catalog;
  final String threadId;
  final String instructions;
  late final A2uiTransportAdapter transport;
  late final StreamSubscription<CodexAppServerEvent> _events;
  final _turns = <String, _CodexTurn>{};
  final _agentMessagePhases = <String, String?>{};

  /// Sends a GenUI message as a schema-constrained local Codex turn.
  Future<void> send(ChatMessage message) async {
    final text =
        '${instructions.trim()}\n\nUse your available Codex tools when they materially help answer the user. Treat their results as evidence. Do not change workspace files unless the user explicitly asks you to.\n\nReturn only the JSON object required by the output schema. Its `a2ui` value must be a JSON-encoded string containing canonical A2UI server-to-client operation JSON. Do not wrap that inner A2UI operation in a `{ "messages": [...] }` envelope. The operation name is a top-level key: use exactly `{ "version": "v0.9", "updateComponents": { "surfaceId": "...", "components": [...] } }`, never `{ "operation": "updateComponents", "surfaceId": "...", "components": [...] }`.\n\nUser request:\n${message.text}';
    final turnId = await client.startTurn(
      threadId: threadId,
      text: text,
      outputSchema: outputSchemaFor(catalog),
    );
    final turn = _turnFor(turnId);
    final done = turn.done ??= Completer<void>();
    if (turn.completed) turn.finish();
    try {
      await done.future;
    } finally {
      _turns.remove(turnId);
    }
  }

  void _handleEvent(CodexAppServerEvent event) {
    final params = event.params;
    if (event.method == 'item/started') {
      final item = params['item'];
      if (item is Map &&
          item['type'] == 'agentMessage' &&
          item['id'] is String) {
        _agentMessagePhases[item['id']! as String] = item['phase'] as String?;
      }
      return;
    }
    if (event.method == 'item/agentMessage/delta') {
      final turnId = params['turnId'];
      final itemId = params['itemId'];
      final delta = params['delta'];
      if (turnId is String &&
          delta is String &&
          (itemId is! String || _agentMessagePhases[itemId] != 'commentary')) {
        final turn = _turnFor(turnId);
        try {
          turn.receivedA2uiDelta = true;
          turn.decoder.addChunk(delta, transport.addChunk);
        } on Object catch (error) {
          turn.fail(error);
        }
      }
      return;
    }
    if (event.method == 'item/completed') {
      final item = params['item'];
      if (item is Map &&
          item['type'] == 'agentMessage' &&
          item['text'] is String) {
        final turnId = params['turnId'];
        if (turnId is! String) return;
        final turn = _turnFor(turnId);
        try {
          if (turn.receivedA2uiDelta) {
            turn.decoder.finish();
          } else {
            for (final message in decodeA2uiMessages(item['text']! as String)) {
              transport.addMessage(message);
            }
          }
        } on Object catch (error) {
          turn.fail(error);
        }
      }
      return;
    }
    if (event.method == 'turn/completed') {
      final turn = params['turn'];
      final id = turn is Map ? turn['id'] : null;
      if (id is String) _turnFor(id).finish();
    }
  }

  _CodexTurn _turnFor(String turnId) =>
      _turns.putIfAbsent(turnId, _CodexTurn.new);

  /// JSON Schema applied to the final Codex assistant message for each turn.
  ///
  /// Codex's structured-output endpoint does not accept the `oneOf` clauses
  /// required by A2UI's native schema. Keeping the rich A2UI envelope in a
  /// constrained string preserves a schema-validated outer response while
  /// letting the A2UI runtime validate the decoded message itself.
  static Map<String, Object?> outputSchemaFor(Catalog catalog) => S
      .object(
        properties: {'a2ui': S.string()},
        required: ['a2ui'],
        additionalProperties: false,
      )
      .value;

  /// Decodes the bridge envelope into canonical A2UI operations.
  static List<a2ui.A2uiMessage> decodeA2uiMessages(String output) {
    final outer = jsonDecode(output);
    if (outer is! Map || outer['a2ui'] is! String) {
      throw const FormatException(
        'Codex did not return the constrained A2UI response envelope.',
      );
    }
    final decoded = jsonDecode(outer['a2ui']! as String);
    final entries = switch (decoded) {
      {'messages': final List messages} => messages,
      Map() => [decoded],
      List() => decoded,
      _ => throw const FormatException('Codex did not return A2UI JSON.'),
    };
    return List.unmodifiable(
      entries.map((entry) {
        if (entry is! Map)
          throw const FormatException(
            'A2UI envelope contained a non-object message.',
          );
        final message = Map<String, dynamic>.from(entry);
        const operationKeys = {
          'createSurface',
          'updateComponents',
          'updateDataModel',
          'deleteSurface',
        };
        // A2UI client actions go from Flutter to the agent. They are not
        // server-to-client surface operations, and must never be passed to the
        // SurfaceController when a model echoes one beside an update.
        if (!message.keys.any(operationKeys.contains)) return null;
        // The app-server schema can constrain the outer envelope but cannot
        // express A2UI's discriminated union. The experiment is pinned to the
        // v0.9 runtime, so supply its protocol version when Codex omits the
        // otherwise-constant envelope field.
        message.putIfAbsent('version', () => 'v0.9');
        return a2ui.A2uiMessage.fromJson(message);
      }).whereType<a2ui.A2uiMessage>(),
    );
  }

  Future<void> close() async {
    await _events.cancel();
    transport.dispose();
    await client.close();
  }
}

final class _CodexTurn {
  Completer<void>? done;
  final decoder = CodexA2uiEnvelopeDecoder();
  var receivedA2uiDelta = false;
  var completed = false;
  Object? error;

  void finish() {
    completed = true;
    final completer = done;
    if (completer == null || completer.isCompleted) return;
    final failure = error;
    if (failure != null) {
      completer.completeError(failure);
    } else {
      completer.complete();
    }
  }

  void fail(Object failure) {
    error = failure;
    completed = true;
    final completer = done;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(failure);
    }
  }
}

/// Incrementally unwraps the schema-constrained `{"a2ui":"..."}` value.
///
/// The unescaped value is canonical A2UI JSON and is passed directly to
/// [A2uiTransportAdapter.addChunk], allowing GenUI's parser to process an
/// app-server agent-message stream instead of waiting for the final message.
final class CodexA2uiEnvelopeDecoder {
  static final _hexDigit = RegExp(r'^[0-9a-fA-F]$');

  var _state = _EnvelopeState.seekingKey;
  var _keyCursor = 0;
  var _escaping = false;
  StringBuffer? _unicodeDigits;

  /// Adds an app-server text delta and forwards any decoded A2UI JSON.
  void addChunk(String chunk, void Function(String chunk) sink) {
    final output = StringBuffer();
    for (final character in chunk.split('')) {
      _consume(character, output);
    }
    if (output.isNotEmpty) sink(output.toString());
  }

  /// Ensures the outer structured-output object ended after the A2UI value.
  void finish() {
    if (_state != _EnvelopeState.complete ||
        _escaping ||
        _unicodeDigits != null) {
      throw const FormatException(
        'Codex ended before completing the constrained A2UI response.',
      );
    }
  }

  void _consume(String character, StringBuffer output) {
    switch (_state) {
      case _EnvelopeState.seekingKey:
        const key = '"a2ui"';
        if (character == key[_keyCursor]) {
          _keyCursor++;
          if (_keyCursor == key.length) {
            _state = _EnvelopeState.seekingColon;
            _keyCursor = 0;
          }
        } else {
          _keyCursor = character == key[0] ? 1 : 0;
        }
      case _EnvelopeState.seekingColon:
        if (character == ':') _state = _EnvelopeState.seekingValue;
      case _EnvelopeState.seekingValue:
        if (character.trim().isEmpty) return;
        if (character != '"') {
          throw const FormatException(
            'The constrained `a2ui` value was not a string.',
          );
        }
        _state = _EnvelopeState.readingValue;
      case _EnvelopeState.readingValue:
        _readValueCharacter(character, output);
      case _EnvelopeState.complete:
        return;
    }
  }

  void _readValueCharacter(String character, StringBuffer output) {
    final unicode = _unicodeDigits;
    if (unicode != null) {
      if (!_hexDigit.hasMatch(character)) {
        throw const FormatException(
          'Invalid unicode escape in Codex A2UI output.',
        );
      }
      unicode.write(character);
      if (unicode.length == 4) {
        output.writeCharCode(int.parse(unicode.toString(), radix: 16));
        _unicodeDigits = null;
        _escaping = false;
      }
      return;
    }
    if (_escaping) {
      switch (character) {
        case '"':
        case '\\':
        case '/':
          output.write(character);
          break;
        case 'b':
          output.write('\b');
          break;
        case 'f':
          output.write('\f');
          break;
        case 'n':
          output.write('\n');
          break;
        case 'r':
          output.write('\r');
          break;
        case 't':
          output.write('\t');
          break;
        case 'u':
          _unicodeDigits = StringBuffer();
          return;
        default:
          throw const FormatException('Invalid escape in Codex A2UI output.');
      }
      _escaping = false;
      return;
    }
    if (character == '\\') {
      _escaping = true;
    } else if (character == '"') {
      _state = _EnvelopeState.complete;
    } else {
      output.write(character);
    }
  }
}

enum _EnvelopeState {
  seekingKey,
  seekingColon,
  seekingValue,
  readingValue,
  complete,
}

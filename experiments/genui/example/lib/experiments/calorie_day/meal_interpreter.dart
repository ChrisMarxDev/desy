// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:codex_app_server/codex_app_server.dart';

/// The small, app-owned record that is appended to the day's local state.
///
/// It is deliberately independent of A2UI: A2UI renders the resulting state,
/// while Codex is responsible only for interpreting one conversational turn.
final class CalorieMeal {
  const CalorieMeal({
    required this.label,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final String label;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  Map<String, Object> toJson() => {
    'label': label,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
  };
}

/// One inspectable step in the local-Codex-to-A2UI handoff.
final class MealFlowEvent {
  MealFlowEvent({
    required this.source,
    required this.name,
    required this.detail,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final DateTime timestamp;
  final String source;
  final String name;
  final String detail;

  String get time =>
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

  Map<String, String> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'source': source,
    'name': name,
    'detail': detail,
  };

  @override
  String toString() => jsonEncode(toJson());
}

/// The outcome of one model-generated interpretation.
final class MealInterpretation {
  const MealInterpretation({
    required this.logged,
    required this.reply,
    this.meal,
  });

  final bool logged;
  final String reply;
  final CalorieMeal? meal;

  factory MealInterpretation.fromJson(Map<String, Object?> json) {
    final logged = json['logged'];
    final reply = json['reply'];
    final label = json['label'];
    final calories = _number(json['calories']);
    final protein = _number(json['protein']);
    final carbs = _number(json['carbs']);
    final fat = _number(json['fat']);
    if (logged is! bool || reply is! String || reply.trim().isEmpty) {
      throw const FormatException(
        'Codex returned an incomplete meal response.',
      );
    }
    if (!logged) return MealInterpretation(logged: false, reply: reply);
    if (label is! String ||
        label.trim().isEmpty ||
        calories == null ||
        protein == null ||
        carbs == null ||
        fat == null ||
        calories < 0 ||
        protein < 0 ||
        carbs < 0 ||
        fat < 0) {
      throw const FormatException('Codex returned invalid meal values.');
    }
    return MealInterpretation(
      logged: true,
      reply: reply,
      meal: CalorieMeal(
        label: label,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
      ),
    );
  }

  static double? _number(Object? value) => switch (value) {
    num() => value.toDouble(),
    _ => null,
  };
}

/// Boundary used by the UI, keeping the local Codex transport replaceable.
abstract interface class MealInterpreter {
  Stream<MealFlowEvent> get events;

  Future<MealInterpretation> interpret({
    required String message,
    required List<CalorieMeal> daySoFar,
  });

  Future<void> close();
}

typedef MealInterpreterFactory = MealInterpreter Function();

/// Explicit unavailable state for non-Codex launches; it never fabricates food
/// data as a substitute for the model.
final class UnavailableMealInterpreter implements MealInterpreter {
  const UnavailableMealInterpreter();

  @override
  Stream<MealFlowEvent> get events => const Stream.empty();

  @override
  Future<MealInterpretation> interpret({
    required String message,
    required List<CalorieMeal> daySoFar,
  }) => Future.value(
    const MealInterpretation(
      logged: false,
      reply:
          'Local Codex is not connected. Start this sample with the Codex driver to log an AI-generated estimate.',
    ),
  );

  @override
  Future<void> close() => Future.value();
}

/// Interprets food messages with the authenticated local Codex app-server.
///
/// This is not an A2UI transport. Codex produces one schema-constrained data
/// record; Flutter appends that record and then sends its local day snapshot to
/// the stable A2UI surface through `updateDataModel`.
final class CodexMealInterpreter implements MealInterpreter {
  CodexMealInterpreter({this.model, this.executable = 'codex'});

  final String? model;
  final String executable;
  CodexAppServerClient? _client;
  String? _threadId;
  StreamSubscription<CodexAppServerEvent>? _events;
  final _turns = <String, _MealTurn>{};
  final _messagePhases = <String, String?>{};
  final _flowEvents = StreamController<MealFlowEvent>.broadcast();

  @override
  Stream<MealFlowEvent> get events => _flowEvents.stream;

  @override
  Future<MealInterpretation> interpret({
    required String message,
    required List<CalorieMeal> daySoFar,
  }) async {
    await _ensureStarted();
    final client = _client!;
    final day = jsonEncode([for (final entry in daySoFar) entry.toJson()]);
    final turnId = await client.startTurn(
      threadId: _threadId!,
      text:
          '''
You are the meal interpreter in a personal calorie-day prototype. Interpret the user's newest message as one food or drink entry, using ordinary nutritional knowledge to estimate calories and macronutrients when quantities are reasonably inferable.

This is an estimate, not nutrition, dietary, or medical advice. Do not give health guidance, targets, or judgments. If the message is not loggable, set `logged` to false and ask one concise clarification. If it is loggable, set `logged` to true, give a concise label, non-negative estimated calories/protein/carbs/fat, and a short reply that explicitly says the values are an estimate.

Existing entries for context only: $day

Newest user message: $message

Return only the JSON object required by the output schema.
''',
      outputSchema: _outputSchema,
    );
    _emit(
      'turn.started',
      'turn=$turnId · message=${message.length} chars · day=${daySoFar.length} entries',
    );
    final turn = _turns.putIfAbsent(turnId, _MealTurn.new);
    final done = turn.done ??= Completer<String>();
    if (turn.completed) turn.finish();
    try {
      final output = await done.future;
      final decoded = jsonDecode(output);
      if (decoded is! Map) {
        throw const FormatException('Codex did not return a meal JSON object.');
      }
      final interpretation = MealInterpretation.fromJson(
        Map<String, Object?>.from(decoded),
      );
      _emit(
        'interpretation.parsed',
        interpretation.logged
            ? 'logged ${interpretation.meal!.label} · ${interpretation.meal!.calories.round()} kcal'
            : 'not logged · ${interpretation.reply}',
      );
      return interpretation;
    } finally {
      _turns.remove(turnId);
    }
  }

  Future<void> _ensureStarted() async {
    if (_client != null) return;
    final client = await CodexAppServerClient.start(executable: executable);
    _emit('app-server.started', 'executable=$executable');
    await client.initialize(name: 'genui_calorie_day', version: '0.1.0');
    _client = client;
    _threadId = await client.startThread(model: model);
    _emit('thread.started', 'thread=$_threadId · model=${model ?? 'default'}');
    _events = client.events.listen(
      _handleEvent,
      onError: (Object error) => _emit('app-server.error', '$error'),
    );
  }

  void _handleEvent(CodexAppServerEvent event) {
    final params = event.params;
    if (event.method == 'item/started') {
      final item = params['item'];
      if (item is Map &&
          item['type'] == 'agentMessage' &&
          item['id'] is String) {
        _messagePhases[item['id']! as String] = item['phase'] as String?;
        _emit(
          'app-server.item.started',
          'phase=${item['phase'] ?? 'unknown'} · item=${item['id']}',
        );
      }
      return;
    }
    if (event.method == 'item/completed') {
      final turnId = params['turnId'];
      final item = params['item'];
      if (turnId is String &&
          item is Map &&
          item['type'] == 'agentMessage' &&
          item['text'] is String &&
          (item['id'] is! String ||
              _messagePhases[item['id']] != 'commentary')) {
        _turns.putIfAbsent(turnId, _MealTurn.new).output =
            item['text']! as String;
        _emit('app-server.agent-message', item['text']! as String);
      }
      return;
    }
    if (event.method == 'turn/completed') {
      final turn = params['turn'];
      final turnId = turn is Map ? turn['id'] : null;
      if (turnId is String) {
        _emit('turn.completed', 'turn=$turnId');
        _turns.putIfAbsent(turnId, _MealTurn.new).finish();
      }
    }
  }

  @override
  Future<void> close() async {
    await _events?.cancel();
    _events = null;
    final client = _client;
    _client = null;
    _threadId = null;
    if (client != null) await client.close();
    await _flowEvents.close();
  }

  void _emit(String name, String detail) {
    final event = MealFlowEvent(source: 'codex', name: name, detail: detail);
    debugPrint('CALORIE_DAY_FLOW $event');
    if (!_flowEvents.isClosed) _flowEvents.add(event);
  }

  static const _outputSchema = <String, Object?>{
    'type': 'object',
    'properties': {
      'logged': {'type': 'boolean'},
      'reply': {'type': 'string'},
      'label': {'type': 'string'},
      'calories': {'type': 'number'},
      'protein': {'type': 'number'},
      'carbs': {'type': 'number'},
      'fat': {'type': 'number'},
    },
    'required': [
      'logged',
      'reply',
      'label',
      'calories',
      'protein',
      'carbs',
      'fat',
    ],
    'additionalProperties': false,
  };
}

final class _MealTurn {
  Completer<String>? done;
  String? output;
  var completed = false;

  void finish() {
    completed = true;
    final completer = done;
    if (completer == null || completer.isCompleted) return;
    final output = this.output;
    if (output == null) {
      completer.completeError(
        const FormatException('Codex completed without a meal response.'),
      );
    } else {
      completer.complete(output);
    }
  }
}

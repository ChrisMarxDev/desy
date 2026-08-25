import 'dart:convert';

/// A typed user action emitted by a generated A2UI surface.
final class GenUiAction {
  /// Creates an immutable generated-surface action.
  GenUiAction({
    required this.name,
    required this.sourceComponentId,
    required this.surfaceId,
    required this.timestamp,
    Map<String, Object?> context = const {},
  }) : context = Map.unmodifiable(context);

  /// Parses the interaction envelope emitted by GenUI's surface controller.
  factory GenUiAction.fromInteraction(String interaction) {
    final Object? decoded;
    try {
      decoded = jsonDecode(interaction);
    } on FormatException {
      throw const FormatException('UI interaction is not valid JSON.');
    }
    if (decoded is! Map) {
      throw const FormatException('UI interaction must be an object.');
    }
    final envelope = Map<String, Object?>.from(decoded);
    if (envelope['version'] != 'v0.9') {
      throw const FormatException('UI interaction must use A2UI v0.9.');
    }
    final rawAction = envelope['action'];
    if (rawAction is! Map) {
      throw const FormatException('UI interaction contains no action.');
    }
    return GenUiAction.fromJson(Map<String, Object?>.from(rawAction));
  }

  /// Parses one action object from the provider-neutral wire format.
  factory GenUiAction.fromJson(Map<String, Object?> json) {
    final name = json['name'];
    final sourceComponentId = json['sourceComponentId'];
    final surfaceId = json['surfaceId'];
    final timestamp = json['timestamp'];
    final rawContext = json['context'];
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('UI action name must be non-empty.');
    }
    if (sourceComponentId is! String || sourceComponentId.trim().isEmpty) {
      throw const FormatException(
        'UI action sourceComponentId must be non-empty.',
      );
    }
    if (surfaceId is! String || surfaceId.trim().isEmpty) {
      throw const FormatException('UI action surfaceId must be non-empty.');
    }
    if (timestamp is! String || DateTime.tryParse(timestamp) == null) {
      throw const FormatException('UI action timestamp must be an ISO date.');
    }
    if (rawContext != null && rawContext is! Map) {
      throw const FormatException('UI action context must be an object.');
    }
    return GenUiAction(
      name: name.trim(),
      sourceComponentId: sourceComponentId.trim(),
      surfaceId: surfaceId.trim(),
      timestamp: timestamp,
      context: rawContext == null
          ? const {}
          : Map<String, Object?>.from(rawContext as Map),
    );
  }

  /// Semantic action selected by the generating agent.
  final String name;

  /// Surface-local component that emitted the action.
  final String sourceComponentId;

  /// Surface affected by the action.
  final String surfaceId;

  /// A2UI event timestamp, preserved exactly as emitted.
  final String timestamp;

  /// Runtime payload and resolved action context.
  final Map<String, Object?> context;

  /// Returns the JSON-safe action sent to an agent backend.
  Map<String, Object?> toJson() => {
    'name': name,
    'sourceComponentId': sourceComponentId,
    'timestamp': timestamp,
    'context': context,
    'surfaceId': surfaceId,
  };
}

/// One provider-neutral input turn for a GenUI agent.
sealed class GenUiTurn {
  const GenUiTurn();

  /// Returns the JSON-safe turn sent to an agent backend.
  Map<String, Object?> toJson();
}

/// A direct text request that starts or advances a GenUI flow.
final class GenUiPromptTurn extends GenUiTurn {
  /// Creates a non-empty prompt turn.
  GenUiPromptTurn(String text) : text = text.trim() {
    if (this.text.isEmpty) {
      throw ArgumentError.value(text, 'text', 'Enter a UI request.');
    }
  }

  /// User-authored request text.
  final String text;

  @override
  Map<String, Object?> toJson() => {'type': 'prompt', 'text': text};
}

/// A generated-surface action returned to the agent as a continuation turn.
final class GenUiActionTurn extends GenUiTurn {
  /// Creates an action turn with the surface state visible when it fired.
  GenUiActionTurn({
    required this.action,
    required List<Map<String, Object?>> currentSurface,
  }) : currentSurface = List.unmodifiable(
         currentSurface.map(
           (component) => Map<String, Object?>.unmodifiable(component),
         ),
       );

  /// Typed action emitted by the generated surface.
  final GenUiAction action;

  /// Complete current A2UI component graph used as agent context.
  final List<Map<String, Object?>> currentSurface;

  @override
  Map<String, Object?> toJson() => {
    'type': 'ui_action',
    'action': action.toJson(),
    'currentSurface': currentSurface,
  };
}

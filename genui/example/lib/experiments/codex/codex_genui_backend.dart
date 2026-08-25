// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart' as a2ui;
import 'package:desy_genui/desy_genui.dart';
import 'package:genui/genui.dart';
import 'package:genui_codex/genui_codex.dart';

import '../../genui_backend.dart';

/// Desktop-only local Codex experiment. It does not use the HTTP backend.
final class CodexGenUiBackend implements StreamingGenUiBackend {
  CodexGenUiBackend({this.model});

  final String? model;
  CodexGenUiDriver? _driver;
  final _incomingMessages = StreamController<a2ui.A2uiMessage>.broadcast();
  StreamSubscription<a2ui.A2uiMessage>? _driverMessages;
  List<Map<String, Object?>>? _latestComponents;

  @override
  Stream<a2ui.A2uiMessage> get incomingMessages => _incomingMessages.stream;

  @override
  Future<GeneratedSurface> respond({
    required GenUiTurn turn,
    required DesyGenUiCatalog catalog,
  }) async {
    final driver = _driver ??= await CodexGenUiDriver.start(
      catalog: catalog.catalog,
      model: model,
      instructions: _instructions(catalog),
    );
    _driverMessages ??= driver.transport.incomingMessages.listen((message) {
      if (message is a2ui.UpdateComponentsMessage) {
        _latestComponents = List.unmodifiable(
          message.components.map((item) => Map<String, Object?>.from(item)),
        );
      }
      _incomingMessages.add(message);
    }, onError: _incomingMessages.addError);
    _latestComponents = null;
    await driver.transport.sendRequest(
      ChatMessage.user(jsonEncode(turn.toJson())),
    );
    final surface = _latestComponents;
    if (surface == null ||
        !surface.any((component) => component['id'] == 'root')) {
      throw StateError(
        'Local Codex completed without an A2UI updateComponents response '
        'containing root.',
      );
    }
    return GeneratedSurface(
      components: surface,
      model: model ?? 'local-codex',
      responseId: 'codex-local',
    );
  }

  String _instructions(DesyGenUiCatalog catalog) {
    final fragments = catalog.backendArtifact['systemPromptFragments'];
    final guidance = fragments is List
        ? fragments.whereType<String>().join('\n')
        : '';
    final schema = jsonEncode(catalog.backendArtifact['fullSchema']);
    return '$guidance\n\n'
        'Use exactly one updateComponents operation for surface '
        'orbit-experiment. The top-level component instance must have id '
        '`root` and component `orbit.component.stack`. Each component object '
        'uses the flat form `{ "id": "...", "component": '
        '"registry.component.id", "property": value }`: properties are '
        'directly on the object. Do not use a nested `component.type`, `props`, '
        'or `children` structure. Supply all child IDs through the component '
        'properties declared in this catalog. Do not create, delete, or update '
        'any other surface. Do not emit an A2UI `action` message; UI actions '
        'are sent from the app to the agent, never in this response. The '
        '`a2ui` string must contain that canonical operation object directly, '
        'with its `version` set to `v0.9`; do not wrap it in `messages`.\n\n'
        'Catalog data schemas (for component properties):\n$schema\n\n'
        'Wire format rule: the operation name is the top-level key. Emit '
        '`{ "version": "v0.9", "updateComponents": { "surfaceId": '
        '"orbit-experiment", "components": [...] } }`. Never emit the '
        'legacy sibling-field form with `operation`, `surfaceId`, and '
        '`components` at the same level.';
  }

  @override
  void close() {
    unawaited(_driverMessages?.cancel());
    unawaited(_incomingMessages.close());
    unawaited(_driver?.close());
  }
}

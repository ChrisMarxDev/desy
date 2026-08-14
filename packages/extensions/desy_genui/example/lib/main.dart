import 'dart:async';

import 'package:a2ui_core/a2ui_core.dart' as a2ui;
import 'package:desy_design_system/desy_design_system.dart';
import 'package:desy_design_system_example/desy_design_system_example.dart';
import 'package:desy_genui/desy_genui.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import 'genui_backend.dart';

void main() => runApp(const DesyGenUiExampleApp());

/// Decides whether an emitted surface action should become an agent turn.
typedef GenUiActionPolicy = bool Function(GenUiAction action);

/// A prompt-driven app rendering A2UI with Desy's dogfood registry.
class DesyGenUiExampleApp extends StatelessWidget {
  /// Creates the sample app.
  const DesyGenUiExampleApp({
    super.key,
    this.backend,
    this.shouldForwardAction,
  });

  /// Optional backend override used by tests or alternative agent hosts.
  final GenUiBackend? backend;

  /// Optional app-owned policy for forwarding generated-surface actions.
  ///
  /// This agent-only sample forwards every user action by default. A real app
  /// can keep navigation, persistence, and other business events local.
  final GenUiActionPolicy? shouldForwardAction;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: DesyDesignSystemFoundation.materialTheme(
      DesyDesignSystemTheme.light,
    ),
    supportedLocales: DesyDesignSystemFoundation.supportedLocales,
    localizationsDelegates: DesyDesignSystemFoundation.localizationsDelegates,
    home: DesyDesignSystemScope(
      theme: DesyDesignSystemTheme.light,
      child: _GenUiPage(
        backend: backend,
        shouldForwardAction: shouldForwardAction,
      ),
    ),
  );
}

class _GenUiPage extends StatefulWidget {
  const _GenUiPage({this.backend, this.shouldForwardAction});

  final GenUiBackend? backend;
  final GenUiActionPolicy? shouldForwardAction;

  @override
  State<_GenUiPage> createState() => _GenUiPageState();
}

class _GenUiPageState extends State<_GenUiPage> {
  static const _surfaceId = 'dogfood-agent-demo';
  late final DesyGenUiCatalog compiled;
  late final SurfaceController controller;
  GenUiBackend? _backend;
  late final bool _ownsBackend;
  StreamSubscription<ChatMessage>? _events;
  String _prompt =
      'Create a concise component inspection card with one clear action.';
  String? _submittedPrompt;
  String _lastAction = 'No generated UI event received yet.';
  String _source = 'LOCAL FIXTURE';
  String? _error;
  bool _isGenerating = false;
  List<Map<String, Object?>> _activeComponents = _fixtureComponents;

  @override
  void initState() {
    super.initState();
    compiled = DesyGenUiCatalog.compile(desyDesignSystemRegistry);
    controller = SurfaceController(catalogs: [compiled.catalog]);
    _ownsBackend = widget.backend == null;
    _backend = widget.backend;
    _events = controller.onSubmit.listen((message) {
      final interaction = message.parts.first.asUiInteractionPart?.interaction;
      if (!mounted || interaction == null) return;
      _handleInteraction(interaction);
    });
    controller.handleMessage(
      a2ui.CreateSurfaceMessage(
        surfaceId: _surfaceId,
        catalogId: compiled.catalog.catalogId!,
      ),
    );
    _updateSurface(_fixtureComponents);
  }

  @override
  void dispose() {
    unawaited(_events?.cancel());
    if (_ownsBackend) _backend?.close();
    controller.dispose();
    super.dispose();
  }

  void _updateSurface(List<Map<String, Object?>> components) {
    _activeComponents = List.unmodifiable(
      components.map(
        (component) => Map<String, Object?>.unmodifiable(component),
      ),
    );
    controller.handleMessage(
      a2ui.UpdateComponentsMessage(
        surfaceId: _surfaceId,
        components: [
          for (final component in components)
            Map<String, dynamic>.from(component),
        ],
      ),
    );
  }

  Future<void> _generate(String prompt) async {
    await _respond(GenUiPromptTurn(prompt), submittedPrompt: prompt);
  }

  void _handleInteraction(String interaction) {
    setState(() => _lastAction = interaction);
    final GenUiAction action;
    try {
      action = GenUiAction.fromInteraction(interaction);
    } on FormatException catch (error) {
      setState(() => _error = 'Invalid generated UI action: ${error.message}');
      return;
    }
    if (widget.shouldForwardAction?.call(action) == false) return;
    unawaited(
      _respond(
        GenUiActionTurn(action: action, currentSurface: _activeComponents),
      ),
    );
  }

  Future<void> _respond(GenUiTurn turn, {String? submittedPrompt}) async {
    if (_isGenerating) return;
    setState(() {
      if (submittedPrompt != null) _submittedPrompt = submittedPrompt;
      _isGenerating = true;
      _error = null;
    });
    try {
      final activeBackend = _backend ??= OpenAiGenUiBackend();
      final result = await activeBackend.respond(turn: turn, catalog: compiled);
      if (!mounted) return;
      _updateSurface(result.components);
      setState(() => _source = '${result.model} · ${result.responseId}');
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) => DesyScaffold(
    childPad: false,
    child: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceXl),
            children: [
              DesyChatThread(
                title: 'GENUI AGENT',
                detail: '${compiled.catalog.catalogId} · $_source',
                messages: [
                  if (_submittedPrompt case final prompt?)
                    DesyChatMessage(
                      role: DesyChatRole.user,
                      child: Text(prompt),
                    ),
                  DesyChatMessage(
                    role: DesyChatRole.agent,
                    pending: _isGenerating,
                    child: _AgentResult(
                      error: _error,
                      controller: controller,
                      surfaceId: _surfaceId,
                      lastAction: _lastAction,
                    ),
                  ),
                ],
                composer: DesyChatComposer(
                  key: const ValueKey('genui-composer'),
                  value: _prompt,
                  loading: _isGenerating,
                  errorText: _error,
                  onChanged: (value) => _prompt = value,
                  onSubmit: _generate,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AgentResult extends StatelessWidget {
  const _AgentResult({
    required this.error,
    required this.controller,
    required this.surfaceId,
    required this.lastAction,
  });

  final String? error;
  final SurfaceController controller;
  final String surfaceId;
  final String lastAction;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (error case final error?)
        Text(
          error,
          key: const ValueKey('generation-error'),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        )
      else
        DesyGenUiSurface(
          controller: controller,
          surfaceId: surfaceId,
          theme: desyDesignSystemRegistry.themes.first,
        ),
      const SizedBox(height: DesyDesignSystemTokens.spaceBase),
      const Divider(height: 1),
      const SizedBox(height: DesyDesignSystemTokens.spaceMd),
      Text('LATEST UI EVENT', style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: DesyDesignSystemTokens.spaceXs),
      SelectableText(
        lastAction,
        key: const ValueKey('last-action'),
        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
      ),
    ],
  );
}

const _fixtureComponents = <Map<String, Object?>>[
  {
    'id': 'root',
    'component': 'desy.component.card',
    'title': 'Dogfood registry connected',
    'body':
        'This surface is rendered from the same Desy registry used by the '
        'maintained workbench catalogue. Generate a prompt to replace it.',
    'showBody': true,
  },
];

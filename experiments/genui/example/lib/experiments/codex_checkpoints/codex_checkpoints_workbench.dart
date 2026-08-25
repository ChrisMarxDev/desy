// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:a2ui_core/a2ui_core.dart' as a2ui;
import 'package:desy_bench/desy_bench.dart';
import 'package:desy_genui/desy_genui.dart';
import 'package:flutter/widgets.dart';
import 'package:genui/genui.dart';

import '../../genui_backend.dart';
import '../../orbit/orbit_theme.dart';
import 'checkpoint_task_driver.dart';

/// Separate GenUI coding workflow showing task decisions rather than chat UI.
class CodexCheckpointsWorkbench extends StatefulWidget {
  const CodexCheckpointsWorkbench({
    super.key,
    required this.catalog,
    required this.theme,
    this.driver,
  });

  final DesyGenUiCatalog catalog;
  final DesyTheme theme;
  final GenUiBackend? driver;

  @override
  State<CodexCheckpointsWorkbench> createState() =>
      _CodexCheckpointsWorkbenchState();
}

class _CodexCheckpointsWorkbenchState extends State<CodexCheckpointsWorkbench> {
  static const _surfaceId = 'codex-checkpoints';

  late final SurfaceController _controller;
  late final StreamSubscription<ChatMessage> _events;
  late final GenUiBackend _driver;
  var _currentSurface = <Map<String, Object?>>[];
  var _loading = true;
  var _lastAction = 'Starting the local coding task…';
  String? _error;

  @override
  void initState() {
    super.initState();
    _driver = widget.driver ?? CheckpointTaskDriver();
    _controller = SurfaceController(catalogs: [widget.catalog.catalog]);
    _events = _controller.onSubmit.listen(_handleInteraction);
    _controller.handleMessage(
      a2ui.CreateSurfaceMessage(
        surfaceId: _surfaceId,
        catalogId: widget.catalog.catalog.catalogId!,
      ),
    );
    unawaited(_continueTask(GenUiPromptTurn('Implement live A2UI bindings.')));
  }

  @override
  void dispose() {
    unawaited(_events.cancel());
    _driver.close();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continueTask(GenUiTurn turn) async {
    if (_loading && _currentSurface.isNotEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _driver.respond(turn: turn, catalog: widget.catalog);
      if (!mounted) return;
      _currentSurface = result.components;
      _controller.handleMessage(
        a2ui.UpdateComponentsMessage(
          surfaceId: _surfaceId,
          components: [
            for (final component in result.components)
              Map<String, dynamic>.from(component),
          ],
        ),
      );
      setState(
        () => _lastAction =
            'Task continued through ${result.responseId.replaceFirst('checkpoint-', '')}.',
      );
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleInteraction(ChatMessage message) {
    final interaction = message.parts.first.asUiInteractionPart?.interaction;
    if (interaction == null) return;
    try {
      final action = GenUiAction.fromInteraction(interaction);
      setState(() => _lastAction = 'Selected ${action.name}. Continuing task…');
      unawaited(
        _continueTask(
          GenUiActionTurn(action: action, currentSurface: _currentSurface),
        ),
      );
    } on FormatException catch (error) {
      setState(
        () => _error = 'The checkpoint action was invalid: ${error.message}',
      );
    }
  }

  void _restartTask() {
    if (_loading) return;
    unawaited(_continueTask(GenUiPromptTurn('Restart checkpoint task.')));
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
    children: [
      Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CheckpointIntroduction(),
              const SizedBox(height: OrbitTokens.spaceXl),
              OrbitSurface(
                tone: OrbitSurfaceTone.muted,
                child: Row(
                  children: [
                    const OrbitBadge(
                      label: 'TASK 01',
                      tone: OrbitBadgeTone.neutral,
                      glyph: OrbitGlyphs.document,
                    ),
                    const SizedBox(width: OrbitTokens.spaceSm),
                    Expanded(
                      child: Text(
                        'Implement live A2UI bindings',
                        style: OrbitType.title(context),
                      ),
                    ),
                    OrbitButton(
                      label: 'Restart task',
                      onPressed: _loading ? null : _restartTask,
                      compact: true,
                      variant: OrbitButtonVariant.secondary,
                      leading: const OrbitGlyph(OrbitGlyphs.activity, size: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: OrbitTokens.spaceXl),
              Row(
                children: [
                  const OrbitBadge(
                    label: 'CODEX TASK DRIVER',
                    tone: OrbitBadgeTone.info,
                    glyph: OrbitGlyphs.sparkle,
                  ),
                  const SizedBox(width: OrbitTokens.spaceSm),
                  Expanded(
                    child: Text(
                      'prompt → checkpoint → action turn → continuation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OrbitType.small(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: OrbitTokens.spaceMd),
              if (_loading) const _CheckpointLoading(),
              if (_loading) const SizedBox(height: OrbitTokens.spaceMd),
              if (_error case final error?)
                OrbitSurface(
                  child: Text(
                    error,
                    style: OrbitType.body(context).copyWith(
                      color: OrbitTheme.of(context).colors.destructive,
                    ),
                  ),
                )
              else
                DesyGenUiSurface(
                  controller: _controller,
                  surfaceId: _surfaceId,
                  theme: widget.theme,
                ),
              const SizedBox(height: OrbitTokens.spaceMd),
              OrbitSurface(
                tone: OrbitSurfaceTone.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: OrbitTokens.spaceMd,
                  vertical: OrbitTokens.spaceSm,
                ),
                child: Row(
                  children: [
                    OrbitGlyph(
                      OrbitGlyphs.activity,
                      color: OrbitTheme.of(context).colors.warning,
                      size: 15,
                    ),
                    const SizedBox(width: OrbitTokens.spaceSm),
                    Text('TASK EVENT', style: OrbitType.overline(context)),
                    const SizedBox(width: OrbitTokens.spaceSm),
                    Expanded(
                      child: Text(
                        _lastAction,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OrbitType.small(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _CheckpointIntroduction extends StatelessWidget {
  const _CheckpointIntroduction();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const OrbitBadge(
        label: 'GENUI CODING EXPERIMENT',
        tone: OrbitBadgeTone.info,
        glyph: OrbitGlyphs.sparkle,
      ),
      const SizedBox(height: OrbitTokens.spaceLg),
      Text(
        'Decide, then let the task continue.',
        style: OrbitType.display(context),
      ),
      const SizedBox(height: OrbitTokens.spaceSm),
      Text(
        'This is not a dashboard. Codex pauses only at a material code decision, receives the selected action as structured continuation context, and returns the next checkpoint.',
        style: OrbitType.body(
          context,
        ).copyWith(color: OrbitTheme.of(context).colors.mutedForeground),
      ),
    ],
  );
}

class _CheckpointLoading extends StatelessWidget {
  const _CheckpointLoading();

  @override
  Widget build(BuildContext context) => OrbitSurface(
    padding: const EdgeInsets.symmetric(
      horizontal: OrbitTokens.spaceMd,
      vertical: OrbitTokens.spaceSm,
    ),
    child: Row(
      children: [
        OrbitSpinner(size: 16, color: OrbitTheme.of(context).colors.info),
        const SizedBox(width: OrbitTokens.spaceSm),
        Text(
          'The coding task is preparing its next checkpoint…',
          style: OrbitType.small(context),
        ),
      ],
    ),
  );
}

import 'dart:async';

import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'workshop_candidate.dart';
import 'workshop_runtime.dart';

/// Desy's isolated, repository-native hot-reload workspace.
class DesyWidgetWorkshopExtension extends DesyWorkspaceExtension {
  /// Creates a Workshop backed by ordinary Dart candidates in the repository.
  DesyWidgetWorkshopExtension({required this.configuration});

  /// Repository and candidate declaration used by the live runtime.
  final DesyWidgetWorkshopConfiguration configuration;

  DesyWorkshopRuntime? _runtime;

  /// The one local runtime survives route changes within this workbench.
  DesyWorkshopRuntime get runtime =>
      _runtime ??= createDesyWorkshopRuntime(configuration);

  @override
  String get id => 'widget-workshop';

  @override
  String get name => 'Workshop';

  @override
  IconData get icon => DesyIcons.sparkles;

  @override
  String get description =>
      'Compare real Flutter implementations and iterate through hot reload.';

  @override
  DesyWorkspaceSessionSummary get currentSession =>
      const DesyWorkspaceSessionSummary(
        title: 'Live widget exploration',
        subtitle: 'Current repository session',
      );

  @override
  Widget build(BuildContext context, DesyWorkspaceExtensionContext extension) =>
      _WidgetWorkshopScreen(
        extension: extension,
        configuration: configuration,
        runtime: runtime,
      );

  @override
  void dispose() => _runtime?.dispose();

  @override
  void startNewAgentSession() => runtime.startNewSession();
}

class _WidgetWorkshopScreen extends StatefulWidget {
  const _WidgetWorkshopScreen({
    required this.extension,
    required this.configuration,
    required this.runtime,
  });

  final DesyWorkspaceExtensionContext extension;
  final DesyWidgetWorkshopConfiguration configuration;
  final DesyWorkshopRuntime runtime;

  @override
  State<_WidgetWorkshopScreen> createState() => _WidgetWorkshopScreenState();
}

class _WidgetWorkshopScreenState extends State<_WidgetWorkshopScreen> {
  late final DesyWorkshopRuntime _runtime;
  var _reloadCount = 0;

  @override
  void initState() {
    super.initState();
    _runtime = widget.runtime..addListener(_handleRuntimeChange);
    final pendingRequest = widget.extension.pendingAgentRequest.trim();
    if (pendingRequest.isNotEmpty) {
      _runtime.setPrompt(pendingRequest);
      widget.extension.onPendingAgentRequestConsumed?.call();
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _reloadCount++);
      _runtime.noteReloadCompleted(_reloadCount);
    });
  }

  @override
  void dispose() {
    _runtime.removeListener(_handleRuntimeChange);
    super.dispose();
  }

  void _handleRuntimeChange() {
    if (mounted) setState(() {});
  }

  Future<void> _runCodex(List<DesyWorkshopCandidate> candidates) async {
    if (!_runtime.canRun) return;
    await _runtime.run(
      candidates: candidates,
      agentBrief: widget.extension.agentBrief,
    );
  }

  @override
  Widget build(BuildContext context) {
    final candidates = widget.configuration.candidates();
    return _WorkshopWorkspace(
      key: const ValueKey('widget-workshop-screen'),
      extension: widget.extension,
      runtime: _runtime,
      candidates: candidates,
      workbenchAnnotationCount: widget.extension.workbenchAnnotations.length,
      reloadCount: _reloadCount,
      onRunCodex: () => unawaited(_runCodex(candidates)),
    );
  }
}

class _WorkshopWorkspace extends StatefulWidget {
  const _WorkshopWorkspace({
    super.key,
    required this.extension,
    required this.runtime,
    required this.candidates,
    required this.workbenchAnnotationCount,
    required this.reloadCount,
    required this.onRunCodex,
  });

  final DesyWorkspaceExtensionContext extension;
  final DesyWorkshopRuntime runtime;
  final List<DesyWorkshopCandidate> candidates;
  final int workbenchAnnotationCount;
  final int reloadCount;
  final VoidCallback onRunCodex;

  @override
  State<_WorkshopWorkspace> createState() => _WorkshopWorkspaceState();
}

class _WorkshopWorkspaceState extends State<_WorkshopWorkspace> {
  var _activityWidth = 360.0;
  var _activityHeight = 300.0;
  var _activityVisible = true;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.theme.colors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final activity = _RuntimePanel(
            runtime: widget.runtime,
            candidates: widget.candidates,
            annotationCount: widget.workbenchAnnotationCount,
            agentBrief: widget.extension.agentBrief,
            onRunCodex: widget.onRunCodex,
            onCollapse: () => setState(() => _activityVisible = false),
          );
          final previews = _CandidatesPanel(
            extension: widget.extension,
            candidates: widget.candidates,
            reloadCount: widget.reloadCount,
          );
          if (constraints.maxWidth < 760) {
            final maxHeight = (constraints.maxHeight - 240).clamp(180.0, 420.0);
            final activityHeight = _activityHeight.clamp(180.0, maxHeight);
            return Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: previews),
                      if (!_activityVisible)
                        Positioned(
                          top: DesyDesignSystemTokens.spaceSm,
                          right: DesyDesignSystemTokens.spaceSm,
                          child: DesyButton.icon(
                            key: const ValueKey(
                              'widget-workshop-restore-activity',
                            ),
                            size: DesyButtonSize.sm,
                            semanticsLabel: 'Show Codex activity',
                            semanticsTooltip: 'Show Codex activity',
                            onPress: () =>
                                setState(() => _activityVisible = true),
                            child: const Icon(
                              DesyIcons.panelRightOpen,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_activityVisible)
                  _PanelResizeHandle(
                    key: const ValueKey(
                      'widget-workshop-activity-resizer-vertical',
                    ),
                    dragAxis: Axis.vertical,
                    onDelta: (delta) => setState(() {
                      _activityHeight = (_activityHeight + delta).clamp(
                        180.0,
                        maxHeight,
                      );
                    }),
                  ),
                if (_activityVisible)
                  SizedBox(height: activityHeight, child: activity),
              ],
            );
          }
          final maxWidth = (constraints.maxWidth - 420).clamp(320.0, 560.0);
          final activityWidth = _activityWidth.clamp(320.0, maxWidth);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: previews),
                    if (!_activityVisible)
                      Positioned(
                        top: DesyDesignSystemTokens.spaceSm,
                        right: DesyDesignSystemTokens.spaceSm,
                        child: DesyButton.icon(
                          key: const ValueKey(
                            'widget-workshop-restore-activity',
                          ),
                          size: DesyButtonSize.sm,
                          semanticsLabel: 'Show Codex activity',
                          semanticsTooltip: 'Show Codex activity',
                          onPress: () =>
                              setState(() => _activityVisible = true),
                          child: const Icon(DesyIcons.panelRightOpen, size: 16),
                        ),
                      ),
                  ],
                ),
              ),
              if (_activityVisible)
                _PanelResizeHandle(
                  key: const ValueKey(
                    'widget-workshop-activity-resizer-horizontal',
                  ),
                  dragAxis: Axis.horizontal,
                  onDelta: (delta) => setState(() {
                    // The handle is the rail's left edge: pulling it left
                    // expands the right-side agent panel.
                    _activityWidth = (_activityWidth - delta).clamp(
                      320.0,
                      maxWidth,
                    );
                  }),
                ),
              if (_activityVisible)
                SizedBox(width: activityWidth, child: activity),
            ],
          );
        },
      ),
    );
  }
}

class _PanelResizeHandle extends StatefulWidget {
  const _PanelResizeHandle({
    super.key,
    required this.dragAxis,
    required this.onDelta,
  });

  final Axis dragAxis;
  final ValueChanged<double> onDelta;

  @override
  State<_PanelResizeHandle> createState() => _PanelResizeHandleState();
}

class _PanelResizeHandleState extends State<_PanelResizeHandle> {
  var _hovered = false;
  var _focused = false;

  void _nudge(double delta) => widget.onDelta(delta);

  @override
  Widget build(BuildContext context) {
    final horizontal = widget.dragAxis == Axis.horizontal;
    final colors = context.theme.colors;
    final active = _hovered || _focused;
    return Semantics(
      label: 'Resize Codex activity panel',
      onIncrease: () => _nudge(24),
      onDecrease: () => _nudge(-24),
      child: Focus(
        onFocusChange: (value) => setState(() => _focused = value),
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          final positive = horizontal
              ? event.logicalKey == LogicalKeyboardKey.arrowRight
              : event.logicalKey == LogicalKeyboardKey.arrowDown;
          final negative = horizontal
              ? event.logicalKey == LogicalKeyboardKey.arrowLeft
              : event.logicalKey == LogicalKeyboardKey.arrowUp;
          if (positive) {
            _nudge(24);
            return KeyEventResult.handled;
          }
          if (negative) {
            _nudge(-24);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          cursor: horizontal
              ? SystemMouseCursors.resizeColumn
              : SystemMouseCursors.resizeRow,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: horizontal
                ? (details) => widget.onDelta(details.delta.dx)
                : null,
            onVerticalDragUpdate: horizontal
                ? null
                : (details) => widget.onDelta(details.delta.dy),
            child: SizedBox(
              width: horizontal ? 9 : double.infinity,
              height: horizontal ? double.infinity : 9,
              child: Center(
                child: AnimatedContainer(
                  duration: _motionDuration(context),
                  width: horizontal ? (active ? 3 : 1) : double.infinity,
                  height: horizontal ? double.infinity : (active ? 3 : 1),
                  color: active ? colors.primary : colors.border,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Duration _motionDuration(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 220);

class _RuntimePanel extends StatelessWidget {
  const _RuntimePanel({
    required this.runtime,
    required this.candidates,
    required this.annotationCount,
    required this.agentBrief,
    required this.onRunCodex,
    required this.onCollapse,
  });

  final DesyWorkshopRuntime runtime;
  final List<DesyWorkshopCandidate> candidates;
  final int annotationCount;
  final DesyWorkspaceAgentBrief agentBrief;
  final VoidCallback onRunCodex;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return ColoredBox(
      key: const ValueKey('widget-workshop-activity-panel'),
      color: colors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Codex activity', style: typography.body.lg),
                    ),
                    _RuntimeStatus(runtime: runtime),
                    const SizedBox(width: DesyDesignSystemTokens.spaceXs),
                    DesyButton.icon(
                      key: const ValueKey('widget-workshop-collapse-activity'),
                      size: DesyButtonSize.xs,
                      variant: DesyButtonVariant.ghost,
                      semanticsLabel: 'Hide Codex activity',
                      semanticsTooltip: 'Hide Codex activity',
                      onPress: onCollapse,
                      child: const Icon(DesyIcons.panelRightClose, size: 15),
                    ),
                  ],
                ),
                const SizedBox(height: DesyDesignSystemTokens.spaceXs),
                Text(
                  '${candidates.length} proposals · $annotationCount annotations',
                  style: typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: DesyDesignSystemTokens.spaceXs),
                Text(
                  'Context: ${agentBrief.summary}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
              child: SingleChildScrollView(
                reverse: true,
                child: DesyProgressTrail(items: _codexActivityItems(runtime)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KeyedSubtree(
                  key: const ValueKey('widget-workshop-prompt-border'),
                  child: DesyTextField(
                    key: const ValueKey('widget-workshop-prompt'),
                    label: 'Message to Codex',
                    hintText: 'Describe the next Workshop iteration…',
                    value: runtime.prompt,
                    enabled: runtime.supported && !runtime.running,
                    minLines: 3,
                    maxLines: 7,
                    onChanged: runtime.setPrompt,
                  ),
                ),
                const SizedBox(height: DesyDesignSystemTokens.spaceSm),
                if (!runtime.supported)
                  Text(
                    'Live editing is available in the macOS dogfood app.',
                    style: typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                    ),
                  )
                else
                  Row(
                    children: [
                      if (runtime.running) ...[
                        DesyButton(
                          variant: DesyButtonVariant.outline,
                          size: DesyButtonSize.sm,
                          mainAxisSize: MainAxisSize.min,
                          onPress: runtime.cancel,
                          child: const Text('Stop'),
                        ),
                        const SizedBox(width: DesyDesignSystemTokens.spaceSm),
                      ],
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DesyButton(
                              key: const ValueKey('widget-workshop-run-codex'),
                              onPress: runtime.canRun ? onRunCodex : null,
                              child: Text(
                                runtime.running
                                    ? 'Codex is working…'
                                    : 'Continue with Codex',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<DesyProgressTrailItem> _codexActivityItems(DesyWorkshopRuntime runtime) {
  final logs = runtime.logs;
  return [
    for (final (index, log) in logs.indexed)
      _codexActivityItem(
        log,
        current: runtime.running && index == logs.length - 1,
      ),
  ];
}

DesyProgressTrailItem _codexActivityItem(String log, {required bool current}) {
  final failed =
      log.contains('error:') ||
      log.startsWith('Could not ') ||
      log.startsWith('Command failed') ||
      log.startsWith('stderr:') ||
      (log.startsWith('Codex exited with code ') &&
          !log.startsWith('Codex exited with code 0.'));
  final state = failed
      ? DesyProgressTrailItemState.failed
      : current
      ? DesyProgressTrailItemState.current
      : DesyProgressTrailItemState.complete;
  final metadata = current
      ? 'Running'
      : failed
      ? 'Failed'
      : null;

  if (log.startsWith(r'$ ')) {
    return DesyProgressTrailItem(
      title: log.startsWith(r'$ codex') ? 'Started Codex' : 'Ran command',
      detail: log.substring(2),
      metadata: metadata,
      state: state,
      icon: Icons.terminal_rounded,
    );
  }
  if (log.startsWith('Current proposal context:')) {
    return DesyProgressTrailItem(
      title: 'Prepared proposal context',
      detail: log.substring('Current proposal context:'.length).trim(),
      metadata: metadata,
      state: state,
      icon: Icons.checklist_rounded,
    );
  }
  if (log.startsWith('Request:')) {
    return DesyProgressTrailItem(
      title: 'Received Workshop request',
      detail: log.substring('Request:'.length).trim(),
      metadata: metadata,
      state: state,
      icon: Icons.chat_bubble_outline_rounded,
    );
  }
  if (log == 'Planning and editing…') {
    return DesyProgressTrailItem(
      title: log,
      metadata: metadata,
      state: state,
      icon: Icons.route_rounded,
    );
  }
  if (log == 'Updated the candidate source.') {
    return DesyProgressTrailItem(
      title: 'Updated the candidate source',
      metadata: metadata,
      state: state,
      icon: Icons.edit_rounded,
    );
  }
  if (log.startsWith('Codex exited with code ')) {
    return DesyProgressTrailItem(
      title: failed ? 'Codex stopped' : 'Codex finished',
      detail: log,
      metadata: metadata,
      state: state,
      icon: failed ? Icons.close_rounded : Icons.check_rounded,
    );
  }
  if (log.startsWith('Ready.')) {
    return DesyProgressTrailItem(
      title: 'Ready for the next iteration',
      detail: log.substring('Ready.'.length).trim(),
      metadata: metadata,
      state: state,
      icon: Icons.play_arrow_rounded,
    );
  }
  if (log.startsWith('Codex conversation ')) {
    return DesyProgressTrailItem(
      title: log,
      metadata: metadata,
      state: state,
      icon: Icons.forum_outlined,
    );
  }
  return DesyProgressTrailItem(
    title: failed ? 'Codex needs attention' : 'Codex update',
    detail: log,
    metadata: metadata,
    state: state,
    icon: failed ? Icons.warning_amber_rounded : Icons.notes_rounded,
  );
}

class _CodexWorkingShimmer extends StatefulWidget {
  const _CodexWorkingShimmer({super.key});

  @override
  State<_CodexWorkingShimmer> createState() => _CodexWorkingShimmerState();
}

class _CodexWorkingShimmerState extends State<_CodexWorkingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return SizedBox(
      width: 116,
      height: 30,
      child: LayoutBuilder(
        builder: (context, constraints) => ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.background,
              border: Border.all(color: colors.primary),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(
                      -60 + (constraints.maxWidth + 120) * _controller.value,
                      0,
                    ),
                    child: child,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 60,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors.primary.withValues(alpha: 0),
                              colors.primary.withValues(alpha: .18),
                              colors.primary.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'Codex working',
                    style: context.theme.typography.body.xs,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CandidatesPanel extends StatefulWidget {
  const _CandidatesPanel({
    required this.extension,
    required this.candidates,
    required this.reloadCount,
  });

  final DesyWorkspaceExtensionContext extension;
  final List<DesyWorkshopCandidate> candidates;
  final int reloadCount;

  @override
  State<_CandidatesPanel> createState() => _CandidatesPanelState();
}

class _CandidatesPanelState extends State<_CandidatesPanel> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return ColoredBox(
      key: const ValueKey('widget-workshop-candidates-panel'),
      color: colors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Implementation options', style: typography.body.lg),
                      const SizedBox(height: DesyDesignSystemTokens.spaceXs),
                      Text(
                        '${widget.candidates.length} widgets · '
                        '${widget.reloadCount} reloads',
                        style: typography.body.xs.copyWith(
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: colors.background,
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: ListView.separated(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero,
                        itemCount: widget.candidates.length,
                        separatorBuilder: (context, index) => ColoredBox(
                          color: colors.border,
                          child: const SizedBox(width: 1),
                        ),
                        itemBuilder: (context, index) {
                          final candidate = widget.candidates[index];
                          return _CandidateCard(
                            key: ValueKey(candidate.id),
                            extension: widget.extension,
                            candidate: candidate,
                            showComponents: widget.candidates.length == 1,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    super.key,
    required this.extension,
    required this.candidate,
    required this.showComponents,
  });

  final DesyWorkspaceExtensionContext extension;
  final DesyWorkshopCandidate candidate;
  final bool showComponents;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return SizedBox(
      width: 640,
      child: ColoredBox(
        color: colors.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(candidate.title, style: typography.body.sm),
                  const SizedBox(height: DesyDesignSystemTokens.spaceXs),
                  Text(
                    candidate.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesyDesignSystemTokens.spaceMd,
                  0,
                  DesyDesignSystemTokens.spaceMd,
                  DesyDesignSystemTokens.spaceMd,
                ),
                child: DesyCard(
                  key: ValueKey(
                    'widget-workshop-generated-preview-card-${candidate.id}',
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ClipRect(
                    child: DesyWidgetPreview(
                      theme: extension.activeTheme,
                      builder: (previewContext) => ColoredBox(
                        color:
                            extension.activeTheme.previewBackgroundColor ??
                            Theme.of(previewContext).scaffoldBackgroundColor,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(
                              DesyDesignSystemTokens.spaceMd,
                            ),
                            child: DesyFittedPreview(
                              child: DesyWorkbenchInspectionScope(
                                context: DesyWorkbenchInspectionContext(
                                  artifactId: candidate.id,
                                  kind: 'Workshop candidate',
                                  label: candidate.title,
                                ),
                                child: Builder(builder: candidate.builder),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (showComponents && candidate.components.isNotEmpty)
              _CandidateComponents(
                extension: extension,
                components: candidate.components,
              ),
          ],
        ),
      ),
    );
  }
}

class _CandidateComponents extends StatelessWidget {
  const _CandidateComponents({
    required this.extension,
    required this.components,
  });

  final DesyWorkspaceExtensionContext extension;
  final List<DesyWorkshopCandidateComponent> components;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return Padding(
      key: const ValueKey('widget-workshop-candidate-components'),
      padding: const EdgeInsets.fromLTRB(
        DesyDesignSystemTokens.spaceMd,
        0,
        DesyDesignSystemTokens.spaceMd,
        DesyDesignSystemTokens.spaceMd,
      ),
      child: SizedBox(
        height: 210,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Components',
                    style: typography.body.sm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${components.length} parts',
                  style: typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesyDesignSystemTokens.spaceSm),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = components.length.clamp(1, 3);
                  final width =
                      (constraints.maxWidth -
                          (columns - 1) * DesyDesignSystemTokens.spaceSm) /
                      columns;
                  final rows = (components.length / columns).ceil();
                  const itemHeight = 164.0;
                  final logicalHeight =
                      rows * itemHeight +
                      (rows - 1) * DesyDesignSystemTokens.spaceSm;
                  return ClipRect(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: logicalHeight,
                        child: Wrap(
                          spacing: DesyDesignSystemTokens.spaceSm,
                          runSpacing: DesyDesignSystemTokens.spaceSm,
                          children: [
                            for (final component in components)
                              SizedBox(
                                width: width,
                                height: itemHeight,
                                child: _CandidateComponentCard(
                                  extension: extension,
                                  component: component,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateComponentCard extends StatelessWidget {
  const _CandidateComponentCard({
    required this.extension,
    required this.component,
  });

  final DesyWorkspaceExtensionContext extension;
  final DesyWorkshopCandidateComponent component;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final registryId = component.registryInstanceId;
    final registered = registryId == null
        ? null
        : extension.registry.resolveComponentInstance(registryId);
    final title = registered == null
        ? component.title ?? registryId ?? component.id
        : '${registered.componentName} · ${registered.name}';

    return DesyCard(
      key: ValueKey('widget-workshop-component-${component.id}'),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceSm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.body.xs.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (component.isInRegistry)
                  DecoratedBox(
                    key: ValueKey(
                      'widget-workshop-component-registry-${component.id}',
                    ),
                    decoration: BoxDecoration(
                      color: colors.secondary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesyDesignSystemTokens.spaceSm,
                        vertical: DesyDesignSystemTokens.spaceXs,
                      ),
                      child: Text(
                        'In registry',
                        style: typography.body.xs.copyWith(
                          color: colors.mutedForeground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ClipRect(
              child: DesyWidgetPreview(
                theme: extension.activeTheme,
                builder: (previewContext) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(
                      DesyDesignSystemTokens.spaceSm,
                    ),
                    child: DesyFittedPreview(
                      child: registryId == null
                          ? Builder(builder: component.builder!)
                          : extension.registry.widgetBuilder.build(
                              previewContext,
                              registryId,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuntimeStatus extends StatelessWidget {
  const _RuntimeStatus({required this.runtime});

  final DesyWorkshopRuntime runtime;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final live = runtime.supported;
    final active = runtime.running;
    if (active) {
      return const _CodexWorkingShimmer(
        key: ValueKey('widget-workshop-codex-shimmer'),
      );
    }
    final label = !live ? 'Preview only' : 'Ready';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(label),
      ),
    );
  }
}

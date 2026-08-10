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
  DesyWorkspaceExtensionPresentation get presentation =>
      DesyWorkspaceExtensionPresentation.standalone;

  @override
  Widget build(BuildContext context, DesyWorkspaceExtensionContext extension) =>
      _WidgetWorkshopScreen(extension: extension, configuration: configuration);
}

class _WidgetWorkshopScreen extends StatefulWidget {
  const _WidgetWorkshopScreen({
    required this.extension,
    required this.configuration,
  });

  final DesyWorkspaceExtensionContext extension;
  final DesyWidgetWorkshopConfiguration configuration;

  @override
  State<_WidgetWorkshopScreen> createState() => _WidgetWorkshopScreenState();
}

class _WidgetWorkshopScreenState extends State<_WidgetWorkshopScreen> {
  late final DesyWorkshopRuntime _runtime;
  final _annotationFocusNode = FocusNode();
  final _selectedCandidateIds = <String>{};
  final _annotations = <DesyWorkshopAnnotation>[];
  DesyWorkshopWidgetTarget? _widgetTarget;
  var _annotationDraft = '';
  var _reloadCount = 0;
  var _sessionsOpen = false;

  @override
  void initState() {
    super.initState();
    _runtime = createDesyWorkshopRuntime(widget.configuration)
      ..addListener(_handleRuntimeChange);
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
    _runtime
      ..removeListener(_handleRuntimeChange)
      ..dispose();
    _annotationFocusNode.dispose();
    super.dispose();
  }

  void _handleRuntimeChange() {
    if (mounted) setState(() {});
  }

  void _setSelected(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedCandidateIds.add(id);
      } else {
        _selectedCandidateIds.remove(id);
      }
    });
  }

  void _selectWidgetTarget(DesyWorkshopWidgetTarget target) {
    setState(() {
      _widgetTarget = target;
      _annotationDraft = '';
      _selectedCandidateIds.add(target.candidateId);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _annotationFocusNode.requestFocus();
    });
  }

  void _clearWidgetTarget() {
    assert(() {
      WidgetInspectorService.instance.selection.clear();
      return true;
    }());
    _annotationFocusNode.unfocus();
    setState(() {
      _widgetTarget = null;
      _annotationDraft = '';
    });
  }

  void _setAnnotationDraft(String value) {
    setState(() => _annotationDraft = value);
  }

  void _commitAnnotation() {
    final target = _widgetTarget;
    final comment = _annotationDraft.trim();
    if (target == null || comment.isEmpty) return;
    setState(() {
      _annotations.add(
        DesyWorkshopAnnotation(
          id: _annotations.length + 1,
          target: target,
          comment: comment,
        ),
      );
      _annotationDraft = '';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _annotationFocusNode.requestFocus();
    });
  }

  Future<void> _runCodex(List<DesyWorkshopCandidate> candidates) async {
    if (!_runtime.canRun) return;
    await _runtime.run(
      candidates: candidates,
      selectedCandidateIds: _selectedCandidateIds,
      annotations: List.unmodifiable(_annotations),
    );
  }

  @override
  Widget build(BuildContext context) {
    final candidates = widget.configuration.candidates();
    _selectedCandidateIds.removeWhere(
      (id) => !candidates.any((candidate) => candidate.id == id),
    );

    return Stack(
      key: const ValueKey('widget-workshop-standalone-screen'),
      children: [
        Positioned.fill(
          child: _WorkshopWorkspace(
            extension: widget.extension,
            runtime: _runtime,
            candidates: candidates,
            selectedCandidateIds: _selectedCandidateIds,
            widgetTarget: _widgetTarget,
            annotations: _annotations,
            annotationDraft: _annotationDraft,
            reloadCount: _reloadCount,
            annotationFocusNode: _annotationFocusNode,
            onAnnotationChanged: _setAnnotationDraft,
            onCommitAnnotation: _commitAnnotation,
            onOpenSessions: () => setState(() => _sessionsOpen = true),
            onRunCodex: () => unawaited(_runCodex(candidates)),
            onWidgetTargetSelected: _selectWidgetTarget,
            onWidgetTargetCleared: _clearWidgetTarget,
            onSelectionChanged: _setSelected,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !_sessionsOpen,
            child: AnimatedOpacity(
              key: const ValueKey('widget-workshop-sessions-scrim'),
              opacity: _sessionsOpen ? 1 : 0,
              duration: _motionDuration(context),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _sessionsOpen = false),
                child: ColoredBox(
                  color: context.theme.colors.foreground.withValues(alpha: .08),
                ),
              ),
            ),
          ),
        ),
        AnimatedPositioned(
          key: const ValueKey('widget-workshop-floating-sessions'),
          duration: _motionDuration(context),
          curve: Curves.easeOutCubic,
          left: _sessionsOpen ? 12 : -304,
          top: 12,
          bottom: 12,
          width: 292,
          child: IgnorePointer(
            ignoring: !_sessionsOpen,
            child: AnimatedOpacity(
              key: const ValueKey('widget-workshop-floating-sessions-opacity'),
              opacity: _sessionsOpen ? 1 : 0,
              duration: _motionDuration(context),
              child: _FloatingSessionsDrawer(
                extension: widget.extension,
                onDismiss: () => setState(() => _sessionsOpen = false),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Duration _motionDuration(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 220);

class _FloatingSessionsDrawer extends StatelessWidget {
  const _FloatingSessionsDrawer({
    required this.extension,
    required this.onDismiss,
  });

  final DesyWorkspaceExtensionContext extension;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const ValueKey('widget-workshop-sessions-drawer-surface'),
    decoration: BoxDecoration(
      color: context.theme.colors.background,
      border: Border.all(color: context.theme.colors.border),
      borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusMd),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusMd),
      child: _WorkshopSessionsSidebar(
        extension: extension,
        onDismiss: onDismiss,
      ),
    ),
  );
}

class _WorkshopSessionsSidebar extends StatelessWidget {
  const _WorkshopSessionsSidebar({
    required this.extension,
    required this.onDismiss,
  });

  final DesyWorkspaceExtensionContext extension;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => DesySidebar(
    key: const ValueKey('widget-workshop-sessions-sidebar'),
    style: const DesySidebarStyleDelta.delta(
      constraints: BoxConstraints(minWidth: double.infinity),
      headerPadding: EdgeInsetsGeometryDelta.value(EdgeInsets.zero),
      contentPadding: EdgeInsetsGeometryDelta.value(
        EdgeInsets.symmetric(horizontal: 8),
      ),
    ),
    header: Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DesyButton.icon(
                key: const ValueKey('widget-workshop-sessions-close'),
                size: DesyButtonSize.sm,
                variant: DesyButtonVariant.outline,
                semanticsLabel: 'Close sessions',
                onPress: onDismiss,
                child: const Icon(Icons.close_rounded, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Conversations',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            extension.registry.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
    children: [
      DesySidebarSection(
        key: const ValueKey('widget-workshop-sessions-section'),
        label: 'Current',
        count: 1,
        children: [
          DesySidebarItem(
            key: const ValueKey('widget-workshop-session-live'),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
            label: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Live widget exploration'),
                SizedBox(height: 2),
                Text('Current repository session'),
              ],
            ),
            selected: true,
            onPress: onDismiss,
          ),
        ],
      ),
      DesySidebarSection(
        key: const ValueKey('widget-workshop-past-conversations-section'),
        label: 'Past conversations',
        count: 0,
        children: const [
          Padding(
            key: ValueKey('widget-workshop-past-conversations-empty'),
            padding: EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Text('No past conversations yet.'),
          ),
        ],
      ),
    ],
  );
}

class _WorkshopWorkspace extends StatefulWidget {
  const _WorkshopWorkspace({
    required this.extension,
    required this.runtime,
    required this.candidates,
    required this.selectedCandidateIds,
    required this.widgetTarget,
    required this.annotations,
    required this.annotationDraft,
    required this.reloadCount,
    required this.annotationFocusNode,
    required this.onAnnotationChanged,
    required this.onCommitAnnotation,
    required this.onOpenSessions,
    required this.onRunCodex,
    required this.onWidgetTargetSelected,
    required this.onWidgetTargetCleared,
    required this.onSelectionChanged,
  });

  final DesyWorkspaceExtensionContext extension;
  final DesyWorkshopRuntime runtime;
  final List<DesyWorkshopCandidate> candidates;
  final Set<String> selectedCandidateIds;
  final DesyWorkshopWidgetTarget? widgetTarget;
  final List<DesyWorkshopAnnotation> annotations;
  final String annotationDraft;
  final int reloadCount;
  final FocusNode annotationFocusNode;
  final ValueChanged<String> onAnnotationChanged;
  final VoidCallback onCommitAnnotation;
  final VoidCallback onOpenSessions;
  final VoidCallback onRunCodex;
  final ValueChanged<DesyWorkshopWidgetTarget> onWidgetTargetSelected;
  final VoidCallback onWidgetTargetCleared;
  final void Function(String id, bool selected) onSelectionChanged;

  @override
  State<_WorkshopWorkspace> createState() => _WorkshopWorkspaceState();
}

class _WorkshopWorkspaceState extends State<_WorkshopWorkspace> {
  var _activityWidth = 360.0;
  var _activityHeight = 300.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return ColoredBox(
      color: colors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesyDesignSystemTokens.spaceMd,
                vertical: DesyDesignSystemTokens.spaceSm,
              ),
              child: Row(
                children: [
                  DesyButton(
                    key: const ValueKey('widget-workshop-back'),
                    size: DesyButtonSize.sm,
                    variant: DesyButtonVariant.ghost,
                    mainAxisSize: MainAxisSize.min,
                    onPress: widget.extension.onExit,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(DesyIcons.arrowLeft, size: 16),
                        SizedBox(width: 6),
                        Text('Back'),
                      ],
                    ),
                  ),
                  const SizedBox(width: DesyDesignSystemTokens.spaceSm),
                  Expanded(
                    child: Text(
                      'Live widget exploration',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.body.lg,
                    ),
                  ),
                  _RuntimeStatus(runtime: widget.runtime),
                  const SizedBox(width: DesyDesignSystemTokens.spaceSm),
                  FButton(
                    variant: FButtonVariant.outline,
                    mainAxisSize: MainAxisSize.min,
                    onPress: widget.runtime.supported && !widget.runtime.running
                        ? () => unawaited(widget.runtime.requestHotReload())
                        : null,
                    child: const Text('Hot reload'),
                  ),
                ],
              ),
            ),
            ColoredBox(color: colors.border, child: const SizedBox(height: 1)),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final activity = _RuntimePanel(
                    runtime: widget.runtime,
                    candidates: widget.candidates,
                    selectedCandidateIds: widget.selectedCandidateIds,
                    annotationCount: widget.annotations.length,
                    onOpenSessions: widget.onOpenSessions,
                    onRunCodex: widget.onRunCodex,
                  );
                  final previews = _CandidatesPanel(
                    extension: widget.extension,
                    candidates: widget.candidates,
                    selectedCandidateIds: widget.selectedCandidateIds,
                    widgetTarget: widget.widgetTarget,
                    annotations: widget.annotations,
                    annotationDraft: widget.annotationDraft,
                    annotationFocusNode: widget.annotationFocusNode,
                    reloadCount: widget.reloadCount,
                    onAnnotationChanged: widget.onAnnotationChanged,
                    onCommitAnnotation: widget.onCommitAnnotation,
                    onWidgetTargetSelected: widget.onWidgetTargetSelected,
                    onWidgetTargetCleared: widget.onWidgetTargetCleared,
                    onSelectionChanged: widget.onSelectionChanged,
                  );
                  if (constraints.maxWidth < 760) {
                    final maxHeight = (constraints.maxHeight - 240).clamp(
                      180.0,
                      420.0,
                    );
                    final activityHeight = _activityHeight.clamp(
                      180.0,
                      maxHeight,
                    );
                    return Column(
                      children: [
                        SizedBox(height: activityHeight, child: activity),
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
                        Expanded(child: previews),
                      ],
                    );
                  }
                  final maxWidth = (constraints.maxWidth - 420).clamp(
                    280.0,
                    560.0,
                  );
                  final activityWidth = _activityWidth.clamp(280.0, maxWidth);
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: activityWidth, child: activity),
                      _PanelResizeHandle(
                        key: const ValueKey(
                          'widget-workshop-activity-resizer-horizontal',
                        ),
                        dragAxis: Axis.horizontal,
                        onDelta: (delta) => setState(() {
                          _activityWidth = (_activityWidth + delta).clamp(
                            280.0,
                            maxWidth,
                          );
                        }),
                      ),
                      Expanded(child: previews),
                    ],
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

class _RuntimePanel extends StatelessWidget {
  const _RuntimePanel({
    required this.runtime,
    required this.candidates,
    required this.selectedCandidateIds,
    required this.annotationCount,
    required this.onOpenSessions,
    required this.onRunCodex,
  });

  final DesyWorkshopRuntime runtime;
  final List<DesyWorkshopCandidate> candidates;
  final Set<String> selectedCandidateIds;
  final int annotationCount;
  final VoidCallback onOpenSessions;
  final VoidCallback onRunCodex;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final selected = candidates
        .where((candidate) => selectedCandidateIds.contains(candidate.id))
        .toList(growable: false);
    return ColoredBox(
      key: const ValueKey('widget-workshop-activity-panel'),
      color: colors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
            child: Row(
              children: [
                Expanded(
                  child: Text('Codex activity', style: typography.body.lg),
                ),
                Text(
                  '${selected.length} selected · $annotationCount annotations',
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
                        FButton(
                          variant: FButtonVariant.outline,
                          mainAxisSize: MainAxisSize.min,
                          onPress: runtime.cancel,
                          child: const Text('Stop'),
                        ),
                        const SizedBox(width: DesyDesignSystemTokens.spaceSm),
                      ],
                      Expanded(
                        child: FButton(
                          key: const ValueKey('widget-workshop-run-codex'),
                          onPress: runtime.canRun ? onRunCodex : null,
                          child: Text(
                            runtime.running
                                ? 'Codex is working…'
                                : 'Continue with Codex',
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: DesyDesignSystemTokens.spaceXs),
                Align(
                  alignment: Alignment.centerLeft,
                  child: DesyButton(
                    key: const ValueKey('widget-workshop-sessions-toggle'),
                    size: DesyButtonSize.sm,
                    variant: DesyButtonVariant.ghost,
                    mainAxisSize: MainAxisSize.min,
                    onPress: onOpenSessions,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Conversations'),
                      ],
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
  if (log.startsWith('Selected context:')) {
    return DesyProgressTrailItem(
      title: 'Prepared selected context',
      detail: log.substring('Selected context:'.length).trim(),
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

class _WorkshopAnnotationDock extends StatefulWidget {
  const _WorkshopAnnotationDock({
    required this.target,
    required this.annotations,
    required this.candidates,
    required this.draft,
    required this.focusNode,
    required this.inspecting,
    required this.onDraftChanged,
    required this.onCommit,
    required this.onInspectionToggle,
  });

  final DesyWorkshopWidgetTarget? target;
  final List<DesyWorkshopAnnotation> annotations;
  final List<DesyWorkshopCandidate> candidates;
  final String draft;
  final FocusNode focusNode;
  final bool inspecting;
  final ValueChanged<String> onDraftChanged;
  final VoidCallback onCommit;
  final VoidCallback onInspectionToggle;

  @override
  State<_WorkshopAnnotationDock> createState() =>
      _WorkshopAnnotationDockState();
}

class _WorkshopAnnotationDockState extends State<_WorkshopAnnotationDock> {
  var _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final target = widget.target;
    final visibleAnnotations = widget.annotations;
    final candidateTitle = target == null
        ? null
        : widget.candidates
              .where((candidate) => candidate.id == target.candidateId)
              .map((candidate) => candidate.title)
              .firstOrNull;

    return DecoratedBox(
      key: const ValueKey('widget-workshop-annotation-dock'),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusMd),
        boxShadow: [
          BoxShadow(
            color: colors.foreground.withValues(alpha: .1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        target == null
                            ? '${widget.annotations.length} annotations'
                            : 'Annotate ${target.displayLabel}',
                        style: typography.body.sm.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (target != null) ...[
                        const SizedBox(height: DesyDesignSystemTokens.spaceXs),
                        Text(
                          '${candidateTitle ?? target.candidateId} · '
                          '${visibleAnnotations.length} total',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typography.body.xs.copyWith(
                            color: colors.mutedForeground,
                          ),
                        ),
                        if (target.sourceLocation case final location?) ...[
                          const SizedBox(
                            height: DesyDesignSystemTokens.spaceXs,
                          ),
                          Text(
                            location.displayLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: typography.body.xs.copyWith(
                              color: colors.mutedForeground,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ],
                      if (target == null) ...[
                        const SizedBox(height: DesyDesignSystemTokens.spaceXs),
                        Text(
                          widget.annotations.isEmpty
                              ? 'Inspect a widget to attach feedback.'
                              : '${widget.annotations.length} committed',
                          style: typography.body.xs.copyWith(
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tooltip(
                  message: widget.inspecting
                      ? 'Stop inspecting'
                      : 'Inspect widgets',
                  child: DesyButton.icon(
                    key: const ValueKey('widget-workshop-inspection-toggle'),
                    size: DesyButtonSize.sm,
                    variant: widget.inspecting
                        ? DesyButtonVariant.primary
                        : DesyButtonVariant.outline,
                    semanticsLabel: widget.inspecting
                        ? 'Stop inspecting widgets'
                        : 'Inspect widgets',
                    onPress: widget.onInspectionToggle,
                    child: const Icon(DesyIcons.crosshair, size: 18),
                  ),
                ),
                const SizedBox(width: DesyDesignSystemTokens.spaceXs),
                DesyButton.icon(
                  key: const ValueKey('widget-workshop-annotation-collapse'),
                  size: DesyButtonSize.sm,
                  variant: DesyButtonVariant.ghost,
                  semanticsLabel: _collapsed
                      ? 'Expand annotations'
                      : 'Collapse annotations',
                  onPress: () => setState(() => _collapsed = !_collapsed),
                  child: Icon(
                    _collapsed
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                  ),
                ),
              ],
            ),
            if (!_collapsed) ...[
              if (visibleAnnotations.isNotEmpty) ...[
                const SizedBox(height: DesyDesignSystemTokens.spaceSm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: SingleChildScrollView(
                    child: DesyAccordion(
                      children: [
                        for (final annotation in visibleAnnotations)
                          DesyAccordionItem(
                            key: ValueKey(
                              'widget-workshop-annotation-${annotation.id}',
                            ),
                            initiallyExpanded: false,
                            title: _WorkshopAnnotationSummary(
                              annotation: annotation,
                            ),
                            child: _WorkshopAnnotationDetails(
                              annotation: annotation,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: DesyDesignSystemTokens.spaceSm),
                Text(
                  'No annotations yet.',
                  key: const ValueKey('widget-workshop-annotations-empty'),
                  style: typography.body.sm.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
              if (target != null) ...[
                const SizedBox(height: DesyDesignSystemTokens.spaceSm),
                KeyedSubtree(
                  key: const ValueKey(
                    'widget-workshop-annotation-input-border',
                  ),
                  child: DesyTextField(
                    key: const ValueKey('widget-workshop-annotation-input'),
                    label: 'Annotation for ${target.displayLabel}',
                    hintText: 'What should change about this widget?',
                    value: widget.draft,
                    focusNode: widget.focusNode,
                    minLines: 2,
                    maxLines: 5,
                    onChanged: widget.onDraftChanged,
                  ),
                ),
                const SizedBox(height: DesyDesignSystemTokens.spaceSm),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FButton(
                    key: const ValueKey('widget-workshop-commit-annotation'),
                    mainAxisSize: MainAxisSize.min,
                    onPress: widget.draft.trim().isEmpty
                        ? null
                        : widget.onCommit,
                    child: const Text('Commit annotation'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _WorkshopAnnotationSummary extends StatelessWidget {
  const _WorkshopAnnotationSummary({required this.annotation});

  final DesyWorkshopAnnotation annotation;

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${annotation.target.widgetType}: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: annotation.comment),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: typography.body.sm,
    );
  }
}

class _WorkshopAnnotationDetails extends StatelessWidget {
  const _WorkshopAnnotationDetails({required this.annotation});

  final DesyWorkshopAnnotation annotation;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesyDesignSystemTokens.spaceMd,
        0,
        DesyDesignSystemTokens.spaceMd,
        DesyDesignSystemTokens.spaceMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(annotation.target.description, style: typography.body.sm),
          const SizedBox(height: DesyDesignSystemTokens.spaceXs),
          if (annotation.target.sourceLocation case final location?)
            Text(
              location.displayLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.body.xs.copyWith(
                color: colors.mutedForeground,
                fontFamily: 'monospace',
              ),
            )
          else
            Text(
              annotation.target.widgetPath,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: typography.body.xs.copyWith(color: colors.mutedForeground),
            ),
          if (annotation.target.widgetKey case final key?) ...[
            const SizedBox(height: DesyDesignSystemTokens.spaceXs),
            Text(
              'Key: $key',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.body.xs.copyWith(color: colors.mutedForeground),
            ),
          ],
        ],
      ),
    );
  }
}

class _CandidatesPanel extends StatefulWidget {
  const _CandidatesPanel({
    required this.extension,
    required this.candidates,
    required this.selectedCandidateIds,
    required this.widgetTarget,
    required this.annotations,
    required this.annotationDraft,
    required this.annotationFocusNode,
    required this.reloadCount,
    required this.onAnnotationChanged,
    required this.onCommitAnnotation,
    required this.onWidgetTargetSelected,
    required this.onWidgetTargetCleared,
    required this.onSelectionChanged,
  });

  final DesyWorkspaceExtensionContext extension;
  final List<DesyWorkshopCandidate> candidates;
  final Set<String> selectedCandidateIds;
  final DesyWorkshopWidgetTarget? widgetTarget;
  final List<DesyWorkshopAnnotation> annotations;
  final String annotationDraft;
  final FocusNode annotationFocusNode;
  final int reloadCount;
  final ValueChanged<String> onAnnotationChanged;
  final VoidCallback onCommitAnnotation;
  final ValueChanged<DesyWorkshopWidgetTarget> onWidgetTargetSelected;
  final VoidCallback onWidgetTargetCleared;
  final void Function(String id, bool selected) onSelectionChanged;

  @override
  State<_CandidatesPanel> createState() => _CandidatesPanelState();
}

class _CandidatesPanelState extends State<_CandidatesPanel> {
  final _scrollController = ScrollController();
  var _inspectMode = false;

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
                if (widget.widgetTarget case final target?) ...[
                  DecoratedBox(
                    key: const ValueKey('widget-workshop-selection-status'),
                    decoration: BoxDecoration(
                      color: colors.desy.signal,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesyDesignSystemTokens.spaceSm,
                        vertical: DesyDesignSystemTokens.spaceXs,
                      ),
                      child: Text(
                        '${target.displayLabel} selected',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typography.body.xs.copyWith(
                          color: colors.desy.onSignal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
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
                          final selected = widget.selectedCandidateIds.contains(
                            candidate.id,
                          );
                          return _CandidateCard(
                            key: ValueKey(candidate.id),
                            extension: widget.extension,
                            candidate: candidate,
                            selected: selected,
                            showComponents:
                                selected &&
                                widget.selectedCandidateIds.length == 1,
                            inspectMode: _inspectMode,
                            widgetSelection:
                                widget.widgetTarget?.candidateId == candidate.id
                                ? widget.widgetTarget
                                : null,
                            onWidgetSelected: widget.onWidgetTargetSelected,
                            onSelected: (selected) => widget.onSelectionChanged(
                              candidate.id,
                              selected,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: DesyDesignSystemTokens.spaceLg,
                  right: DesyDesignSystemTokens.spaceLg,
                  bottom: DesyDesignSystemTokens.spaceLg,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: _WorkshopAnnotationDock(
                        target: widget.widgetTarget,
                        annotations: widget.annotations,
                        candidates: widget.candidates,
                        draft: widget.annotationDraft,
                        focusNode: widget.annotationFocusNode,
                        inspecting: _inspectMode,
                        onDraftChanged: widget.onAnnotationChanged,
                        onCommit: widget.onCommitAnnotation,
                        onInspectionToggle: () {
                          final enabled = !_inspectMode;
                          setState(() => _inspectMode = enabled);
                          if (!enabled) widget.onWidgetTargetCleared();
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
    required this.selected,
    required this.showComponents,
    required this.inspectMode,
    required this.widgetSelection,
    required this.onWidgetSelected,
    required this.onSelected,
  });

  final DesyWorkspaceExtensionContext extension;
  final DesyWorkshopCandidate candidate;
  final bool selected;
  final bool showComponents;
  final bool inspectMode;
  final DesyWorkshopWidgetTarget? widgetSelection;
  final ValueChanged<DesyWorkshopWidgetTarget> onWidgetSelected;
  final ValueChanged<bool> onSelected;

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
              child: FCheckbox(
                value: selected,
                onChange: onSelected,
                label: Text(candidate.title, style: typography.body.sm),
                description: Text(
                  candidate.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
                              child: _InspectablePreview(
                                candidateId: candidate.id,
                                enabled: inspectMode,
                                selection: widgetSelection,
                                selectionColor:
                                    context.theme.colors.desy.signal,
                                onSelected: onWidgetSelected,
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

class _InspectablePreview extends StatefulWidget {
  const _InspectablePreview({
    required this.candidateId,
    required this.enabled,
    required this.selection,
    required this.selectionColor,
    required this.onSelected,
    required this.child,
  });

  final String candidateId;
  final bool enabled;
  final DesyWorkshopWidgetTarget? selection;
  final Color selectionColor;
  final ValueChanged<DesyWorkshopWidgetTarget> onSelected;
  final Widget child;

  @override
  State<_InspectablePreview> createState() => _InspectablePreviewState();
}

class _InspectablePreviewState extends State<_InspectablePreview> {
  final _rootKey = GlobalKey();

  void _selectAt(TapDownDetails details) {
    final rootContext = _rootKey.currentContext;
    final root = rootContext?.findRenderObject();
    if (rootContext is! Element || root == null || !root.attached) return;
    final rootPosition = root is RenderBox
        ? root.globalToLocal(details.globalPosition)
        : details.localPosition;

    ({Element element, Rect bounds, int depth})? bestHit;
    void visit(Element element, int depth) {
      final renderObject = element.findRenderObject();
      if (renderObject != null &&
          renderObject.attached &&
          renderObject != root &&
          !renderObject.semanticBounds.isEmpty) {
        final bounds = MatrixUtils.transformRect(
          renderObject.getTransformTo(root),
          renderObject.semanticBounds,
        );
        if (bounds.isFinite && bounds.contains(rootPosition)) {
          final projectElement = _nearestProjectElement(element, rootContext);
          final current = bestHit;
          final area = bounds.width * bounds.height;
          final currentArea = current == null
              ? double.infinity
              : current.bounds.width * current.bounds.height;
          if (area < currentArea ||
              (area == currentArea && depth > (current?.depth ?? -1))) {
            bestHit = (element: projectElement, bounds: bounds, depth: depth);
          }
        }
      }
      element.visitChildren((child) => visit(child, depth + 1));
    }

    rootContext.visitChildren((child) => visit(child, 0));
    final hit = bestHit;
    if (hit == null) return;
    final element = hit.element;
    widget.onSelected(
      DesyWorkshopWidgetTarget(
        candidateId: widget.candidateId,
        widgetType: element.widget.runtimeType.toString(),
        widgetPath: _widgetPath(element),
        description: _describeWidget(element.widget),
        bounds: hit.bounds,
        sourceLocation: _sourceLocation(element),
        widgetKey: _describeKey(element.widget.key),
      ),
    );
  }

  Element _nearestProjectElement(Element element, Element root) {
    if (debugIsWidgetLocalCreation(element.widget)) return element;
    var result = element;
    element.visitAncestorElements((ancestor) {
      if (ancestor == root) return false;
      if (debugIsWidgetLocalCreation(ancestor.widget)) {
        result = ancestor;
        return false;
      }
      return true;
    });
    return result;
  }

  DesyWorkshopSourceLocation? _sourceLocation(Element element) {
    DesyWorkshopSourceLocation? result;
    assert(() {
      final service = WidgetInspectorService.instance;
      service.selection.currentElement = element;
      // Flutter currently exposes creationLocation only through its inspector
      // serialization contract. Workshop is a debug-time developer tool.
      // ignore: invalid_use_of_visible_for_testing_member
      final delegate = InspectorSerializationDelegate(service: service);
      final serialized = element.toDiagnosticsNode().toJsonMap(delegate);
      final rawLocation = serialized['creationLocation'];
      if (rawLocation is Map<Object?, Object?>) {
        try {
          result = DesyWorkshopSourceLocation.fromInspectorJson(rawLocation);
        } on FormatException {
          result = null;
        }
      }
      return true;
    }());
    return result;
  }

  String? _describeKey(Key? key) {
    if (key == null) return null;
    if (key is ValueKey<Object?>) return '${key.value}';
    return key.toString();
  }

  String _describeWidget(Widget widget) {
    final description = switch (widget) {
      Text(data: final data?) => 'Text("${_compactDescription(data)}")',
      Text(textSpan: final span?) =>
        'Text("${_compactDescription(span.toPlainText())}")',
      SelectableText(data: final data?) =>
        'SelectableText("${_compactDescription(data)}")',
      SelectableText(textSpan: final span?) =>
        'SelectableText("${_compactDescription(span.toPlainText())}")',
      RichText(:final text) =>
        'RichText("${_compactDescription(text.toPlainText())}")',
      Semantics(:final properties) when properties.label != null =>
        'Semantics("${_compactDescription(properties.label!)}")',
      Tooltip(:final message) when message != null =>
        'Tooltip("${_compactDescription(message)}")',
      TextField(:final decoration)
          when decoration?.labelText != null || decoration?.hintText != null =>
        'TextField("${_compactDescription(decoration?.labelText ?? decoration!.hintText!)}")',
      Icon(:final icon) when icon != null =>
        'Icon(U+${icon.codePoint.toRadixString(16).toUpperCase()})',
      _ => widget.toStringShort(),
    };
    return description;
  }

  String _compactDescription(String value) {
    final escaped = value
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll('"', r'\"');
    return escaped.length <= 64 ? escaped : '${escaped.substring(0, 61)}…';
  }

  String _widgetPath(Element element) {
    final root = _rootKey.currentContext;
    final segments = <String>[element.widget.runtimeType.toString()];
    element.visitAncestorElements((ancestor) {
      if (ancestor == root) return false;
      if (debugIsWidgetLocalCreation(ancestor.widget)) {
        segments.add(ancestor.widget.runtimeType.toString());
      }
      return true;
    });
    final ordered = segments.reversed.toList(growable: false);
    final visible = ordered.length > 8
        ? ordered.sublist(ordered.length - 8)
        : ordered;
    return visible.join(' > ');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        RepaintBoundary(key: _rootKey, child: widget.child),
        if (widget.selection case final selection?)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SelectionOutlinePainter(
                  bounds: selection.bounds,
                  color: widget.selectionColor,
                ),
              ),
            ),
          ),
        if (widget.selection case final selection?)
          Positioned(
            left: selection.bounds.left,
            top: selection.bounds.top >= 26
                ? selection.bounds.top - 26
                : selection.bounds.top,
            child: IgnorePointer(
              child: Semantics(
                label: 'Selected widget ${selection.displayLabel}',
                child: DecoratedBox(
                  key: const ValueKey('widget-workshop-selection-label'),
                  decoration: BoxDecoration(
                    color: context.theme.colors.desy.signal,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    child: Text(
                      selection.displayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.theme.colors.desy.onSignal,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (widget.enabled)
          Positioned.fill(
            child: Semantics(
              button: true,
              label: 'Select a widget in ${widget.candidateId}',
              child: MouseRegion(
                cursor: SystemMouseCursors.precise,
                child: Listener(
                  key: ValueKey(
                    'widget-workshop-inspector-${widget.candidateId}',
                  ),
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) => _selectAt(
                    TapDownDetails(
                      globalPosition: event.position,
                      localPosition: event.localPosition,
                      kind: event.kind,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SelectionOutlinePainter extends CustomPainter {
  const _SelectionOutlinePainter({required this.bounds, required this.color});

  final Rect bounds;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(bounds, Paint()..color = color.withValues(alpha: .18));
    canvas.drawRect(
      bounds,
      Paint()
        ..color = color.withValues(alpha: .3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
    canvas.drawRect(
      bounds.deflate(1.5),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final handles = Paint()..color = color;
    for (final point in [
      bounds.topLeft,
      bounds.topRight,
      bounds.bottomLeft,
      bounds.bottomRight,
    ]) {
      canvas.drawCircle(point, 4, handles);
    }
  }

  @override
  bool shouldRepaint(covariant _SelectionOutlinePainter oldDelegate) =>
      oldDelegate.bounds != bounds || oldDelegate.color != color;
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

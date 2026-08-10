import 'dart:async';

import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/foundation.dart' show DiagnosticsTreeStyle;
import 'package:flutter/material.dart';

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
      _WidgetWorkshopScreen(
        extension: extension,
        configuration: configuration,
      );
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
  final _selectedCandidateIds = <String>{};
  var _reloadCount = 0;

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

  @override
  Widget build(BuildContext context) {
    final candidates = widget.configuration.candidates();
    _selectedCandidateIds.removeWhere(
      (id) => !candidates.any((candidate) => candidate.id == id),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final workspace = _WorkshopWorkspace(
          extension: widget.extension,
          runtime: _runtime,
          candidates: candidates,
          selectedCandidateIds: _selectedCandidateIds,
          reloadCount: _reloadCount,
          onSelectionChanged: _setSelected,
        );
        if (constraints.maxWidth < 760) {
          return Column(
            children: [
              _CompactWorkshopHeader(extension: widget.extension),
              Expanded(child: workspace),
            ],
          );
        }
        return Row(
          key: const ValueKey('widget-workshop-standalone-screen'),
          children: [
            SizedBox(
              width: 272,
              child: _WorkshopSessionsSidebar(extension: widget.extension),
            ),
            Container(width: 1, color: context.theme.colors.border),
            Expanded(child: workspace),
          ],
        );
      },
    );
  }
}

class _WorkshopSessionsSidebar extends StatelessWidget {
  const _WorkshopSessionsSidebar({required this.extension});

  final DesyWorkspaceExtensionContext extension;

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
                key: const ValueKey('widget-workshop-exit'),
                size: DesyButtonSize.sm,
                variant: DesyButtonVariant.outline,
                semanticsLabel: 'Back to Atlas',
                onPress: extension.onExit,
                child: const Icon(DesyIcons.arrowLeft, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Workshop',
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
        label: 'Sessions',
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
          ),
        ],
      ),
    ],
  );
}

class _CompactWorkshopHeader extends StatelessWidget {
  const _CompactWorkshopHeader({required this.extension});

  final DesyWorkspaceExtensionContext extension;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: context.theme.colors.border)),
    ),
    child: Row(
      children: [
        DesyButton.icon(
          key: const ValueKey('widget-workshop-exit-compact'),
          size: DesyButtonSize.sm,
          variant: DesyButtonVariant.outline,
          semanticsLabel: 'Back to Atlas',
          onPress: extension.onExit,
          child: const Icon(DesyIcons.arrowLeft, size: 16),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Text('Live widget exploration')),
      ],
    ),
  );
}

class _WorkshopWorkspace extends StatelessWidget {
  const _WorkshopWorkspace({
    required this.extension,
    required this.runtime,
    required this.candidates,
    required this.selectedCandidateIds,
    required this.reloadCount,
    required this.onSelectionChanged,
  });

  final DesyWorkspaceExtensionContext extension;
  final DesyWorkshopRuntime runtime;
  final List<DesyWorkshopCandidate> candidates;
  final Set<String> selectedCandidateIds;
  final int reloadCount;
  final void Function(String id, bool selected) onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return ColoredBox(
      color: colors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hot reload workshop',
                          style: typography.display.xl2,
                        ),
                        const SizedBox(
                          height: DesyDesignSystemTokens.spaceXs,
                        ),
                        Text(
                          'Compare real Flutter implementations under '
                          '${extension.activeTheme.name}, then continue the '
                          'selected direction with Codex.',
                          style: typography.body.sm.copyWith(
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _RuntimeStatus(runtime: runtime),
                  const SizedBox(width: DesyDesignSystemTokens.spaceSm),
                  FButton(
                    variant: FButtonVariant.outline,
                    mainAxisSize: MainAxisSize.min,
                    onPress: runtime.supported && !runtime.running
                        ? () => unawaited(runtime.requestHotReload())
                        : null,
                    child: const Text('Hot reload'),
                  ),
                ],
              ),
              const SizedBox(height: DesyDesignSystemTokens.spaceLg),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final activity = _RuntimePanel(
                      runtime: runtime,
                      candidates: candidates,
                      selectedCandidateIds: selectedCandidateIds,
                    );
                    final previews = _CandidatesPanel(
                      extension: extension,
                      candidates: candidates,
                      selectedCandidateIds: selectedCandidateIds,
                      reloadCount: reloadCount,
                      onSelectionChanged: onSelectionChanged,
                    );
                    if (constraints.maxWidth < 900) {
                      return Column(
                        children: [
                          SizedBox(height: 320, child: activity),
                          const SizedBox(
                            height: DesyDesignSystemTokens.spaceMd,
                          ),
                          Expanded(child: previews),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: 360, child: activity),
                        const SizedBox(width: DesyDesignSystemTokens.spaceMd),
                        Expanded(child: previews),
                      ],
                    );
                  },
                ),
              ),
            ],
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
  });

  final DesyWorkshopRuntime runtime;
  final List<DesyWorkshopCandidate> candidates;
  final Set<String> selectedCandidateIds;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final selected = candidates
        .where((candidate) => selectedCandidateIds.contains(candidate.id))
        .toList(growable: false);

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Codex activity', style: typography.body.lg)),
                Text(
                  '${selected.length} selected',
                  style: typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesyDesignSystemTokens.spaceMd),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.secondary,
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(
                    DesyDesignSystemTokens.radiusMd,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(
                    DesyDesignSystemTokens.spaceSm,
                  ),
                  child: SingleChildScrollView(
                    reverse: true,
                    child: SelectionArea(
                      child: Text(
                        runtime.logs.join('\n'),
                        style: typography.body.xs.copyWith(
                          color: colors.foreground,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: DesyDesignSystemTokens.spaceMd),
            Text('Workshop input', style: typography.body.sm),
            const SizedBox(height: DesyDesignSystemTokens.spaceSm),
            DesyTextField(
              key: const ValueKey('widget-workshop-prompt'),
              label: 'Widget change request',
              hintText: 'Combine the strongest parts into a new option…',
              value: runtime.prompt,
              enabled: runtime.supported && !runtime.running,
              minLines: 4,
              maxLines: 7,
              onChanged: runtime.setPrompt,
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
                      onPress: runtime.canRun
                          ? () => unawaited(
                              runtime.run(
                                candidates: candidates,
                                selectedCandidateIds: selectedCandidateIds,
                              ),
                            )
                          : null,
                      child: Text(
                        runtime.running
                            ? 'Codex is working…'
                            : 'Continue with Codex',
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _CandidatesPanel extends StatefulWidget {
  const _CandidatesPanel({
    required this.extension,
    required this.candidates,
    required this.selectedCandidateIds,
    required this.reloadCount,
    required this.onSelectionChanged,
  });

  final DesyWorkspaceExtensionContext extension;
  final List<DesyWorkshopCandidate> candidates;
  final Set<String> selectedCandidateIds;
  final int reloadCount;
  final void Function(String id, bool selected) onSelectionChanged;

  @override
  State<_CandidatesPanel> createState() => _CandidatesPanelState();
}

class _CandidatesPanelState extends State<_CandidatesPanel> {
  final _scrollController = ScrollController();
  var _inspectMode = false;
  _WidgetSelection? _widgetSelection;

  @override
  void reassemble() {
    super.reassemble();
    _widgetSelection = null;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return FCard(
      clipBehavior: Clip.antiAlias,
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
                      const SizedBox(
                        height: DesyDesignSystemTokens.spaceXs,
                      ),
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
                if (_widgetSelection case final selection?) ...[
                  Text(
                    selection.widgetType,
                    style: typography.body.xs.copyWith(color: colors.primary),
                  ),
                  const SizedBox(width: DesyDesignSystemTokens.spaceMd),
                ],
                FButton(
                  variant: _inspectMode
                      ? FButtonVariant.primary
                      : FButtonVariant.outline,
                  mainAxisSize: MainAxisSize.min,
                  onPress: () => setState(() => _inspectMode = !_inspectMode),
                  child: Text(
                    _inspectMode ? 'Stop inspecting' : 'Inspect widgets',
                  ),
                ),
              ],
            ),
          ),
          ColoredBox(color: colors.border, child: const SizedBox(height: 1)),
          Expanded(
            child: ColoredBox(
              color: colors.secondary,
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(
                    DesyDesignSystemTokens.spaceLg,
                  ),
                  itemCount: widget.candidates.length,
                  separatorBuilder: (context, index) => const SizedBox(
                    width: DesyDesignSystemTokens.spaceMd,
                  ),
                  itemBuilder: (context, index) {
                    final candidate = widget.candidates[index];
                    return _CandidateCard(
                      key: ValueKey(candidate.id),
                      extension: widget.extension,
                      candidate: candidate,
                      selected: widget.selectedCandidateIds.contains(
                        candidate.id,
                      ),
                      inspectMode: _inspectMode,
                      widgetSelection:
                          _widgetSelection?.candidateId == candidate.id
                          ? _widgetSelection
                          : null,
                      onWidgetSelected: (selection) =>
                          setState(() => _widgetSelection = selection),
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
    required this.inspectMode,
    required this.widgetSelection,
    required this.onWidgetSelected,
    required this.onSelected,
  });

  final DesyWorkspaceExtensionContext extension;
  final DesyWorkshopCandidate candidate;
  final bool selected;
  final bool inspectMode;
  final _WidgetSelection? widgetSelection;
  final ValueChanged<_WidgetSelection> onWidgetSelected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return SizedBox(
      width: 640,
      child: FCard(
        clipBehavior: Clip.antiAlias,
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
            ColoredBox(color: colors.border, child: const SizedBox(height: 1)),
            Expanded(
              child: ClipRect(
                child: DesyWidgetPreview(
                  theme: extension.activeTheme,
                  builder: (previewContext) => ColoredBox(
                    color:
                        extension.activeTheme.previewBackgroundColor ??
                        Theme.of(previewContext).scaffoldBackgroundColor,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(
                            DesyDesignSystemTokens.spaceMd,
                          ),
                          child: _InspectablePreview(
                            candidateId: candidate.id,
                            enabled: inspectMode,
                            selection: widgetSelection,
                            selectionColor: colors.primary,
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
            ColoredBox(color: colors.border, child: const SizedBox(height: 1)),
            Padding(
              padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceSm),
              child: Text(
                candidate.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: typography.body.xs.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ),
          ],
        ),
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
  final _WidgetSelection? selection;
  final Color selectionColor;
  final ValueChanged<_WidgetSelection> onSelected;
  final Widget child;

  @override
  State<_InspectablePreview> createState() => _InspectablePreviewState();
}

class _InspectablePreviewState extends State<_InspectablePreview> {
  final _rootKey = GlobalKey();

  void _selectAt(TapDownDetails details) {
    final root = _rootKey.currentContext?.findRenderObject();
    if (root == null || !root.attached) return;

    for (final renderObject in _renderObjectsAt(details.globalPosition, root)) {
      if (renderObject == root || renderObject.semanticBounds.isEmpty) continue;
      final creator = renderObject.debugCreator;
      if (creator is! DebugCreator) continue;
      final element = _nearestLocalElement(creator.element);
      final bounds = MatrixUtils.transformRect(
        renderObject.getTransformTo(root),
        renderObject.semanticBounds,
      );
      if (bounds.isEmpty || !bounds.isFinite) continue;
      widget.onSelected(
        _WidgetSelection(
          candidateId: widget.candidateId,
          widgetType: element.widget.runtimeType.toString(),
          bounds: bounds,
        ),
      );
      return;
    }
  }

  Element _nearestLocalElement(Element creator) {
    if (debugIsWidgetLocalCreation(creator.widget)) return creator;
    var result = creator;
    creator.visitAncestorElements((ancestor) {
      result = ancestor;
      return !debugIsWidgetLocalCreation(ancestor.widget);
    });
    return result;
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
        if (widget.enabled)
          Positioned.fill(
            child: Semantics(
              button: true,
              label: 'Select a widget in ${widget.candidateId}',
              child: MouseRegion(
                cursor: SystemMouseCursors.precise,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  excludeFromSemantics: true,
                  onTapDown: _selectAt,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WidgetSelection {
  const _WidgetSelection({
    required this.candidateId,
    required this.widgetType,
    required this.bounds,
  });

  final String candidateId;
  final String widgetType;
  final Rect bounds;
}

class _SelectionOutlinePainter extends CustomPainter {
  const _SelectionOutlinePainter({required this.bounds, required this.color});

  final Rect bounds;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(bounds, Paint()..color = color.withValues(alpha: .12));
    canvas.drawRect(
      bounds.deflate(1),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _SelectionOutlinePainter oldDelegate) =>
      oldDelegate.bounds != bounds || oldDelegate.color != color;
}

List<RenderObject> _renderObjectsAt(Offset globalPosition, RenderObject root) {
  final regularHits = <RenderObject>[];
  final edgeHits = <RenderObject>[];

  bool visit(RenderObject object, Matrix4 transform) {
    final inverse = Matrix4.tryInvert(transform);
    if (inverse == null) return false;
    final localPosition = MatrixUtils.transformPoint(inverse, globalPosition);
    var hit = false;

    final children = object.debugDescribeChildren();
    for (var index = children.length - 1; index >= 0; index--) {
      final diagnostics = children[index];
      final child = diagnostics.value;
      if (diagnostics.style == DiagnosticsTreeStyle.offstage ||
          child is! RenderObject) {
        continue;
      }
      final paintClip = object.describeApproximatePaintClip(child);
      if (paintClip != null && !paintClip.contains(localPosition)) continue;
      final childTransform = transform.clone();
      object.applyPaintTransform(child, childTransform);
      if (visit(child, childTransform)) hit = true;
    }

    final bounds = object.semanticBounds;
    if (bounds.contains(localPosition)) {
      hit = true;
      if (!bounds.deflate(2).contains(localPosition)) edgeHits.add(object);
    }
    if (hit) regularHits.add(object);
    return hit;
  }

  visit(root, root.getTransformTo(null));
  double area(RenderObject object) {
    final size = object.semanticBounds.size;
    return size.width * size.height;
  }

  regularHits.sort((a, b) => area(a).compareTo(area(b)));
  return <RenderObject>{...edgeHits, ...regularHits}.toList();
}

class _RuntimeStatus extends StatelessWidget {
  const _RuntimeStatus({required this.runtime});

  final DesyWorkshopRuntime runtime;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final live = runtime.supported;
    final active = runtime.running;
    final label = !live ? 'Preview only' : active ? 'Codex working' : 'Ready';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: active
            ? colors.primary.withValues(alpha: .1)
            : colors.secondary,
        border: Border.all(
          color: active ? colors.primary : colors.border,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(label),
      ),
    );
  }
}

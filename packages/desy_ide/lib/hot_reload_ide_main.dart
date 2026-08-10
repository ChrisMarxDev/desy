import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/foundation.dart' show DiagnosticsTreeStyle;
import 'package:flutter/material.dart';

import 'hot_reload_widget.dart';

const _configuredProjectDirectory = String.fromEnvironment(
  'DESY_IDE_PROJECT_DIR',
);

final _previewThemeData = DesyDesignSystemFoundation.themeData(
  DesyDesignSystemTheme.light,
);

final _desyPreviewTheme = DesyTheme(
  id: 'desy-ide.preview.light',
  name: 'Desy light',
  previewBackgroundColor: _previewThemeData.colors.background,
  wrap: (context, child) => DesyDesignSystemThemeScope(
    theme: DesyDesignSystemTheme.light,
    child: child,
  ),
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _HotReloadIdeApp());
}

class _HotReloadIdeApp extends StatelessWidget {
  const _HotReloadIdeApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Desy IDE · Hot reload workshop',
    theme: DesyDesignSystemFoundation.materialTheme(
      DesyDesignSystemTheme.light,
    ),
    home: const DesyDesignSystemScope(
      theme: DesyDesignSystemTheme.light,
      child: _HotReloadIdeScreen(),
    ),
  );
}

class _HotReloadIdeScreen extends StatefulWidget {
  const _HotReloadIdeScreen();

  @override
  State<_HotReloadIdeScreen> createState() => _HotReloadIdeScreenState();
}

class _HotReloadIdeScreenState extends State<_HotReloadIdeScreen> {
  late final _CodexController _codex;
  final _selectedCandidateIds = <String>{'homepage.playful'};
  var _reloadCount = 0;

  @override
  void initState() {
    super.initState();
    _codex = _CodexController(_resolveProjectDirectory())
      ..addListener(_handleControllerChange);
  }

  @override
  void reassemble() {
    super.reassemble();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _reloadCount++);
      _codex.noteReloadCompleted(_reloadCount);
    });
  }

  @override
  void dispose() {
    _codex
      ..removeListener(_handleControllerChange)
      ..dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    if (mounted) setState(() {});
  }

  void _toggleCandidate(String id, bool selected) {
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
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final candidates = buildHotReloadCandidates();

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
                        const SizedBox(height: DesyDesignSystemTokens.spaceXs),
                        Text(
                          'Describe the next step, compare real Flutter '
                          'implementations, and select the direction Codex '
                          'should continue.',
                          style: typography.body.sm.copyWith(
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(running: _codex.running),
                  const SizedBox(width: DesyDesignSystemTokens.spaceSm),
                  FButton(
                    variant: FButtonVariant.outline,
                    mainAxisSize: MainAxisSize.min,
                    onPress: _codex.running
                        ? null
                        : () => unawaited(_codex.requestHotReload()),
                    child: const Text('Hot reload'),
                  ),
                ],
              ),
              const SizedBox(height: DesyDesignSystemTokens.spaceLg),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 360,
                      child: _CodexPanel(
                        controller: _codex,
                        candidates: candidates,
                        selectedCandidateIds: _selectedCandidateIds,
                      ),
                    ),
                    const SizedBox(width: DesyDesignSystemTokens.spaceMd),
                    Expanded(
                      child: _CandidatesPanel(
                        candidates: candidates,
                        selectedCandidateIds: _selectedCandidateIds,
                        reloadCount: _reloadCount,
                        onSelectionChanged: _toggleCandidate,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodexPanel extends StatelessWidget {
  const _CodexPanel({
    required this.controller,
    required this.candidates,
    required this.selectedCandidateIds,
  });

  final _CodexController controller;
  final List<HotReloadCandidate> candidates;
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
                Expanded(
                  child: Text('Codex activity', style: typography.body.lg),
                ),
                Text(
                  '${selected.length} selected',
                  style: typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesyDesignSystemTokens.spaceXs),
            Text(
              'Follow the current edit, then describe the next iteration below.',
              style: typography.body.xs.copyWith(color: colors.mutedForeground),
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
                  padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceSm),
                  child: SingleChildScrollView(
                    reverse: true,
                    child: SelectionArea(
                      child: Text(
                        controller.logs.join('\n'),
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
            ColoredBox(color: colors.border, child: const SizedBox(height: 1)),
            const SizedBox(height: DesyDesignSystemTokens.spaceMd),
            Text('Workshop input', style: typography.body.sm),
            const SizedBox(height: DesyDesignSystemTokens.spaceXs),
            Text(
              'Your feedback and selected implementations become the next '
              'Codex request.',
              style: typography.body.xs.copyWith(color: colors.mutedForeground),
            ),
            const SizedBox(height: DesyDesignSystemTokens.spaceSm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.background,
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(
                  DesyDesignSystemTokens.radiusMd,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceSm),
                child: DesyTextField(
                  label: 'Widget change request',
                  hintText: 'Combine the strongest parts into a new option…',
                  value: controller.prompt,
                  enabled: !controller.running,
                  minLines: 5,
                  maxLines: 8,
                  onChanged: controller.setPrompt,
                ),
              ),
            ),
            const SizedBox(height: DesyDesignSystemTokens.spaceSm),
            Text(
              selected.isEmpty
                  ? 'No implementation selected'
                  : 'Selected: ${selected.map((item) => item.title).join(', ')}',
              style: typography.body.xs.copyWith(
                color: selected.isEmpty
                    ? colors.mutedForeground
                    : colors.primary,
              ),
            ),
            const SizedBox(height: DesyDesignSystemTokens.spaceSm),
            Row(
              children: [
                if (controller.running) ...[
                  FButton(
                    variant: FButtonVariant.outline,
                    mainAxisSize: MainAxisSize.min,
                    onPress: controller.cancel,
                    child: const Text('Stop'),
                  ),
                  const SizedBox(width: DesyDesignSystemTokens.spaceSm),
                ],
                Expanded(
                  child: FButton(
                    onPress: controller.canRun
                        ? () => unawaited(
                            controller.run(
                              candidates: candidates,
                              selectedCandidateIds: selectedCandidateIds,
                            ),
                          )
                        : null,
                    child: Text(
                      controller.running
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
    required this.candidates,
    required this.selectedCandidateIds,
    required this.reloadCount,
    required this.onSelectionChanged,
  });

  final List<HotReloadCandidate> candidates;
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final introduction = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Implementation options', style: typography.body.lg),
                    const SizedBox(height: DesyDesignSystemTokens.spaceXs),
                    Text(
                      'Scroll sideways to compare. Widget canvases render at '
                      '1:1 so inspection matches Flutter geometry.',
                      style: typography.body.xs.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                );
                final actions = Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: DesyDesignSystemTokens.spaceMd,
                  runSpacing: DesyDesignSystemTokens.spaceSm,
                  children: [
                    if (_widgetSelection case final selection?)
                      Text(
                        '${selection.widgetType} · '
                        '${selection.renderObjectType}',
                        style: typography.body.xs.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    Text(
                      '${widget.candidates.length} widgets  ·  '
                      '${widget.reloadCount} reloads',
                      style: typography.body.xs.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                    FButton(
                      variant: _inspectMode
                          ? FButtonVariant.primary
                          : FButtonVariant.outline,
                      mainAxisSize: MainAxisSize.min,
                      onPress: () =>
                          setState(() => _inspectMode = !_inspectMode),
                      child: Text(
                        _inspectMode ? 'Stop inspecting' : 'Inspect widgets',
                      ),
                    ),
                  ],
                );

                if (constraints.maxWidth < 720) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      introduction,
                      const SizedBox(height: DesyDesignSystemTokens.spaceMd),
                      Align(alignment: Alignment.centerLeft, child: actions),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: introduction),
                    const SizedBox(width: DesyDesignSystemTokens.spaceMd),
                    actions,
                  ],
                );
              },
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
                  padding: const EdgeInsets.fromLTRB(
                    DesyDesignSystemTokens.spaceLg,
                    DesyDesignSystemTokens.spaceLg,
                    DesyDesignSystemTokens.spaceLg,
                    DesyDesignSystemTokens.spaceLg +
                        DesyDesignSystemTokens.spaceSm,
                  ),
                  itemCount: widget.candidates.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: DesyDesignSystemTokens.spaceMd),
                  itemBuilder: (context, index) {
                    final candidate = widget.candidates[index];
                    return _CandidateCard(
                      key: ValueKey(candidate.id),
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
                      onSelected: (selected) =>
                          widget.onSelectionChanged(candidate.id, selected),
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
    required this.candidate,
    required this.selected,
    required this.inspectMode,
    required this.widgetSelection,
    required this.onWidgetSelected,
    required this.onSelected,
  });

  final HotReloadCandidate candidate;
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
      width: 664,
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
                  theme: _desyPreviewTheme,
                  builder: (previewContext) => ColoredBox(
                    color:
                        _desyPreviewTheme.previewBackgroundColor ??
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
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      candidate.id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.body.xs.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  ),
                  if (widgetSelection case final selection?)
                    Text(
                      '${selection.widgetType} selected',
                      style: typography.body.xs.copyWith(color: colors.primary),
                    )
                  else if (selected)
                    Text(
                      'Codex context',
                      style: typography.body.xs.copyWith(color: colors.primary),
                    ),
                ],
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

    final candidates = _renderObjectsAt(details.globalPosition, root);
    for (final renderObject in candidates) {
      if (renderObject == root || renderObject.semanticBounds.isEmpty) continue;
      final creator = renderObject.debugCreator;
      if (creator is! DebugCreator) continue;

      final projectElement = _nearestProjectElement(creator.element);
      final transform = renderObject.getTransformTo(root);
      final bounds = MatrixUtils.transformRect(
        transform,
        renderObject.semanticBounds,
      );
      if (bounds.isEmpty || !bounds.isFinite) continue;

      widget.onSelected(
        _WidgetSelection(
          candidateId: widget.candidateId,
          widgetType: projectElement.widget.runtimeType.toString(),
          renderObjectType: renderObject.runtimeType.toString(),
          bounds: bounds,
        ),
      );
      return;
    }
  }

  Element _nearestProjectElement(Element creator) {
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
    final selection = widget.selection;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        RepaintBoundary(key: _rootKey, child: widget.child),
        if (selection != null)
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
    required this.renderObjectType,
    required this.bounds,
  });

  final String candidateId;
  final String widgetType;
  final String renderObjectType;
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.running});

  final bool running;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: running
            ? colors.primary.withValues(alpha: .1)
            : colors.secondary,
        border: Border.all(color: running ? colors.primary : colors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: running ? colors.primary : colors.mutedForeground,
                shape: BoxShape.circle,
              ),
              child: const SizedBox.square(dimension: 7),
            ),
            const SizedBox(width: DesyDesignSystemTokens.spaceSm),
            Text(running ? 'Codex working' : 'Ready'),
          ],
        ),
      ),
    );
  }
}

class _CodexController extends ChangeNotifier {
  _CodexController(this.projectDirectory)
    : _pidFile = File('$projectDirectory/build/desy_ide_hot_reload.pid') {
    _append('Ready. Select an implementation and describe the next step.');
  }

  final String projectDirectory;
  final File _pidFile;
  final logs = <String>[];
  final _stderrTail = <String>[];

  Process? _process;
  var prompt =
      'Create a new implementation that combines the strongest parts of the '
      'selected direction with a clearer path into the workbench.';
  var running = false;
  var _disposed = false;

  bool get canRun => !running && prompt.trim().isNotEmpty;

  void setPrompt(String value) {
    prompt = value;
    _notify();
  }

  Future<void> run({
    required List<HotReloadCandidate> candidates,
    required Set<String> selectedCandidateIds,
  }) async {
    if (!canRun) return;

    final selected = candidates
        .where((candidate) => selectedCandidateIds.contains(candidate.id))
        .toList(growable: false);
    final selectionContext = _selectionContext(selected);
    running = true;
    logs.clear();
    _stderrTail.clear();
    _append(r'$ codex exec --approve-for-me …');
    _append('Selected context: ${_selectionLabel(selected)}');
    _append('Request: ${prompt.trim()}');

    try {
      final process = await Process.start(
        'codex',
        const [
          'exec',
          '--approve-for-me',
          '--ephemeral',
          '--color',
          'never',
          '--json',
          '-',
        ],
        workingDirectory: projectDirectory,
        runInShell: true,
      );
      if (_disposed) {
        process.kill();
        return;
      }

      _process = process;
      process.stdin.write(
        _agentPrompt(
          request: prompt.trim(),
          selectionContext: selectionContext,
        ),
      );
      await process.stdin.close();

      final outputDone = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach(_handleCodexEvent);
      final errorDone = process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach(_captureStderr);
      final exitCode = await process.exitCode;
      await Future.wait([outputDone, errorDone]);
      if (_disposed) return;

      _process = null;
      running = false;
      _append('Codex exited with code $exitCode.');
      if (exitCode == 0) {
        await requestHotReload();
      } else {
        for (final line in _stderrTail) {
          _append('stderr: $line');
        }
      }
    } on Object catch (error) {
      _process = null;
      running = false;
      _append('Could not run Codex: $error');
    }
  }

  String _selectionContext(List<HotReloadCandidate> selected) {
    if (selected.isEmpty) {
      return 'No implementation was selected. Treat the written request as '
          'the only direction.';
    }
    return [
      'The user explicitly selected these implementations as context:',
      for (final candidate in selected)
        '- ${candidate.id} — ${candidate.title}: ${candidate.description}',
      'Use their intent as a reference for the next iteration. Preserve their '
          'stable IDs if they remain, and add a new stable ID for a genuinely '
          'new alternative.',
    ].join('\n');
  }

  String _selectionLabel(List<HotReloadCandidate> selected) => selected.isEmpty
      ? 'none'
      : selected.map((candidate) => candidate.title).join(', ');

  Future<void> requestHotReload() async {
    try {
      final value = (await _pidFile.readAsString()).trim();
      final flutterToolPid = int.tryParse(value);
      if (flutterToolPid == null) {
        _append('Invalid Flutter PID file: $value');
        return;
      }

      final sent = Process.killPid(flutterToolPid, ProcessSignal.sigusr1);
      _append(
        sent
            ? 'Sent SIGUSR1 to Flutter tool $flutterToolPid. Reloading…'
            : 'Flutter tool $flutterToolPid did not accept the reload signal.',
      );
    } on FileSystemException {
      _append(
        'No reload controller found. Start with `task ide:hot_reload` so '
        'Flutter writes its PID file.',
      );
    }
  }

  void noteReloadCompleted(int count) {
    _append('Hot reload $count completed; workshop state was preserved.');
  }

  void cancel() {
    final process = _process;
    if (process == null) return;
    _append('Stopping Codex process ${process.pid}…');
    process.kill(ProcessSignal.sigterm);
  }

  void _handleCodexEvent(String line) {
    try {
      final event = jsonDecode(line) as Map<String, dynamic>;
      final type = event['type'];
      if (type == 'thread.started') {
        _append('Codex session started.');
        return;
      }
      if (type == 'turn.started') {
        _append('Planning and editing…');
        return;
      }
      if (type == 'turn.failed' || type == 'error') {
        _append('Codex error: ${event['error'] ?? event['message'] ?? line}');
        return;
      }
      if (type != 'item.started' && type != 'item.completed') return;

      final item = event['item'];
      if (item is! Map<String, dynamic>) return;
      final itemType = item['type'];
      if (itemType == 'agent_message' && type == 'item.completed') {
        final message = item['text'];
        if (message is String && message.trim().isNotEmpty) {
          _append(message.trim());
        }
        return;
      }
      if (itemType == 'command_execution' && type == 'item.started') {
        final command = item['command'];
        if (command is String) _append(r'$ ' + _compact(command));
        return;
      }
      if (itemType == 'command_execution' && type == 'item.completed') {
        final exitCode = item['exit_code'];
        if (exitCode is int && exitCode != 0) {
          _append('Command failed with code $exitCode.');
        }
        return;
      }
      if (itemType == 'file_change' && type == 'item.completed') {
        _append('Updated the implementation source.');
      }
    } on FormatException {
      _captureStderr(line);
    }
  }

  void _captureStderr(String line) {
    if (line.trim().isEmpty) return;
    _stderrTail.add(line);
    if (_stderrTail.length > 8) _stderrTail.removeAt(0);
  }

  String _compact(String value) {
    final oneLine = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return oneLine.length <= 100 ? oneLine : '${oneLine.substring(0, 97)}…';
  }

  String _agentPrompt({
    required String request,
    required String selectionContext,
  }) =>
      '''You are editing a deliberately isolated Flutter widget-workshop prototype.

Edit only lib/hot_reload_widget.dart. Do not modify, create, rename, or delete any other file. Keep the public HotReloadCandidate class and buildHotReloadCandidates() function signatures unchanged so the running host can hot reload them. Return multiple real Flutter implementation candidates with stable IDs, short titles, useful descriptions, and WidgetBuilder values. Use the existing desy_design_system and Flutter imports; do not add dependencies. Do not launch the app or run long-lived commands.

$selectionContext

Implement this request:
$request

After editing, run: dart format lib/hot_reload_widget.dart
Then briefly summarize which candidates changed or were added.''';

  void _append(String line) {
    if (_disposed) return;
    logs.add(line);
    if (logs.length > 160) logs.removeRange(0, logs.length - 160);
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _process?.kill(ProcessSignal.sigterm);
    _process = null;
    super.dispose();
  }
}

String _resolveProjectDirectory() {
  if (_configuredProjectDirectory.isNotEmpty) {
    return _configuredProjectDirectory;
  }
  return Directory.current.absolute.path;
}

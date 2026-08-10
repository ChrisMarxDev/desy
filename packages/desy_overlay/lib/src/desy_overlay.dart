import 'dart:async';
import 'dart:math' as math;

import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'desy_annotation.dart';

const _inspectionSignalColor = Color(0xFFFF2D8D);
const _inspectionSignalForeground = Color(0xFF18000C);

/// Controls which Flutter build modes may show [DesyOverlay].
enum DesyOverlayMode {
  /// Show the overlay only in a Flutter debug build.
  debugOnly,

  /// Keep the overlay available in every build mode.
  ///
  /// This must be an explicit consumer decision. Release targets do not expose
  /// Dart source locations and runtime type names may not be stable. Prefer
  /// widget keys and [Semantics.identifier] for durable agent identification.
  always,
}

/// Adds a compact widget review layer above an ordinary Flutter app.
///
/// The easiest integration point is [builder], passed to [MaterialApp.builder].
class DesyOverlay extends StatelessWidget {
  /// Creates a widget annotation overlay.
  const DesyOverlay({
    super.key,
    required this.child,
    required this.onAnnotationSubmitted,
    this.enabled = true,
    this.mode = DesyOverlayMode.debugOnly,
    this.initiallySelecting = false,
  });

  /// The consumer application beneath the overlay.
  final Widget child;

  /// Called after the user sends feedback.
  ///
  /// The consumer owns persistence and forwarding to an AI agent.
  final DesyAnnotationCallback onAnnotationSubmitted;

  /// Whether the overlay is currently enabled.
  final bool enabled;

  /// The build modes in which the overlay can appear.
  final DesyOverlayMode mode;

  /// Whether selection mode starts active.
  final bool initiallySelecting;

  /// Creates a [MaterialApp.builder] integration while preserving an existing
  /// builder when one is supplied.
  static TransitionBuilder builder({
    required DesyAnnotationCallback onAnnotationSubmitted,
    TransitionBuilder? existingBuilder,
    bool enabled = true,
    DesyOverlayMode mode = DesyOverlayMode.debugOnly,
    bool initiallySelecting = false,
  }) => (context, child) {
    final builtChild =
        existingBuilder?.call(context, child) ??
        child ??
        const SizedBox.shrink();
    return DesyOverlay(
      onAnnotationSubmitted: onAnnotationSubmitted,
      enabled: enabled,
      mode: mode,
      initiallySelecting: initiallySelecting,
      child: builtChild,
    );
  };

  @override
  Widget build(BuildContext context) {
    final available = enabled && (mode == DesyOverlayMode.always || kDebugMode);
    if (!available) return child;
    return _DesyDebugOverlayHost(
      onAnnotationSubmitted: onAnnotationSubmitted,
      initiallySelecting: initiallySelecting,
      child: child,
    );
  }
}

class _DesyDebugOverlayHost extends StatelessWidget {
  const _DesyDebugOverlayHost({
    required this.child,
    required this.onAnnotationSubmitted,
    required this.initiallySelecting,
  });

  final Widget child;
  final DesyAnnotationCallback onAnnotationSubmitted;
  final bool initiallySelecting;

  @override
  Widget build(BuildContext context) => Overlay(
    initialEntries: [
      OverlayEntry(
        builder: (context) => _DesyDebugOverlay(
          onAnnotationSubmitted: onAnnotationSubmitted,
          initiallySelecting: initiallySelecting,
          child: child,
        ),
      ),
    ],
  );
}

class _DesyDebugOverlay extends StatefulWidget {
  const _DesyDebugOverlay({
    required this.child,
    required this.onAnnotationSubmitted,
    required this.initiallySelecting,
  });

  final Widget child;
  final DesyAnnotationCallback onAnnotationSubmitted;
  final bool initiallySelecting;

  @override
  State<_DesyDebugOverlay> createState() => _DesyDebugOverlayState();
}

class _DesyDebugOverlayState extends State<_DesyDebugOverlay> {
  final _rootKey = GlobalKey();
  final _commentFocusNode = FocusNode();
  var _selecting = false;
  var _cardOpen = false;
  var _comment = '';
  var _submitting = false;
  String? _error;
  Offset? _cardOffset;
  DesyWidgetTarget? _target;

  @override
  void initState() {
    super.initState();
    _selecting = widget.initiallySelecting;
  }

  @override
  void reassemble() {
    super.reassemble();
    _target = null;
    _selecting = false;
    _cardOpen = false;
    _error = null;
  }

  @override
  void dispose() {
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _toggleSelecting() {
    if (_selecting) {
      _cancelSelection();
      return;
    }
    _commentFocusNode.unfocus();
    setState(() {
      _selecting = true;
      _cardOpen = false;
      _target = null;
      _comment = '';
      _error = null;
    });
  }

  void _cancelSelection() {
    if (!_selecting) return;
    setState(() => _selecting = false);
  }

  void _closeCard() {
    _commentFocusNode.unfocus();
    setState(() {
      _target = null;
      _cardOpen = false;
      _comment = '';
      _error = null;
    });
  }

  void _selectAt(PointerDownEvent event) {
    final rootContext = _rootKey.currentContext;
    final root = rootContext?.findRenderObject();
    if (rootContext is! Element || root == null || !root.attached) return;
    final rootPosition = root is RenderBox
        ? root.globalToLocal(event.position)
        : event.localPosition;

    ({Element element, RenderObject renderObject, Rect bounds, int depth})?
    bestHit;

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
          final projectElement = _nearestLocalElement(element, rootContext);
          final current = bestHit;
          final area = bounds.width * bounds.height;
          final currentArea = current == null
              ? double.infinity
              : current.bounds.width * current.bounds.height;
          if (area < currentArea ||
              (area == currentArea && depth > (current?.depth ?? -1))) {
            bestHit = (
              element: projectElement,
              renderObject: renderObject,
              bounds: bounds,
              depth: depth,
            );
          }
        }
      }
      element.visitChildren((child) => visit(child, depth + 1));
    }

    rootContext.visitChildren((child) => visit(child, 0));
    final hit = bestHit;
    if (hit == null) return;

    setState(() {
      _target = _createTarget(
        element: hit.element,
        renderObject: hit.renderObject,
        bounds: hit.bounds,
        root: rootContext,
      );
      _cardOpen = true;
      _comment = '';
      _error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _commentFocusNode.requestFocus();
    });
  }

  DesyWidgetTarget _createTarget({
    required Element element,
    required RenderObject renderObject,
    required Rect bounds,
    required Element root,
  }) {
    final ancestry = _ancestry(element, root);
    final renderBox = renderObject is RenderBox ? renderObject : null;
    return DesyWidgetTarget(
      buildMode: _buildMode,
      widgetType: element.widget.runtimeType.toString(),
      description: _describeWidget(element.widget),
      widgetPath: ancestry.reversed.join(' > '),
      ancestorWidgetTypes: ancestry,
      stateType: element is StatefulElement
          ? element.state.runtimeType.toString()
          : null,
      renderObjectType: renderObject.runtimeType.toString(),
      bounds: bounds,
      paintBounds: renderObject.paintBounds,
      semanticBounds: renderObject.semanticBounds,
      renderSize: renderBox?.size,
      layoutConstraints: renderBox?.constraints.toString(),
      identitySignals: _identitySignals(element, root),
      diagnostics: _diagnostics(element.widget),
      sourceLocation: _sourceLocation(element),
      widgetKey: _describeKey(element.widget.key),
    );
  }

  DesyBuildMode get _buildMode {
    if (kReleaseMode) return DesyBuildMode.release;
    if (kProfileMode) return DesyBuildMode.profile;
    return DesyBuildMode.debug;
  }

  Element _nearestLocalElement(Element element, Element root) {
    if (kReleaseMode) return element;
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

  DesySourceLocation? _sourceLocation(Element element) {
    if (!kDebugMode) return null;
    DesySourceLocation? result;
    assert(() {
      final service = WidgetInspectorService.instance;
      service.selection.currentElement = element;
      // Flutter exposes creationLocation through its inspector serialization.
      // ignore: invalid_use_of_visible_for_testing_member
      final delegate = InspectorSerializationDelegate(service: service);
      final serialized = element.toDiagnosticsNode().toJsonMap(delegate);
      final location = serialized['creationLocation'];
      if (location is Map<Object?, Object?>) {
        final file = location['file'];
        final line = location['line'];
        final column = location['column'];
        if (file is String && line is int && column is int) {
          result = DesySourceLocation(file: file, line: line, column: column);
        }
      }
      return true;
    }());
    return result;
  }

  List<String> _ancestry(Element element, Element root) {
    final types = <String>[element.widget.runtimeType.toString()];
    var visited = 0;
    element.visitAncestorElements((ancestor) {
      if (ancestor == root || visited == 80) return false;
      visited++;
      final widget = ancestor.widget;
      final useful =
          kReleaseMode ||
          debugIsWidgetLocalCreation(widget) ||
          widget.key != null ||
          widget is Semantics;
      if (useful && types.length < 10) {
        types.add(widget.runtimeType.toString());
      }
      return true;
    });
    return types;
  }

  List<DesyWidgetSignal> _identitySignals(Element element, Element root) {
    final signals = <DesyWidgetSignal>[];
    final seen = <String>{};

    void add(DesyWidgetSignalKind kind, String? rawValue) {
      final value = rawValue?.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (value == null || value.isEmpty) return;
      final compact = value.length <= 160
          ? value
          : '${value.substring(0, 157)}…';
      if (!seen.add('${kind.name}:$compact')) return;
      signals.add(DesyWidgetSignal(kind: kind, value: compact));
    }

    void inspect(Widget widget) {
      add(DesyWidgetSignalKind.key, _describeKey(widget.key));
      switch (widget) {
        case Text(data: final data?):
          add(DesyWidgetSignalKind.visibleText, data);
        case Text(textSpan: final span?):
          add(DesyWidgetSignalKind.visibleText, span.toPlainText());
        case SelectableText(data: final data?):
          add(DesyWidgetSignalKind.visibleText, data);
        case SelectableText(textSpan: final span?):
          add(DesyWidgetSignalKind.visibleText, span.toPlainText());
        case RichText(:final text):
          add(DesyWidgetSignalKind.visibleText, text.toPlainText());
        case Tooltip(:final message):
          add(DesyWidgetSignalKind.visibleText, message);
        case TextField(:final decoration):
          add(
            DesyWidgetSignalKind.visibleText,
            decoration?.labelText ?? decoration?.hintText,
          );
        case Semantics(:final properties):
          add(DesyWidgetSignalKind.semanticsIdentifier, properties.identifier);
          add(DesyWidgetSignalKind.semanticLabel, properties.label);
          add(DesyWidgetSignalKind.semanticValue, properties.value);
          add(DesyWidgetSignalKind.semanticHint, properties.hint);
        default:
          break;
      }
    }

    inspect(element.widget);
    var visited = 0;
    element.visitAncestorElements((ancestor) {
      if (ancestor == root || visited == 80) return false;
      inspect(ancestor.widget);
      visited++;
      return true;
    });
    return signals;
  }

  List<DesyWidgetDiagnostic> _diagnostics(Widget widget) {
    const blockedNames = {
      'controller',
      'focusNode',
      'onChanged',
      'onPressed',
      'onTap',
      'builder',
    };
    final result = <DesyWidgetDiagnostic>[];
    try {
      for (final property in widget.toDiagnosticsNode().getProperties()) {
        final name = property.name;
        if (name == null ||
            name.isEmpty ||
            blockedNames.contains(name) ||
            name.startsWith('on')) {
          continue;
        }
        final rawValue = property.toDescription().trim();
        if (rawValue.isEmpty || rawValue == 'null') continue;
        final value = rawValue.length <= 160
            ? rawValue
            : '${rawValue.substring(0, 157)}…';
        result.add(DesyWidgetDiagnostic(name: name, value: value));
        if (result.length == 16) break;
      }
    } on Object {
      return const [];
    }
    return result;
  }

  String? _describeKey(Key? key) {
    if (key == null || key is UniqueKey) return null;
    if (key is ValueKey<Object?>) return '${key.value}';
    if (key is ObjectKey) return '${key.value}';
    final description = key.toString();
    return description.contains('#') ? null : description;
  }

  String _describeWidget(Widget widget) => switch (widget) {
    Text(data: final data?) => 'Text("${_compact(data)}")',
    Text(textSpan: final span?) => 'Text("${_compact(span.toPlainText())}")',
    SelectableText(data: final data?) => 'SelectableText("${_compact(data)}")',
    SelectableText(textSpan: final span?) =>
      'SelectableText("${_compact(span.toPlainText())}")',
    RichText(:final text) => 'RichText("${_compact(text.toPlainText())}")',
    Semantics(:final properties) when properties.label != null =>
      'Semantics("${_compact(properties.label!)}")',
    Tooltip(:final message) when message != null =>
      'Tooltip("${_compact(message)}")',
    TextField(:final decoration)
        when decoration?.labelText != null || decoration?.hintText != null =>
      'TextField("${_compact(decoration?.labelText ?? decoration!.hintText!)}")',
    Icon(:final icon) when icon != null =>
      'Icon(U+${icon.codePoint.toRadixString(16).toUpperCase()})',
    _ => widget.toStringShort(),
  };

  String _compact(String value) {
    final escaped = value
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll('"', r'\"');
    return escaped.length <= 64 ? escaped : '${escaped.substring(0, 61)}…';
  }

  Future<void> _submit() async {
    final target = _target;
    final comment = _comment.trim();
    if (target == null || comment.isEmpty || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await Future<void>.sync(
        () => widget.onAnnotationSubmitted(
          DesyAnnotation(target: target, comment: comment),
        ),
      );
      if (!mounted) return;
      _commentFocusNode.unfocus();
      setState(() {
        _target = null;
        _comment = '';
        _cardOpen = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Could not send feedback: $error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Offset _resolvedCardOffset(BoxConstraints constraints, double cardWidth) {
    const cardHeight = 280.0;
    final fallback = Offset(
      math.max(12, constraints.maxWidth - cardWidth - 16),
      math.max(12, constraints.maxHeight - cardHeight - 72),
    );
    final offset = _cardOffset ?? fallback;
    return Offset(
      offset.dx.clamp(8, math.max(8, constraints.maxWidth - cardWidth - 8)),
      offset.dy.clamp(8, math.max(8, constraints.maxHeight - cardHeight - 8)),
    );
  }

  void _moveCard(Offset delta, BoxConstraints constraints, double cardWidth) {
    final current = _resolvedCardOffset(constraints, cardWidth);
    setState(() => _cardOffset = current + delta);
  }

  @override
  Widget build(BuildContext context) {
    final target = _target;
    final desyTheme =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark
        ? DesyDesignSystemTheme.dark
        : DesyDesignSystemTheme.light;

    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            _selecting) {
          _cancelSelection();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = math.min(
            360.0,
            math.max(0.0, constraints.maxWidth - 24),
          );
          final cardOffset = _resolvedCardOffset(constraints, cardWidth);
          return Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(key: _rootKey, child: widget.child),
              if (target != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _SelectionOutlinePainter(bounds: target.bounds),
                    ),
                  ),
                ),
              if (target != null)
                Positioned(
                  left: target.bounds.left,
                  top: target.bounds.top >= 26
                      ? target.bounds.top - 26
                      : target.bounds.top,
                  child: IgnorePointer(
                    child: _SelectionLabel(label: target.widgetType),
                  ),
                ),
              if (_selecting)
                Positioned.fill(
                  child: Semantics(
                    button: true,
                    label: 'Select a component to annotate',
                    child: MouseRegion(
                      cursor: SystemMouseCursors.precise,
                      child: Listener(
                        key: const ValueKey('desy-overlay-selection-layer'),
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: _selectAt,
                      ),
                    ),
                  ),
                ),
              if (_selecting)
                Positioned(
                  right: 16,
                  bottom: 62,
                  child: DesyDesignSystemThemeScope(
                    theme: desyTheme,
                    child: const _SelectionPrompt(),
                  ),
                ),
              if (_cardOpen && target != null)
                Positioned(
                  left: cardOffset.dx,
                  top: cardOffset.dy,
                  width: cardWidth,
                  child: DesyDesignSystemThemeScope(
                    theme: desyTheme,
                    child: _AnnotationCard(
                      target: target,
                      comment: _comment,
                      error: _error,
                      submitting: _submitting,
                      commentFocusNode: _commentFocusNode,
                      onClose: _closeCard,
                      onDragDelta: (delta) =>
                          _moveCard(delta, constraints, cardWidth),
                      onCommentChanged: (value) =>
                          setState(() => _comment = value),
                      onSubmit: _submit,
                    ),
                  ),
                ),
              Positioned(
                right: 16,
                bottom: 16,
                child: DesyDesignSystemThemeScope(
                  theme: desyTheme,
                  child: _OverlayControls(
                    selecting: _selecting,
                    onToggleSelecting: _toggleSelecting,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OverlayControls extends StatelessWidget {
  const _OverlayControls({
    required this.selecting,
    required this.onToggleSelecting,
  });

  final bool selecting;
  final VoidCallback onToggleSelecting;

  @override
  Widget build(BuildContext context) => Row(
    key: const ValueKey('desy-overlay-controls'),
    mainAxisSize: MainAxisSize.min,
    children: [
      Semantics(
        button: true,
        label: selecting ? 'Cancel component selection' : 'Select a component',
        child: DesyButton(
          key: const ValueKey('desy-overlay-select'),
          size: DesyButtonSize.sm,
          variant: selecting
              ? DesyButtonVariant.primary
              : DesyButtonVariant.outline,
          mainAxisSize: MainAxisSize.min,
          onPress: onToggleSelecting,
          child: const Icon(DesyIcons.crosshair, size: 17),
        ),
      ),
    ],
  );
}

class _SelectionPrompt extends StatelessWidget {
  const _SelectionPrompt();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const ValueKey('desy-overlay-selection-prompt'),
    decoration: BoxDecoration(
      color: context.theme.colors.background,
      border: Border.all(color: _inspectionSignalColor),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(DesyIcons.crosshair, size: 14),
          const SizedBox(width: 6),
          Text('Select a component', style: context.theme.typography.body.xs),
        ],
      ),
    ),
  );
}

class _AnnotationCard extends StatelessWidget {
  const _AnnotationCard({
    required this.target,
    required this.comment,
    required this.error,
    required this.submitting,
    required this.commentFocusNode,
    required this.onClose,
    required this.onDragDelta,
    required this.onCommentChanged,
    required this.onSubmit,
  });

  final DesyWidgetTarget target;
  final String comment;
  final String? error;
  final bool submitting;
  final FocusNode commentFocusNode;
  final VoidCallback onClose;
  final ValueChanged<Offset> onDragDelta;
  final ValueChanged<String> onCommentChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final canSubmit = comment.trim().isNotEmpty && !submitting;
    final location = target.sourceLocation?.toString() ?? target.widgetPath;
    return DesyCard(
      key: const ValueKey('desy-overlay-annotation-card'),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.move,
                      child: GestureDetector(
                        key: const ValueKey('desy-overlay-drag-handle'),
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (details) => onDragDelta(details.delta),
                        child: Row(
                          children: [
                            const Icon(DesyIcons.messageSquare, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                target.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: typography.body.sm,
                              ),
                            ),
                            Text(
                              '${target.identitySignals.length} signals',
                              style: typography.body.xs.copyWith(
                                color: colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: DesyDesignSystemTokens.spaceSm),
                  Semantics(
                    button: true,
                    label: 'Close annotation',
                    child: DesyButton(
                      key: const ValueKey('desy-overlay-close'),
                      size: DesyButtonSize.sm,
                      variant: DesyButtonVariant.ghost,
                      mainAxisSize: MainAxisSize.min,
                      onPress: onClose,
                      child: const Icon(DesyIcons.x, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.body.xs.copyWith(
                color: colors.mutedForeground,
                fontFamily: 'monospace',
              ),
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
                  key: const ValueKey('desy-overlay-comment'),
                  label: 'Design feedback',
                  hintText: 'What should change?',
                  value: comment,
                  focusNode: commentFocusNode,
                  minLines: 3,
                  maxLines: 6,
                  enabled: !submitting,
                  onChanged: onCommentChanged,
                ),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: DesyDesignSystemTokens.spaceSm),
              Text(
                error!,
                style: typography.body.xs.copyWith(color: colors.destructive),
              ),
            ],
            const SizedBox(height: DesyDesignSystemTokens.spaceSm),
            Align(
              alignment: Alignment.centerRight,
              child: DesyButton(
                key: const ValueKey('desy-overlay-submit'),
                size: DesyButtonSize.sm,
                mainAxisSize: MainAxisSize.min,
                onPress: canSubmit ? onSubmit : null,
                child: Text(submitting ? 'Sending…' : 'Send feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionLabel extends StatelessWidget {
  const _SelectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Selected widget $label',
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: _inspectionSignalColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _inspectionSignalForeground,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    ),
  );
}

class _SelectionOutlinePainter extends CustomPainter {
  const _SelectionOutlinePainter({required this.bounds});

  final Rect bounds;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      bounds,
      Paint()..color = _inspectionSignalColor.withValues(alpha: .03),
    );
    canvas.drawRect(
      bounds.deflate(.5),
      Paint()
        ..color = _inspectionSignalColor.withValues(alpha: .45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final handles = Paint()
      ..color = _inspectionSignalColor.withValues(alpha: .55);
    for (final point in [
      bounds.topLeft,
      bounds.topRight,
      bounds.bottomLeft,
      bounds.bottomRight,
    ]) {
      canvas.drawCircle(point, 1.75, handles);
    }
  }

  @override
  bool shouldRepaint(covariant _SelectionOutlinePainter oldDelegate) =>
      oldDelegate.bounds != bounds;
}

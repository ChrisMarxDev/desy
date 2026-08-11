import 'dart:async';

import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'desy_annotation.dart';
import 'overlay/overlay_layout.dart';
import 'overlay/overlay_widgets.dart';
import 'overlay/widget_target_inspector.dart';

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
/// The easiest integration point is [builder], passed to the consumer app's
/// builder. The overlay does not require a Material application or inspect
/// Material-specific widget types.
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

  /// Creates an application-builder integration while preserving an existing
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
    return _DesyOverlayHost(
      onAnnotationSubmitted: onAnnotationSubmitted,
      initiallySelecting: initiallySelecting,
      child: child,
    );
  }
}

class _DesyOverlayHost extends StatelessWidget {
  const _DesyOverlayHost({
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
        builder: (context) => _DesyOverlaySurface(
          onAnnotationSubmitted: onAnnotationSubmitted,
          initiallySelecting: initiallySelecting,
          child: child,
        ),
      ),
    ],
  );
}

class _DesyOverlaySurface extends StatefulWidget {
  const _DesyOverlaySurface({
    required this.child,
    required this.onAnnotationSubmitted,
    required this.initiallySelecting,
  });

  final Widget child;
  final DesyAnnotationCallback onAnnotationSubmitted;
  final bool initiallySelecting;

  @override
  State<_DesyOverlaySurface> createState() => _DesyOverlaySurfaceState();
}

class _DesyOverlaySurfaceState extends State<_DesyOverlaySurface> {
  static const _targetInspector = DesyWidgetTargetInspector();

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
    final rootRenderObject = rootContext?.findRenderObject();
    if (rootContext is! Element ||
        rootRenderObject == null ||
        !rootRenderObject.attached) {
      return;
    }
    final target = _targetInspector.inspect(
      root: rootContext,
      rootRenderObject: rootRenderObject,
      globalPosition: event.position,
    );
    if (target == null) return;

    setState(() {
      _target = target;
      _cardOpen = true;
      _comment = '';
      _error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _commentFocusNode.requestFocus();
    });
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
        _selecting = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Could not send feedback: $error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _moveCard(Offset delta, DesyOverlayLayout layout) {
    setState(
      () => _cardOffset = layout.clampCardOffset(layout.cardOffset + delta),
    );
  }

  bool get _touchMode => switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.fuchsia ||
    TargetPlatform.iOS => true,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    final target = _target;
    final mediaQuery = MediaQuery.maybeOf(context);
    final desyTheme =
        (mediaQuery?.platformBrightness ?? Brightness.light) == Brightness.dark
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
          final layout = DesyOverlayLayout.resolve(
            viewport: constraints.biggest,
            padding: mediaQuery?.padding ?? EdgeInsets.zero,
            viewInsets: mediaQuery?.viewInsets ?? EdgeInsets.zero,
            requestedCardOffset: _cardOffset,
            touchMode: _touchMode,
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(key: _rootKey, child: widget.child),
              if (target != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      key: const ValueKey('desy-overlay-selection-outline'),
                      painter: DesySelectionOutlinePainter(
                        bounds: target.bounds,
                      ),
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
                    child: DesySelectionLabel(label: target.widgetType),
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
                  right: layout.chromeRight,
                  bottom: layout.promptBottom,
                  child: DesyOverlayChrome(
                    theme: desyTheme,
                    child: const DesySelectionPrompt(),
                  ),
                ),
              if (_cardOpen && target != null)
                Positioned(
                  left: layout.cardOffset.dx,
                  top: layout.cardOffset.dy,
                  width: layout.cardWidth,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: layout.cardMaxHeight,
                    ),
                    child: DesyOverlayChrome(
                      theme: desyTheme,
                      child: DesyAnnotationCard(
                        target: target,
                        comment: _comment,
                        error: _error,
                        submitting: _submitting,
                        touchMode: _touchMode,
                        compact: layout.cardMaxHeight < 240,
                        commentFocusNode: _commentFocusNode,
                        onClose: _closeCard,
                        onDragDelta: (delta) => _moveCard(delta, layout),
                        onCommentChanged: (value) =>
                            setState(() => _comment = value),
                        onSubmit: _submit,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: layout.chromeRight,
                bottom: layout.launcherBottom,
                child: DesyOverlayChrome(
                  theme: desyTheme,
                  child: DesyOverlayControls(
                    selecting: _selecting,
                    touchMode: _touchMode,
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

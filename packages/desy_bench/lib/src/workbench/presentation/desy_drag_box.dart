// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_box_transform/flutter_box_transform.dart';

@immutable
class DesyDragBoxGeometry {
  const DesyDragBoxGeometry({required this.rect, this.flip = Flip.none});

  final Rect rect;
  final Flip flip;
}

enum DesyDragBoxInteractionKind { move, resize }

@immutable
class DesyDragBoxInteraction {
  const DesyDragBoxInteraction({
    required this.kind,
    required this.initialRect,
    this.handle = HandlePosition.none,
  });

  final DesyDragBoxInteractionKind kind;
  final Rect initialRect;
  final HandlePosition handle;
}

typedef DesyDragBoxGeometryResolver =
    DesyDragBoxGeometry Function(
      DesyDragBoxGeometry geometry,
      DesyDragBoxInteraction interaction,
    );

const _editingPointerDevices = <PointerDeviceKind>{
  PointerDeviceKind.mouse,
  PointerDeviceKind.touch,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
};

/// The shared move-and-resize frame used by Desy's editing surfaces.
///
/// Callers own coordinate state and label content. This widget owns the
/// interaction, selection handles, clipped child content, child hit testing,
/// and label placement.
class DesyDragBox extends StatefulWidget {
  const DesyDragBox({
    super.key,
    required this.geometry,
    required this.clampingRect,
    required this.constraints,
    required this.onChanged,
    required this.child,
    this.onChangeEnd,
    this.frameKey,
    this.contentKey,
    this.resizeHandleKeyPrefix,
    this.selected = true,
    this.draggable = true,
    this.resizable = true,
    this.ignoreChildPointer = true,
    this.onSelect,
    this.onDoubleTap,
    this.onInteractionStart,
    this.geometryResolver,
    this.onInteractionEnd,
    this.label,
    this.labelGap = 6,
  });

  final DesyDragBoxGeometry geometry;
  final Rect clampingRect;
  final BoxConstraints constraints;

  /// Frame-coalesced live resize changes. Drag movement stays local.
  final ValueChanged<DesyDragBoxGeometry> onChanged;

  /// The final geometry after a drag or resize gesture.
  ///
  /// When omitted, [onChanged] receives the final geometry for compatibility.
  final ValueChanged<DesyDragBoxGeometry>? onChangeEnd;
  final Widget child;
  final Key? frameKey;
  final Key? contentKey;
  final String? resizeHandleKeyPrefix;
  final bool selected;
  final bool draggable;
  final bool resizable;
  final bool ignoreChildPointer;
  final VoidCallback? onSelect;
  final VoidCallback? onDoubleTap;
  final ValueChanged<DesyDragBoxInteraction>? onInteractionStart;
  final DesyDragBoxGeometryResolver? geometryResolver;
  final ValueChanged<DesyDragBoxInteraction>? onInteractionEnd;
  final Widget? label;
  final double labelGap;

  @override
  State<DesyDragBox> createState() => _DesyDragBoxState();
}

class _DesyDragBoxState extends State<DesyDragBox> {
  late final TransformableBoxController _transformController =
      TransformableBoxController(
        rect: widget.geometry.rect,
        flip: widget.geometry.flip,
        clampingRect: widget.clampingRect,
        constraints: widget.constraints,
        allowFlippingWhileResizing: false,
      );
  DesyDragBoxGeometry? _pendingGeometry;
  var _frameCallbackScheduled = false;
  int? _activePointer;
  Offset? _pointerDownPosition;
  Duration? _lastClickTime;
  Offset? _lastClickPosition;
  var _pointerMoved = false;
  DesyDragBoxInteraction? _activeInteraction;

  @override
  void didUpdateWidget(covariant DesyDragBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.geometry.rect != widget.geometry.rect &&
        _transformController.rect != widget.geometry.rect) {
      _transformController.setRect(widget.geometry.rect, notify: false);
    }
    if (oldWidget.geometry.flip != widget.geometry.flip &&
        _transformController.flip != widget.geometry.flip) {
      _transformController.setFlip(widget.geometry.flip, notify: false);
    }
    if (oldWidget.clampingRect != widget.clampingRect) {
      _transformController.setClampingRect(widget.clampingRect, notify: false);
    }
    if (oldWidget.constraints != widget.constraints) {
      _transformController.setConstraints(widget.constraints, notify: false);
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Set<HandlePosition> handles = widget.selected
        ? const {...HandlePosition.values}
        : const {};
    return AnimatedBuilder(
      animation: _transformController,
      child: widget.child,
      builder: (context, child) => Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          TransformableBox(
            controller: _transformController,
            allowContentFlipping: false,
            allowFlippingWhileResizing: false,
            // Keep resize hit regions outside the element. With inside-aligned
            // handles, small selected widgets can have no remaining move
            // surface because the eight resize detectors cover their content.
            handleAlignment: HandleAlignment.outside,
            handleTapSize: 12,
            draggable: widget.draggable,
            resizable: widget.selected && widget.resizable,
            // Trackpad two-finger pan events must reach the canvas scroll
            // view. Treating them as an item drag makes the frame jump while
            // the user is merely navigating the canvas.
            supportedDragDevices: _editingPointerDevices,
            supportedResizeDevices: _editingPointerDevices,
            visibleHandles: handles,
            enabledHandles: handles,
            onTap: widget.onSelect,
            onDragStart: (_) => _beginInteraction(
              const DesyDragBoxInteraction(
                kind: DesyDragBoxInteractionKind.move,
                initialRect: Rect.zero,
              ),
            ),
            onDragUpdate: (result, _) => _applyProposedGeometry(
              DesyDragBoxGeometry(rect: result.rect, flip: result.flip),
              publishLiveChange: false,
            ),
            onDragEnd: (_) => _finishInteraction(),
            onDragCancel: _finishInteraction,
            onResizeStart: (handle, _) => _beginInteraction(
              DesyDragBoxInteraction(
                kind: DesyDragBoxInteractionKind.resize,
                initialRect: _transformController.rect,
                handle: handle,
              ),
            ),
            onResizeUpdate: (result, _) => _queueGeometry(
              _applyProposedGeometry(
                DesyDragBoxGeometry(rect: result.rect, flip: result.flip),
                publishLiveChange: false,
              ),
            ),
            onResizeEnd: (_, _) => _finishInteraction(),
            onResizeCancel: (_) => _finishInteraction(),
            cornerHandleBuilder: (context, handle) => KeyedSubtree(
              key: _handleKey(handle),
              child: DefaultCornerHandle(
                handle: handle,
                size: 6,
                decoration: BoxDecoration(
                  color: context.theme.colors.background,
                  borderRadius: BorderRadius.circular(1),
                  border: Border.all(
                    color: context.theme.colors.desy.signal.withValues(
                      alpha: .62,
                    ),
                    width: 1,
                  ),
                ),
              ),
            ),
            sideHandleBuilder: (context, handle) => KeyedSubtree(
              key: _handleKey(handle),
              child: DefaultSideHandle(
                handle: handle,
                length: 6,
                thickness: 6,
                decoration: BoxDecoration(
                  color: context.theme.colors.desy.signal.withValues(
                    alpha: .62,
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            contentBuilder: (context, rect, flip) {
              final content = Listener(
                key: widget.contentKey,
                behavior: HitTestBehavior.opaque,
                onPointerDown: _handlePointerDown,
                onPointerMove: _handlePointerMove,
                onPointerUp: _handlePointerUp,
                onPointerCancel: _handlePointerCancel,
                child: IgnorePointer(
                  ignoring: widget.ignoreChildPointer,
                  child: child,
                ),
              );
              return MouseRegion(
                cursor: widget.draggable
                    ? SystemMouseCursors.move
                    : SystemMouseCursors.basic,
                child: ClipRect(key: widget.frameKey, child: content),
              );
            },
          ),
          if (widget.label case final label?)
            Positioned(
              left: _transformController.rect.left,
              top: _transformController.rect.bottom + widget.labelGap,
              child: label,
            ),
        ],
      ),
    );
  }

  void _queueGeometry(DesyDragBoxGeometry geometry) {
    _pendingGeometry = geometry;
    if (_frameCallbackScheduled) return;
    _frameCallbackScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _frameCallbackScheduled = false;
      if (!mounted) return;
      final pending = _pendingGeometry;
      _pendingGeometry = null;
      if (pending != null) widget.onChanged(pending);
    });
  }

  void _beginInteraction(DesyDragBoxInteraction interaction) {
    final actual = DesyDragBoxInteraction(
      kind: interaction.kind,
      initialRect: _transformController.rect,
      handle: interaction.handle,
    );
    _activeInteraction = actual;
    widget.onInteractionStart?.call(actual);
  }

  DesyDragBoxGeometry _applyProposedGeometry(
    DesyDragBoxGeometry geometry, {
    required bool publishLiveChange,
  }) {
    final interaction = _activeInteraction;
    final resolved = interaction == null
        ? geometry
        : widget.geometryResolver?.call(geometry, interaction) ?? geometry;
    if (_transformController.flip != resolved.flip) {
      _transformController.setFlip(resolved.flip, notify: false);
    }
    if (_transformController.rect != resolved.rect || resolved != geometry) {
      _transformController.setRect(resolved.rect, recalculate: false);
    }
    if (publishLiveChange) _queueGeometry(resolved);
    return resolved;
  }

  void _handlePointerDown(PointerDownEvent event) {
    widget.onSelect?.call();
    if (widget.onDoubleTap == null) return;
    _activePointer = event.pointer;
    _pointerDownPosition = event.position;
    _pointerMoved = false;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer || _pointerMoved) return;
    final origin = _pointerDownPosition;
    if (origin != null && (event.position - origin).distance > kTouchSlop) {
      _pointerMoved = true;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointer) return;
    _activePointer = null;
    _pointerDownPosition = null;
    if (_pointerMoved) {
      _pointerMoved = false;
      _lastClickTime = null;
      _lastClickPosition = null;
      return;
    }
    final lastTime = _lastClickTime;
    final lastPosition = _lastClickPosition;
    final isDoubleClick =
        lastTime != null &&
        event.timeStamp - lastTime <= kDoubleTapTimeout &&
        lastPosition != null &&
        (event.position - lastPosition).distance <= kDoubleTapSlop;
    if (isDoubleClick) {
      _lastClickTime = null;
      _lastClickPosition = null;
      widget.onDoubleTap?.call();
    } else {
      _lastClickTime = event.timeStamp;
      _lastClickPosition = event.position;
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointer) return;
    _activePointer = null;
    _pointerDownPosition = null;
    _pointerMoved = false;
    _lastClickTime = null;
    _lastClickPosition = null;
  }

  void _finishInteraction() {
    _pendingGeometry = null;
    final interaction = _activeInteraction;
    _activeInteraction = null;
    final geometry = DesyDragBoxGeometry(
      rect: _transformController.rect,
      flip: _transformController.flip,
    );
    final onChangeEnd = widget.onChangeEnd;
    if (onChangeEnd == null) {
      widget.onChanged(geometry);
    } else {
      onChangeEnd(geometry);
    }
    if (interaction != null) widget.onInteractionEnd?.call(interaction);
  }

  Key? _handleKey(HandlePosition handle) =>
      widget.resizeHandleKeyPrefix == null || handle == HandlePosition.none
      ? null
      : ValueKey('${widget.resizeHandleKeyPrefix}-${handle.name}');
}

class DesyDragBoxLabel extends StatelessWidget {
  const DesyDragBoxLabel({
    super.key,
    required this.size,
    required this.identifier,
  });

  final Size size;
  final String identifier;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final textStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: colors.desy.onSignal);
    return IgnorePointer(
      child: Semantics(
        label:
            '$identifier, selection size ${size.width.round()} by ${size.height.round()} pixels',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.desy.signal,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  identifier,
                  style: textStyle?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                Text('·', style: textStyle),
                const SizedBox(width: 6),
                Text(
                  '${size.width.round()} × ${size.height.round()} px',
                  style: textStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_box_transform/flutter_box_transform.dart';

@immutable
class DesyDragBoxGeometry {
  const DesyDragBoxGeometry({required this.rect, this.flip = Flip.none});

  final Rect rect;
  final Flip flip;
}

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
            key: widget.frameKey,
            controller: _transformController,
            allowContentFlipping: false,
            allowFlippingWhileResizing: false,
            handleAlignment: HandleAlignment.inside,
            handleTapSize: 18,
            draggable: widget.draggable,
            resizable: widget.selected && widget.resizable,
            visibleHandles: handles,
            enabledHandles: handles,
            onTap: widget.onSelect,
            onDragEnd: (_) => _finishInteraction(),
            onDragCancel: _finishInteraction,
            onResizeUpdate: (result, _) => _queueGeometry(
              DesyDragBoxGeometry(rect: result.rect, flip: result.flip),
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
                    color: context.theme.colors.primary,
                    width: 1.25,
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
                  color: context.theme.colors.primary,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            contentBuilder: (context, rect, flip) => MouseRegion(
              cursor: widget.draggable
                  ? SystemMouseCursors.move
                  : SystemMouseCursors.basic,
              child: ClipRect(
                child: Listener(
                  key: widget.contentKey,
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (_) => widget.onSelect?.call(),
                  child: IgnorePointer(
                    ignoring: widget.ignoreChildPointer,
                    child: child,
                  ),
                ),
              ),
            ),
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

  void _finishInteraction() {
    _pendingGeometry = null;
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
    ).textTheme.labelSmall?.copyWith(color: colors.primaryForeground);
    return IgnorePointer(
      child: Semantics(
        label:
            '$identifier, selection size ${size.width.round()} by ${size.height.round()} pixels',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primary,
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

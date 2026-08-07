// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
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
/// interaction, selection handles, child hit testing, and label placement.
class DesyDragBox extends StatelessWidget {
  const DesyDragBox({
    super.key,
    required this.geometry,
    required this.clampingRect,
    required this.constraints,
    required this.onChanged,
    required this.child,
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
  final ValueChanged<DesyDragBoxGeometry> onChanged;
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
  Widget build(BuildContext context) {
    final Set<HandlePosition> handles = selected
        ? const {...HandlePosition.values}
        : const {};
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        TransformableBox(
          key: frameKey,
          rect: geometry.rect,
          flip: geometry.flip,
          clampingRect: clampingRect,
          constraints: constraints,
          allowContentFlipping: false,
          allowFlippingWhileResizing: false,
          handleAlignment: HandleAlignment.inside,
          handleTapSize: 18,
          draggable: draggable,
          resizable: selected && resizable,
          visibleHandles: handles,
          enabledHandles: handles,
          onTap: onSelect,
          onChanged: (result, _) => onChanged(
            DesyDragBoxGeometry(rect: result.rect, flip: result.flip),
          ),
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
            cursor: draggable
                ? SystemMouseCursors.move
                : SystemMouseCursors.basic,
            child: Listener(
              key: contentKey,
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => onSelect?.call(),
              child: IgnorePointer(ignoring: ignoreChildPointer, child: child),
            ),
          ),
        ),
        if (label case final label?)
          Positioned(
            left: geometry.rect.left,
            top: geometry.rect.bottom + labelGap,
            child: label,
          ),
      ],
    );
  }

  Key? _handleKey(HandlePosition handle) =>
      resizeHandleKeyPrefix == null || handle == HandlePosition.none
      ? null
      : ValueKey('$resizeHandleKeyPrefix-${handle.name}');
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

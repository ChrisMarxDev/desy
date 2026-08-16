// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';

import '../../registry.dart';
import '../workbench_annotation.dart';
import '../widget_preview.dart';
import 'desy_drag_box.dart';

const _minimumBoxExtent = 8.0;
const _canvasExtent = 100000.0;
const _labelGap = 6.0;
const _labelHeight = 28.0;
const _trailingSpace = 56.0;

/// One immutable, registry-derived item shown in a [DesyCollectionCanvas].
///
/// [value] stays typed for the host screen. The canvas only needs a stable ID,
/// an initial logical size, and a real-widget preview builder.
class DesyCanvasSceneItem<T> {
  const DesyCanvasSceneItem({
    required this.id,
    required this.name,
    required this.value,
    required this.previewBuilder,
    this.initialSize = const Size(320, 240),
    this.initialRect,
  });

  final String id;
  final String name;
  final T value;
  final DesyCanvasPreviewBuilder<T> previewBuilder;
  final Size initialSize;
  final Rect? initialRect;
}

typedef DesyCanvasPreviewBuilder<T> =
    Widget Function(BuildContext context, T value);

/// Builds the host-specific controls for one selected scene item.
///
/// Components can return a knob panel while a prototype session can return its
/// direction notes. The canvas does not need to know either domain.
typedef DesyCanvasDetailsBuilder<T> =
    Widget Function(BuildContext context, DesyCanvasSceneItem<T> item);

/// A local, interactive workspace for a typed collection of real widgets.
///
/// The host owns registry resolution, real preview construction, and details.
/// This widget owns only ephemeral arrangement, selection, and camera state.
class DesyCollectionCanvas<T> extends StatefulWidget {
  const DesyCollectionCanvas({
    super.key,
    required this.theme,
    required this.items,
    required this.title,
    required this.detailsBuilder,
    this.description,
    this.badgeLabel,
    this.itemNoun = 'items',
    this.keyPrefix = 'collection-canvas',
  });

  final DesyTheme theme;
  final List<DesyCanvasSceneItem<T>> items;
  final String title;
  final DesyCanvasDetailsBuilder<T> detailsBuilder;
  final String? description;
  final String? badgeLabel;
  final String itemNoun;
  final String keyPrefix;

  @override
  State<DesyCollectionCanvas<T>> createState() =>
      _DesyCollectionCanvasState<T>();
}

class _DesyCollectionCanvasState<T> extends State<DesyCollectionCanvas<T>> {
  final _geometries = <String, DesyDragBoxGeometry>{};
  final _paintOrder = <String>[];
  final _zoomController = TransformationController();
  String? _selectedId;
  var _zoom = 1.0;

  @override
  void initState() {
    super.initState();
    _zoomController.addListener(_handleZoomChanged);
  }

  @override
  void dispose() {
    _zoomController
      ..removeListener(_handleZoomChanged)
      ..dispose();
    super.dispose();
  }

  void _handleZoomChanged() {
    final zoom = _zoomController.value.getMaxScaleOnAxis();
    if (!mounted || (zoom - _zoom).abs() < .001) return;
    setState(() => _zoom = zoom);
  }

  @override
  Widget build(BuildContext context) {
    _synchronizeItems();
    final selected = _selectedItem;
    return LayoutBuilder(
      builder: (context, constraints) {
        final background =
            widget.theme.previewBackgroundColor ??
            context.theme.colors.background;
        final stage = SizedBox(
          width: _canvasSize(constraints).width,
          height: _canvasSize(constraints).height,
          child: CustomPaint(
            painter: _CollectionCanvasGridPainter(background: background),
            child: Stack(
              key: ValueKey('${widget.keyPrefix}-stage'),
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _clearSelection,
                  ),
                ),
                for (final id in _paintOrder)
                  if (_itemForId(id) case final item?)
                    _CollectionCanvasItem<T>(
                      key: ValueKey('${widget.keyPrefix}-item-$id'),
                      keyPrefix: widget.keyPrefix,
                      theme: widget.theme,
                      item: item,
                      geometry: _geometries[id]!,
                      selected: _selectedId == id,
                      onSelect: () => _select(item),
                      onChanged: (geometry) => _updateGeometry(id, geometry),
                    ),
              ],
            ),
          ),
        );
        final drawerWidth = math
            .min(360.0, constraints.maxWidth * .36)
            .clamp(280.0, 360.0)
            .toDouble();
        final inspection = DesyWorkbenchInspectionHost.maybeOf(context);
        return ColoredBox(
          color: background,
          child: Stack(
            children: [
              InteractiveViewer(
                key: ValueKey('${widget.keyPrefix}-viewport'),
                transformationController: _zoomController,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(_canvasExtent),
                minScale: .25,
                maxScale: 2.5,
                trackpadScrollCausesScale: false,
                child: stage,
              ),
              Positioned(
                top: 16,
                left: 20,
                child: _CollectionCanvasHeader(
                  title: widget.title,
                  badgeLabel: widget.badgeLabel,
                  description: widget.description,
                  itemCount: widget.items.length,
                  itemNoun: widget.itemNoun,
                  onResetView: _resetView,
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: _CollectionCanvasZoomDock(
                  zoom: _zoom,
                  onZoomOut: () => _setZoom(_zoom - .15),
                  onZoomIn: () => _setZoom(_zoom + .15),
                ),
              ),
              if (inspection?.onToggleInspection case final onToggle?)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _CollectionCanvasActionBar(
                      keyPrefix: widget.keyPrefix,
                      annotating: inspection!.inspectionActive,
                      onSelect: inspection.inspectionActive
                          ? onToggle
                          : _clearSelection,
                      onAnnotate: onToggle,
                    ),
                  ),
                ),
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: drawerWidth,
                child: IgnorePointer(
                  ignoring: selected == null,
                  child: AnimatedSlide(
                    key: ValueKey('${widget.keyPrefix}-inspector-drawer'),
                    offset: selected == null
                        ? const Offset(1.1, 0)
                        : Offset.zero,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: selected == null ? 0 : 1,
                      duration: const Duration(milliseconds: 120),
                      child: _CollectionCanvasInspectorDrawer(
                        closeKey: ValueKey(
                          '${widget.keyPrefix}-close-inspector',
                        ),
                        onClose: _clearSelection,
                        child: selected == null
                            ? const SizedBox.shrink()
                            : widget.detailsBuilder(context, selected),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  DesyCanvasSceneItem<T>? get _selectedItem => _itemForId(_selectedId);

  void _synchronizeItems() {
    final ids = widget.items.map((item) => item.id).toSet();
    _geometries.removeWhere((id, _) => !ids.contains(id));
    _paintOrder.removeWhere((id) => !ids.contains(id));
    for (final (index, item) in widget.items.indexed) {
      _geometries.putIfAbsent(item.id, () => _initialGeometry(item, index));
      if (!_paintOrder.contains(item.id)) _paintOrder.add(item.id);
    }
    if (_selectedId != null && !ids.contains(_selectedId)) _selectedId = null;
  }

  DesyCanvasSceneItem<T>? _itemForId(String? id) {
    if (id == null) return null;
    for (final item in widget.items) {
      if (item.id == id) return item;
    }
    return null;
  }

  DesyDragBoxGeometry _initialGeometry(DesyCanvasSceneItem<T> item, int index) {
    const fallback = Size(320, 240);
    const columns = 3;
    const gap = 64.0;
    const inset = 72.0;
    final placement = item.initialRect;
    if (placement != null) {
      return DesyDragBoxGeometry(
        rect: Rect.fromLTWH(
          placement.left,
          placement.top,
          math.max(placement.width, _minimumBoxExtent),
          math.max(placement.height, _minimumBoxExtent),
        ),
      );
    }
    final size = item.initialSize;
    return DesyDragBoxGeometry(
      rect: Rect.fromLTWH(
        inset + (index % columns) * (fallback.width + gap),
        inset + (index ~/ columns) * (fallback.height + gap),
        math.max(size.width, _minimumBoxExtent),
        math.max(size.height, _minimumBoxExtent),
      ),
    );
  }

  void _select(DesyCanvasSceneItem<T> item) {
    if (_selectedId == item.id) return;
    setState(() {
      _selectedId = item.id;
      _paintOrder
        ..remove(item.id)
        ..add(item.id);
    });
  }

  void _clearSelection() {
    if (_selectedId == null) return;
    setState(() => _selectedId = null);
  }

  void _updateGeometry(String id, DesyDragBoxGeometry geometry) {
    setState(() => _geometries[id] = geometry);
  }

  void _setZoom(double value) {
    final zoom = value.clamp(.25, 2.5).toDouble();
    final matrix = _zoomController.value;
    _zoomController.value = Matrix4.identity()
      ..setTranslationRaw(matrix.storage[12], matrix.storage[13], 0)
      ..scaleByDouble(zoom, zoom, 1, 1);
  }

  void _resetView() => _zoomController.value = Matrix4.identity();

  Size _canvasSize(BoxConstraints constraints) {
    var width = constraints.maxWidth;
    var height = constraints.maxHeight;
    for (final geometry in _geometries.values) {
      width = math.max(width, geometry.rect.right + _trailingSpace);
      height = math.max(
        height,
        geometry.rect.bottom + _labelGap + _labelHeight + _trailingSpace,
      );
    }
    return Size(width, height);
  }
}

class _CollectionCanvasActionBar extends StatelessWidget {
  const _CollectionCanvasActionBar({
    required this.keyPrefix,
    required this.annotating,
    required this.onSelect,
    required this.onAnnotate,
  });

  final String keyPrefix;
  final bool annotating;
  final VoidCallback onSelect;
  final VoidCallback onAnnotate;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Canvas modes',
    container: true,
    child: DecoratedBox(
      key: ValueKey('$keyPrefix-action-bar'),
      decoration: BoxDecoration(
        color: context.theme.colors.background,
        border: Border.all(color: context.theme.colors.border),
        borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusMd),
        boxShadow: [
          BoxShadow(
            color: context.theme.colors.foreground.withValues(alpha: .12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DesyButton(
              key: ValueKey('$keyPrefix-mode-select'),
              size: DesyButtonSize.sm,
              variant: annotating
                  ? DesyButtonVariant.ghost
                  : DesyButtonVariant.primary,
              mainAxisSize: MainAxisSize.min,
              semanticsLabel: 'Select canvas items',
              semanticsTooltip: 'Select canvas items',
              onPress: onSelect,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(DesyIcons.crosshair, size: 15),
                  SizedBox(width: 6),
                  Text('Select'),
                ],
              ),
            ),
            const SizedBox(width: 2),
            DesyButton(
              key: ValueKey('$keyPrefix-mode-annotate'),
              size: DesyButtonSize.sm,
              variant: annotating
                  ? DesyButtonVariant.primary
                  : DesyButtonVariant.ghost,
              mainAxisSize: MainAxisSize.min,
              semanticsLabel: annotating
                  ? 'Stop annotating canvas widgets'
                  : 'Annotate canvas widgets',
              semanticsTooltip: annotating
                  ? 'Stop annotating canvas widgets'
                  : 'Annotate canvas widgets',
              onPress: onAnnotate,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(DesyIcons.messageSquare, size: 15),
                  SizedBox(width: 6),
                  Text('Annotate'),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CollectionCanvasItem<T> extends StatelessWidget {
  const _CollectionCanvasItem({
    super.key,
    required this.keyPrefix,
    required this.theme,
    required this.item,
    required this.geometry,
    required this.selected,
    required this.onSelect,
    required this.onChanged,
  });

  final String keyPrefix;
  final DesyTheme theme;
  final DesyCanvasSceneItem<T> item;
  final DesyDragBoxGeometry geometry;
  final bool selected;
  final VoidCallback onSelect;
  final ValueChanged<DesyDragBoxGeometry> onChanged;

  @override
  Widget build(BuildContext context) => DesyDragBox(
    geometry: geometry,
    clampingRect: const Rect.fromLTRB(
      -_canvasExtent,
      -_canvasExtent,
      _canvasExtent,
      _canvasExtent,
    ),
    constraints: const BoxConstraints(
      minWidth: _minimumBoxExtent,
      minHeight: _minimumBoxExtent,
    ),
    frameKey: ValueKey('$keyPrefix-frame-${item.id}'),
    contentKey: ValueKey('$keyPrefix-content-${item.id}'),
    resizeHandleKeyPrefix: '$keyPrefix-resize-${item.id}',
    selected: selected,
    ignoreChildPointer: true,
    onSelect: onSelect,
    onChanged: onChanged,
    outsideFrameDecoration: BoxDecoration(
      border: Border.all(
        color: context.theme.colors.desy.signal.withValues(
          alpha: selected ? .9 : .28,
        ),
        width: selected ? 1.5 : 1,
      ),
    ),
    outsideFrameInset: selected ? 2 : 1,
    label: DesyDragBoxLabel(
      key: ValueKey('$keyPrefix-selection-size-${item.id}'),
      size: geometry.rect.size,
      identifier: item.name,
      selected: selected,
    ),
    child: Semantics(
      container: true,
      selected: selected,
      label: 'Select ${item.name}',
      child: Center(
        child: DesyWidgetPreview(
          theme: theme,
          builder: (context) => item.previewBuilder(context, item.value),
        ),
      ),
    ),
  );
}

class _CollectionCanvasInspectorDrawer extends StatelessWidget {
  const _CollectionCanvasInspectorDrawer({
    required this.closeKey,
    required this.onClose,
    required this.child,
  });

  final Key closeKey;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.theme.colors.background,
      border: Border(left: BorderSide(color: context.theme.colors.border)),
    ),
    child: Column(
      children: [
        SizedBox(
          height: 48,
          child: Align(
            alignment: Alignment.centerRight,
            child: DesyButton.icon(
              key: closeKey,
              variant: DesyButtonVariant.ghost,
              size: DesyButtonSize.md,
              onPress: onClose,
              semanticsLabel: 'Collapse details sidebar',
              semanticsTooltip: 'Collapse details sidebar',
              child: const Icon(DesyIcons.panelRightClose, size: 18),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    ),
  );
}

class _CollectionCanvasHeader extends StatelessWidget {
  const _CollectionCanvasHeader({
    required this.title,
    required this.badgeLabel,
    required this.description,
    required this.itemCount,
    required this.itemNoun,
    required this.onResetView,
  });

  final String title;
  final String? badgeLabel;
  final String? description;
  final int itemCount;
  final String itemNoun;
  final VoidCallback onResetView;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.theme.colors.background.withValues(alpha: .92),
      border: Border.all(color: context.theme.colors.border),
      borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusMd),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (badgeLabel case final badge?) ...[
            const SizedBox(width: 7),
            DesyBadge(variant: DesyBadgeVariant.secondary, child: Text(badge)),
          ],
          const SizedBox(width: 8),
          Text(
            '$itemCount $itemNoun',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
          if (description != null) ...[
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Text(
                description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
            ),
          ],
          const SizedBox(width: 4),
          DesyButton(
            key: const ValueKey('collection-canvas-reset-view'),
            size: DesyButtonSize.xs,
            variant: DesyButtonVariant.ghost,
            onPress: onResetView,
            child: const Text('Reset view'),
          ),
        ],
      ),
    ),
  );
}

class _CollectionCanvasZoomDock extends StatelessWidget {
  const _CollectionCanvasZoomDock({
    required this.zoom,
    required this.onZoomOut,
    required this.onZoomIn,
  });

  final double zoom;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.theme.colors.background.withValues(alpha: .92),
      border: Border.all(color: context.theme.colors.border),
      borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusMd),
    ),
    child: Padding(
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesyButton.icon(
            key: const ValueKey('collection-canvas-zoom-out'),
            variant: DesyButtonVariant.ghost,
            size: DesyButtonSize.xs,
            onPress: onZoomOut,
            semanticsLabel: 'Zoom out',
            child: const Icon(DesyIcons.minus, size: 14),
          ),
          SizedBox(
            width: 42,
            child: Text(
              '${(zoom * 100).round()}%',
              textAlign: TextAlign.center,
              style: context.theme.typography.body.xs.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          DesyButton.icon(
            key: const ValueKey('collection-canvas-zoom-in'),
            variant: DesyButtonVariant.ghost,
            size: DesyButtonSize.xs,
            onPress: onZoomIn,
            semanticsLabel: 'Zoom in',
            child: const Icon(DesyIcons.plus, size: 14),
          ),
        ],
      ),
    ),
  );
}

class _CollectionCanvasGridPainter extends CustomPainter {
  const _CollectionCanvasGridPainter({required this.background});

  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final paint = Paint()
      ..color =
          (background.computeLuminance() > .5 ? Colors.black : Colors.white)
              .withValues(alpha: .10);
    for (var y = 10.0; y < size.height; y += 20) {
      for (var x = 10.0; x < size.width; x += 20) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CollectionCanvasGridPainter oldDelegate) =>
      oldDelegate.background != background;
}

// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../registry.dart';
import '../workbench_annotation.dart';
import '../widget_preview.dart';
import 'desy_drag_box.dart';
import 'workbench_control_sheet.dart';

const _minimumBoxExtent = 8.0;
const _canvasExtent = 100000.0;
const _canvasEdgePadding = 1024.0;
const _minimumCanvasZoom = .5;
const _maximumCanvasZoom = 2.5;
const _labelGap = 6.0;
const _labelHeight = 28.0;
const _trailingSpace = 56.0;

class _CanvasSelectModeIntent extends Intent {
  const _CanvasSelectModeIntent();
}

class _CanvasAnnotateModeIntent extends Intent {
  const _CanvasAnnotateModeIntent();
}

/// One immutable, registry-derived item shown in a [DesyCollectionCanvas].
///
/// [value] stays typed for the host screen. The canvas only needs a stable ID,
/// an initial logical size, and a real-widget preview builder.
class DesyCanvasSceneItem<T> {
  const DesyCanvasSceneItem({
    required this.id,
    required this.name,
    required this.value,
    this.previewBuilder,
    this.previewSurfaceBuilder,
    this.initialSize = const Size(320, 240),
    this.initialRect,
    this.geometryResolver,
    this.draggable = true,
    this.ignoreChildPointer = false,
    this.itemKey,
    this.frameKey,
    this.contentKey,
    this.labelKey,
    this.resizeHandleKeyPrefix,
    this.onGeometryChanged,
    this.onSelected,
  }) : assert(previewBuilder != null || previewSurfaceBuilder != null);

  final String id;
  final String name;
  final T value;
  final DesyCanvasPreviewBuilder<T>? previewBuilder;
  final DesyCanvasPreviewSurfaceBuilder<T>? previewSurfaceBuilder;
  final Size initialSize;
  final Rect? initialRect;
  final DesyDragBoxGeometryResolver? geometryResolver;
  final bool draggable;
  final bool ignoreChildPointer;
  final Key? itemKey;
  final Key? frameKey;
  final Key? contentKey;
  final Key? labelKey;
  final String? resizeHandleKeyPrefix;
  final ValueChanged<DesyDragBoxGeometry>? onGeometryChanged;
  final VoidCallback? onSelected;
}

typedef DesyCanvasPreviewBuilder<T> =
    Widget Function(BuildContext context, T value);

typedef DesyCanvasPreviewSurfaceBuilder<T> =
    Widget Function(
      BuildContext context,
      T value,
      DesyDragBoxGeometry geometry,
      VoidCallback onSelect,
      ValueChanged<DesyDragBoxGeometry> onChanged,
    );

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
    this.toolbar,
    this.showInspectorDrawer = true,
    this.initialSelectedItemId,
    this.clearSelectionOnCanvasTap = true,
    this.geometryRevision = 0,
    this.onItemSelected,
    this.zoomDockKeyPrefix = 'collection-canvas',
    this.initialZoom = 1,
    this.zoomRevision = 0,
  });

  final DesyTheme theme;
  final List<DesyCanvasSceneItem<T>> items;
  final String title;
  final DesyCanvasDetailsBuilder<T> detailsBuilder;
  final String? description;
  final String? badgeLabel;
  final String itemNoun;
  final String keyPrefix;
  final Widget? toolbar;
  final bool showInspectorDrawer;
  final String? initialSelectedItemId;
  final bool clearSelectionOnCanvasTap;
  final int geometryRevision;
  final ValueChanged<DesyCanvasSceneItem<T>>? onItemSelected;
  final String zoomDockKeyPrefix;
  final double initialZoom;
  final int zoomRevision;

  @override
  State<DesyCollectionCanvas<T>> createState() =>
      _DesyCollectionCanvasState<T>();
}

class _DesyCollectionCanvasState<T> extends State<DesyCollectionCanvas<T>> {
  final _geometries = <String, DesyDragBoxGeometry>{};
  final _paintOrder = <String>[];
  final _zoomController = TransformationController();
  int? _blankCanvasPointer;
  String? _selectedId;
  var _zoom = 1.0;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialSelectedItemId;
    _setZoomValue(widget.initialZoom);
    _zoomController.addListener(_handleZoomChanged);
  }

  @override
  void didUpdateWidget(covariant DesyCollectionCanvas<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.geometryRevision != widget.geometryRevision) {
      _geometries.clear();
    }
    if (oldWidget.zoomRevision != widget.zoomRevision) {
      _setZoomValue(widget.initialZoom);
    }
    if (oldWidget.initialSelectedItemId != widget.initialSelectedItemId &&
        widget.initialSelectedItemId != null) {
      _selectedId = widget.initialSelectedItemId;
    }
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
        final canvasBorderColor = context.theme.colors.border.withValues(
          alpha: .72,
        );
        final workspaceBackground = Color.alphaBlend(
          context.theme.colors.mutedForeground.withValues(alpha: .08),
          context.theme.colors.background,
        );
        final stage = SizedBox(
          width: _canvasSize(constraints).width,
          height: _canvasSize(constraints).height,
          child: ColoredBox(
            color: background,
            child: CustomPaint(
              painter: _CollectionCanvasGridPainter(background: background),
              foregroundPainter: _CollectionCanvasBorderPainter(
                color: canvasBorderColor,
              ),
              child: Stack(
                key: ValueKey('${widget.keyPrefix}-stage'),
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: _beginBlankCanvasPan,
                      onPointerMove: _updateBlankCanvasPan,
                      onPointerUp: _endBlankCanvasPan,
                      onPointerCancel: _endBlankCanvasPan,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.clearSelectionOnCanvasTap
                            ? _clearSelection
                            : null,
                      ),
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
          ),
        );
        final drawerWidth = math
            .min(360.0, constraints.maxWidth * .36)
            .clamp(280.0, 360.0)
            .toDouble();
        final inspection = DesyWorkbenchInspectionHost.maybeOf(context);
        final canvas = DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: canvasBorderColor),
          ),
          child: ColoredBox(
            key: ValueKey('${widget.keyPrefix}-workspace'),
            color: workspaceBackground,
            child: Stack(
              children: [
                Listener(
                  key: ValueKey('${widget.keyPrefix}-viewport'),
                  onPointerSignal: _handlePointerSignal,
                  onPointerPanZoomStart: _handleTrackpadStart,
                  onPointerPanZoomUpdate: _handleTrackpadUpdate,
                  onPointerPanZoomEnd: _handleTrackpadEnd,
                  child: AnimatedBuilder(
                    animation: _zoomController,
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      minWidth: 0,
                      maxWidth: double.infinity,
                      minHeight: 0,
                      maxHeight: double.infinity,
                      child: stage,
                    ),
                    builder: (context, child) => Transform(
                      alignment: Alignment.topLeft,
                      transform: _zoomController.value,
                      child: child,
                    ),
                  ),
                ),
                Positioned(
                  top: widget.toolbar == null ? 16 : 12,
                  left: widget.toolbar == null ? 20 : 12,
                  child:
                      widget.toolbar ??
                      _CollectionCanvasHeader(
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
                    keyPrefix: widget.zoomDockKeyPrefix,
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
                        onSelect: () => _enterSelectMode(inspection),
                        onAnnotate: onToggle,
                      ),
                    ),
                  ),
                if (widget.showInspectorDrawer)
                  Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    width: drawerWidth,
                    child: DesyWorkbenchControlSheet(
                      key: ValueKey('${widget.keyPrefix}-inspector-drawer'),
                      visible: selected != null,
                      closeKey: ValueKey('${widget.keyPrefix}-close-inspector'),
                      onClose: _clearSelection,
                      child: selected == null
                          ? const SizedBox.shrink()
                          : widget.detailsBuilder(context, selected),
                    ),
                  ),
              ],
            ),
          ),
        );
        if (inspection?.onToggleInspection == null) return canvas;
        return Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.digit1, meta: true):
                _CanvasSelectModeIntent(),
            SingleActivator(LogicalKeyboardKey.digit1, control: true):
                _CanvasSelectModeIntent(),
            SingleActivator(LogicalKeyboardKey.digit2, meta: true):
                _CanvasAnnotateModeIntent(),
            SingleActivator(LogicalKeyboardKey.digit2, control: true):
                _CanvasAnnotateModeIntent(),
          },
          child: Actions(
            actions: {
              _CanvasSelectModeIntent: CallbackAction<_CanvasSelectModeIntent>(
                onInvoke: (_) {
                  _enterSelectMode(inspection!);
                  return null;
                },
              ),
              _CanvasAnnotateModeIntent:
                  CallbackAction<_CanvasAnnotateModeIntent>(
                    onInvoke: (_) {
                      _enterAnnotateMode(inspection!);
                      return null;
                    },
                  ),
            },
            child: canvas,
          ),
        );
      },
    );
  }

  void _enterSelectMode(DesyWorkbenchInspectionHost inspection) {
    if (inspection.inspectionActive) inspection.onToggleInspection!();
    _clearSelection();
  }

  void _enterAnnotateMode(DesyWorkbenchInspectionHost inspection) {
    if (!inspection.inspectionActive) inspection.onToggleInspection!();
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
    item.onSelected?.call();
    widget.onItemSelected?.call(item);
  }

  void _clearSelection() {
    if (_selectedId == null) return;
    setState(() => _selectedId = null);
  }

  void _updateGeometry(String id, DesyDragBoxGeometry geometry) {
    setState(() => _geometries[id] = geometry);
    _itemForId(id)?.onGeometryChanged?.call(geometry);
  }

  void _setZoom(double value) {
    final zoom = value.clamp(_minimumCanvasZoom, _maximumCanvasZoom).toDouble();
    final matrix = _zoomController.value;
    if ((zoom - _zoom).abs() >= .001) setState(() => _zoom = zoom);
    _zoomController.value = Matrix4.identity()
      ..setTranslationRaw(matrix.storage[12], matrix.storage[13], 0)
      ..scaleByDouble(zoom, zoom, 1, 1);
  }

  void _setZoomValue(double value) {
    _zoom = value.clamp(_minimumCanvasZoom, _maximumCanvasZoom).toDouble();
    _zoomController.value = Matrix4.identity()
      ..scaleByDouble(_zoom, _zoom, 1, 1);
  }

  _TrackpadGesture? _trackpadGesture;

  void _beginBlankCanvasPan(PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.trackpad) {
      _blankCanvasPointer = event.pointer;
    }
  }

  void _updateBlankCanvasPan(PointerMoveEvent event) {
    if (event.pointer == _blankCanvasPointer) _panCanvasBy(event.delta);
  }

  void _endBlankCanvasPan(PointerEvent event) {
    if (event.pointer == _blankCanvasPointer) _blankCanvasPointer = null;
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (event) {
      if (event is PointerScrollEvent) _panCanvasBy(-event.scrollDelta);
    });
  }

  void _handleTrackpadStart(PointerPanZoomStartEvent event) {
    _trackpadGesture = _TrackpadGesture(
      pointer: event.pointer,
      scale: _zoomController.value.getMaxScaleOnAxis(),
      sceneFocalPoint: _zoomController.toScene(event.localPosition),
    );
  }

  void _handleTrackpadUpdate(PointerPanZoomUpdateEvent event) {
    final gesture = _trackpadGesture;
    if (gesture == null || gesture.pointer != event.pointer) return;
    final scale = (gesture.scale * event.scale)
        .clamp(_minimumCanvasZoom, _maximumCanvasZoom)
        .toDouble();
    final focalPoint = event.localPosition + event.pan;
    _zoomController.value = Matrix4.identity()
      ..setTranslationRaw(
        focalPoint.dx - gesture.sceneFocalPoint.dx * scale,
        focalPoint.dy - gesture.sceneFocalPoint.dy * scale,
        0,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void _handleTrackpadEnd(PointerPanZoomEndEvent event) {
    if (_trackpadGesture?.pointer == event.pointer) _trackpadGesture = null;
  }

  void _panCanvasBy(Offset delta) {
    final matrix = _zoomController.value.clone();
    _zoomController.value = matrix
      ..setTranslationRaw(
        matrix.storage[12] + delta.dx,
        matrix.storage[13] + delta.dy,
        0,
      );
  }

  void _resetView() => _zoomController.value = Matrix4.identity();

  Size _canvasSize(BoxConstraints constraints) {
    var width = constraints.maxWidth + _canvasEdgePadding * 2;
    var height = constraints.maxHeight + _canvasEdgePadding * 2;
    for (final geometry in _geometries.values) {
      width = math.max(
        width,
        geometry.rect.right + _canvasEdgePadding + _trailingSpace,
      );
      height = math.max(
        height,
        geometry.rect.bottom +
            _labelGap +
            _labelHeight +
            _canvasEdgePadding +
            _trailingSpace,
      );
    }
    return Size(width, height);
  }
}

class _TrackpadGesture {
  const _TrackpadGesture({
    required this.pointer,
    required this.scale,
    required this.sceneFocalPoint,
  });

  final int pointer;
  final double scale;
  final Offset sceneFocalPoint;
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
            _CanvasModeButton(
              key: ValueKey('$keyPrefix-mode-select'),
              selected: !annotating,
              label: 'Select canvas items',
              shortcut: const ['⌘', '1'],
              onPress: onSelect,
              icon: DesyIcons.mousePointer,
            ),
            const SizedBox(width: 2),
            _CanvasModeButton(
              key: ValueKey('$keyPrefix-mode-annotate'),
              selected: annotating,
              label: annotating
                  ? 'Stop annotating canvas widgets'
                  : 'Annotate canvas widgets',
              shortcut: const ['⌘', '2'],
              onPress: onAnnotate,
              icon: DesyIcons.messageSquare,
            ),
          ],
        ),
      ),
    ),
  );
}

/// One compact desktop tool with a visible shortcut and discoverable label.
class _CanvasModeButton extends StatelessWidget {
  const _CanvasModeButton({
    super.key,
    required this.selected,
    required this.label,
    required this.shortcut,
    required this.icon,
    required this.onPress,
  });

  final bool selected;
  final String label;
  final List<String> shortcut;
  final IconData icon;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: DesyButton(
      size: DesyButtonSize.xs,
      variant: selected ? DesyButtonVariant.primary : DesyButtonVariant.ghost,
      mainAxisSize: MainAxisSize.min,
      semanticsLabel: label,
      semanticsTooltip: label,
      onPress: onPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 4),
          DesyKeyboardShortcutLabel(
            keys: shortcut,
            semanticLabel: 'Keyboard shortcut: ${shortcut.join(' plus ')}',
          ),
        ],
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
  Widget build(BuildContext context) => KeyedSubtree(
    key: item.itemKey,
    child: DesyDragBox(
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
      frameKey: item.frameKey ?? ValueKey('$keyPrefix-frame-${item.id}'),
      contentKey: item.contentKey ?? ValueKey('$keyPrefix-content-${item.id}'),
      resizeHandleKeyPrefix:
          item.resizeHandleKeyPrefix ?? '$keyPrefix-resize-${item.id}',
      selected: selected,
      draggable: item.draggable,
      ignoreChildPointer: item.ignoreChildPointer,
      onSelect: onSelect,
      onChanged: onChanged,
      geometryResolver: item.geometryResolver,
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
        key: item.labelKey ?? ValueKey('$keyPrefix-selection-size-${item.id}'),
        size: geometry.rect.size,
        identifier: item.name,
        selected: selected,
      ),
      child: Semantics(
        container: true,
        selected: selected,
        label: 'Select ${item.name}',
        child:
            item.previewSurfaceBuilder?.call(
              context,
              item.value,
              geometry,
              onSelect,
              onChanged,
            ) ??
            Center(
              child: DesyWidgetPreview(
                theme: theme,
                builder: (context) => item.previewBuilder!(context, item.value),
              ),
            ),
      ),
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
    required this.keyPrefix,
    required this.zoom,
    required this.onZoomOut,
    required this.onZoomIn,
  });

  final String keyPrefix;
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
            key: ValueKey('$keyPrefix-zoom-out'),
            variant: DesyButtonVariant.ghost,
            size: DesyButtonSize.xs,
            onPress: onZoomOut,
            semanticsLabel: 'Zoom out',
            child: const Icon(DesyIcons.minus, size: 14),
          ),
          Semantics(
            key: ValueKey('$keyPrefix-zoom-level'),
            label: 'Zoom ${(zoom * 100).round()} percent',
            child: SizedBox(
              width: 42,
              child: Text(
                '${(zoom * 100).round()}%',
                textAlign: TextAlign.center,
                style: context.theme.typography.body.xs.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          DesyButton.icon(
            key: ValueKey('$keyPrefix-zoom-in'),
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

class _CollectionCanvasBorderPainter extends CustomPainter {
  const _CollectionCanvasBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 1 || size.height < 1) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(
      Rect.fromLTWH(.5, .5, size.width - 1, size.height - 1),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CollectionCanvasBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

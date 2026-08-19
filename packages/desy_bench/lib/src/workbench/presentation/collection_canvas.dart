// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:object_canvas/object_canvas.dart';

import '../../registry.dart';
import '../workbench_annotation.dart';
import '../widget_preview.dart';
import 'desy_drag_box.dart';
import 'workbench_control_sheet.dart';

const _minimumBoxExtent = 8.0;
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

  @override
  State<DesyCollectionCanvas<T>> createState() =>
      _DesyCollectionCanvasState<T>();
}

class _DesyCollectionCanvasState<T> extends State<DesyCollectionCanvas<T>> {
  late final ObjectCanvasController<String> _canvas;
  final _reportedGeometries = <String, CanvasObjectGeometry>{};
  var _resetGeometryOnNextSync = false;
  var _zoom = 1.0;
  var _syncingCanvas = false;

  @override
  void initState() {
    super.initState();
    _canvas =
        ObjectCanvasController<String>(
            canvasSize: const Size.square(1),
            multiSelectionEnabled: false,
            overflow: CanvasOverflow.show,
            snapConfiguration: CanvasSnapConfiguration(strategies: const []),
            defaults: const CanvasObjectDefaults(
              constraints: CanvasObjectConstraints(
                minSize: Size.square(_minimumBoxExtent),
              ),
              capabilities: CanvasObjectCapabilities(
                rotatable: false,
                scalable: false,
              ),
            ),
            onSelectionChanged: _handleSelectionChanged,
          )
          ..addListener(_handleCanvasChanged)
          ..viewportController.addListener(_handleViewportChanged);
    _setZoomValue(widget.initialZoom);
  }

  @override
  void didUpdateWidget(covariant DesyCollectionCanvas<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.geometryRevision != widget.geometryRevision) {
      _resetGeometryOnNextSync = true;
      _reportedGeometries.clear();
    }
    if (oldWidget.initialSelectedItemId != widget.initialSelectedItemId &&
        widget.initialSelectedItemId != null) {
      _selectItemId(widget.initialSelectedItemId!);
    }
  }

  @override
  void dispose() {
    _canvas
      ..removeListener(_handleCanvasChanged)
      ..viewportController.removeListener(_handleViewportChanged)
      ..dispose();
    super.dispose();
  }

  void _handleViewportChanged() {
    final zoom = _canvas.viewportScale;
    if (!mounted || (zoom - _zoom).abs() < .001) return;
    setState(() => _zoom = zoom);
  }

  void _handleCanvasChanged() {
    if (_syncingCanvas) return;
    _publishGeometryChanges();
  }

  void _handleSelectionChanged(Set<String> selectedIds) {
    if (_syncingCanvas) return;
    final id = selectedIds.firstOrNull;
    if (id case final selectedId?) {
      final item = _itemForId(selectedId);
      if (item != null) {
        item.onSelected?.call();
        widget.onItemSelected?.call(item);
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
        final stageSize = _canvasSize(constraints);
        _synchronizeCanvas(stageSize);
        final selected = _selectedItem;
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
                ObjectCanvas<String>(
                  key: ValueKey('${widget.keyPrefix}-viewport'),
                  controller: _canvas,
                  minScale: _minimumCanvasZoom,
                  maxScale: _maximumCanvasZoom,
                  viewportBoundaryMargin: const EdgeInsets.all(
                    _canvasEdgePadding,
                  ),
                  clearSelectionOnCanvasTap: widget.clearSelectionOnCanvasTap,
                  objectVisibility: (object) => _itemForId(object.id) != null,
                  semanticLabelBuilder: (object) =>
                      _itemForId(object.id)?.name ?? object.id,
                  style: ObjectCanvasStyle(
                    viewportColor: workspaceBackground,
                    canvasColor: background,
                    selectionColor: context.theme.colors.desy.signal,
                    guideColor: context.theme.colors.desy.signal,
                    marqueeFillColor: context.theme.colors.desy.signalSurface
                        .withValues(alpha: .24),
                    marqueeStrokeColor: context.theme.colors.desy.signal,
                  ),
                  underlayBuilder: (context, controller) => CustomPaint(
                    key: ValueKey('${widget.keyPrefix}-stage'),
                    painter: _CollectionCanvasGridPainter(
                      background: background,
                    ),
                    foregroundPainter: _CollectionCanvasBorderPainter(
                      color: canvasBorderColor,
                    ),
                  ),
                  overlayBuilder: (context, controller) =>
                      _CollectionCanvasLabels<T>(
                        keyPrefix: widget.keyPrefix,
                        controller: controller,
                        itemForId: _itemForId,
                      ),
                  objectBuilder: _buildCanvasObject,
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
                  child: DesyZoomDock(
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
    _canvas.clearSelection();
  }

  void _enterAnnotateMode(DesyWorkbenchInspectionHost inspection) {
    if (!inspection.inspectionActive) inspection.onToggleInspection!();
  }

  DesyCanvasSceneItem<T>? get _selectedItem =>
      _itemForId(_canvas.selectedObjectIds.firstOrNull);

  void _synchronizeCanvas(Size stageSize) {
    _syncingCanvas = true;
    try {
      if (_canvas.canvasSize != stageSize) _canvas.setCanvasSize(stageSize);
      final ids = widget.items.map((item) => item.id).toSet();
      _reportedGeometries.removeWhere((id, _) => !ids.contains(id));
      final objects = <CanvasObject<String>>[];
      for (final (index, item) in widget.items.indexed) {
        final existing = _objectForId(item.id);
        objects.add(
          CanvasObject<String>(
            id: item.id,
            data: item.id,
            geometry: existing == null || _resetGeometryOnNextSync
                ? _initialGeometry(item, index)
                : _canvas.geometryFor(item.id),
            constraints: const CanvasObjectConstraints(
              minSize: Size.square(_minimumBoxExtent),
            ),
            capabilities: CanvasObjectCapabilities(
              movable: item.draggable,
              rotatable: false,
              scalable: false,
            ),
          ),
        );
      }
      _canvas.replaceObjects(objects);
      if (widget.initialSelectedItemId case final selectedId?
          when _canvas.selectedObjectIds.isEmpty && ids.contains(selectedId)) {
        _canvas.setSelectedObjects([selectedId]);
      }
      _resetGeometryOnNextSync = false;
      _rememberCurrentGeometries();
    } finally {
      _syncingCanvas = false;
    }
  }

  DesyCanvasSceneItem<T>? _itemForId(String? id) {
    if (id == null) return null;
    for (final item in widget.items) {
      if (item.id == id) return item;
    }
    return null;
  }

  CanvasObjectGeometry _initialGeometry(
    DesyCanvasSceneItem<T> item,
    int index,
  ) {
    const fallback = Size(320, 240);
    const columns = 3;
    const gap = 64.0;
    const inset = 72.0;
    final placement = item.initialRect;
    if (placement != null) {
      return CanvasObjectGeometry(
        position: placement.topLeft,
        size: Size(
          math.max(placement.width, _minimumBoxExtent),
          math.max(placement.height, _minimumBoxExtent),
        ),
      );
    }
    final size = item.initialSize;
    return CanvasObjectGeometry(
      position: Offset(
        inset + (index % columns) * (fallback.width + gap),
        inset + (index ~/ columns) * (fallback.height + gap),
      ),
      size: Size(
        math.max(size.width, _minimumBoxExtent),
        math.max(size.height, _minimumBoxExtent),
      ),
    );
  }

  Widget _buildCanvasObject(BuildContext context, CanvasObject<String> object) {
    final item = _itemForId(object.id);
    if (item == null) return const SizedBox.shrink();
    final geometry = DesyDragBoxGeometry(
      rect: object.geometry.position & object.geometry.size,
    );
    final selected = _canvas.selectedObjectIds.contains(object.id);
    final preview =
        item.previewSurfaceBuilder?.call(
          context,
          item.value,
          geometry,
          () => _selectItemId(item.id),
          (geometry) => _updateGeometry(item.id, geometry),
        ) ??
        Center(
          child: DesyWidgetPreview(
            theme: widget.theme,
            builder: (context) => item.previewBuilder!(context, item.value),
          ),
        );
    final framed = DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: context.theme.colors.desy.signal.withValues(
            alpha: selected ? .9 : .28,
          ),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: KeyedSubtree(
        key:
            item.contentKey ??
            ValueKey('${widget.keyPrefix}-content-${item.id}'),
        child: IgnorePointer(
          ignoring: item.ignoreChildPointer,
          child: Semantics(
            container: true,
            selected: selected,
            label: 'Select ${item.name}',
            child: preview,
          ),
        ),
      ),
    );
    return KeyedSubtree(
      key: item.itemKey ?? ValueKey('${widget.keyPrefix}-item-${item.id}'),
      child: KeyedSubtree(
        key: item.frameKey ?? ValueKey('${widget.keyPrefix}-frame-${item.id}'),
        child: framed,
      ),
    );
  }

  void _selectItemId(String id) => _canvas.setSelectedObjects([id]);

  void _clearSelection() => _canvas.clearSelection();

  void _updateGeometry(String id, DesyDragBoxGeometry geometry) {
    final currentGeometry = _canvas.geometryFor(id);
    final resolved =
        _itemForId(id)?.geometryResolver?.call(
          geometry,
          DesyDragBoxInteraction(
            kind: DesyDragBoxInteractionKind.resize,
            initialRect: currentGeometry.position & currentGeometry.size,
          ),
        ) ??
        geometry;
    _canvas.updateGeometries([
      CanvasGeometryValue(
        objectId: id,
        geometry: CanvasObjectGeometry(
          position: resolved.rect.topLeft,
          size: resolved.rect.size,
        ),
      ),
    ]);
  }

  void _publishGeometryChanges() {
    for (final object in _canvas.objects) {
      final geometry = _canvas.geometryFor(object.id);
      if (_reportedGeometries[object.id] == geometry) continue;
      _reportedGeometries[object.id] = geometry;
      _itemForId(object.id)?.onGeometryChanged?.call(
        DesyDragBoxGeometry(rect: geometry.position & geometry.size),
      );
    }
  }

  void _rememberCurrentGeometries() {
    for (final object in _canvas.objects) {
      _reportedGeometries[object.id] = _canvas.geometryFor(object.id);
    }
  }

  void _setZoom(double value) {
    final zoom = value.clamp(_minimumCanvasZoom, _maximumCanvasZoom).toDouble();
    final matrix = _canvas.viewportController.value;
    if ((zoom - _zoom).abs() >= .001) setState(() => _zoom = zoom);
    _canvas.viewportController.value = Matrix4.identity()
      ..setTranslationRaw(matrix.storage[12], matrix.storage[13], 0)
      ..scaleByDouble(zoom, zoom, 1, 1);
  }

  void _setZoomValue(double value) {
    _zoom = value.clamp(_minimumCanvasZoom, _maximumCanvasZoom).toDouble();
    _canvas.viewportController.value = Matrix4.identity()
      ..scaleByDouble(_zoom, _zoom, 1, 1);
  }

  void _resetView() => _canvas.viewportController.value = Matrix4.identity();

  Size _canvasSize(BoxConstraints constraints) {
    var width = constraints.maxWidth + _canvasEdgePadding * 2;
    var height = constraints.maxHeight + _canvasEdgePadding * 2;
    for (final (index, item) in widget.items.indexed) {
      final object = _objectForId(item.id);
      final geometry = object == null
          ? _initialGeometry(item, index)
          : _canvas.geometryFor(item.id);
      width = math.max(
        width,
        geometry.paintBounds.right + _canvasEdgePadding + _trailingSpace,
      );
      height = math.max(
        height,
        geometry.paintBounds.bottom +
            _labelGap +
            _labelHeight +
            _canvasEdgePadding +
            _trailingSpace,
      );
    }
    return Size(width, height);
  }

  CanvasObject<String>? _objectForId(String id) {
    for (final object in _canvas.objects) {
      if (object.id == id) return object;
    }
    return null;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _CollectionCanvasLabels<T> extends StatelessWidget {
  const _CollectionCanvasLabels({
    required this.keyPrefix,
    required this.controller,
    required this.itemForId,
  });

  final String keyPrefix;
  final ObjectCanvasController<String> controller;
  final DesyCanvasSceneItem<T>? Function(String? id) itemForId;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      for (final object in controller.objects)
        if (itemForId(object.id) case final item?)
          Positioned(
            left: controller.geometryFor(object.id).position.dx,
            top:
                controller.geometryFor(object.id).position.dy +
                controller.geometryFor(object.id).size.height +
                _labelGap,
            child: DesyDragBoxLabel(
              key:
                  item.labelKey ??
                  ValueKey('$keyPrefix-selection-size-${item.id}'),
              size: controller.geometryFor(object.id).size,
              identifier: item.name,
              selected: controller.selectedObjectIds.contains(object.id),
            ),
          ),
    ],
  );
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

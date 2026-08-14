// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:state_beacon/state_beacon.dart';

import 'component_knob_panel.dart';
import 'preview_accessibility_panel.dart';
import 'preview_accessibility_overlay.dart';
import 'desy_drag_box.dart';
import 'detail_extensions_region.dart';
import 'motion_playback_controls.dart';
import '../../device_preview.dart';
import '../../motion_playback.dart';
import '../../registry.dart';
import '../widget_preview.dart';
import '../workbench_annotation.dart';
import '../workbench_session.dart';

const _minimumBoxExtent = 8.0;
const _detailToolbarTop = 12.0;
const _detailToolbarReservedHeight = 58.0;
const _toolbarSelectionGap = 8.0;
const _selectionLabelGap = 6.0;
const _selectionLabelReservedHeight = 28.0;

const _selectionMinimumTop =
    _detailToolbarTop + _detailToolbarReservedHeight + _toolbarSelectionGap;

// The detail canvas deliberately has no user-facing edge or maximum artboard
// size. A large finite coordinate space keeps the underlying transform package
// numerically stable while allowing artboards to extend beyond the viewport.
const _unboundedCanvasExtent = 100000.0;
const _detailCanvasItemGap = 16.0;
const _detailCanvasTrailingSpace = 40.0;

double _boundedBoxExtent(double value) =>
    value < _minimumBoxExtent ? _minimumBoxExtent : value;

Rect _lockAspectRatio({
  required double ratio,
  required Rect current,
  required Rect proposed,
  Rect? clampingRect,
}) {
  final widthDriven =
      (proposed.width - current.width).abs() >
      (proposed.height - current.height).abs() * ratio;
  final width = widthDriven
      ? proposed.width.abs()
      : proposed.height.abs() * ratio;
  final height = width / ratio;
  final rightAnchored =
      (proposed.right - current.right).abs() <
      (proposed.left - current.left).abs();
  final bottomAnchored =
      (proposed.bottom - current.bottom).abs() <
      (proposed.top - current.top).abs();
  var rect = Rect.fromLTWH(
    rightAnchored ? current.right - width : current.left,
    bottomAnchored ? current.bottom - height : current.top,
    width.isFinite && width > 0 ? width : 0,
    height.isFinite && height > 0 ? height : 0,
  );
  final bounds = clampingRect;
  if (bounds == null ||
      !bounds.width.isFinite ||
      !bounds.height.isFinite ||
      bounds.width <= 0 ||
      bounds.height <= 0) {
    return rect;
  }

  final scale = math.min(
    1,
    math.min(bounds.width / rect.width, bounds.height / rect.height),
  );
  if (!scale.isFinite || scale <= 0) {
    return rect;
  }
  if (scale < 1) {
    rect = Rect.fromLTWH(
      rightAnchored ? rect.right - rect.width * scale : rect.left,
      bottomAnchored ? rect.bottom - rect.height * scale : rect.top,
      rect.width * scale,
      rect.height * scale,
    );
  }

  final dx = rect.left < bounds.left
      ? bounds.left - rect.left
      : rect.right > bounds.right
      ? bounds.right - rect.right
      : 0.0;
  final dy = rect.top < bounds.top
      ? bounds.top - rect.top
      : rect.bottom > bounds.bottom
      ? bounds.bottom - rect.bottom
      : 0.0;
  return rect.shift(Offset(dx, dy));
}

/// The inspect-and-adjust surface for a single entry.
class DesyDetailScreen extends StatefulWidget {
  const DesyDetailScreen({
    super.key,
    required this.session,
    required this.entry,
    this.inspectionContext,
    this.onOpenFolder,
  });

  final DesyWorkbenchSession session;
  final DesyRegistryEntry entry;
  final DesyWorkbenchInspectionContext? inspectionContext;
  final ValueChanged<String>? onOpenFolder;

  @override
  State<DesyDetailScreen> createState() => _DesyDetailScreenState();
}

class _DesyDetailScreenState extends State<DesyDetailScreen>
    with TickerProviderStateMixin {
  String _selectedVariantId = 'default';
  String? _selectedMotionChildId;
  DesyMotionPlaybackController? _motionPlayback;

  DesyMotionEntry? get _motion => switch (widget.entry.source) {
    final DesyMotionEntry motion => motion,
    _ => null,
  };

  @override
  void initState() {
    super.initState();
    _initializeMotionPlayback();
  }

  @override
  void didUpdateWidget(covariant DesyDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id ||
        oldWidget.entry.source != widget.entry.source) {
      _selectedVariantId = 'default';
      _disposeMotionPlayback();
      _initializeMotionPlayback();
    }
  }

  void _initializeMotionPlayback() {
    final motion = _motion;
    if (motion == null) return;
    _selectedMotionChildId = motion.defaultChild.id;
    _motionPlayback = DesyMotionPlaybackController(
      vsync: this,
      duration: motion.duration ?? DesyMotionPlaybackController.defaultDuration,
      curve: motion.curve,
    );
  }

  void _disposeMotionPlayback() {
    _motionPlayback?.dispose();
    _motionPlayback = null;
  }

  @override
  void dispose() {
    _disposeMotionPlayback();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final entry = widget.entry;
    final theme = session.activeTheme;
    final device = session.previewDevice.watch(context);
    final accessibility = session.previewAccessibility.watch(context);
    final values = session.knobValues.watch(context);
    final component = entry.component;
    final motion = _motion;
    final variants = <_DetailVariant>[
      _DetailVariant(
        id: 'default',
        name: component == null ? entry.name : 'Default',
        selected: _selectedVariantId == 'default',
        onSelect: component == null
            ? null
            : () => _selectVariant(component: component),
        builder: component == null
            ? motion == null
                  ? entry.builder
                  : _buildMotionPreview
            : (context) => component.buildWithValues(
                context,
                _selectedVariantId == 'default' ? values : const {},
                widgets: session.registry.widgetBuilder,
              ),
      ),
      // The base preview already represents the component's default form.
      // Components commonly declare a `default` preset for registry lookup,
      // but rendering it here would create two visually identical Defaults.
      for (final instanceId
          in component?.instanceIds.where(
                (instanceId) => instanceId != 'default',
              ) ??
              const <String>[])
        _DetailVariant(
          id: 'instance-$instanceId',
          name: component!.instanceLabel(instanceId),
          selected: _selectedVariantId == 'instance-$instanceId',
          onSelect: () =>
              _selectVariant(component: component, instanceId: instanceId),
          builder: (context) => _selectedVariantId == 'instance-$instanceId'
              ? component.buildWithValues(
                  context,
                  values,
                  widgets: session.registry.widgetBuilder,
                )
              : component.buildInstance(
                  context,
                  instanceId,
                  session.registry.widgetBuilder,
                ),
        ),
      if (component != null)
        for (final scenario in component.scenarios)
          _DetailVariant(
            id: 'scenario-${scenario.id}',
            name: 'State · ${scenario.name}',
            selected: false,
            onSelect: null,
            builder: scenario.builder,
          ),
    ];

    return _DetailBody(
      preview: _DetailInstanceGallery(
        session: session,
        theme: theme,
        device: device,
        accessibility: accessibility,
        toolbar: _DetailPreviewToolbar(
          entry: entry,
          onOpenFolder: widget.onOpenFolder,
        ),
        variants: variants,
        inspectionContext: widget.inspectionContext,
      ),
      inspector: _DetailInspector(
        session: session,
        component: component,
        entry: entry,
        values: values,
        motionControls: motion == null ? null : _buildMotionControls(),
      ),
    );
  }

  Widget _buildMotionPreview(BuildContext context) {
    final playback = _motionPlayback;
    final motion = _motion;
    if (playback == null || motion == null) {
      return widget.entry.builder(context);
    }
    return DesyMotionPlaybackScope(
      progress: playback.progress,
      child: Builder(
        builder: (context) => motion.build(
          context,
          motion
              .childForId(_selectedMotionChildId ?? motion.defaultChild.id)
              .build(context, widgets: widget.session.registry.widgetBuilder),
        ),
      ),
    );
  }

  Widget _buildMotionControls() {
    final motion = _motion!;
    return DesyMotionPlaybackControls(
      controller: _motionPlayback!,
      specimenChildren: motion.children,
      selectedSpecimenChildId: _selectedMotionChildId ?? motion.defaultChild.id,
      onSpecimenChildSelected: (id) {
        if (id == _selectedMotionChildId) return;
        setState(() => _selectedMotionChildId = id);
      },
    );
  }

  void _selectVariant({
    required DesyRegistryComponent component,
    String? instanceId,
  }) {
    final variantId = instanceId == null ? 'default' : 'instance-$instanceId';
    if (_selectedVariantId == variantId) return;
    setState(() => _selectedVariantId = variantId);
    final registered = instanceId == null
        ? null
        : widget.session.registry.resolveComponentInstance(
            '${component.id}.$instanceId',
          );
    widget.session.editComponentVariant(
      component: component,
      instance: registered,
    );
  }
}

class _DetailVariant {
  const _DetailVariant({
    required this.id,
    required this.name,
    required this.selected,
    required this.onSelect,
    required this.builder,
  });

  final String id;
  final String name;
  final bool selected;
  final VoidCallback? onSelect;
  final DesyPreviewBuilder builder;
}

class _DetailInstanceGallery extends StatefulWidget {
  const _DetailInstanceGallery({
    required this.session,
    required this.theme,
    required this.device,
    required this.accessibility,
    required this.toolbar,
    required this.variants,
    this.inspectionContext,
  });

  final DesyWorkbenchSession session;
  final DesyTheme theme;
  final DesyDevicePreset? device;
  final DesyPreviewAccessibilitySettings accessibility;
  final Widget toolbar;
  final List<_DetailVariant> variants;
  final DesyWorkbenchInspectionContext? inspectionContext;

  @override
  State<_DetailInstanceGallery> createState() => _DetailInstanceGalleryState();
}

class _DetailInstanceGalleryState extends State<_DetailInstanceGallery> {
  final Map<String, DesyDragBoxGeometry> _geometries = {};
  final List<String> _paintOrder = [];
  final TransformationController _zoomController = TransformationController();
  DesyDevicePreset? _lastDevice;
  DesyDevicePreset? _zoomedDevice;
  int? _canvasPointer;
  Offset? _canvasPointerPosition;
  var _zoom = 1.0;

  @override
  void initState() {
    super.initState();
    _zoomController.addListener(_handleZoomChanged);
  }

  @override
  void didUpdateWidget(covariant _DetailInstanceGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.device != widget.device) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitDevicePreview();
      });
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
    if (!mounted) return;
    setState(() => _zoom = zoom);
  }

  void _synchronizeItems(DesyPreviewStage stage, DesyDevicePreset? device) {
    final activeIds = widget.variants.map((variant) => variant.id).toSet();
    _geometries.removeWhere((id, _) => !activeIds.contains(id));
    _paintOrder.removeWhere((id) => !activeIds.contains(id));
    final deviceChanged = device != _lastDevice;
    for (var index = 0; index < widget.variants.length; index++) {
      final variant = widget.variants[index];
      final geometry = DesyDragBoxGeometry(
        rect: Rect.fromLTWH(
          stage.offset.dx,
          math.max(stage.offset.dy, _selectionMinimumTop) +
              index *
                  ((device?.screenSize.height ?? stage.size.height) +
                      _selectionLabelGap +
                      _selectionLabelReservedHeight +
                      _detailCanvasItemGap),
          device?.screenSize.width ?? stage.size.width,
          device?.screenSize.height ?? stage.size.height,
        ),
      );
      if (deviceChanged) {
        // Selecting a device starts each viewer at its logical viewport size,
        // rather than fitting it into the previous responsive artboard. The
        // scrollable canvas keeps that full-size frame available without
        // imposing a maximum size.
        _geometries[variant.id] = geometry;
      } else {
        _geometries.putIfAbsent(variant.id, () => geometry);
      }
      if (!_paintOrder.contains(variant.id)) _paintOrder.add(variant.id);
    }
    _lastDevice = device;
  }

  void _select(_DetailVariant variant) {
    setState(() {
      _paintOrder
        ..remove(variant.id)
        ..add(variant.id);
    });
    variant.onSelect?.call();
  }

  void _updateGeometry(String id, DesyDragBoxGeometry geometry) {
    setState(() => _geometries[id] = geometry);
  }

  void _setZoom(double value) {
    final zoom = value.clamp(.25, 2.5).toDouble();
    final matrix = _zoomController.value;
    if (mounted && (zoom - _zoom).abs() >= .001) {
      setState(() => _zoom = zoom);
    }
    _zoomController.value = Matrix4.identity()
      ..setTranslationRaw(matrix.storage[12], matrix.storage[13], 0)
      ..scaleByDouble(zoom, zoom, 1, 1);
  }

  void _panCanvas(Offset delta) {
    final matrix = _zoomController.value;
    _zoomController.value = Matrix4.copy(matrix)
      ..setTranslationRaw(
        matrix.storage[12] + delta.dx,
        matrix.storage[13] + delta.dy,
        0,
      );
  }

  void _onCanvasPointerDown(PointerDownEvent event) {
    _canvasPointer = event.pointer;
    _canvasPointerPosition = event.position;
  }

  void _onCanvasPointerMove(PointerMoveEvent event) {
    if (event.pointer != _canvasPointer) return;
    final previous = _canvasPointerPosition;
    if (previous == null) return;
    _canvasPointerPosition = event.position;
    _panCanvas(event.position - previous);
  }

  void _onCanvasPointerEnd(PointerEvent event) {
    if (event.pointer != _canvasPointer) return;
    _canvasPointer = null;
    _canvasPointerPosition = null;
  }

  void _fitDevicePreview() {
    final device = _zoomedDevice ?? widget.device;
    _setZoom(
      device == null ? 1 : math.min(.72, 620 / device.screenSize.height),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.session.stage.watch(context);
    _synchronizeItems(stage, widget.device);
    final activeDevice = widget.session.previewDevice.value;
    if (_zoomedDevice != activeDevice) {
      _zoomedDevice = activeDevice;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitDevicePreview();
      });
    }
    final background =
        widget.theme.previewBackgroundColor ?? context.theme.colors.background;
    final variants = {
      for (final variant in widget.variants) variant.id: variant,
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = _canvasSize(constraints);
        return ColoredBox(
          color: background,
          child: Stack(
            children: [
              Transform(
                key: const ValueKey('detail-canvas-viewport'),
                alignment: Alignment.topLeft,
                transform: _zoomController.value,
                child: SizedBox(
                  width: canvasSize.width,
                  height: canvasSize.height,
                  child: CustomPaint(
                    painter: _DottedPreviewPainter(background: background),
                    child: Stack(
                      key: const ValueKey('detail-instance-gallery'),
                      fit: StackFit.expand,
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: _onCanvasPointerDown,
                            onPointerMove: _onCanvasPointerMove,
                            onPointerUp: _onCanvasPointerEnd,
                            onPointerCancel: _onCanvasPointerEnd,
                          ),
                        ),
                        for (final id in _paintOrder)
                          if (variants[id] case final variant?)
                            _DetailCanvasItem(
                              key: ValueKey(
                                'detail-instance-viewer-${variant.id}',
                              ),
                              variant: variant,
                              geometry: _geometries[variant.id]!,
                              theme: widget.theme,
                              device: widget.device,
                              accessibility: widget.accessibility,
                              inspectionContext: widget.inspectionContext,
                              onSelect: () => _select(variant),
                              onChanged: (geometry) =>
                                  _updateGeometry(variant.id, geometry),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: _detailToolbarTop,
                left: 12,
                child: widget.toolbar,
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: _DetailCanvasZoomDock(
                  zoom: _zoom,
                  onZoomOut: () => _setZoom(_zoom - .15),
                  onZoomIn: () => _setZoom(_zoom + .15),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Size _canvasSize(BoxConstraints constraints) {
    var width = constraints.maxWidth;
    var height = constraints.maxHeight;
    for (final geometry in _geometries.values) {
      width = math.max(width, geometry.rect.right + _detailCanvasTrailingSpace);
      height = math.max(
        height,
        geometry.rect.bottom +
            _selectionLabelGap +
            _selectionLabelReservedHeight +
            _detailCanvasTrailingSpace,
      );
    }
    return Size(width, height);
  }
}

class _DetailCanvasZoomDock extends StatelessWidget {
  const _DetailCanvasZoomDock({
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
            key: const ValueKey('detail-canvas-zoom-out'),
            variant: DesyButtonVariant.ghost,
            size: DesyButtonSize.xs,
            onPress: onZoomOut,
            semanticsLabel: 'Zoom out',
            semanticsTooltip: 'Zoom out',
            child: const Icon(DesyIcons.minus, size: 14),
          ),
          Semantics(
            key: const ValueKey('detail-canvas-zoom-level'),
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
            key: const ValueKey('detail-canvas-zoom-in'),
            variant: DesyButtonVariant.ghost,
            size: DesyButtonSize.xs,
            onPress: onZoomIn,
            semanticsLabel: 'Zoom in',
            semanticsTooltip: 'Zoom in',
            child: const Icon(DesyIcons.plus, size: 14),
          ),
        ],
      ),
    ),
  );
}

class _DetailCanvasItem extends StatelessWidget {
  const _DetailCanvasItem({
    super.key,
    required this.variant,
    required this.geometry,
    required this.theme,
    required this.device,
    required this.accessibility,
    required this.inspectionContext,
    required this.onSelect,
    required this.onChanged,
  });

  final _DetailVariant variant;
  final DesyDragBoxGeometry geometry;
  final DesyTheme theme;
  final DesyDevicePreset? device;
  final DesyPreviewAccessibilitySettings accessibility;
  final DesyWorkbenchInspectionContext? inspectionContext;
  final VoidCallback onSelect;
  final ValueChanged<DesyDragBoxGeometry> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDefault = variant.id == 'default';
    final preview = inspectionContext == null
        ? DesyWidgetPreview(theme: theme, builder: variant.builder)
        : DesyWorkbenchInspectionScope(
            context: inspectionContext!,
            child: DesyWidgetPreview(theme: theme, builder: variant.builder),
          );
    final child = _PreviewAccessibilityScope(
      settings: accessibility,
      child: preview,
    );
    final visual = _buildVisual(context, child);
    return DesyDragBox(
      geometry: geometry,
      clampingRect: const Rect.fromLTRB(
        -_unboundedCanvasExtent,
        -_unboundedCanvasExtent,
        _unboundedCanvasExtent,
        _unboundedCanvasExtent,
      ),
      constraints: const BoxConstraints(
        minWidth: _minimumBoxExtent,
        minHeight: _minimumBoxExtent,
      ),
      frameKey: isDefault
          ? const ValueKey('detail-artboard')
          : ValueKey('detail-instance-artboard-${variant.id}'),
      contentKey: isDefault
          ? const ValueKey('detail-artboard-hit')
          : ValueKey('detail-instance-artboard-hit-${variant.id}'),
      resizeHandleKeyPrefix: 'detail-resize-${variant.id}',
      selected: variant.selected,
      // Device previews own their move surface so the rendered bezel cannot
      // claim a drag. Responsive viewers continue to use DragBox directly.
      draggable: device == null,
      ignoreChildPointer: device == null,
      onSelect: onSelect,
      onChanged: onChanged,
      geometryResolver: device == null
          ? null
          : (geometry, interaction) => DesyDragBoxGeometry(
              rect: _lockAspectRatio(
                ratio: device!.screenSize.aspectRatio,
                current: interaction.initialRect,
                proposed: geometry.rect,
              ),
              flip: geometry.flip,
            ),
      label: DesyDragBoxLabel(
        key: isDefault
            ? const ValueKey('detail-selection-size')
            : ValueKey('detail-instance-label-${variant.id}'),
        size: geometry.rect.size,
        identifier: variant.name,
      ),
      child: device == null
          ? visual
          : _DeviceDragSurface(
              geometry: geometry,
              onSelect: onSelect,
              onChanged: onChanged,
              child: visual,
            ),
    );
  }

  Widget _buildVisual(BuildContext context, Widget child) => Semantics(
    key: ValueKey('detail-instance-selector-${variant.id}'),
    container: true,
    selected: variant.selected,
    label: variant.onSelect == null
        ? '${variant.name} preview'
        : '${variant.name} instance preview',
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: context.theme.colors.desy.signal.withValues(alpha: .48),
        ),
      ),
      child: ClipRect(
        child: Center(
          child: device == null
              ? child
              : DesyDevicePreview(
                  device: device!,
                  child: ColoredBox(
                    key: ValueKey('detail-device-screen-${device!.name}'),
                    color:
                        theme.previewBackgroundColor ??
                        context.theme.colors.background,
                    child: Align(alignment: Alignment.center, child: child),
                  ),
                ),
        ),
      ),
    ),
  );
}

class _DeviceDragSurface extends StatefulWidget {
  const _DeviceDragSurface({
    required this.geometry,
    required this.onSelect,
    required this.onChanged,
    required this.child,
  });

  final DesyDragBoxGeometry geometry;
  final VoidCallback onSelect;
  final ValueChanged<DesyDragBoxGeometry> onChanged;
  final Widget child;

  @override
  State<_DeviceDragSurface> createState() => _DeviceDragSurfaceState();
}

class _DeviceDragSurfaceState extends State<_DeviceDragSurface> {
  int? _pointer;
  Offset? _startPosition;
  DesyDragBoxGeometry? _startGeometry;

  bool _isArtboardPointer(PointerDeviceKind kind) => switch (kind) {
    PointerDeviceKind.mouse ||
    PointerDeviceKind.touch ||
    PointerDeviceKind.stylus ||
    PointerDeviceKind.invertedStylus => true,
    _ => false,
  };

  void _onPointerDown(PointerDownEvent event) {
    if (!_isArtboardPointer(event.kind)) return;
    widget.onSelect();
    _pointer = event.pointer;
    _startPosition = event.position;
    _startGeometry = widget.geometry;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    final startPosition = _startPosition;
    final startGeometry = _startGeometry;
    if (startPosition == null || startGeometry == null) return;
    widget.onChanged(
      DesyDragBoxGeometry(
        rect: startGeometry.rect.shift(event.position - startPosition),
        flip: startGeometry.flip,
      ),
    );
  }

  void _onPointerEnd(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    _startPosition = null;
    _startGeometry = null;
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.opaque,
    onPointerDown: _onPointerDown,
    onPointerMove: _onPointerMove,
    onPointerUp: _onPointerEnd,
    onPointerCancel: (_) => _pointer = null,
    child: IgnorePointer(child: widget.child),
  );
}

/// The detail route's only content split.
///
/// ShellRoute owns the global sidebar. This surface owns the local split
/// between the preview and the component controls.
class _DetailBody extends StatefulWidget {
  const _DetailBody({required this.preview, required this.inspector});

  final Widget preview;
  final Widget inspector;

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> {
  static const _minimumPreviewWidth = 360.0;
  static const _minimumInspectorWidth = 240.0;
  static const _maximumInspectorWidth = 520.0;
  static const _minimumPreviewHeight = 240.0;
  static const _minimumInspectorHeight = 180.0;
  static const _maximumInspectorHeight = 520.0;

  var _inspectorWidth = 320.0;
  var _inspectorHeight = 260.0;
  var _resizingInspector = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final dividerSize = DesyDesignSystemTokens.resizeDividerHitSize;
      if (constraints.maxWidth < 720) {
        final maximumInspectorHeight =
            (constraints.maxHeight - _minimumPreviewHeight - dividerSize)
                .clamp(_minimumInspectorHeight, _maximumInspectorHeight)
                .toDouble();
        final inspectorHeight = _inspectorHeight
            .clamp(_minimumInspectorHeight, maximumInspectorHeight)
            .toDouble();
        return Column(
          children: [
            Expanded(child: widget.preview),
            DesyResizeDivider(
              key: const ValueKey('detail-controls-resize-handle'),
              axis: Axis.horizontal,
              value: inspectorHeight,
              semanticsLabel: 'Resize controls panel',
              onResizeStart: () => setState(() => _resizingInspector = true),
              onResize: (delta) => setState(
                () => _inspectorHeight = (inspectorHeight - delta)
                    .clamp(_minimumInspectorHeight, maximumInspectorHeight)
                    .toDouble(),
              ),
              onResizeEnd: () => setState(() => _resizingInspector = false),
            ),
            AnimatedContainer(
              key: const ValueKey('detail-controls-panel'),
              duration: _resizingInspector
                  ? Duration.zero
                  : const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              height: inspectorHeight,
              child: widget.inspector,
            ),
          ],
        );
      }
      final maximumInspectorWidth =
          (constraints.maxWidth - _minimumPreviewWidth - dividerSize)
              .clamp(_minimumInspectorWidth, _maximumInspectorWidth)
              .toDouble();
      final inspectorWidth = _inspectorWidth
          .clamp(_minimumInspectorWidth, maximumInspectorWidth)
          .toDouble();
      return Row(
        children: [
          Expanded(child: widget.preview),
          DesyResizeDivider(
            key: const ValueKey('detail-controls-resize-handle'),
            axis: Axis.vertical,
            value: inspectorWidth,
            semanticsLabel: 'Resize controls panel',
            onResizeStart: () => setState(() => _resizingInspector = true),
            onResize: (delta) => setState(
              () => _inspectorWidth = (inspectorWidth - delta)
                  .clamp(_minimumInspectorWidth, maximumInspectorWidth)
                  .toDouble(),
            ),
            onResizeEnd: () => setState(() => _resizingInspector = false),
          ),
          AnimatedContainer(
            key: const ValueKey('detail-controls-panel'),
            duration: _resizingInspector
                ? Duration.zero
                : const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            width: inspectorWidth,
            child: widget.inspector,
          ),
        ],
      );
    },
  );
}

class _DetailPreviewToolbar extends StatelessWidget {
  const _DetailPreviewToolbar({
    required this.entry,
    required this.onOpenFolder,
  });

  final DesyRegistryEntry entry;
  final ValueChanged<String>? onOpenFolder;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      key: const ValueKey('detail-preview-toolbar'),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.secondary,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailBreadcrumbs(entry: entry, onOpenFolder: onOpenFolder),
        ],
      ),
    );
  }
}

class _DetailBreadcrumbs extends StatelessWidget {
  const _DetailBreadcrumbs({required this.entry, required this.onOpenFolder});

  final DesyRegistryEntry entry;
  final ValueChanged<String>? onOpenFolder;

  @override
  Widget build(BuildContext context) {
    final segments = [...entry.folderNames, entry.name];
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: context.theme.colors.mutedForeground,
    );
    return Semantics(
      label: 'Breadcrumb',
      container: true,
      explicitChildNodes: true,
      child: Wrap(
        key: const ValueKey('detail-breadcrumbs'),
        spacing: 3,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var index = 0; index < segments.length; index++) ...[
            if (index > 0)
              Icon(
                DesyIcons.chevronRight,
                size: 11,
                color: context.theme.colors.mutedForeground,
              ),
            if (index < entry.folderIds.length)
              Semantics(
                key: ValueKey(
                  'detail-breadcrumb-folder-${entry.folderIds[index]}',
                ),
                button: true,
                enabled: onOpenFolder != null,
                label: 'Open ${segments[index]} folder',
                excludeSemantics: true,
                onTap: onOpenFolder == null
                    ? null
                    : () => onOpenFolder!(entry.folderIds[index]),
                child: DesyButton(
                  variant: DesyButtonVariant.ghost,
                  size: DesyButtonSize.xs,
                  mainAxisSize: MainAxisSize.min,
                  onPress: onOpenFolder == null
                      ? null
                      : () => onOpenFolder!(entry.folderIds[index]),
                  child: Text(
                    segments[index],
                    key: ValueKey('detail-breadcrumb-$index'),
                    style: style,
                  ),
                ),
              )
            else
              Text(
                segments[index],
                key: ValueKey('detail-breadcrumb-$index'),
                style: style,
              ),
          ],
        ],
      ),
    );
  }
}

class _DetailInspector extends StatelessWidget {
  const _DetailInspector({
    required this.session,
    required this.component,
    required this.entry,
    required this.values,
    required this.motionControls,
  });

  final DesyWorkbenchSession session;
  final DesyRegistryComponent? component;
  final DesyRegistryEntry entry;
  final Map<String, Object> values;
  final Widget? motionControls;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.theme.colors.background,
    child: ListView(
      padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceLg),
      children: [
        if (motionControls case final controls?) ...[controls],
        if (component != null && component!.knobDefinitions.isNotEmpty) ...[
          if (motionControls != null)
            const SizedBox(height: DesyDesignSystemTokens.spaceLg),
          DesyComponentKnobPanel(
            registry: session.registry,
            knobs: component!.knobDefinitions,
            values: values,
            onChanged: session.setKnob,
            title: 'Controls',
          ),
        ],
        if (motionControls == null &&
            (component == null || component!.knobDefinitions.isEmpty)) ...[
          DesyKnobSheet(title: 'Controls', sections: const []),
        ],
        DesyDetailExtensionsRegion(session: session, entry: entry),
        const SizedBox(height: DesyDesignSystemTokens.spaceLg),
        DesyPreviewAccessibilityPanel(
          settings: session.previewAccessibility.watch(context),
          onChanged: session.setPreviewAccessibility,
          selectedDevice: session.previewDevice.watch(context),
          onDeviceChanged: session.selectPreviewDevice,
        ),
      ],
    ),
  );
}

class _PreviewAccessibilityScope extends StatelessWidget {
  const _PreviewAccessibilityScope({
    required this.settings,
    required this.child,
  });

  final DesyPreviewAccessibilitySettings settings;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final colors = context.theme.colors;
    final preview = MediaQuery(
      data: media.copyWith(
        textScaler: TextScaler.linear(settings.textScale),
        boldText: settings.boldText,
        highContrast: settings.highContrast,
        disableAnimations: settings.disableAnimations,
      ),
      child: Directionality(
        textDirection: settings.textDirection,
        child: child,
      ),
    );
    return DesyPreviewAccessibilityOverlay(
      showLabels: settings.showSemantics,
      showHitTargets: settings.showHitTargets,
      passingColor: colors.desy.positive,
      undersizedColor: colors.destructive,
      unlabeledColor: colors.desy.signal,
      labelColor: colors.foreground,
      labelBackgroundColor: colors.background,
      child: preview,
    );
  }
}

/// A bounded stage for inspecting a real consumer widget in its theme.
class DesyPreviewCanvas extends StatelessWidget {
  const DesyPreviewCanvas({
    super.key,
    required this.session,
    required this.theme,
    required this.device,
    required this.toolbar,
    required this.child,
    this.instanceLabel,
    this.canvasKey = const ValueKey('detail-preview-canvas'),
    this.artboardKey = const ValueKey('detail-artboard'),
    this.selectionLabelKey = const ValueKey('detail-selection-size'),
    this.selected = true,
    this.onSelect,
  });

  final DesyWorkbenchSession session;
  final DesyTheme theme;
  final DesyDevicePreset? device;
  final Widget? toolbar;
  final Widget child;
  final String? instanceLabel;
  final Key canvasKey;
  final Key artboardKey;
  final Key selectionLabelKey;
  final bool selected;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final stage = session.stage.watch(context);
    final background =
        theme.previewBackgroundColor ?? context.theme.colors.background;
    return LayoutBuilder(
      builder: (context, constraints) {
        final selectionMinimumTop = toolbar == null
            ? 18.0
            : _selectionMinimumTop;
        final maxWidth = (constraints.maxWidth - 24).clamp(
          _minimumBoxExtent,
          double.infinity,
        );
        final maxHeight =
            (constraints.maxHeight -
                    selectionMinimumTop -
                    12 -
                    _selectionLabelGap -
                    _selectionLabelReservedHeight)
                .clamp(_minimumBoxExtent, double.infinity);
        // A free canvas is the component's real responsive viewport: resizing
        // it must change the constraints delivered to the consumer widget,
        // never scale an already-laid-out result. Device frames are the sole
        // exception because their fixed logical dimensions may need to be
        // scaled down as one complete preview to fit the Desy canvas.
        final scale = device == null
            ? 1.0
            : math.min(
                1,
                math.min(
                  maxWidth / stage.size.width,
                  maxHeight / stage.size.height,
                ),
              );
        final size = device == null
            ? Size(
                math.max(stage.size.width, _minimumBoxExtent),
                math.max(stage.size.height, _minimumBoxExtent),
              )
            : Size(
                (stage.size.width * scale).clamp(_minimumBoxExtent, maxWidth),
                (stage.size.height * scale).clamp(_minimumBoxExtent, maxHeight),
              );
        final offset = Offset(
          stage.offset.dx.clamp(
            12,
            (constraints.maxWidth - size.width - 12).clamp(12, double.infinity),
          ),
          stage.offset.dy.clamp(
            selectionMinimumTop,
            (constraints.maxHeight -
                    size.height -
                    12 -
                    _selectionLabelGap -
                    _selectionLabelReservedHeight)
                .clamp(selectionMinimumTop, double.infinity),
          ),
        );
        return ColoredBox(
          color: background,
          child: CustomPaint(
            painter: _DottedPreviewPainter(background: background),
            child: Stack(
              key: canvasKey,
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                if (toolbar case final toolbar?)
                  Positioned(top: _detailToolbarTop, left: 12, child: toolbar),
                DesyDragBox(
                  geometry: DesyDragBoxGeometry(rect: offset & size),
                  clampingRect: Rect.fromLTRB(
                    12,
                    selectionMinimumTop,
                    constraints.maxWidth - 12,
                    constraints.maxHeight -
                        12 -
                        _selectionLabelGap -
                        _selectionLabelReservedHeight,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: _minimumBoxExtent,
                    minHeight: _minimumBoxExtent,
                  ),
                  frameKey: artboardKey,
                  resizeHandleKeyPrefix: 'detail-resize',
                  selected: selected,
                  onSelect: onSelect,
                  ignoreChildPointer: true,
                  onDoubleTap: device == null
                      ? null
                      : () => session.selectPreviewDevice(device),
                  geometryResolver: device == null
                      ? null
                      : (geometry, interaction) => DesyDragBoxGeometry(
                          rect: _lockAspectRatio(
                            ratio: device!.screenSize.aspectRatio,
                            current: interaction.initialRect,
                            proposed: geometry.rect,
                            clampingRect: Rect.fromLTRB(
                              12,
                              selectionMinimumTop,
                              constraints.maxWidth - 12,
                              constraints.maxHeight -
                                  12 -
                                  _selectionLabelGap -
                                  _selectionLabelReservedHeight,
                            ),
                          ),
                          flip: geometry.flip,
                        ),
                  onChanged: (geometry) => session.updateStage(
                    stage.copyWith(
                      offset: geometry.rect.topLeft,
                      size: Size(
                        _boundedBoxExtent(geometry.rect.width / scale),
                        _boundedBoxExtent(geometry.rect.height / scale),
                      ),
                    ),
                  ),
                  label: DesyDragBoxLabel(
                    key: selectionLabelKey,
                    size: size,
                    identifier: instanceLabel ?? 'Default',
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.theme.colors.desy.signal.withValues(
                          alpha: .48,
                        ),
                      ),
                    ),
                    child: ClipRect(
                      child: Center(
                        child: device == null
                            ? child
                            : DesyDevicePreview(
                                device: device!,
                                child: ColoredBox(
                                  key: ValueKey(
                                    'detail-device-screen-${device!.name}',
                                  ),
                                  color: background,
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: child,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DottedPreviewPainter extends CustomPainter {
  const _DottedPreviewPainter({required this.background});

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
  bool shouldRepaint(covariant _DottedPreviewPainter oldDelegate) =>
      oldDelegate.background != background;
}

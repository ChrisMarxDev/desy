import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../actions/canvas_action.dart';
import '../controller/object_canvas_controller.dart';
import '../model/canvas_object.dart';
import '../model/canvas_policy.dart';
import '../snapping/canvas_snap.dart';

/// Builds the widget rendered inside an object's real layout constraints.
///
/// The canvas invokes this builder only when that object's effective render
/// state changes, or when the builder itself is replaced.
typedef ObjectCanvasObjectBuilder<T> =
    Widget Function(BuildContext context, CanvasObject<T> object);

/// Builds canvas underlays or overlays from current controller state.
typedef ObjectCanvasOverlayBuilder<T> =
    Widget Function(BuildContext context, ObjectCanvasController<T> controller);

/// Builds an accessibility label for an object.
typedef ObjectCanvasSemanticLabelBuilder<T> =
    String Function(CanvasObject<T> object);

/// Decides whether an object is rendered and directly interactive.
typedef ObjectCanvasVisibility<T> = bool Function(CanvasObject<T> object);

const _dragGestureDevices = {
  PointerDeviceKind.touch,
  PointerDeviceKind.mouse,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
  PointerDeviceKind.unknown,
};

/// Defines the visual treatment of the viewport and canvas interactions.
class ObjectCanvasStyle {
  /// Creates canvas styling with neutral viewport and blue selection defaults.
  const ObjectCanvasStyle({
    this.viewportColor = const Color(0xFFF1F3F5),
    this.canvasColor = const Color(0xFFFFFFFF),
    this.selectionColor = const Color(0xFF2563EB),
    this.guideColor = const Color(0xFFF43F5E),
    this.marqueeFillColor = const Color(0x1F2563EB),
    this.marqueeStrokeColor = const Color(0xFF2563EB),
    this.selectionStrokeWidth = 1.5,
    this.handleSize = 10,
    this.handleTapSize = 24,
  });

  /// The color painted behind the finite canvas.
  final Color viewportColor;

  /// The color exported behind all canvas objects.
  final Color canvasColor;

  /// The color used for selected outlines and transform handles.
  final Color selectionColor;

  /// The color used for active snapping guides.
  final Color guideColor;

  /// The fill color used by marquee selection.
  final Color marqueeFillColor;

  /// The stroke color used by marquee selection.
  final Color marqueeStrokeColor;

  /// The stroke width of selected object outlines in screen pixels.
  final double selectionStrokeWidth;

  /// The visible transform-handle size in screen pixels.
  final double handleSize;

  /// The transform-handle pointer target size in screen pixels.
  final double handleTapSize;
}

/// A finite, controller-owned canvas. It deliberately renders no inspector,
/// toolbar, sidebar, or other UI outside the stage boundary.
class ObjectCanvas<T> extends StatefulWidget {
  /// Creates a canvas whose objects are rendered by [objectBuilder].
  const ObjectCanvas({
    super.key,
    required this.controller,
    required this.objectBuilder,
    this.style = const ObjectCanvasStyle(),
    this.underlayBuilder,
    this.overlayBuilder,
    this.minScale = 0.1,
    this.maxScale = 8,
    this.viewportBoundaryMargin = const EdgeInsets.all(1000),
    this.panEnabled = true,
    this.scaleEnabled = true,
    this.autofocus = false,
    this.semanticLabelBuilder,
    this.objectVisibility,
    this.marqueeSelectionEnabled = true,
    this.duplicateDataBuilder,
  });

  /// Creates a canvas whose application data is already a [Widget].
  ObjectCanvas.widgets({
    super.key,
    required this.controller,
    this.style = const ObjectCanvasStyle(),
    this.underlayBuilder,
    this.overlayBuilder,
    this.minScale = 0.1,
    this.maxScale = 8,
    this.viewportBoundaryMargin = const EdgeInsets.all(1000),
    this.panEnabled = true,
    this.scaleEnabled = true,
    this.autofocus = false,
    this.semanticLabelBuilder,
    this.objectVisibility,
    this.marqueeSelectionEnabled = true,
    this.duplicateDataBuilder,
  }) : assert(T == Widget, 'ObjectCanvas.widgets requires T to be Widget.'),
       objectBuilder = ((context, object) => object.data as Widget);

  /// Owns document, selection, transform, camera, snapping, and history state.
  final ObjectCanvasController<T> controller;

  /// Builds application content for each visible object.
  final ObjectCanvasObjectBuilder<T> objectBuilder;

  /// Defines viewport, stage, selection, guide, and handle colors and sizes.
  final ObjectCanvasStyle style;

  /// Builds non-exported canvas decoration beneath the finite render boundary.
  final ObjectCanvasOverlayBuilder<T>? underlayBuilder;

  /// Builds non-exported UI above the canvas, such as a stage border.
  final ObjectCanvasOverlayBuilder<T>? overlayBuilder;

  /// The smallest permitted camera scale.
  final double minScale;

  /// The largest permitted camera scale.
  final double maxScale;

  /// The panning margin around the finite canvas in viewport coordinates.
  final EdgeInsets viewportBoundaryMargin;

  /// Whether camera panning is enabled.
  final bool panEnabled;

  /// Whether camera pinch and wheel scaling is enabled.
  final bool scaleEnabled;

  /// Whether the canvas requests keyboard focus when mounted.
  final bool autofocus;

  /// Builds object-specific semantics labels.
  final ObjectCanvasSemanticLabelBuilder<T>? semanticLabelBuilder;

  /// Filters rendering, hit testing, marquee selection, and handles.
  final ObjectCanvasVisibility<T>? objectVisibility;

  /// Whether dragging empty canvas space draws a marquee selection rectangle.
  final bool marqueeSelectionEnabled;

  /// Builds application-owned data for keyboard-duplicated objects.
  final CanvasDuplicateDataBuilder<T>? duplicateDataBuilder;

  @override
  State<ObjectCanvas<T>> createState() => _ObjectCanvasState<T>();
}

class _ObjectCanvasState<T> extends State<ObjectCanvas<T>> {
  final GlobalKey _renderBoundaryKey = GlobalKey();
  final GlobalKey _stageKey = GlobalKey();
  final FocusNode _focusNode = FocusNode(debugLabel: 'ObjectCanvas');
  Offset _moveDelta = Offset.zero;
  Offset? _moveStartPointer;
  Rect? _marquee;
  Offset? _marqueeOrigin;
  CanvasSelectionMode _marqueeSelectionMode = CanvasSelectionMode.replace;
  CanvasObjectGeometry? _resizeStartGeometry;
  Offset? _resizeStartPointer;
  CanvasResizeEdges _resizeEdges = const CanvasResizeEdges();
  CanvasObjectGeometry? _rotationStartGeometry;
  Offset? _rotationPivot;
  double? _rotationStartAngle;
  final Map<String, _CanvasObjectItem<T>> _objectItems = {};

  ObjectCanvasController<T> get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerChanged);
    controller.attachRenderBoundary(_renderBoundaryKey);
  }

  @override
  void didUpdateWidget(ObjectCanvas<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, controller)) {
      oldWidget.controller.removeListener(_onControllerChanged);
      oldWidget.controller.detachRenderBoundary(_renderBoundaryKey);
      controller.addListener(_onControllerChanged);
      controller.attachRenderBoundary(_renderBoundaryKey);
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    controller.detachRenderBoundary(_renderBoundaryKey);
    _focusNode.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final canvasClip = controller.overflow == CanvasOverflow.show
        ? Clip.none
        : Clip.hardEdge;
    final snapshots = _objectSnapshots();
    final currentIds = snapshots.keys.toSet();
    _objectItems.removeWhere((id, item) => !currentIds.contains(id));
    return _ObjectCanvasModel<T>(
      controller: controller,
      objectBuilder: widget.objectBuilder,
      semanticLabelBuilder: widget.semanticLabelBuilder,
      snapshots: snapshots,
      child: Focus(
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        onKeyEvent: _onKeyEvent,
        child: ColoredBox(
          color: widget.style.viewportColor,
          child: ClipRect(
            child: InteractiveViewer(
              transformationController: controller.viewportController,
              constrained: false,
              boundaryMargin: widget.viewportBoundaryMargin,
              minScale: widget.minScale,
              maxScale: widget.maxScale,
              panEnabled: widget.panEnabled,
              scaleEnabled: widget.scaleEnabled,
              child: SizedBox.fromSize(
                key: _stageKey,
                size: controller.canvasSize,
                child: Stack(
                  key: const ValueKey('object-canvas-stage-stack'),
                  clipBehavior: canvasClip,
                  children: [
                    if (widget.underlayBuilder case final builder?)
                      Positioned.fill(child: builder(context, controller)),
                    RepaintBoundary(
                      key: _renderBoundaryKey,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        supportedDevices: _dragGestureDevices,
                        onTap: controller.clearSelection,
                        onPanStart: widget.marqueeSelectionEnabled
                            ? _onMarqueeStart
                            : null,
                        onPanUpdate: widget.marqueeSelectionEnabled
                            ? _onMarqueeUpdate
                            : null,
                        onPanEnd: widget.marqueeSelectionEnabled
                            ? _onMarqueeEnd
                            : null,
                        onPanCancel: widget.marqueeSelectionEnabled
                            ? _onMarqueeCancel
                            : null,
                        child: ColoredBox(
                          color: widget.style.canvasColor,
                          child: Stack(
                            key: const ValueKey('object-canvas-content-stack'),
                            clipBehavior: canvasClip,
                            children: [
                              for (final object in controller.objects)
                                if (_isObjectVisible(object))
                                  _objectItemFor(object.id),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(child: _buildEditorOverlay(context)),
                    if (widget.overlayBuilder case final builder?)
                      Positioned.fill(child: builder(context, controller)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, _CanvasObjectSnapshot<T>> _objectSnapshots() {
    final selectedIds = controller.selectedObjectIds;
    return {
      for (final object in controller.objects)
        object.id: _CanvasObjectSnapshot(
          object: object.copyWith(geometry: controller.geometryFor(object.id)),
          capabilities: controller.capabilitiesFor(object.id),
          selected: selectedIds.contains(object.id),
        ),
    };
  }

  _CanvasObjectItem<T> _objectItemFor(String id) => _objectItems.putIfAbsent(
    id,
    () => _CanvasObjectItem<T>(
      key: ValueKey('object-canvas-item-$id'),
      objectId: id,
      owner: this,
    ),
  );

  Widget _buildObject(
    BuildContext context,
    _CanvasObjectSnapshot<T> snapshot,
    Widget content,
    ObjectCanvasSemanticLabelBuilder<T>? semanticLabelBuilder,
  ) {
    final view = snapshot.object;
    final geometry = view.geometry;
    final capabilities = snapshot.capabilities;
    return Positioned(
      key: ValueKey('object-canvas-object-${view.id}'),
      left: geometry.position.dx,
      top: geometry.position.dy,
      width: geometry.size.width,
      height: geometry.size.height,
      child: Transform(
        alignment: geometry.pivot,
        transform: Matrix4.identity()
          ..rotateZ(geometry.rotation)
          ..scaleByDouble(geometry.scale, geometry.scale, 1, 1),
        child: Semantics(
          label: semanticLabelBuilder?.call(view) ?? 'Canvas object ${view.id}',
          selected: snapshot.selected,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            supportedDevices: _dragGestureDevices,
            onTap: () => _selectObject(view.id),
            onPanStart: capabilities.movable
                ? (details) => _onObjectMoveStart(view.id, details)
                : null,
            onPanUpdate: capabilities.movable ? _onObjectMoveUpdate : null,
            onPanEnd: capabilities.movable ? (_) => _onObjectMoveEnd() : null,
            onPanCancel: capabilities.movable ? _onObjectMoveCancel : null,
            child: ClipRect(child: content),
          ),
        ),
      ),
    );
  }

  bool _isObjectVisible(CanvasObject<T> object) =>
      widget.objectVisibility?.call(object) ?? true;

  void _selectObject(String id) {
    _focusNode.requestFocus();
    controller.selectObjects(
      [id],
      mode: _isAdditiveModifierPressed()
          ? CanvasSelectionMode.toggle
          : CanvasSelectionMode.replace,
    );
  }

  void _onObjectMoveStart(String id, DragStartDetails details) {
    _focusNode.requestFocus();
    if (!controller.selectedObjectIds.contains(id)) {
      controller.selectObjects(
        [id],
        mode: _isAdditiveModifierPressed()
            ? CanvasSelectionMode.add
            : CanvasSelectionMode.replace,
      );
    }
    final movingIds = controller.selectedObjectIds
        .where((selectedId) => controller.capabilitiesFor(selectedId).movable)
        .toList(growable: false);
    _moveDelta = Offset.zero;
    _moveStartPointer = details.globalPosition;
    controller.beginTransform(CanvasTransformKind.move, movingIds);
  }

  void _onObjectMoveUpdate(DragUpdateDetails details) {
    final startPointer = _moveStartPointer;
    if (startPointer == null) return;
    _moveDelta =
        (details.globalPosition - startPointer) / controller.viewportScale;
    controller.previewMoveBy(
      _moveDelta,
      screenScale: controller.viewportScale,
      snap: !_isSnapBypassModifierPressed(),
    );
  }

  void _onObjectMoveEnd() {
    _moveStartPointer = null;
    controller.commitTransform();
  }

  void _onObjectMoveCancel() {
    _moveStartPointer = null;
    controller.cancelTransform();
  }

  void _onMarqueeStart(DragStartDetails details) {
    if (details.kind == PointerDeviceKind.trackpad) return;
    _marqueeOrigin = details.localPosition;
    _marquee = Rect.fromPoints(details.localPosition, details.localPosition);
    _marqueeSelectionMode = _isAdditiveModifierPressed()
        ? CanvasSelectionMode.add
        : CanvasSelectionMode.replace;
    setState(() {});
  }

  void _onMarqueeUpdate(DragUpdateDetails details) {
    final origin = _marqueeOrigin;
    if (origin == null) return;
    _marquee = Rect.fromPoints(origin, details.localPosition);
    setState(() {});
  }

  void _onMarqueeEnd(DragEndDetails details) {
    final marquee = _marquee;
    if (marquee != null) {
      final ids = [
        for (final object in controller.objects)
          if (_isObjectVisible(object) &&
              marquee.overlaps(controller.geometryFor(object.id).paintBounds))
            object.id,
      ];
      controller.selectObjects(ids, mode: _marqueeSelectionMode);
    }
    _clearMarquee();
  }

  void _onMarqueeCancel() => _clearMarquee();

  void _clearMarquee() {
    _marqueeOrigin = null;
    _marquee = null;
    if (mounted) setState(() {});
  }

  Widget _buildEditorOverlay(BuildContext context) {
    final selected = controller.selectedObjectIds
        .where((id) => _isObjectVisible(controller.requireObject(id)))
        .toList(growable: false);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ObjectCanvasOverlayPainter<T>(
                controller: controller,
                style: widget.style,
                marquee: _marquee,
                selectedObjectIds: selected.toSet(),
              ),
            ),
          ),
        ),
        if (selected.length == 1) _buildSingleSelectionHandles(selected.single),
      ],
    );
  }

  Widget _buildSingleSelectionHandles(String id) {
    final geometry = controller.geometryFor(id);
    final capabilities = controller.capabilitiesFor(id);
    final canResize =
        controller.transformMode == CanvasTransformMode.layoutResize
        ? capabilities.resizable
        : capabilities.scalable;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (canResize) _buildResizeHandles(id, geometry),
        if (capabilities.rotatable) _buildRotationHandle(id, geometry),
      ],
    );
  }

  Widget _buildResizeHandles(String id, CanvasObjectGeometry geometry) => Stack(
    clipBehavior: Clip.none,
    children: [
      for (final handle in _resizeHandles)
        _buildResizeHandle(id, geometry, handle),
    ],
  );

  Widget _buildResizeHandle(
    String id,
    CanvasObjectGeometry geometry,
    _ResizeHandle handle,
  ) {
    final point = _canvasPointForAlignment(geometry, handle.alignment);
    return Positioned(
      key: ValueKey('object-canvas-resize-$id-${handle.keySuffix}'),
      left: point.dx - widget.style.handleTapSize / 2,
      top: point.dy - widget.style.handleTapSize / 2,
      width: widget.style.handleTapSize,
      height: widget.style.handleTapSize,
      child: MouseRegion(
        cursor: handle.cursorFor(geometry.rotation),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          supportedDevices: _dragGestureDevices,
          onPanStart: (details) => _onResizeStart(id, handle.edges, details),
          onPanUpdate: (details) => _onResizeUpdate(id, details),
          onPanEnd: (_) => _onResizeEnd(),
          onPanCancel: _onResizeCancel,
          child: _CanvasHandle(
            color: widget.style.selectionColor,
            size: widget.style.handleSize,
          ),
        ),
      ),
    );
  }

  void _onResizeStart(
    String id,
    CanvasResizeEdges edges,
    DragStartDetails details,
  ) {
    _resizeStartGeometry = controller.requireObject(id).geometry;
    _resizeStartPointer = details.globalPosition;
    _resizeEdges = edges;
    controller.beginTransform(
      controller.transformMode == CanvasTransformMode.layoutResize
          ? CanvasTransformKind.layoutResize
          : CanvasTransformKind.transformScale,
      [id],
    );
  }

  void _onResizeUpdate(String id, DragUpdateDetails details) {
    final start = _resizeStartGeometry;
    final startPointer = _resizeStartPointer;
    if (start == null || startPointer == null) return;
    final canvasDelta =
        (details.globalPosition - startPointer) / controller.viewportScale;
    final next = controller.transformMode == CanvasTransformMode.layoutResize
        ? _layoutResizeGeometryForDelta(id, start, _resizeEdges, canvasDelta)
        : _scaleGeometryForDelta(id, start, _resizeEdges, canvasDelta);
    controller.previewGeometries([
      CanvasGeometryValue(objectId: id, geometry: next),
    ]);
  }

  void _onResizeEnd() {
    _clearResizeState();
    controller.commitTransform();
  }

  void _onResizeCancel() {
    _clearResizeState();
    controller.cancelTransform();
  }

  void _clearResizeState() {
    _resizeStartGeometry = null;
    _resizeStartPointer = null;
  }

  CanvasObjectGeometry _layoutResizeGeometryForDelta(
    String id,
    CanvasObjectGeometry start,
    CanvasResizeEdges edges,
    Offset canvasDelta,
  ) {
    final localDelta =
        _rotateOffset(canvasDelta, -start.rotation) / start.scale;
    final constraints = controller.constraintsFor(id);
    final preserveAspectRatio = _isAspectRatioModifierPressed();
    final centered = _isCenteredResizeModifierPressed();
    var desired = _layoutResizeGeometryForLocalDelta(
      start,
      edges,
      localDelta,
      constraints: constraints,
      preserveAspectRatio: preserveAspectRatio,
      centered: centered,
    );
    if (start.rotation.abs() < 0.0001) {
      final snappedRect = controller.resolveResizePreview(
        id,
        desired.layoutBounds,
        edges: edges,
        screenScale: controller.viewportScale,
        snap: !_isSnapBypassModifierPressed(),
      );
      if (preserveAspectRatio || centered) {
        final correctedDelta = Offset(
          localDelta.dx +
              (edges.left
                      ? snappedRect.left - desired.layoutBounds.left
                      : edges.right
                      ? snappedRect.right - desired.layoutBounds.right
                      : 0) /
                  start.scale,
          localDelta.dy +
              (edges.top
                      ? snappedRect.top - desired.layoutBounds.top
                      : edges.bottom
                      ? snappedRect.bottom - desired.layoutBounds.bottom
                      : 0) /
                  start.scale,
        );
        desired = _layoutResizeGeometryForLocalDelta(
          start,
          edges,
          correctedDelta,
          constraints: constraints,
          preserveAspectRatio: preserveAspectRatio,
          centered: centered,
        );
      } else {
        desired = start.copyWith(
          position: snappedRect.topLeft,
          size: snappedRect.size,
        );
      }
    }
    return _constrainResizeToCanvas(start, desired);
  }

  CanvasObjectGeometry _layoutResizeGeometryForLocalDelta(
    CanvasObjectGeometry start,
    CanvasResizeEdges edges,
    Offset localDelta, {
    required CanvasObjectConstraints constraints,
    required bool preserveAspectRatio,
    required bool centered,
  }) {
    final multiplier = centered ? 2.0 : 1.0;
    late final Size nextSize;
    if (preserveAspectRatio) {
      final direction = Offset(
        edges.left
            ? -start.size.width
            : edges.right
            ? start.size.width
            : 0,
        edges.top
            ? -start.size.height
            : edges.bottom
            ? start.size.height
            : 0,
      );
      final lengthSquared =
          direction.dx * direction.dx + direction.dy * direction.dy;
      var scale = lengthSquared == 0
          ? 1.0
          : 1 +
                multiplier *
                    (localDelta.dx * direction.dx +
                        localDelta.dy * direction.dy) /
                    lengthSquared;
      final minimumScale = math.max(
        constraints.minSize.width / start.size.width,
        constraints.minSize.height / start.size.height,
      );
      final maximumScale = math.min(
        constraints.maxSize.width / start.size.width,
        constraints.maxSize.height / start.size.height,
      );
      scale = scale.clamp(minimumScale, maximumScale).toDouble();
      nextSize = start.size * scale;
    } else {
      final widthDelta = edges.left
          ? -localDelta.dx
          : edges.right
          ? localDelta.dx
          : 0;
      final heightDelta = edges.top
          ? -localDelta.dy
          : edges.bottom
          ? localDelta.dy
          : 0;
      nextSize = constraints.constrain(
        Size(
          start.size.width + widthDelta * multiplier,
          start.size.height + heightDelta * multiplier,
        ),
      );
    }

    final fixedStart = centered
        ? Offset(start.size.width / 2, start.size.height / 2)
        : Offset(
            edges.left
                ? start.size.width
                : edges.right
                ? 0
                : start.size.width / 2,
            edges.top
                ? start.size.height
                : edges.bottom
                ? 0
                : start.size.height / 2,
          );
    final fixedNext = centered
        ? Offset(nextSize.width / 2, nextSize.height / 2)
        : Offset(
            edges.left
                ? nextSize.width
                : edges.right
                ? 0
                : nextSize.width / 2,
            edges.top
                ? nextSize.height
                : edges.bottom
                ? 0
                : nextSize.height / 2,
          );
    final fixedCanvas = _canvasPointForLocal(start, fixedStart);
    final nextPivot = _localPivot(start.pivot, nextSize);
    final transformedFixed =
        nextPivot +
        _rotateOffset((fixedNext - nextPivot) * start.scale, start.rotation);
    return start.copyWith(
      position: fixedCanvas - transformedFixed,
      size: nextSize,
    );
  }

  CanvasObjectGeometry _scaleGeometryForDelta(
    String id,
    CanvasObjectGeometry start,
    CanvasResizeEdges edges,
    Offset canvasDelta,
  ) {
    final axisDelta = _rotateOffset(canvasDelta, -start.rotation);
    final centered = _isCenteredResizeModifierPressed();
    final direction = Offset(
      edges.left
          ? -start.size.width * start.scale
          : edges.right
          ? start.size.width * start.scale
          : 0,
      edges.top
          ? -start.size.height * start.scale
          : edges.bottom
          ? start.size.height * start.scale
          : 0,
    );
    final lengthSquared =
        direction.dx * direction.dx + direction.dy * direction.dy;
    final factor = lengthSquared == 0
        ? 1.0
        : 1 +
              (centered ? 2 : 1) *
                  (axisDelta.dx * direction.dx + axisDelta.dy * direction.dy) /
                  lengthSquared;
    final minimumScale = math.max(
      0.001,
      math.max(8 / start.size.width, 8 / start.size.height),
    );
    var nextScale = math.max(minimumScale, start.scale * factor);
    var desired = _scaleGeometryForValue(
      start,
      edges,
      nextScale,
      centered: centered,
    );
    if (start.rotation.abs() < 0.0001) {
      final snappedRect = controller.resolveResizePreview(
        id,
        desired.paintBounds,
        edges: edges,
        screenScale: controller.viewportScale,
        snap: !_isSnapBypassModifierPressed(),
      );
      if (centered) {
        final center = desired.paintBounds.center;
        nextScale = math.max(
          minimumScale,
          edges.left
              ? (center.dx - snappedRect.left) * 2 / start.size.width
              : edges.right
              ? (snappedRect.right - center.dx) * 2 / start.size.width
              : edges.top
              ? (center.dy - snappedRect.top) * 2 / start.size.height
              : (snappedRect.bottom - center.dy) * 2 / start.size.height,
        );
      } else {
        nextScale = math.max(
          minimumScale,
          edges.left || edges.right
              ? snappedRect.width / start.size.width
              : snappedRect.height / start.size.height,
        );
      }
      desired = _scaleGeometryForValue(
        start,
        edges,
        nextScale,
        centered: centered,
      );
    }
    return _constrainResizeToCanvas(start, desired);
  }

  CanvasObjectGeometry _scaleGeometryForValue(
    CanvasObjectGeometry start,
    CanvasResizeEdges edges,
    double scale, {
    required bool centered,
  }) {
    final fixedLocal = centered
        ? Offset(start.size.width / 2, start.size.height / 2)
        : Offset(
            edges.left
                ? start.size.width
                : edges.right
                ? 0
                : start.size.width / 2,
            edges.top
                ? start.size.height
                : edges.bottom
                ? 0
                : start.size.height / 2,
          );
    final fixedCanvas = _canvasPointForLocal(start, fixedLocal);
    final pivot = _localPivot(start.pivot, start.size);
    final transformedFixed =
        pivot + _rotateOffset((fixedLocal - pivot) * scale, start.rotation);
    return start.copyWith(
      position: fixedCanvas - transformedFixed,
      scale: scale,
    );
  }

  CanvasObjectGeometry _constrainResizeToCanvas(
    CanvasObjectGeometry start,
    CanvasObjectGeometry desired,
  ) {
    if (controller.overflow != CanvasOverflow.deny) return desired;
    final canvasBounds = Offset.zero & controller.canvasSize;
    if (_containsPaintBounds(canvasBounds, desired)) return desired;
    if (!_containsPaintBounds(canvasBounds, start)) return desired;

    var lower = 0.0;
    var upper = 1.0;
    for (var index = 0; index < 24; index++) {
      final amount = (lower + upper) / 2;
      final candidate = start.copyWith(
        position: Offset.lerp(start.position, desired.position, amount),
        size: Size.lerp(start.size, desired.size, amount),
        scale: _lerpDouble(start.scale, desired.scale, amount),
      );
      if (_containsPaintBounds(canvasBounds, candidate)) {
        lower = amount;
      } else {
        upper = amount;
      }
    }
    return start.copyWith(
      position: Offset.lerp(start.position, desired.position, lower),
      size: Size.lerp(start.size, desired.size, lower),
      scale: _lerpDouble(start.scale, desired.scale, lower),
    );
  }

  static bool _containsPaintBounds(
    Rect canvasBounds,
    CanvasObjectGeometry geometry,
  ) {
    final bounds = geometry.paintBounds;
    return bounds.left >= canvasBounds.left &&
        bounds.top >= canvasBounds.top &&
        bounds.right <= canvasBounds.right &&
        bounds.bottom <= canvasBounds.bottom;
  }

  static Offset _canvasPointForAlignment(
    CanvasObjectGeometry geometry,
    Alignment alignment,
  ) => _canvasPointForLocal(
    geometry,
    Offset(
      (alignment.x + 1) * geometry.size.width / 2,
      (alignment.y + 1) * geometry.size.height / 2,
    ),
  );

  static Offset _canvasPointForLocal(
    CanvasObjectGeometry geometry,
    Offset local,
  ) {
    final pivot = _localPivot(geometry.pivot, geometry.size);
    return geometry.position +
        pivot +
        _rotateOffset((local - pivot) * geometry.scale, geometry.rotation);
  }

  static Offset _localPivot(Alignment pivot, Size size) =>
      Offset((pivot.x + 1) * size.width / 2, (pivot.y + 1) * size.height / 2);

  static Offset _rotateOffset(Offset value, double angle) {
    final cosine = math.cos(angle);
    final sine = math.sin(angle);
    return Offset(
      value.dx * cosine - value.dy * sine,
      value.dx * sine + value.dy * cosine,
    );
  }

  static double _lerpDouble(double start, double end, double amount) =>
      start + (end - start) * amount;

  Widget _buildRotationHandle(String id, CanvasObjectGeometry geometry) {
    final topCenter = _canvasPointForAlignment(geometry, Alignment.topCenter);
    final center = _canvasPointForAlignment(geometry, Alignment.center);
    final outward = topCenter - center;
    final distance = outward.distance;
    final handleCenter = distance == 0
        ? topCenter - const Offset(0, 36)
        : topCenter + outward / distance * 36;
    return Positioned(
      key: ValueKey('object-canvas-rotate-$id'),
      left: handleCenter.dx - widget.style.handleTapSize / 2,
      top: handleCenter.dy - widget.style.handleTapSize / 2,
      width: widget.style.handleTapSize,
      height: widget.style.handleTapSize,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          supportedDevices: _dragGestureDevices,
          onPanStart: (details) => _onRotationStart(id, details),
          onPanUpdate: (details) => _onRotationUpdate(id, details),
          onPanEnd: (_) => _onRotationEnd(),
          onPanCancel: _onRotationCancel,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: widget.style.canvasColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.style.selectionColor,
                  width: widget.style.selectionStrokeWidth,
                ),
              ),
              child: SizedBox.square(dimension: widget.style.handleSize),
            ),
          ),
        ),
      ),
    );
  }

  void _onRotationStart(String id, DragStartDetails details) {
    final geometry = controller.requireObject(id).geometry;
    final pivot = Offset(
      geometry.position.dx + (geometry.pivot.x + 1) * geometry.size.width / 2,
      geometry.position.dy + (geometry.pivot.y + 1) * geometry.size.height / 2,
    );
    final pointer = _globalToStage(details.globalPosition);
    _rotationStartGeometry = geometry;
    _rotationPivot = pivot;
    _rotationStartAngle = math.atan2(
      pointer.dy - pivot.dy,
      pointer.dx - pivot.dx,
    );
    controller.beginTransform(CanvasTransformKind.rotate, [id]);
  }

  void _onRotationUpdate(String id, DragUpdateDetails details) {
    final start = _rotationStartGeometry;
    final pivot = _rotationPivot;
    final startAngle = _rotationStartAngle;
    if (start == null || pivot == null || startAngle == null) return;
    final pointer = _globalToStage(details.globalPosition);
    final angle = math.atan2(pointer.dy - pivot.dy, pointer.dx - pivot.dx);
    controller.previewGeometries([
      CanvasGeometryValue(
        objectId: id,
        geometry: start.copyWith(rotation: start.rotation + angle - startAngle),
      ),
    ]);
  }

  void _onRotationEnd() {
    _clearRotationState();
    controller.commitTransform();
  }

  void _onRotationCancel() {
    _clearRotationState();
    controller.cancelTransform();
  }

  void _clearRotationState() {
    _rotationStartGeometry = null;
    _rotationPivot = null;
    _rotationStartAngle = null;
  }

  Offset _globalToStage(Offset globalPosition) {
    final renderObject = _stageKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return globalPosition;
    return renderObject.globalToLocal(globalPosition);
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    final command = keyboard.isControlPressed || keyboard.isMetaPressed;
    if (command && event.logicalKey == LogicalKeyboardKey.keyZ) {
      if (keyboard.isShiftPressed) {
        controller.redo();
      } else {
        controller.undo();
      }
      return KeyEventResult.handled;
    }
    if (command && event.logicalKey == LogicalKeyboardKey.keyD) {
      controller.duplicateObjects(
        controller.selectedObjectIds.toList(),
        dataBuilder: widget.duplicateDataBuilder,
      );
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (controller.hasActiveTransform) {
        controller.cancelTransform();
      } else {
        controller.clearSelection();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      controller.removeObjects(controller.selectedObjectIds.toList());
      return KeyEventResult.handled;
    }
    final step = keyboard.isShiftPressed ? 10.0 : 1.0;
    final delta = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => Offset(-step, 0),
      LogicalKeyboardKey.arrowRight => Offset(step, 0),
      LogicalKeyboardKey.arrowUp => Offset(0, -step),
      LogicalKeyboardKey.arrowDown => Offset(0, step),
      _ => null,
    };
    if (delta == null) return KeyEventResult.ignored;
    final ids = controller.selectedObjectIds
        .where((id) => controller.capabilitiesFor(id).movable)
        .toList(growable: false);
    if (ids.isNotEmpty) {
      controller.moveObjectsBy(
        ids,
        delta,
        label: ids.length == 1 ? 'Nudge object' : 'Nudge objects',
      );
    }
    return KeyEventResult.handled;
  }

  static bool _isAdditiveModifierPressed() {
    final keyboard = HardwareKeyboard.instance;
    return keyboard.isShiftPressed ||
        keyboard.isControlPressed ||
        keyboard.isMetaPressed;
  }

  static bool _isSnapBypassModifierPressed() =>
      HardwareKeyboard.instance.isAltPressed;

  static bool _isAspectRatioModifierPressed() =>
      HardwareKeyboard.instance.isShiftPressed;

  static bool _isCenteredResizeModifierPressed() {
    final keyboard = HardwareKeyboard.instance;
    return keyboard.isControlPressed || keyboard.isMetaPressed;
  }
}

class _CanvasObjectItem<T> extends StatelessWidget {
  _CanvasObjectItem({super.key, required this.objectId, required this.owner})
    : content = _CanvasObjectContent<T>(objectId: objectId, owner: owner);

  final String objectId;
  final _ObjectCanvasState<T> owner;
  final _CanvasObjectContent<T> content;

  @override
  Widget build(BuildContext context) {
    const aspect = _CanvasObjectAspect.wrapper;
    final model = _ObjectCanvasModel.of<T>(
      context,
      _CanvasObjectDependency(objectId, aspect),
    );
    return owner._buildObject(
      context,
      model.snapshotFor(objectId),
      content,
      model.semanticLabelBuilder,
    );
  }
}

class _CanvasObjectContent<T> extends StatelessWidget {
  const _CanvasObjectContent({required this.objectId, required this.owner});

  final String objectId;
  final _ObjectCanvasState<T> owner;

  @override
  Widget build(BuildContext context) {
    final model = _ObjectCanvasModel.of<T>(
      context,
      _CanvasObjectDependency(objectId, _CanvasObjectAspect.content),
    );
    return model.objectBuilder(context, model.snapshotFor(objectId).object);
  }
}

enum _CanvasObjectAspect { wrapper, content }

class _CanvasObjectDependency {
  const _CanvasObjectDependency(this.objectId, this.aspect);

  final String objectId;
  final _CanvasObjectAspect aspect;

  @override
  bool operator ==(Object other) =>
      other is _CanvasObjectDependency &&
      other.objectId == objectId &&
      other.aspect == aspect;

  @override
  int get hashCode => Object.hash(objectId, aspect);
}

class _ObjectCanvasModel<T> extends InheritedModel<_CanvasObjectDependency> {
  const _ObjectCanvasModel({
    required this.controller,
    required this.objectBuilder,
    required this.semanticLabelBuilder,
    required this.snapshots,
    required super.child,
  });

  final ObjectCanvasController<T> controller;
  final ObjectCanvasObjectBuilder<T> objectBuilder;
  final ObjectCanvasSemanticLabelBuilder<T>? semanticLabelBuilder;
  final Map<String, _CanvasObjectSnapshot<T>> snapshots;

  static _ObjectCanvasModel<S> of<S>(
    BuildContext context,
    _CanvasObjectDependency dependency,
  ) {
    final model = InheritedModel.inheritFrom<_ObjectCanvasModel<S>>(
      context,
      aspect: dependency,
    );
    assert(model != null, 'Canvas object must be below its canvas model.');
    return model!;
  }

  _CanvasObjectSnapshot<T> snapshotFor(String objectId) {
    final snapshot = snapshots[objectId];
    assert(snapshot != null, 'Unknown canvas object $objectId.');
    return snapshot!;
  }

  @override
  bool updateShouldNotify(_ObjectCanvasModel<T> oldWidget) {
    if (!identical(controller, oldWidget.controller) ||
        !identical(objectBuilder, oldWidget.objectBuilder) ||
        !identical(semanticLabelBuilder, oldWidget.semanticLabelBuilder) ||
        snapshots.length != oldWidget.snapshots.length) {
      return true;
    }
    return snapshots.entries.any(
      (entry) => entry.value != oldWidget.snapshots[entry.key],
    );
  }

  @override
  bool updateShouldNotifyDependent(
    _ObjectCanvasModel<T> oldWidget,
    Set<_CanvasObjectDependency> dependencies,
  ) {
    if (!identical(controller, oldWidget.controller)) {
      return true;
    }
    return dependencies.any((dependency) {
      if (dependency.aspect == _CanvasObjectAspect.content &&
          !identical(objectBuilder, oldWidget.objectBuilder)) {
        return true;
      }
      if (dependency.aspect == _CanvasObjectAspect.wrapper &&
          !identical(semanticLabelBuilder, oldWidget.semanticLabelBuilder)) {
        return true;
      }
      final current = snapshots[dependency.objectId];
      final previous = oldWidget.snapshots[dependency.objectId];
      return switch (dependency.aspect) {
        _CanvasObjectAspect.wrapper => current != previous,
        _CanvasObjectAspect.content =>
          current == null ||
              previous == null ||
              !current.hasSameContentAs(previous),
      };
    });
  }
}

class _CanvasObjectSnapshot<T> {
  const _CanvasObjectSnapshot({
    required this.object,
    required this.capabilities,
    required this.selected,
  });

  final CanvasObject<T> object;
  final CanvasObjectCapabilities capabilities;
  final bool selected;

  bool hasSameContentAs(_CanvasObjectSnapshot<T> other) =>
      other.object.id == object.id &&
      other.object.data == object.data &&
      other.object.geometry == object.geometry &&
      other.object.constraints == object.constraints &&
      other.object.capabilities == object.capabilities;

  @override
  bool operator ==(Object other) =>
      other is _CanvasObjectSnapshot<T> &&
      hasSameContentAs(other) &&
      _sameCapabilities(other.capabilities, capabilities) &&
      other.selected == selected;

  @override
  int get hashCode => Object.hash(
    object.id,
    object.data,
    object.geometry,
    object.constraints,
    object.capabilities,
    capabilities.selectable,
    capabilities.movable,
    capabilities.resizable,
    capabilities.scalable,
    capabilities.rotatable,
    selected,
  );

  static bool _sameCapabilities(
    CanvasObjectCapabilities first,
    CanvasObjectCapabilities second,
  ) =>
      first.selectable == second.selectable &&
      first.movable == second.movable &&
      first.resizable == second.resizable &&
      first.scalable == second.scalable &&
      first.rotatable == second.rotatable;
}

const _resizeHandles = <_ResizeHandle>[
  _ResizeHandle(
    keySuffix: 'top-left',
    alignment: Alignment.topLeft,
    edges: CanvasResizeEdges(left: true, top: true),
  ),
  _ResizeHandle(
    keySuffix: 'top',
    alignment: Alignment.topCenter,
    edges: CanvasResizeEdges(top: true),
  ),
  _ResizeHandle(
    keySuffix: 'top-right',
    alignment: Alignment.topRight,
    edges: CanvasResizeEdges(top: true, right: true),
  ),
  _ResizeHandle(
    keySuffix: 'right',
    alignment: Alignment.centerRight,
    edges: CanvasResizeEdges(right: true),
  ),
  _ResizeHandle(
    keySuffix: 'bottom-right',
    alignment: Alignment.bottomRight,
    edges: CanvasResizeEdges(right: true, bottom: true),
  ),
  _ResizeHandle(
    keySuffix: 'bottom',
    alignment: Alignment.bottomCenter,
    edges: CanvasResizeEdges(bottom: true),
  ),
  _ResizeHandle(
    keySuffix: 'bottom-left',
    alignment: Alignment.bottomLeft,
    edges: CanvasResizeEdges(left: true, bottom: true),
  ),
  _ResizeHandle(
    keySuffix: 'left',
    alignment: Alignment.centerLeft,
    edges: CanvasResizeEdges(left: true),
  ),
];

class _ResizeHandle {
  const _ResizeHandle({
    required this.keySuffix,
    required this.alignment,
    required this.edges,
  });

  final String keySuffix;
  final Alignment alignment;
  final CanvasResizeEdges edges;

  MouseCursor cursorFor(double rotation) {
    var angle = math.atan2(alignment.y, alignment.x) + rotation;
    while (angle < 0) {
      angle += math.pi;
    }
    angle %= math.pi;
    if (angle < math.pi / 8 || angle >= math.pi * 7 / 8) {
      return SystemMouseCursors.resizeLeftRight;
    }
    if (angle < math.pi * 3 / 8) {
      return SystemMouseCursors.resizeUpLeftDownRight;
    }
    if (angle < math.pi * 5 / 8) {
      return SystemMouseCursors.resizeUpDown;
    }
    return SystemMouseCursors.resizeUpRightDownLeft;
  }
}

class _CanvasHandle extends StatelessWidget {
  const _CanvasHandle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Center(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        border: Border.all(color: color, width: 1.5),
      ),
      child: SizedBox.square(dimension: size),
    ),
  );
}

class _ObjectCanvasOverlayPainter<T> extends CustomPainter {
  const _ObjectCanvasOverlayPainter({
    required this.controller,
    required this.style,
    required this.marquee,
    required this.selectedObjectIds,
  });

  final ObjectCanvasController<T> controller;
  final ObjectCanvasStyle style;
  final Rect? marquee;
  final Set<String> selectedObjectIds;

  @override
  void paint(Canvas canvas, Size size) {
    final selectionPaint = Paint()
      ..color = style.selectionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.selectionStrokeWidth;
    for (final id in selectedObjectIds) {
      final corners = controller.geometryFor(id).paintCorners;
      final path = Path()..moveTo(corners.first.dx, corners.first.dy);
      for (final corner in corners.skip(1)) {
        path.lineTo(corner.dx, corner.dy);
      }
      path.close();
      canvas.drawPath(path, selectionPaint);
    }

    final guidePaint = Paint()
      ..color = style.guideColor
      ..strokeWidth = 1;
    for (final guide in controller.snapGuides) {
      if (guide.axis == CanvasSnapAxis.x) {
        canvas.drawLine(
          Offset(guide.coordinate, guide.start),
          Offset(guide.coordinate, guide.end),
          guidePaint,
        );
      } else {
        canvas.drawLine(
          Offset(guide.start, guide.coordinate),
          Offset(guide.end, guide.coordinate),
          guidePaint,
        );
      }
    }

    if (marquee case final rect?) {
      canvas.drawRect(rect, Paint()..color = style.marqueeFillColor);
      canvas.drawRect(
        rect,
        Paint()
          ..color = style.marqueeStrokeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ObjectCanvasOverlayPainter<T> oldDelegate) =>
      true;
}

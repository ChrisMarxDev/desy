// Internal ephemeral scene model for the screenshot-builder extension.
// ignore_for_file: public_member_api_docs

import 'dart:collection';
import 'dart:math' as math;

import 'package:desy_bench/desy_bench.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:object_canvas/object_canvas.dart';

abstract class DesyScreenshotLayer {
  DesyScreenshotLayer({
    required this.id,
    required this.name,
    this.hidden = false,
  });

  final String id;
  String name;
  bool hidden;

  String get kindLabel;
}

final class DesyScreenshotWidgetLayer extends DesyScreenshotLayer {
  DesyScreenshotWidgetLayer({
    required super.id,
    required super.name,
    required this.instanceId,
    required Map<String, Object> knobValues,
    this.awaitingNaturalSize = false,
  }) : knobValues = Map.of(knobValues);

  final String instanceId;
  final Map<String, Object> knobValues;
  bool awaitingNaturalSize;

  @override
  String get kindLabel => 'Widget';
}

final class DesyScreenshotImageLayer extends DesyScreenshotLayer {
  DesyScreenshotImageLayer({
    required super.id,
    required super.name,
    required this.bytes,
  });

  final Uint8List bytes;

  @override
  String get kindLabel => 'Image';
}

final class DesyScreenshotTextLayer extends DesyScreenshotLayer {
  DesyScreenshotTextLayer({
    required super.id,
    required super.name,
    required this.text,
    this.typographyId,
    this.colorId,
  });

  String text;
  String? typographyId;
  String? colorId;

  @override
  String get kindLabel => 'Text';
}

class DesyScreenshotSceneController extends ChangeNotifier {
  DesyScreenshotSceneController({
    Size canvasSize = const Size(1200, 630),
    Color? backgroundColor,
    required String themeId,
  }) : _backgroundColor = backgroundColor,
       _themeId = themeId {
    canvas = ObjectCanvasController<DesyScreenshotLayer>(
      canvasSize: canvasSize,
      defaults: const CanvasObjectDefaults(
        constraints: CanvasObjectConstraints(
          minSize: Size.square(minimumLayerExtent),
          maxSize: Size.square(maximumCanvasExtent),
        ),
      ),
    )..addListener(_handleCanvasChanged);
  }

  static const minimumCanvasExtent = 64.0;
  static const maximumCanvasExtent = 8192.0;
  static const minimumLayerExtent = 24.0;
  static const defaultWidgetSize = Size(240, 120);
  static const defaultTextSize = Size(360, 96);

  late final ObjectCanvasController<DesyScreenshotLayer> canvas;
  var _nextLayer = 0;
  Color? _backgroundColor;
  String _themeId;

  UnmodifiableListView<DesyScreenshotLayer> get layers =>
      UnmodifiableListView(canvas.objects.map((object) => object.data));

  Size get canvasSize => canvas.canvasSize;
  Color? get backgroundColor => _backgroundColor;
  String get themeId => _themeId;
  String? get selectedId => canvas.selectedObjectIds.firstOrNull;
  DesyScreenshotLayer? get selectedLayer => layerById(selectedId);

  DesyScreenshotLayer? layerById(String? id) {
    if (id == null) return null;
    for (final object in canvas.objects) {
      if (object.id == id) return object.data;
    }
    return null;
  }

  CanvasObjectGeometry geometryFor(String id) => canvas.geometryFor(id);

  Rect rectFor(String id) => geometryFor(id).paintBounds;

  Size logicalSizeFor(String id) => geometryFor(id).size;

  double scaleFor(String id) => geometryFor(id).scale;

  void select(String? id) {
    if (id == null) {
      canvas.clearSelection();
    } else if (layerById(id) != null && !layerById(id)!.hidden) {
      canvas.setSelectedObjects([id]);
    }
  }

  String addWidget(
    DesyRegisteredComponentInstance instance, {
    Offset? position,
  }) {
    final declaredSize = instance.component.defaultSize;
    final size = declaredSize ?? defaultWidgetSize;
    final id = _newId('widget');
    _addLayer(
      DesyScreenshotWidgetLayer(
        id: id,
        name: '${instance.componentName} · ${instance.name}',
        instanceId: instance.id,
        knobValues: instance.component.valuesFor(instance.instanceId),
        awaitingNaturalSize: declaredSize == null,
      ),
      size: size,
      position: position,
    );
    return id;
  }

  String addImage({
    required Uint8List bytes,
    required String name,
    required Size naturalSize,
    Offset? position,
  }) {
    final id = _newId('image');
    _addLayer(
      DesyScreenshotImageLayer(id: id, name: name, bytes: bytes),
      size: _fitInitialImageSize(naturalSize),
      position: position,
    );
    return id;
  }

  String addText({
    String text = 'Your text',
    String? typographyId,
    String? colorId,
    Offset? position,
  }) {
    final id = _newId('text');
    _addLayer(
      DesyScreenshotTextLayer(
        id: id,
        name: 'Text',
        text: text,
        typographyId: typographyId,
        colorId: colorId,
      ),
      size: defaultTextSize,
      position: position,
    );
    return id;
  }

  void setNaturalWidgetSize(String id, Size logicalSize) {
    final layer = layerById(id);
    if (layer is! DesyScreenshotWidgetLayer ||
        !layer.awaitingNaturalSize ||
        logicalSize.isEmpty ||
        !logicalSize.width.isFinite ||
        !logicalSize.height.isFinite) {
      return;
    }
    layer.awaitingNaturalSize = false;
    final geometry = canvas.requireObject(id).geometry;
    canvas.updateGeometries([
      CanvasGeometryValue(
        objectId: id,
        geometry: geometry.copyWith(size: _fitSizeToCanvas(logicalSize)),
      ),
    ], label: 'Measure widget');
  }

  void resize(String id, Size logicalSize) {
    final layer = layerById(id);
    if (layer == null) return;
    if (layer is DesyScreenshotWidgetLayer) {
      layer.awaitingNaturalSize = false;
    }
    final geometry = canvas.requireObject(id).geometry;
    canvas.updateGeometries([
      CanvasGeometryValue(
        objectId: id,
        geometry: geometry.copyWith(size: _fitSizeToCanvas(logicalSize)),
      ),
    ], label: 'Resize layer');
  }

  void setWidgetScale(String id, double scale) {
    final layer = layerById(id);
    if (layer is! DesyScreenshotWidgetLayer) return;
    final geometry = canvas.requireObject(id).geometry;
    final next = scale.clamp(.1, 2.0);
    if (next == geometry.scale) return;
    canvas.updateGeometries([
      CanvasGeometryValue(
        objectId: id,
        geometry: _fitGeometryToCanvas(geometry.copyWith(scale: next)),
      ),
    ], label: 'Scale widget');
  }

  void setKnob(String id, String knobId, Object value) {
    final layer = layerById(id);
    if (layer is! DesyScreenshotWidgetLayer) return;
    layer.knobValues[knobId] = value;
    notifyListeners();
  }

  void setText(String id, String value) {
    final layer = layerById(id);
    if (layer is! DesyScreenshotTextLayer || layer.text == value) return;
    layer.text = value;
    notifyListeners();
  }

  void setTextTypography(String id, String? typographyId) {
    final layer = layerById(id);
    if (layer is! DesyScreenshotTextLayer ||
        layer.typographyId == typographyId) {
      return;
    }
    layer.typographyId = typographyId;
    notifyListeners();
  }

  void setTextColor(String id, String? colorId) {
    final layer = layerById(id);
    if (layer is! DesyScreenshotTextLayer || layer.colorId == colorId) return;
    layer.colorId = colorId;
    notifyListeners();
  }

  void toggleHidden(String id) {
    final layer = layerById(id);
    if (layer == null) return;
    layer.hidden = !layer.hidden;
    if (layer.hidden && selectedId == id) canvas.clearSelection();
    notifyListeners();
  }

  void moveForward(String id) => canvas.moveObjectsForward([id]);

  void moveBackward(String id) => canvas.moveObjectsBackward([id]);

  void remove(String id) => canvas.removeObjects([id]);

  void setCanvasSize(Size size) {
    final next = Size(
      size.width.clamp(minimumCanvasExtent, maximumCanvasExtent),
      size.height.clamp(minimumCanvasExtent, maximumCanvasExtent),
    );
    canvas.setCanvasSize(next);
  }

  void setBackgroundColor(Color? color) {
    if (_backgroundColor == color) return;
    _backgroundColor = color;
    notifyListeners();
  }

  void setTheme(String themeId, {Color? defaultBackground}) {
    if (_themeId == themeId) return;
    _themeId = themeId;
    _backgroundColor = defaultBackground;
    notifyListeners();
  }

  void _addLayer(
    DesyScreenshotLayer layer, {
    required Size size,
    Offset? position,
  }) {
    final fitted = _fitSizeToCanvas(size);
    final offset =
        position ??
        Offset(
          (canvasSize.width - fitted.width) / 2,
          (canvasSize.height - fitted.height) / 2,
        );
    final rect = _clampRect(offset & fitted);
    canvas.addObjects([
      CanvasObject<DesyScreenshotLayer>(
        id: layer.id,
        data: layer,
        geometry: CanvasObjectGeometry(position: rect.topLeft, size: rect.size),
      ),
    ]);
    canvas.setSelectedObjects([layer.id]);
  }

  String _newId(String prefix) => '$prefix-${_nextLayer++}';

  Size _fitInitialImageSize(Size naturalSize) {
    if (naturalSize.isEmpty ||
        !naturalSize.width.isFinite ||
        !naturalSize.height.isFinite) {
      return const Size(320, 240);
    }
    final maximum = Size(canvasSize.width * .6, canvasSize.height * .6);
    final scale = math.min(
      1,
      math.min(
        maximum.width / naturalSize.width,
        maximum.height / naturalSize.height,
      ),
    );
    return Size(naturalSize.width * scale, naturalSize.height * scale);
  }

  Size _fitSizeToCanvas(Size size) => Size(
    size.width.clamp(
      minimumLayerExtent,
      canvasSize.width.clamp(minimumLayerExtent, maximumCanvasExtent),
    ),
    size.height.clamp(
      minimumLayerExtent,
      canvasSize.height.clamp(minimumLayerExtent, maximumCanvasExtent),
    ),
  );

  Rect _clampRect(Rect rect) {
    final size = _fitSizeToCanvas(rect.size);
    return Rect.fromLTWH(
      rect.left.clamp(0, math.max(0, canvasSize.width - size.width)),
      rect.top.clamp(0, math.max(0, canvasSize.height - size.height)),
      size.width,
      size.height,
    );
  }

  CanvasObjectGeometry _fitGeometryToCanvas(CanvasObjectGeometry geometry) {
    final bounds = geometry.paintBounds;
    var correction = Offset.zero;
    if (bounds.left < 0) correction += Offset(-bounds.left, 0);
    if (bounds.top < 0) correction += Offset(0, -bounds.top);
    if (bounds.right > canvasSize.width) {
      correction += Offset(canvasSize.width - bounds.right, 0);
    }
    if (bounds.bottom > canvasSize.height) {
      correction += Offset(0, canvasSize.height - bounds.bottom);
    }
    return geometry.copyWith(position: geometry.position + correction);
  }

  void _handleCanvasChanged() => notifyListeners();

  @override
  void dispose() {
    canvas
      ..removeListener(_handleCanvasChanged)
      ..dispose();
    super.dispose();
  }
}

// Internal ephemeral scene model for the screenshot-builder extension.
// ignore_for_file: public_member_api_docs

import 'dart:collection';
import 'dart:math' as math;

import 'package:desy_bench/desy_bench.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

abstract class DesyScreenshotLayer {
  DesyScreenshotLayer({
    required this.id,
    required this.name,
    required this.rect,
    this.hidden = false,
  });

  final String id;
  String name;
  Rect rect;
  bool hidden;

  String get kindLabel;
}

final class DesyScreenshotWidgetLayer extends DesyScreenshotLayer {
  DesyScreenshotWidgetLayer({
    required super.id,
    required super.name,
    required super.rect,
    required this.instanceId,
    required Map<String, Object> knobValues,
    this.scale = 1,
    this.awaitingNaturalSize = false,
  }) : knobValues = Map.of(knobValues);

  final String instanceId;
  final Map<String, Object> knobValues;
  double scale;
  bool awaitingNaturalSize;

  Size get logicalSize => Size(rect.width / scale, rect.height / scale);

  @override
  String get kindLabel => 'Widget';
}

final class DesyScreenshotImageLayer extends DesyScreenshotLayer {
  DesyScreenshotImageLayer({
    required super.id,
    required super.name,
    required super.rect,
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
    required super.rect,
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
  }) : _canvasSize = canvasSize,
       _backgroundColor = backgroundColor,
       _themeId = themeId;

  static const minimumCanvasExtent = 64.0;
  static const maximumCanvasExtent = 8192.0;
  static const minimumLayerExtent = 24.0;
  static const defaultWidgetSize = Size(240, 120);
  static const defaultTextSize = Size(360, 96);

  final List<DesyScreenshotLayer> _layers = [];
  var _nextLayer = 0;
  String? _selectedId;
  Size _canvasSize;
  Color? _backgroundColor;
  String _themeId;

  UnmodifiableListView<DesyScreenshotLayer> get layers =>
      UnmodifiableListView(_layers);

  Size get canvasSize => _canvasSize;
  Color? get backgroundColor => _backgroundColor;
  String get themeId => _themeId;
  String? get selectedId => _selectedId;

  DesyScreenshotLayer? get selectedLayer => layerById(_selectedId);

  DesyScreenshotLayer? layerById(String? id) {
    if (id == null) return null;
    for (final layer in _layers) {
      if (layer.id == id) return layer;
    }
    return null;
  }

  void select(String? id) {
    if (_selectedId == id || (id != null && layerById(id) == null)) return;
    _selectedId = id;
    notifyListeners();
  }

  String addWidget(
    DesyRegisteredComponentInstance instance, {
    Offset? position,
  }) {
    final declaredSize = instance.component.defaultSize;
    final size = declaredSize ?? defaultWidgetSize;
    final id = _newId('widget');
    _layers.add(
      DesyScreenshotWidgetLayer(
        id: id,
        name: '${instance.componentName} · ${instance.name}',
        instanceId: instance.id,
        rect: _initialRect(size, position),
        knobValues: instance.component.valuesFor(instance.instanceId),
        awaitingNaturalSize: declaredSize == null,
      ),
    );
    _selectedId = id;
    notifyListeners();
    return id;
  }

  String addImage({
    required Uint8List bytes,
    required String name,
    required Size naturalSize,
    Offset? position,
  }) {
    final fitted = _fitInitialImageSize(naturalSize);
    final id = _newId('image');
    _layers.add(
      DesyScreenshotImageLayer(
        id: id,
        name: name,
        bytes: bytes,
        rect: _initialRect(fitted, position),
      ),
    );
    _selectedId = id;
    notifyListeners();
    return id;
  }

  String addText({
    String text = 'Your text',
    String? typographyId,
    String? colorId,
    Offset? position,
  }) {
    final id = _newId('text');
    _layers.add(
      DesyScreenshotTextLayer(
        id: id,
        name: 'Text',
        text: text,
        typographyId: typographyId,
        colorId: colorId,
        rect: _initialRect(defaultTextSize, position),
      ),
    );
    _selectedId = id;
    notifyListeners();
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
    final fitted = _fitSizeToCanvas(logicalSize);
    layer.awaitingNaturalSize = false;
    layer.rect = _clampRect(
      Rect.fromLTWH(
        layer.rect.left,
        layer.rect.top,
        fitted.width * layer.scale,
        fitted.height * layer.scale,
      ),
    );
    notifyListeners();
  }

  void move(String id, Offset topLeft, {bool snap = true}) {
    final layer = layerById(id);
    if (layer == null) return;
    final next = snap ? _snappedTopLeft(layer, topLeft) : topLeft;
    layer.rect = _clampRect(next & layer.rect.size);
    notifyListeners();
  }

  void resize(String id, Size visualSize) {
    final layer = layerById(id);
    if (layer == null) return;
    final maximum = Size(
      (_canvasSize.width - layer.rect.left).clamp(
        minimumLayerExtent,
        maximumCanvasExtent,
      ),
      (_canvasSize.height - layer.rect.top).clamp(
        minimumLayerExtent,
        maximumCanvasExtent,
      ),
    );
    final size = Size(
      visualSize.width.clamp(minimumLayerExtent, maximum.width),
      visualSize.height.clamp(minimumLayerExtent, maximum.height),
    );
    layer.rect = layer.rect.topLeft & size;
    if (layer is DesyScreenshotWidgetLayer) {
      layer.awaitingNaturalSize = false;
    }
    notifyListeners();
  }

  void setWidgetScale(String id, double scale) {
    final layer = layerById(id);
    if (layer is! DesyScreenshotWidgetLayer) return;
    final next = scale.clamp(.1, 2.0);
    if (next == layer.scale) return;
    final logicalSize = layer.logicalSize;
    layer.scale = next;
    layer.rect = _clampRect(
      layer.rect.topLeft &
          Size(logicalSize.width * next, logicalSize.height * next),
    );
    notifyListeners();
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
    notifyListeners();
  }

  void moveForward(String id) {
    final index = _layers.indexWhere((layer) => layer.id == id);
    if (index < 0 || index == _layers.length - 1) return;
    final layer = _layers.removeAt(index);
    _layers.insert(index + 1, layer);
    notifyListeners();
  }

  void moveBackward(String id) {
    final index = _layers.indexWhere((layer) => layer.id == id);
    if (index <= 0) return;
    final layer = _layers.removeAt(index);
    _layers.insert(index - 1, layer);
    notifyListeners();
  }

  void remove(String id) {
    final previousLength = _layers.length;
    _layers.removeWhere((layer) => layer.id == id);
    if (_layers.length == previousLength) return;
    if (_selectedId == id) _selectedId = null;
    notifyListeners();
  }

  void setCanvasSize(Size size) {
    final next = Size(
      size.width.clamp(minimumCanvasExtent, maximumCanvasExtent),
      size.height.clamp(minimumCanvasExtent, maximumCanvasExtent),
    );
    if (next == _canvasSize) return;
    _canvasSize = next;
    notifyListeners();
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

  String _newId(String prefix) => '$prefix-${_nextLayer++}';

  Rect _initialRect(Size size, Offset? position) {
    final fitted = _fitSizeToCanvas(size);
    final offset =
        position ??
        Offset(
          (_canvasSize.width - fitted.width) / 2,
          (_canvasSize.height - fitted.height) / 2,
        );
    return _clampRect(offset & fitted);
  }

  Size _fitInitialImageSize(Size naturalSize) {
    if (naturalSize.isEmpty ||
        !naturalSize.width.isFinite ||
        !naturalSize.height.isFinite) {
      return const Size(320, 240);
    }
    final maximum = Size(_canvasSize.width * .6, _canvasSize.height * .6);
    final scale = math.min(
      1,
      math.min(
        maximum.width / naturalSize.width,
        maximum.height / naturalSize.height,
      ),
    );
    return Size(naturalSize.width * scale, naturalSize.height * scale);
  }

  Size _fitSizeToCanvas(Size size) {
    final maximum = Size(
      _canvasSize.width.clamp(minimumLayerExtent, maximumCanvasExtent),
      _canvasSize.height.clamp(minimumLayerExtent, maximumCanvasExtent),
    );
    return Size(
      size.width.clamp(minimumLayerExtent, maximum.width),
      size.height.clamp(minimumLayerExtent, maximum.height),
    );
  }

  Rect _clampRect(Rect rect) {
    final width = rect.width.clamp(
      minimumLayerExtent,
      _canvasSize.width.clamp(minimumLayerExtent, maximumCanvasExtent),
    );
    final height = rect.height.clamp(
      minimumLayerExtent,
      _canvasSize.height.clamp(minimumLayerExtent, maximumCanvasExtent),
    );
    return Rect.fromLTWH(
      rect.left.clamp(
        0,
        (_canvasSize.width - width).clamp(0, maximumCanvasExtent),
      ),
      rect.top.clamp(
        0,
        (_canvasSize.height - height).clamp(0, maximumCanvasExtent),
      ),
      width,
      height,
    );
  }

  Offset _snappedTopLeft(DesyScreenshotLayer layer, Offset desired) {
    const threshold = 8.0;
    final horizontal = <double>[
      0,
      (_canvasSize.width - layer.rect.width) / 2,
      _canvasSize.width - layer.rect.width,
    ];
    final vertical = <double>[
      0,
      (_canvasSize.height - layer.rect.height) / 2,
      _canvasSize.height - layer.rect.height,
    ];
    for (final other in _layers) {
      if (identical(other, layer) || other.hidden) continue;
      horizontal.addAll([
        other.rect.left,
        other.rect.center.dx - layer.rect.width / 2,
        other.rect.right - layer.rect.width,
      ]);
      vertical.addAll([
        other.rect.top,
        other.rect.center.dy - layer.rect.height / 2,
        other.rect.bottom - layer.rect.height,
      ]);
    }
    return Offset(
      _nearestWithin(desired.dx, horizontal, threshold),
      _nearestWithin(desired.dy, vertical, threshold),
    );
  }
}

double _nearestWithin(double value, Iterable<double> candidates, double limit) {
  var result = value;
  var distance = limit;
  for (final candidate in candidates) {
    final nextDistance = (candidate - value).abs();
    if (nextDistance <= distance) {
      distance = nextDistance;
      result = candidate;
    }
  }
  return result;
}

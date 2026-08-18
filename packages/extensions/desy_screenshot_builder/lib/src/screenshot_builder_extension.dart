import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:object_canvas/object_canvas.dart';

import 'screenshot_export.dart';

part 'screenshot_builder_layers.dart';
part 'screenshot_builder_canvas.dart';
part 'screenshot_builder_sidebar.dart';

/// An ephemeral canvas for composing registry widgets, images, and text.
class DesyScreenshotBuilderExtension extends DesyWorkspaceExtension {
  /// Creates the experimental screenshot-builder extension.
  const DesyScreenshotBuilderExtension();

  @override
  String get id => 'screenshot-builder';

  @override
  String get name => 'Screenshot builder';

  @override
  IconData get icon => DesyIcons.camera;

  @override
  String get description =>
      'Compose and export an ephemeral image from your real design system.';

  @override
  DesyWorkspaceExtensionPresentation get presentation =>
      DesyWorkspaceExtensionPresentation.standalone;

  @override
  Widget build(BuildContext context, DesyWorkspaceExtensionContext extension) =>
      _ScreenshotBuilderScreen(extension: extension);
}

class _ScreenshotBuilderScreen extends StatefulWidget {
  const _ScreenshotBuilderScreen({required this.extension});

  final DesyWorkspaceExtensionContext extension;

  @override
  State<_ScreenshotBuilderScreen> createState() =>
      _ScreenshotBuilderScreenState();
}

class _ScreenshotBuilderScreenState extends State<_ScreenshotBuilderScreen> {
  static const _sidebarMinimum = 340.0;
  static const _sidebarMaximum = 440.0;
  static const _inspectorMinimum = 340.0;
  static const _inspectorMaximum = 480.0;
  static const _minimumCanvasExtent = 64.0;
  static const _maximumCanvasExtent = 8192.0;
  static const _minimumLayerExtent = 24.0;
  static const _defaultCanvasSize = Size(1200, 630);
  static const _defaultWidgetSize = Size(240, 120);
  static const _defaultTextSize = Size(360, 96);

  final _viewportKey = GlobalKey(debugLabel: 'screenshot-canvas-viewport');
  late final ObjectCanvasController<DesyScreenshotLayer> _canvas;

  var _sidebarWidth = 360.0;
  var _inspectorWidth = 360.0;
  var _compactSidebarHeight = 240.0;
  var _compactInspectorHeight = 240.0;
  var _dropActive = false;
  var _exporting = false;
  var _viewportSize = Size.zero;
  var _hasInitialFit = false;
  var _themeId = '';
  var _nextLayer = 0;
  Color? _backgroundColor;
  String? _status;

  DesyWorkspaceExtensionContext get extension => widget.extension;

  DesyTheme get selectedTheme {
    for (final theme in extension.registry.themes) {
      if (theme.id == _themeId) return theme;
    }
    return extension.activeTheme;
  }

  List<DesyScreenshotLayer> get layers => [
    for (final object in _canvas.objects) object.data,
  ];

  DesyScreenshotLayer? get selectedLayer =>
      _canvas.selectedObjects.firstOrNull?.data;

  @override
  void initState() {
    super.initState();
    _themeId = extension.activeTheme.id;
    _backgroundColor = extension.activeTheme.previewBackgroundColor;
    _canvas = ObjectCanvasController<DesyScreenshotLayer>(
      canvasSize: _defaultCanvasSize,
      defaults: const CanvasObjectDefaults(
        constraints: CanvasObjectConstraints(
          minSize: Size.square(_minimumLayerExtent),
          maxSize: Size.square(_maximumCanvasExtent),
        ),
      ),
    )..addListener(_handleCanvasChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitCanvas());
  }

  @override
  void dispose() {
    _canvas
      ..removeListener(_handleCanvasChange)
      ..dispose();
    super.dispose();
  }

  void _handleCanvasChange() {
    if (mounted) setState(() {});
  }

  void _addPaletteItem(_PalettePayload payload, {Offset? position}) {
    switch (payload) {
      case _WidgetPalettePayload(:final instance):
        _addWidgetLayer(instance, position: position);
      case _TextPalettePayload():
        _addTextLayer(
          position: position,
          typographyId: extension.registry.allFonts.firstOrNull?.id,
          colorId: _defaultTextColorId(),
        );
    }
  }

  String? _defaultTextColorId() {
    final colors = extension.registry.allColors;
    if (colors.isEmpty) return null;
    final background = _backgroundColor ?? Colors.white;
    final backgroundLuminance = background.computeLuminance();
    DesyColorEntry best = colors.first;
    var bestContrast = 0.0;
    for (final entry in colors) {
      final light = math.max(
        backgroundLuminance,
        entry.color.computeLuminance(),
      );
      final dark = math.min(
        backgroundLuminance,
        entry.color.computeLuminance(),
      );
      final contrast = (light + .05) / (dark + .05);
      if (contrast > bestContrast) {
        best = entry;
        bestContrast = contrast;
      }
    }
    return best.id;
  }

  Future<void> _pickImage() async {
    const images = XTypeGroup(
      label: 'Images',
      extensions: ['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'],
      mimeTypes: [
        'image/png',
        'image/jpeg',
        'image/webp',
        'image/gif',
        'image/bmp',
      ],
      uniformTypeIdentifiers: [
        'public.png',
        'public.jpeg',
        'org.webmproject.webp',
        'com.compuserve.gif',
        'com.microsoft.bmp',
      ],
      webWildCards: ['image/*'],
    );
    final file = await openFile(acceptedTypeGroups: const [images]);
    if (file == null || !mounted) return;
    await _importImages([file]);
  }

  Future<void> _handleFileDrop(DropDoneDetails details) async {
    setState(() => _dropActive = false);
    final position = _stagePositionFromGlobal(details.globalPosition);
    await _importImages(details.files, position: position);
  }

  Future<void> _importImages(Iterable<XFile> files, {Offset? position}) async {
    var imported = 0;
    for (final file in files) {
      if (!_looksLikeImage(file)) continue;
      Uint8List bytes;
      Uint8List? bookmark;
      var securityAccess = false;
      if (file is DropItem) {
        bookmark = file.extraAppleBookmark;
        if (bookmark != null && bookmark.isNotEmpty) {
          securityAccess = await DesktopDrop.instance
              .startAccessingSecurityScopedResource(bookmark: bookmark);
        }
      }
      try {
        bytes = await file.readAsBytes();
      } finally {
        if (securityAccess && bookmark != null) {
          await DesktopDrop.instance.stopAccessingSecurityScopedResource(
            bookmark: bookmark,
          );
        }
      }
      final naturalSize = await _imageSize(bytes);
      if (!mounted) return;
      _addImageLayer(
        bytes: bytes,
        name: file.name.isEmpty ? 'Image' : file.name,
        naturalSize: naturalSize,
        position: position == null
            ? null
            : position + Offset(24.0 * imported, 24.0 * imported),
      );
      imported++;
    }
    if (!mounted) return;
    setState(() {
      _status = imported == 0
          ? 'No supported image files were found.'
          : 'Added $imported image${imported == 1 ? '' : 's'}.';
    });
  }

  bool _looksLikeImage(XFile file) {
    final mime = file.mimeType ?? '';
    if (mime.startsWith('image/')) return true;
    final name = file.name.toLowerCase();
    return const [
      '.png',
      '.jpg',
      '.jpeg',
      '.webp',
      '.gif',
      '.bmp',
    ].any(name.endsWith);
  }

  Future<Size> _imageSize(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      try {
        return Size(
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        );
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  Future<void> _exportScreenshot() async {
    if (_exporting) return;
    setState(() {
      _exporting = true;
      _status = null;
    });
    try {
      await WidgetsBinding.instance.endOfFrame;
      final bytes = await _canvas.renderPng();
      final location = await saveDesyScreenshot(bytes);
      if (!mounted) return;
      setState(() => _status = 'Saved PNG to $location');
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = 'Export failed: $error');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Offset? _stagePositionFromGlobal(Offset globalPosition) {
    final renderObject = _viewportKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return null;
    final viewportPosition = renderObject.globalToLocal(globalPosition);
    return _canvas.viewportController.toScene(viewportPosition);
  }

  void _fitCanvas() {
    if (_viewportSize.isEmpty) return;
    const inset = 56.0;
    final canvas = _canvas.canvasSize;
    final scale = math
        .min(
          (_viewportSize.width - inset).clamp(1, double.infinity) /
              canvas.width,
          (_viewportSize.height - inset).clamp(1, double.infinity) /
              canvas.height,
        )
        .clamp(.1, 4.0);
    final horizontal = (_viewportSize.width - canvas.width * scale) / 2;
    final vertical = (_viewportSize.height - canvas.height * scale) / 2;
    _canvas.viewportController.value = Matrix4.identity()
      ..translateByDouble(horizontal, vertical, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
    _hasInitialFit = true;
  }

  void _zoom(double factor) {
    if (_viewportSize.isEmpty) return;
    final transform = _canvas.viewportController;
    final current = transform.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(.1, 4.0);
    final viewportCenter = _viewportSize.center(Offset.zero);
    final sceneCenter = transform.toScene(viewportCenter);
    transform.value = Matrix4.identity()
      ..translateByDouble(viewportCenter.dx, viewportCenter.dy, 0, 1)
      ..scaleByDouble(next, next, 1, 1)
      ..translateByDouble(-sceneCenter.dx, -sceneCenter.dy, 0, 1);
  }

  String _addWidgetLayer(
    DesyRegisteredComponentInstance instance, {
    Offset? position,
  }) {
    final declaredSize = instance.component.defaultSize;
    final id = _newLayerId('widget');
    _addLayer(
      DesyScreenshotWidgetLayer(
        id: id,
        name: '${instance.componentName} · ${instance.name}',
        instanceId: instance.id,
        knobValues: instance.component.valuesFor(instance.instanceId),
      ),
      size: declaredSize ?? _defaultWidgetSize,
      position: position,
    );
    return id;
  }

  String _addImageLayer({
    required Uint8List bytes,
    required String name,
    required Size naturalSize,
    Offset? position,
  }) {
    final id = _newLayerId('image');
    _addLayer(
      DesyScreenshotImageLayer(id: id, name: name, bytes: bytes),
      size: _fitInitialImageSize(naturalSize),
      position: position,
    );
    return id;
  }

  String _addTextLayer({
    String text = 'Your text',
    String? typographyId,
    String? colorId,
    Offset? position,
  }) {
    final id = _newLayerId('text');
    _addLayer(
      DesyScreenshotTextLayer(
        id: id,
        name: 'Text',
        text: text,
        typographyId: typographyId,
        colorId: colorId,
      ),
      size: _defaultTextSize,
      position: position,
    );
    return id;
  }

  void _addLayer(
    DesyScreenshotLayer layer, {
    required Size size,
    Offset? position,
  }) {
    _canvas.addObjectData(
      id: layer.id,
      data: layer,
      size: size,
      center: position,
    );
  }

  void _setCanvasSize(Size size) {
    _canvas.setCanvasSize(
      Size(
        size.width.clamp(_minimumCanvasExtent, _maximumCanvasExtent),
        size.height.clamp(_minimumCanvasExtent, _maximumCanvasExtent),
      ),
    );
  }

  void _setTheme(String themeId, {Color? defaultBackground}) {
    if (_themeId == themeId) return;
    setState(() {
      _themeId = themeId;
      _backgroundColor = defaultBackground;
    });
  }

  void _setBackgroundColor(Color? color) {
    if (_backgroundColor == color) return;
    setState(() => _backgroundColor = color);
  }

  void _setKnob(String id, String knobId, Object value) {
    final layer = _layerById(id);
    if (layer is! DesyScreenshotWidgetLayer) return;
    final values = Map<String, Object>.of(layer.knobValues)..[knobId] = value;
    _updateLayer(id, layer.copyWith(knobValues: values), label: 'Change knob');
  }

  void _setText(String id, String value) {
    final layer = _layerById(id);
    if (layer is! DesyScreenshotTextLayer || layer.text == value) return;
    _updateLayer(id, layer.copyWith(text: value), label: 'Change text');
  }

  void _setTextTypography(String id, String? typographyId) {
    final layer = _layerById(id);
    if (layer is! DesyScreenshotTextLayer ||
        layer.typographyId == typographyId) {
      return;
    }
    _updateLayer(
      id,
      layer.copyWith(typographyId: typographyId),
      label: 'Change text style',
    );
  }

  void _setTextColor(String id, String? colorId) {
    final layer = _layerById(id);
    if (layer is! DesyScreenshotTextLayer || layer.colorId == colorId) return;
    _updateLayer(
      id,
      layer.copyWith(colorId: colorId),
      label: 'Change text color',
    );
  }

  void _toggleHidden(String id) {
    final layer = _layerById(id);
    if (layer == null) return;
    final nextHidden = !layer.hidden;
    _updateLayer(id, layer.copyWith(hidden: nextHidden), label: 'Toggle layer');
    if (nextHidden && _canvas.selectedObjectIds.contains(id)) {
      _canvas.clearSelection();
    }
  }

  DesyScreenshotLayer? _layerById(String id) {
    for (final object in _canvas.objects) {
      if (object.id == id) return object.data;
    }
    return null;
  }

  void _updateLayer(
    String id,
    DesyScreenshotLayer layer, {
    required String label,
  }) => _canvas.updateData([
    CanvasDataValue(objectId: id, data: layer),
  ], label: label);

  String _newLayerId(String prefix) => '$prefix-${_nextLayer++}';

  Size _fitInitialImageSize(Size naturalSize) {
    if (naturalSize.isEmpty ||
        !naturalSize.width.isFinite ||
        !naturalSize.height.isFinite) {
      return const Size(320, 240);
    }
    final maximum = Size(
      _canvas.canvasSize.width * .6,
      _canvas.canvasSize.height * .6,
    );
    final scale = math.min(
      1,
      math.min(
        maximum.width / naturalSize.width,
        maximum.height / naturalSize.height,
      ),
    );
    return Size(naturalSize.width * scale, naturalSize.height * scale);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return ColoredBox(
      color: colors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 1120;
          final sidebar = _ScreenshotSidebar(
            canvas: _canvas,
            layers: layers,
            backgroundColor: _backgroundColor,
            extension: extension,
            selectedTheme: selectedTheme,
            exporting: _exporting,
            status: _status,
            onExit: extension.onExit,
            onAdd: _addPaletteItem,
            onPickImage: () => unawaited(_pickImage()),
            onExport: () => unawaited(_exportScreenshot()),
            onCanvasSizeChanged: _setCanvasSize,
            onThemeChanged: _setTheme,
            onBackgroundChanged: _setBackgroundColor,
            onToggleHidden: _toggleHidden,
          );
          final inspector = _ScreenshotLayerInspector(
            canvas: _canvas,
            selectedLayer: selectedLayer,
            extension: extension,
            onSetKnob: _setKnob,
            onSetText: _setText,
            onSetTextTypography: _setTextTypography,
            onSetTextColor: _setTextColor,
            onToggleHidden: _toggleHidden,
          );
          final viewport = DropTarget(
            onDragEntered: (_) => setState(() => _dropActive = true),
            onDragExited: (_) => setState(() => _dropActive = false),
            onDragDone: (details) => unawaited(_handleFileDrop(details)),
            child: _CanvasViewport(
              key: _viewportKey,
              canvas: _canvas,
              backgroundColor: _backgroundColor,
              extension: extension,
              selectedTheme: selectedTheme,
              dropActive: _dropActive,
              onViewportSize: (size) {
                if (_viewportSize == size) return;
                _viewportSize = size;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_hasInitialFit) {
                    _fitCanvas();
                  }
                });
              },
              onAcceptPalette: (payload, position) =>
                  _addPaletteItem(payload, position: position),
              onFit: _fitCanvas,
              onZoomIn: () => _zoom(1.2),
              onZoomOut: () => _zoom(1 / 1.2),
            ),
          );

          if (compact) {
            final hasSelection = selectedLayer != null;
            final panelMaximum = (constraints.maxHeight * .34)
                .clamp(180.0, 300.0)
                .toDouble();
            final sidebarHeight = _compactSidebarHeight
                .clamp(180.0, panelMaximum)
                .toDouble();
            final inspectorHeight = _compactInspectorHeight
                .clamp(180.0, panelMaximum)
                .toDouble();
            return Column(
              children: [
                SizedBox(height: sidebarHeight, child: sidebar),
                DesyResizeDivider(
                  axis: Axis.horizontal,
                  value: sidebarHeight,
                  semanticsLabel: 'Screenshot builder panel height',
                  onResize: (delta) => setState(() {
                    _compactSidebarHeight = (_compactSidebarHeight + delta)
                        .clamp(180.0, panelMaximum);
                  }),
                ),
                Expanded(child: viewport),
                if (hasSelection) ...[
                  DesyResizeDivider(
                    key: const ValueKey('screenshot-inspector-resize-handle'),
                    axis: Axis.horizontal,
                    value: inspectorHeight,
                    semanticsLabel: 'Screenshot element inspector height',
                    onResize: (delta) => setState(() {
                      _compactInspectorHeight =
                          (_compactInspectorHeight - delta).clamp(
                            180.0,
                            panelMaximum,
                          );
                    }),
                  ),
                  SizedBox(height: inspectorHeight, child: inspector),
                ],
              ],
            );
          }

          final sidebarWidth = _sidebarWidth
              .clamp(
                _sidebarMinimum,
                math.min(_sidebarMaximum, constraints.maxWidth * .34),
              )
              .toDouble();
          final inspectorWidth = _inspectorWidth
              .clamp(
                _inspectorMinimum,
                math.min(_inspectorMaximum, constraints.maxWidth * .34),
              )
              .toDouble();
          return Row(
            children: [
              SizedBox(width: sidebarWidth, child: sidebar),
              DesyResizeDivider(
                axis: Axis.vertical,
                value: sidebarWidth,
                semanticsLabel: 'Screenshot builder sidebar width',
                onResize: (delta) => setState(() {
                  _sidebarWidth = (_sidebarWidth + delta).clamp(
                    _sidebarMinimum,
                    math.min(_sidebarMaximum, constraints.maxWidth * .34),
                  );
                }),
              ),
              SizedBox(width: inspectorWidth, child: inspector),
              DesyResizeDivider(
                key: const ValueKey('screenshot-inspector-resize-handle'),
                axis: Axis.vertical,
                value: inspectorWidth,
                semanticsLabel: 'Screenshot element inspector width',
                onResize: (delta) => setState(() {
                  _inspectorWidth = (_inspectorWidth + delta).clamp(
                    _inspectorMinimum,
                    math.min(_inspectorMaximum, constraints.maxWidth * .34),
                  );
                }),
              ),
              Expanded(child: viewport),
            ],
          );
        },
      ),
    );
  }
}

sealed class _PalettePayload {
  const _PalettePayload();
}

final class _WidgetPalettePayload extends _PalettePayload {
  const _WidgetPalettePayload(this.instance);

  final DesyRegisteredComponentInstance instance;
}

final class _TextPalettePayload extends _PalettePayload {
  const _TextPalettePayload();
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

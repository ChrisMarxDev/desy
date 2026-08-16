import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'screenshot_export.dart';
import 'screenshot_scene.dart';

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

  final _boundaryKey = GlobalKey(debugLabel: 'screenshot-export-boundary');
  final _stageKey = GlobalKey(debugLabel: 'screenshot-logical-stage');
  final _transform = TransformationController();
  late final DesyScreenshotSceneController _scene;

  var _sidebarWidth = 360.0;
  var _inspectorWidth = 360.0;
  var _compactSidebarHeight = 240.0;
  var _compactInspectorHeight = 240.0;
  var _dropActive = false;
  var _exporting = false;
  var _viewportSize = Size.zero;
  var _hasInitialFit = false;
  String? _status;

  DesyWorkspaceExtensionContext get extension => widget.extension;

  DesyTheme get selectedTheme {
    for (final theme in extension.registry.themes) {
      if (theme.id == _scene.themeId) return theme;
    }
    return extension.activeTheme;
  }

  @override
  void initState() {
    super.initState();
    _scene = DesyScreenshotSceneController(
      themeId: extension.activeTheme.id,
      backgroundColor: extension.activeTheme.previewBackgroundColor,
    )..addListener(_handleSceneChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitCanvas());
  }

  @override
  void dispose() {
    _scene
      ..removeListener(_handleSceneChange)
      ..dispose();
    _transform.dispose();
    super.dispose();
  }

  void _handleSceneChange() {
    if (mounted) setState(() {});
  }

  void _addPaletteItem(_PalettePayload payload, {Offset? position}) {
    switch (payload) {
      case _WidgetPalettePayload(:final instance):
        _scene.addWidget(instance, position: position);
      case _TextPalettePayload():
        _scene.addText(
          position: position,
          typographyId: extension.registry.allFonts.firstOrNull?.id,
          colorId: _defaultTextColorId(),
        );
    }
  }

  String? _defaultTextColorId() {
    final colors = extension.registry.allColors;
    if (colors.isEmpty) return null;
    final background = _scene.backgroundColor ?? Colors.white;
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
      _scene.addImage(
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
      final bytes = await captureDesyScreenshot(_boundaryKey);
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
    final renderObject = _stageKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return null;
    return renderObject.globalToLocal(globalPosition);
  }

  void _fitCanvas() {
    if (_viewportSize.isEmpty) return;
    const inset = 56.0;
    final canvas = _scene.canvasSize;
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
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        horizontal - _CanvasViewport.stageMargin * scale,
        vertical - _CanvasViewport.stageMargin * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
    _hasInitialFit = true;
  }

  void _zoom(double factor) {
    if (_viewportSize.isEmpty) return;
    final current = _transform.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(.1, 4.0);
    final viewportCenter = _viewportSize.center(Offset.zero);
    final sceneCenter = _transform.toScene(viewportCenter);
    _transform.value = Matrix4.identity()
      ..translateByDouble(viewportCenter.dx, viewportCenter.dy, 0, 1)
      ..scaleByDouble(next, next, 1, 1)
      ..translateByDouble(-sceneCenter.dx, -sceneCenter.dy, 0, 1);
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
            scene: _scene,
            extension: extension,
            selectedTheme: selectedTheme,
            exporting: _exporting,
            status: _status,
            onExit: extension.onExit,
            onAdd: _addPaletteItem,
            onPickImage: () => unawaited(_pickImage()),
            onExport: () => unawaited(_exportScreenshot()),
          );
          final inspector = _ScreenshotLayerInspector(
            scene: _scene,
            extension: extension,
          );
          final viewport = DropTarget(
            onDragEntered: (_) => setState(() => _dropActive = true),
            onDragExited: (_) => setState(() => _dropActive = false),
            onDragDone: (details) => unawaited(_handleFileDrop(details)),
            child: _CanvasViewport(
              scene: _scene,
              extension: extension,
              selectedTheme: selectedTheme,
              boundaryKey: _boundaryKey,
              stageKey: _stageKey,
              transform: _transform,
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
            final hasSelection = _scene.selectedLayer != null;
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

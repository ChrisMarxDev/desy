// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:state_beacon/state_beacon.dart';

import 'component_knob_panel.dart';
import 'collection_canvas.dart';
import 'preview_accessibility_panel.dart';
import 'preview_accessibility_overlay.dart';
import 'desy_drag_box.dart';
import 'detail_extensions_region.dart';
import 'motion_playback_controls.dart';
import 'workbench_control_sheet.dart';
import 'workbench_breadcrumbs.dart';
import '../../device_preview.dart';
import '../../motion_playback.dart';
import '../../registry.dart';
import '../component_image_export.dart';
import '../component_image_save.dart';
import '../widget_preview.dart';
import '../workbench_annotation.dart';
import '../workbench_session.dart';

const _minimumBoxExtent = 8.0;
const _detailToolbarTop = desyWorkbenchCanvasInset;
const _detailToolbarReservedHeight = 58.0;
const _toolbarSelectionGap = 8.0;
const _selectionLabelGap = 6.0;
const _selectionLabelReservedHeight = 28.0;

const _selectionMinimumTop =
    _detailToolbarTop + _detailToolbarReservedHeight + _toolbarSelectionGap;

const _detailCanvasItemGap = 16.0;

/// The inspect-and-adjust surface for a single entry.
class DesyDetailScreen extends StatefulWidget {
  const DesyDetailScreen({
    super.key,
    required this.session,
    required this.entry,
    this.inspectionContext,
    this.onOpenFolder,
    this.onOpenCatalogue,
    this.imageSaver = saveDesyImage,
    this.imageExportAction,
  });

  final DesyWorkbenchSession session;
  final DesyRegistryEntry entry;
  final DesyWorkbenchInspectionContext? inspectionContext;
  final ValueChanged<String>? onOpenFolder;
  final VoidCallback? onOpenCatalogue;
  final DesyImageSaver imageSaver;
  final DesyImageExportAction? imageExportAction;

  @override
  State<DesyDetailScreen> createState() => _DesyDetailScreenState();
}

class _DesyDetailScreenState extends State<DesyDetailScreen>
    with TickerProviderStateMixin {
  late final _DetailImageExportController _imageExportController;
  String _selectedVariantId = 'default';
  DesyMotionPlaybackController? _motionPlayback;

  DesyAnimationComponentBase? get _animationComponent =>
      switch (widget.entry.component) {
        final DesyAnimationComponentBase component => component,
        _ => null,
      };

  @override
  void initState() {
    super.initState();
    _imageExportController = _DetailImageExportController();
    _initializeMotionPlayback();
  }

  @override
  void didUpdateWidget(covariant DesyDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id ||
        oldWidget.entry.source != widget.entry.source) {
      _selectedVariantId = 'default';
      _imageExportController.reset();
      _disposeMotionPlayback();
      _initializeMotionPlayback();
    }
  }

  void _initializeMotionPlayback() {
    final animation = _animationComponent;
    if (animation == null) return;
    _motionPlayback = DesyMotionPlaybackController(
      vsync: this,
      duration: animation.duration,
      curve: animation.curve,
    );
  }

  void _disposeMotionPlayback() {
    _motionPlayback?.dispose();
    _motionPlayback = null;
  }

  @override
  void dispose() {
    _disposeMotionPlayback();
    _imageExportController.dispose();
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
    final animation = _animationComponent;
    final variants = <_DetailVariant>[
      _DetailVariant(
        id: 'default',
        name: component == null ? entry.name : 'Default',
        selected: _selectedVariantId == 'default',
        onSelect: component == null
            ? null
            : () => _selectVariant(component: component),
        builder: component == null
            ? entry.builder
            : (context) => _buildComponentPreview(
                context,
                component,
                values: _selectedVariantId == 'default' ? values : const {},
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
          builder: (context) => _buildComponentPreview(
            context,
            component,
            values: _selectedVariantId == 'instance-$instanceId'
                ? values
                : null,
            instanceId: _selectedVariantId == 'instance-$instanceId'
                ? null
                : instanceId,
          ),
        ),
      if (component != null)
        for (final scenario in component.scenarios)
          _DetailVariant(
            id: 'scenario-${scenario.id}',
            name: 'State · ${scenario.name}',
            selected: false,
            onSelect: null,
            builder: (context) =>
                _buildMotionPreview(context, scenario.builder),
          ),
    ];

    return _DetailBody(
      preview: _DetailInstanceGallery(
        session: session,
        entry: entry,
        theme: theme,
        device: device,
        accessibility: accessibility,
        onOpenFolder: widget.onOpenFolder,
        onOpenCatalogue: widget.onOpenCatalogue,
        imageSaver: widget.imageSaver,
        imageExportAction: widget.imageExportAction,
        imageExportController: component == null
            ? null
            : _imageExportController,
        variants: variants,
        inspectionContext: widget.inspectionContext,
      ),
      inspector: _DetailInspector(
        session: session,
        component: component,
        entry: entry,
        values: values,
        motionControls: animation == null ? null : _buildMotionControls(),
        imageExportController: component == null
            ? null
            : _imageExportController,
      ),
    );
  }

  Widget _buildComponentPreview(
    BuildContext context,
    DesyRegistryComponent component, {
    Map<String, Object>? values,
    String? instanceId,
  }) {
    final animation = _animationComponent;
    final playback = _motionPlayback;
    if (animation != null && playback != null) {
      return DesyMotionPlaybackScope(
        progress: playback.progress,
        child: Builder(
          builder: (context) => instanceId == null
              ? animation.buildWithPlayback(
                  context,
                  values ?? const {},
                  widget.session.registry.widgetBuilder,
                  playback.progress,
                )
              : animation.buildInstanceWithPlayback(
                  context,
                  instanceId,
                  widget.session.registry.widgetBuilder,
                  playback.progress,
                ),
        ),
      );
    }
    return instanceId == null
        ? component.buildWithValues(
            context,
            values ?? const {},
            widgets: widget.session.registry.widgetBuilder,
          )
        : component.buildInstance(
            context,
            instanceId,
            widget.session.registry.widgetBuilder,
          );
  }

  Widget _buildMotionPreview(BuildContext context, DesyPreviewBuilder builder) {
    final playback = _motionPlayback;
    if (playback == null) return builder(context);
    return DesyMotionPlaybackScope(
      progress: playback.progress,
      child: Builder(builder: builder),
    );
  }

  Widget _buildMotionControls() {
    return DesyMotionPlaybackControls(
      controller: _motionPlayback!,
      compact: true,
      stacked: true,
      globalDuration: _motionPlayback!.duration,
      onGlobalDurationChanged: (duration) {
        _motionPlayback!.setDuration(duration);
        setState(() {});
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

class _DetailImageExportController extends ChangeNotifier {
  Object? _owner;
  Future<void> Function()? _onExport;
  bool _exporting = false;
  String? _status;

  bool get exporting => _exporting;
  String? get status => _status;

  void attach(Object owner, Future<void> Function() onExport) {
    _owner = owner;
    _onExport = onExport;
  }

  void detach(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _onExport = null;
  }

  Future<void> export() async {
    if (_exporting) return;
    await _onExport?.call();
  }

  void start() {
    _exporting = true;
    _status = 'Exporting image…';
    notifyListeners();
  }

  void complete(String status) {
    _status = status;
    notifyListeners();
  }

  void finish() {
    _exporting = false;
    notifyListeners();
  }

  void clearStatus() {
    if (_status == null) return;
    _status = null;
    notifyListeners();
  }

  void reset() {
    _exporting = false;
    _status = null;
    notifyListeners();
  }
}

class _DetailInstanceGallery extends StatefulWidget {
  const _DetailInstanceGallery({
    required this.session,
    required this.entry,
    required this.theme,
    required this.device,
    required this.accessibility,
    required this.onOpenFolder,
    required this.onOpenCatalogue,
    required this.imageSaver,
    required this.imageExportAction,
    required this.imageExportController,
    required this.variants,
    this.inspectionContext,
  });

  final DesyWorkbenchSession session;
  final DesyRegistryEntry entry;
  final DesyTheme theme;
  final DesyDevicePreset? device;
  final DesyPreviewAccessibilitySettings accessibility;
  final ValueChanged<String>? onOpenFolder;
  final VoidCallback? onOpenCatalogue;
  final DesyImageSaver imageSaver;
  final DesyImageExportAction? imageExportAction;
  final _DetailImageExportController? imageExportController;
  final List<_DetailVariant> variants;
  final DesyWorkbenchInspectionContext? inspectionContext;

  @override
  State<_DetailInstanceGallery> createState() => _DetailInstanceGalleryState();
}

class _DetailInstanceGalleryState extends State<_DetailInstanceGallery> {
  final Map<String, GlobalKey> _captureKeys = {};
  String? _activeVariantId;

  @override
  void initState() {
    super.initState();
    _activeVariantId = _preferredActiveVariantId();
    widget.imageExportController?.attach(this, _exportActiveImage);
  }

  @override
  void didUpdateWidget(covariant _DetailInstanceGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageExportController != widget.imageExportController) {
      oldWidget.imageExportController?.detach(this);
      widget.imageExportController?.attach(this, _exportActiveImage);
    }
    final activeIds = widget.variants.map((variant) => variant.id).toSet();
    _captureKeys.removeWhere((id, _) => !activeIds.contains(id));
    final selectedId = _selectedVariantId();
    if (selectedId != null) {
      _activeVariantId = selectedId;
    } else if (!activeIds.contains(_activeVariantId)) {
      _activeVariantId = _preferredActiveVariantId();
    }
  }

  @override
  void dispose() {
    widget.imageExportController?.detach(this);
    super.dispose();
  }

  void _synchronizeCaptureKeys() {
    final activeIds = widget.variants.map((variant) => variant.id).toSet();
    _captureKeys.removeWhere((id, _) => !activeIds.contains(id));
    for (final variant in widget.variants) {
      _captureKeys.putIfAbsent(variant.id, GlobalKey.new);
    }
  }

  void _select(_DetailVariant variant) {
    setState(() {
      _activeVariantId = variant.id;
    });
    widget.imageExportController?.clearStatus();
    variant.onSelect?.call();
  }

  String? _selectedVariantId() {
    for (final variant in widget.variants) {
      if (variant.selected) return variant.id;
    }
    return null;
  }

  String? _preferredActiveVariantId() =>
      _selectedVariantId() ??
      (widget.variants.isEmpty ? null : widget.variants.first.id);

  Future<void> _exportActiveImage() async {
    final controller = widget.imageExportController;
    if (controller == null || controller.exporting) return;
    final variantId = _activeVariantId;
    final boundaryKey = variantId == null ? null : _captureKeys[variantId];
    if (variantId == null || boundaryKey == null) return;

    controller.start();
    try {
      final fileName = desyPngFileName(
        entryId: widget.entry.id,
        variantId: variantId,
        themeId: widget.theme.id,
      );
      final exportAction =
          widget.imageExportAction ??
          DesyComponentImageExporter(saveImage: widget.imageSaver).export;
      final result = await exportAction(
        boundaryKey: boundaryKey,
        fileName: fileName,
      );
      if (!mounted) return;
      controller.complete(switch (result) {
        DesyImageSaveResult.saved => 'Saved $fileName',
        DesyImageSaveResult.cancelled => 'Image export canceled',
      });
    } catch (error, stackTrace) {
      if (error is! UnsupportedError) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'desy_bench',
            context: ErrorDescription(
              'while exporting registry component "${widget.entry.id}"',
            ),
          ),
        );
      }
      if (!mounted) return;
      controller.complete(
        error is UnsupportedError
            ? error.message?.toString() ?? 'Image export is unavailable'
            : 'Image export failed. Let the preview settle and try again.',
      );
    } finally {
      if (mounted) controller.finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.session.stage.watch(context);
    _synchronizeCaptureKeys();
    return DesyCollectionCanvas<_DetailVariant>(
      key: ValueKey('detail-canvas-${widget.device?.name ?? 'responsive'}'),
      theme: widget.theme,
      title: widget.entry.name,
      detailsBuilder: (_, _) => const SizedBox.shrink(),
      keyPrefix: 'detail-instance',
      zoomDockKeyPrefix: 'detail-canvas',
      toolbar: _DetailPreviewToolbar(
        entry: widget.entry,
        onOpenFolder: widget.onOpenFolder,
        onOpenCatalogue: widget.onOpenCatalogue,
      ),
      showInspectorDrawer: false,
      clearSelectionOnCanvasTap: false,
      initialSelectedItemId: _activeVariantId,
      geometryRevision: widget.device?.index ?? -1,
      // A preset supplies a first drag-box size only. It never scales the
      // preview or turns the component into a simulated device frame.
      initialZoom: 1,
      items: [
        for (final (index, variant) in widget.variants.indexed)
          DesyCanvasSceneItem(
            id: variant.id,
            name: variant.name,
            value: variant,
            initialRect: _initialRect(stage, index),
            itemKey: ValueKey('detail-instance-viewer-${variant.id}'),
            frameKey: variant.id == 'default'
                ? const ValueKey('detail-artboard')
                : ValueKey('detail-instance-artboard-${variant.id}'),
            contentKey: variant.id == 'default'
                ? const ValueKey('detail-artboard-hit')
                : ValueKey('detail-instance-artboard-hit-${variant.id}'),
            labelKey: variant.id == 'default'
                ? const ValueKey('detail-selection-size')
                : ValueKey('detail-instance-label-${variant.id}'),
            previewBuilder: (context, variant) =>
                _previewSurface(context, variant, _captureKeys[variant.id]!),
            onSelected: () => _select(variant),
            onGeometryChanged: (geometry) {
              if (variant.id == 'default') {
                widget.session.updateStage(
                  stage.copyWith(
                    offset: geometry.rect.topLeft,
                    size: geometry.rect.size,
                  ),
                );
              }
            },
          ),
      ],
    );
  }

  Rect _initialRect(DesyPreviewStage stage, int index) => Rect.fromLTWH(
    stage.offset.dx,
    math.max(stage.offset.dy, _selectionMinimumTop) +
        index *
            ((widget.device?.screenSize.height ?? stage.size.height) +
                _selectionLabelGap +
                _selectionLabelReservedHeight +
                _detailCanvasItemGap),
    widget.device?.screenSize.width ?? stage.size.width,
    widget.device?.screenSize.height ?? stage.size.height,
  );

  Widget _previewSurface(
    BuildContext context,
    _DetailVariant variant,
    GlobalKey captureKey,
  ) {
    final preview = widget.inspectionContext == null
        ? DesyWidgetPreview(theme: widget.theme, builder: variant.builder)
        : DesyWorkbenchInspectionScope(
            context: widget.inspectionContext!,
            child: DesyWidgetPreview(
              theme: widget.theme,
              builder: variant.builder,
            ),
          );
    final accessiblePreview = _PreviewAccessibilityScope(
      settings: widget.accessibility,
      captureKey: captureKey,
      child: preview,
    );
    return Semantics(
      key: ValueKey('detail-instance-selector-${variant.id}'),
      container: true,
      selected: variant.id == _activeVariantId,
      label: variant.onSelect == null
          ? '${variant.name} preview'
          : '${variant.name} instance preview',
      child: Stack(
        fit: StackFit.expand,
        children: [
          KeyedSubtree(
            key: ValueKey('detail-preview-background-${variant.id}'),
            child: ColoredBox(
              key: widget.device == null
                  ? null
                  : ValueKey('detail-device-screen-${widget.device!.name}'),
              // A detail artboard must not invent a consumer background. The
              // surrounding canvas remains visible until the real widget
              // chooses to paint a surface of its own.
              color: Colors.transparent,
            ),
          ),
          Center(child: accessiblePreview),
        ],
      ),
    );
  }
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
  var _inspectorVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _inspectorVisible = true);
    });
  }

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
              child: _DetailControlSheet(
                visible: _inspectorVisible,
                child: widget.inspector,
              ),
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
            child: _DetailControlSheet(
              visible: _inspectorVisible,
              child: widget.inspector,
            ),
          ),
        ],
      );
    },
  );
}

class _DetailControlSheet extends StatelessWidget {
  const _DetailControlSheet({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) => DesyWorkbenchControlSheet(
    key: const ValueKey('detail-controls-sheet'),
    visible: visible,
    child: child,
  );
}

class _DetailPreviewToolbar extends StatelessWidget {
  const _DetailPreviewToolbar({
    required this.entry,
    required this.onOpenFolder,
    required this.onOpenCatalogue,
  });

  final DesyRegistryEntry entry;
  final ValueChanged<String>? onOpenFolder;
  final VoidCallback? onOpenCatalogue;

  @override
  Widget build(BuildContext context) => DesyWorkbenchBreadcrumbs(
    key: const ValueKey('detail-preview-toolbar'),
    textKey: const ValueKey('detail-breadcrumbs'),
    segments: [
      DesyWorkbenchBreadcrumb(label: 'all/', onOpen: onOpenCatalogue),
      for (final (index, folderName) in entry.folderNames.indexed)
        DesyWorkbenchBreadcrumb(
          label: folderName,
          onOpen: onOpenFolder == null
              ? null
              : () => onOpenFolder!(entry.folderIds[index]),
        ),
      DesyWorkbenchBreadcrumb(label: entry.name),
    ],
  );
}

class _DetailInspector extends StatelessWidget {
  const _DetailInspector({
    required this.session,
    required this.component,
    required this.entry,
    required this.values,
    required this.motionControls,
    required this.imageExportController,
  });

  final DesyWorkbenchSession session;
  final DesyRegistryComponent? component;
  final DesyRegistryEntry entry;
  final Map<String, Object> values;
  final Widget? motionControls;
  final _DetailImageExportController? imageExportController;

  @override
  Widget build(BuildContext context) {
    final accessibilitySegments = buildPreviewEnvironmentSegments(
      settings: session.previewAccessibility.watch(context),
      onChanged: session.setPreviewAccessibility,
      selectedDevice: session.previewDevice.watch(context),
      onDeviceChanged: session.selectPreviewDevice,
    );
    final componentSegments =
        component != null && component!.knobDefinitions.isNotEmpty
        ? DesyComponentKnobPanel.segments(
            registry: session.registry,
            knobs: component!.knobDefinitions,
            values: values,
            onChanged: session.setKnob,
            componentId: entry.id,
          )
        : [
            if (component != null)
              DesyKnobSegment(
                title: 'COMPONENT',
                children: [DesyTextValueKnobRow(label: 'ID', value: entry.id)],
              ),
          ];
    final primarySegments = <DesyKnobSegment>[
      if (motionControls case final controls?)
        DesyKnobSegment(
          title: 'PLAYBACK',
          description: 'Control this component animation preview.',
          children: [controls],
        ),
      ...componentSegments,
    ];
    final environmentSegments = <DesyKnobSegment>[
      ...accessibilitySegments,
      if (imageExportController case final controller?)
        DesyKnobSegment(
          title: 'IMAGE',
          description: 'Export the selected real preview.',
          children: [_DetailActionsSheet(controller: controller)],
        ),
    ];
    return ColoredBox(
      color: context.theme.colors.background,
      child: ListView(
        key: const ValueKey('detail-controls-list'),
        padding: EdgeInsets.zero,
        children: [
          if (primarySegments.isNotEmpty)
            DesyKnobSheet(segments: primarySegments),
          DesyDetailExtensionsRegion(session: session, entry: entry),
          if (environmentSegments.isNotEmpty)
            DesyKnobSheet(segments: environmentSegments),
        ],
      ),
    );
  }
}

class _DetailActionsSheet extends StatelessWidget {
  const _DetailActionsSheet({required this.controller});

  final _DetailImageExportController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => KeyedSubtree(
      key: const ValueKey('detail-actions-sheet'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DesyButton(
            key: const ValueKey('detail-export-image'),
            variant: DesyButtonVariant.primary,
            size: DesyButtonSize.md,
            onPress: controller.exporting ? null : controller.export,
            semanticsLabel: controller.exporting
                ? 'Exporting component image'
                : 'Export component image',
            child: const Text('Export image'),
          ),
          if (controller.status case final status?) ...[
            const SizedBox(height: DesyDesignSystemTokens.spaceSm),
            Semantics(
              key: const ValueKey('detail-export-image-status'),
              liveRegion: true,
              child: Text(
                status,
                style: context.theme.typography.body.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _PreviewAccessibilityScope extends StatelessWidget {
  const _PreviewAccessibilityScope({
    required this.settings,
    required this.captureKey,
    required this.child,
  });

  final DesyPreviewAccessibilitySettings settings;
  final GlobalKey captureKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final colors = context.theme.colors;
    final preview = RepaintBoundary(
      key: captureKey,
      child: MediaQuery(
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

/// A bounded stage for inspecting a real consumer widget at its artboard size.
///
/// A selected preset supplies the initial size only. The resulting drag box
/// remains a normal, freely resizable Flutter constraint boundary.
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
    final canvasBackground =
        theme.previewBackgroundColor ?? context.theme.colors.background;
    final viewportBackground = context.theme.colors.desy.panelSubtle;
    final gridLineColor =
        (canvasBackground.computeLuminance() > .5 ? Colors.black : Colors.white)
            .withValues(alpha: .10);
    return LayoutBuilder(
      builder: (context, constraints) {
        final selectionMinimumTop = toolbar == null
            ? 18.0
            : _selectionMinimumTop;
        // Device choices are viewport presets, not device frames. Their
        // dimensions become the actual artboard constraints and remain fully
        // editable, just like the responsive viewport.
        final size = Size(
          math.max(stage.size.width, _minimumBoxExtent),
          math.max(stage.size.height, _minimumBoxExtent),
        );
        final offset = Offset(
          math.max(stage.offset.dx, 12),
          math.max(stage.offset.dy, selectionMinimumTop),
        );
        return ColoredBox(
          color: viewportBackground,
          child: Stack(
            key: canvasKey,
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              if (toolbar case final toolbar?)
                Positioned(
                  top: _detailToolbarTop,
                  left: desyWorkbenchCanvasInset,
                  child: toolbar,
                ),
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
                ignoreChildPointer: false,
                onChanged: (geometry) => session.updateStage(
                  stage.copyWith(
                    offset: geometry.rect.topLeft,
                    size: geometry.rect.size,
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
                    child: SizedBox.expand(
                      child: ColoredBox(
                        key: device == null
                            ? null
                            : ValueKey('detail-device-screen-${device!.name}'),
                        color: canvasBackground,
                        child: DesyCanvasGridBackground(
                          backgroundColor: canvasBackground,
                          lineColor: gridLineColor,
                          child: child,
                        ),
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
}

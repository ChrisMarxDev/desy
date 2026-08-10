// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:state_beacon/state_beacon.dart';

import 'component_knob_panel.dart';
import 'desy_drag_box.dart';
import 'detail_extensions_region.dart';
import 'motion_playback_controls.dart';
import '../../device_preview.dart';
import '../../motion_playback.dart';
import '../../registry.dart';
import '../widget_preview.dart';
import '../workbench_session.dart';

const _minimumBoxExtent = 8.0;
const _detailToolbarTop = 12.0;
const _detailToolbarReservedHeight = 58.0;
const _toolbarSelectionGap = 8.0;
const _selectionLabelGap = 6.0;
const _selectionLabelReservedHeight = 28.0;

const _selectionMinimumTop =
    _detailToolbarTop + _detailToolbarReservedHeight + _toolbarSelectionGap;

double _boundedBoxExtent(double value) =>
    value < _minimumBoxExtent ? _minimumBoxExtent : value;

/// The inspect-and-adjust surface for a single entry.
class DesyDetailScreen extends StatefulWidget {
  const DesyDetailScreen({
    super.key,
    required this.session,
    required this.entry,
    this.onOpenFolder,
  });

  final DesyWorkbenchSession session;
  final DesyRegistryEntry entry;
  final ValueChanged<String>? onOpenFolder;

  @override
  State<DesyDetailScreen> createState() => _DesyDetailScreenState();
}

class _DesyDetailScreenState extends State<DesyDetailScreen>
    with TickerProviderStateMixin {
  String _selectedVariantId = 'default';
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
      for (final instanceId in component?.instanceIds ?? const [])
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
        toolbar: _DetailPreviewToolbar(
          session: session,
          entry: entry,
          selectedDevice: device,
          onOpenFolder: widget.onOpenFolder,
        ),
        variants: variants,
      ),
      inspector: _DetailInspector(
        session: session,
        component: component,
        entry: entry,
        values: values,
        selectedVariantName: variants
            .firstWhere((variant) => variant.selected)
            .name,
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
      child: Builder(builder: motion.builder),
    );
  }

  Widget _buildMotionControls() =>
      DesyMotionPlaybackControls(controller: _motionPlayback!);

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

class _DetailInstanceGallery extends StatelessWidget {
  const _DetailInstanceGallery({
    required this.session,
    required this.theme,
    required this.device,
    required this.toolbar,
    required this.variants,
  });

  final DesyWorkbenchSession session;
  final DesyTheme theme;
  final DesyDevicePreset? device;
  final Widget toolbar;
  final List<_DetailVariant> variants;

  @override
  Widget build(BuildContext context) {
    final stage = session.stage.watch(context);
    final viewerHeight = device == null
        ? (stage.size.height + 72).clamp(280, 640).toDouble()
        : 540.0;
    final background =
        theme.previewBackgroundColor ?? context.theme.colors.background;
    return ColoredBox(
      color: background,
      child: ListView.separated(
        key: const ValueKey('detail-instance-gallery'),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: variants.length + 1,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Align(alignment: Alignment.centerLeft, child: toolbar);
          }
          final variant = variants[index - 1];
          final isDefault = variant.id == 'default';
          return FocusableActionDetector(
            key: ValueKey('detail-instance-focus-${variant.id}'),
            enabled: variant.onSelect != null,
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
            },
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  variant.onSelect?.call();
                  return null;
                },
              ),
            },
            child: Semantics(
              key: ValueKey('detail-instance-selector-${variant.id}'),
              button: variant.onSelect != null,
              selected: variant.selected,
              onTap: variant.onSelect,
              label: variant.onSelect == null
                  ? '${variant.name} preview'
                  : '${variant.name} instance preview',
              child: SizedBox(
                key: ValueKey('detail-instance-viewer-${variant.id}'),
                height: viewerHeight,
                child: DesyPreviewCanvas(
                  session: session,
                  theme: theme,
                  device: device,
                  toolbar: null,
                  instanceLabel: variant.name,
                  selected: variant.selected,
                  onSelect: variant.onSelect,
                  canvasKey: isDefault
                      ? const ValueKey('detail-preview-canvas')
                      : ValueKey('detail-instance-canvas-${variant.id}'),
                  artboardKey: isDefault
                      ? const ValueKey('detail-artboard')
                      : ValueKey('detail-instance-artboard-${variant.id}'),
                  selectionLabelKey: isDefault
                      ? const ValueKey('detail-selection-size')
                      : ValueKey('detail-instance-label-${variant.id}'),
                  child: DesyWidgetPreview(
                    theme: theme,
                    builder: variant.builder,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The detail route's only content split.
///
/// ShellRoute owns the global sidebar. This row owns just the component
/// preview and its local controls, avoiding a second nested resizing system.
class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.preview, required this.inspector});

  final Widget preview;
  final Widget inspector;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final divider = ColoredBox(
        color: context.theme.colors.border,
        child: const SizedBox.expand(),
      );
      if (constraints.maxWidth < 720) {
        return Column(
          children: [
            Expanded(child: preview),
            SizedBox(height: 1, child: divider),
            SizedBox(height: 260, child: inspector),
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: preview),
          SizedBox(width: 1, child: divider),
          SizedBox(width: 320, child: inspector),
        ],
      );
    },
  );
}

class _DetailPreviewToolbar extends StatelessWidget {
  const _DetailPreviewToolbar({
    required this.session,
    required this.entry,
    required this.selectedDevice,
    required this.onOpenFolder,
  });

  final DesyWorkbenchSession session;
  final DesyRegistryEntry entry;
  final DesyDevicePreset? selectedDevice;
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
          const SizedBox(height: 5),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _button(context, label: 'Responsive', device: null),
              _button(
                context,
                label: 'iPhone 15 Pro',
                device: DesyDevicePreset.iPhone15Pro,
              ),
              _button(
                context,
                label: 'iPad Pro 11',
                device: DesyDevicePreset.iPadPro11,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _button(
    BuildContext context, {
    required String label,
    required DesyDevicePreset? device,
  }) => DesyButton(
    size: DesyButtonSize.xs,
    mainAxisSize: MainAxisSize.min,
    variant: selectedDevice == device
        ? DesyButtonVariant.primary
        : DesyButtonVariant.outline,
    onPress: () => session.selectPreviewDevice(device),
    child: Text(label),
  );
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
    required this.selectedVariantName,
    required this.motionControls,
  });

  final DesyWorkbenchSession session;
  final DesyRegistryComponent? component;
  final DesyRegistryEntry entry;
  final Map<String, Object> values;
  final String selectedVariantName;
  final Widget? motionControls;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.theme.colors.muted,
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Controls', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Editing $selectedVariantName',
          key: const ValueKey('detail-selected-instance'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (motionControls case final controls?) ...[
          const SizedBox(height: 20),
          controls,
        ],
        if (component != null && component!.knobDefinitions.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Knobs', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          DesyComponentKnobPanel(
            registry: session.registry,
            knobs: component!.knobDefinitions,
            values: values,
            onChanged: session.setKnob,
          ),
        ],
        if (motionControls == null &&
            (component == null ||
                (component!.knobDefinitions.isEmpty &&
                    component!.scenarios.isEmpty &&
                    component!.instanceIds.isEmpty))) ...[
          const SizedBox(height: 12),
          Text(
            'No controls declared.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        DesyDetailExtensionsRegion(session: session, entry: entry),
      ],
    ),
  );
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
          color:
              theme.previewBackgroundColor ?? context.theme.colors.background,
          child: CustomPaint(
            painter: _DottedPreviewPainter(
              background:
                  theme.previewBackgroundColor ??
                  context.theme.colors.background,
            ),
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
                  ignoreChildPointer: false,
                  onDoubleTap: device == null
                      ? null
                      : () => session.selectPreviewDevice(device),
                  geometryResolver: device == null
                      ? null
                      : (geometry, interaction) => DesyDragBoxGeometry(
                          rect: DesyDeviceGeometry.lockFrameAspect(
                            preset: device!,
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
                    size: device?.screenSize ?? stage.size,
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
                                child: Align(
                                  alignment: Alignment.center,
                                  child: child,
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

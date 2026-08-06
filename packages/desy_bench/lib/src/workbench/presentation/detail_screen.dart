// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:state_beacon/state_beacon.dart';

import 'component_knob_panel.dart';
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
class DesyDetailScreen extends StatelessWidget {
  const DesyDetailScreen({
    super.key,
    required this.session,
    required this.entry,
  });

  final DesyWorkbenchSession session;
  final DesyRegistryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = session.activeTheme;
    final scenario = session.selectedScenario.watch(context);
    final selectedInstance = session.selectedComponentInstance.watch(context);
    final bezel = session.previewBezel.watch(context);
    final values = session.knobValues.watch(context);
    final component = entry.component;
    final preview = DesyWidgetPreview(
      theme: theme,
      builder: (context) => scenario != null
          ? scenario.builder(context)
          : selectedInstance != null
          ? component!.buildInstance(context, selectedInstance)
          : component == null
          ? entry.builder(context)
          : component.buildWithKnobs?.call(context, DesyKnobValues(values)) ??
                component.preview(context),
    );

    return _DetailBody(
      preview: DesyPreviewCanvas(
        session: session,
        theme: theme,
        bezel: bezel,
        toolbar: _DetailPreviewToolbar(
          session: session,
          entry: entry,
          selectedBezel: bezel,
        ),
        child: preview,
      ),
      inspector: _DetailInspector(
        session: session,
        component: component,
        entry: entry,
        selectedScenario: scenario,
        selectedInstance: selectedInstance,
        values: values,
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
    required this.selectedBezel,
  });

  final DesyWorkbenchSession session;
  final DesyRegistryEntry entry;
  final DesyPreviewBezel? selectedBezel;

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
          _DetailBreadcrumbs(entry: entry),
          const SizedBox(height: 5),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _button(context, label: 'Canvas', bezel: null),
              _button(
                context,
                label: 'iPhone 15 Pro',
                bezel: DesyPreviewBezel.iPhone15Pro,
              ),
              _button(
                context,
                label: 'iPad Pro 11',
                bezel: DesyPreviewBezel.iPadPro11,
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
    required DesyPreviewBezel? bezel,
  }) => FButton(
    size: FButtonSizeVariant.xs,
    mainAxisSize: MainAxisSize.min,
    variant: selectedBezel == bezel
        ? FButtonVariant.primary
        : FButtonVariant.outline,
    onPress: () => session.selectPreviewBezel(bezel),
    child: Text(label),
  );
}

class _DetailBreadcrumbs extends StatelessWidget {
  const _DetailBreadcrumbs({required this.entry});

  final DesyRegistryEntry entry;

  @override
  Widget build(BuildContext context) {
    final segments = [...entry.folderNames, entry.name];
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: context.theme.colors.mutedForeground,
    );
    return Semantics(
      label: 'Breadcrumb ${segments.join(', ')}',
      excludeSemantics: true,
      child: Wrap(
        key: const ValueKey('detail-breadcrumbs'),
        spacing: 3,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var index = 0; index < segments.length; index++) ...[
            if (index > 0)
              Icon(
                FLucideIcons.chevronRight,
                size: 11,
                color: context.theme.colors.mutedForeground,
              ),
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
    required this.selectedScenario,
    required this.selectedInstance,
    required this.values,
  });

  final DesyWorkbenchSession session;
  final DesyComponent? component;
  final DesyRegistryEntry entry;
  final DesyComponentScenario? selectedScenario;
  final DesyComponentInstance? selectedInstance;
  final Map<String, Object> values;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.theme.colors.muted,
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Controls', style: Theme.of(context).textTheme.titleMedium),
        if (component != null && component!.scenarios.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Instances', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          _InstanceSelector(
            selected: selectedScenario,
            scenarios: component!.scenarios,
            onChanged: session.selectScenario,
          ),
        ],
        if (component != null && component!.instances.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Component instances',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          _ComponentInstanceSelector(
            instances: component!.instances,
            selected: selectedInstance,
            onSelect: session.applyInstance,
          ),
        ],
        if (component != null && component!.knobs.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Knobs', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          DesyComponentKnobPanel(
            knobs: component!.knobs,
            values: values,
            onChanged: session.setKnob,
          ),
        ],
        if (component == null ||
            (component!.knobs.isEmpty &&
                component!.scenarios.isEmpty &&
                component!.instances.isEmpty)) ...[
          const SizedBox(height: 12),
          Text(
            'No controls declared.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    ),
  );
}

class _InstanceSelector extends StatelessWidget {
  const _InstanceSelector({
    required this.selected,
    required this.scenarios,
    required this.onChanged,
  });

  final DesyComponentScenario? selected;
  final List<DesyComponentScenario> scenarios;
  final ValueChanged<DesyComponentScenario?> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      FButton(
        size: FButtonSizeVariant.sm,
        mainAxisSize: MainAxisSize.min,
        variant: selected == null
            ? FButtonVariant.primary
            : FButtonVariant.outline,
        onPress: () => onChanged(null),
        child: const Text('Default'),
      ),
      for (final scenario in scenarios)
        FButton(
          size: FButtonSizeVariant.xs,
          mainAxisSize: MainAxisSize.min,
          variant: selected?.id == scenario.id
              ? FButtonVariant.primary
              : FButtonVariant.outline,
          onPress: () => onChanged(scenario),
          child: Text(scenario.name),
        ),
    ],
  );
}

class _ComponentInstanceSelector extends StatelessWidget {
  const _ComponentInstanceSelector({
    required this.instances,
    required this.selected,
    required this.onSelect,
  });

  final List<DesyComponentInstance> instances;
  final DesyComponentInstance? selected;
  final ValueChanged<DesyComponentInstance> onSelect;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final instance in instances)
        FTile(
          title: Text(instance.name, overflow: TextOverflow.ellipsis),
          subtitle: instance.description == null
              ? null
              : Text(
                  instance.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          suffix: selected?.id == instance.id
              ? const Icon(FLucideIcons.check)
              : null,
          onPress: () => onSelect(instance),
        ),
    ],
  );
}

/// A bounded stage for inspecting a real consumer widget in its theme.
class DesyPreviewCanvas extends StatelessWidget {
  const DesyPreviewCanvas({
    super.key,
    required this.session,
    required this.theme,
    required this.bezel,
    required this.toolbar,
    required this.child,
  });

  final DesyWorkbenchSession session;
  final DesyTheme theme;
  final DesyPreviewBezel? bezel;
  final Widget toolbar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final stage = session.stage.watch(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = (constraints.maxWidth - 24).clamp(
          _minimumBoxExtent,
          double.infinity,
        );
        final maxHeight =
            (constraints.maxHeight -
                    _selectionMinimumTop -
                    12 -
                    _selectionLabelGap -
                    _selectionLabelReservedHeight)
                .clamp(_minimumBoxExtent, double.infinity);
        final scale = math.min(
          1,
          math.min(maxWidth / stage.size.width, maxHeight / stage.size.height),
        );
        final size = Size(
          (stage.size.width * scale).clamp(_minimumBoxExtent, maxWidth),
          (stage.size.height * scale).clamp(_minimumBoxExtent, maxHeight),
        );
        final offset = Offset(
          stage.offset.dx.clamp(
            12,
            (constraints.maxWidth - size.width - 12).clamp(12, double.infinity),
          ),
          stage.offset.dy.clamp(
            _selectionMinimumTop,
            (constraints.maxHeight -
                    size.height -
                    12 -
                    _selectionLabelGap -
                    _selectionLabelReservedHeight)
                .clamp(_selectionMinimumTop, double.infinity),
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
              key: const ValueKey('detail-preview-canvas'),
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(top: _detailToolbarTop, left: 12, child: toolbar),
                Positioned(
                  left: offset.dx,
                  top: offset.dy,
                  width: size.width,
                  height: size.height,
                  child: _Artboard(
                    key: const ValueKey('detail-artboard'),
                    bezel: bezel,
                    onMove: (details) => session.updateStage(
                      stage.copyWith(offset: offset + details.delta),
                    ),
                    onResize: (details, corner) {
                      final resizeFromLeft =
                          corner == _ArtboardCorner.topLeft ||
                          corner == _ArtboardCorner.bottomLeft;
                      final resizeFromTop =
                          corner == _ArtboardCorner.topLeft ||
                          corner == _ArtboardCorner.topRight;
                      final nextSize = Size(
                        _boundedBoxExtent(
                          stage.size.width +
                              (resizeFromLeft
                                  ? -details.delta.dx
                                  : details.delta.dx),
                        ),
                        _boundedBoxExtent(
                          stage.size.height +
                              (resizeFromTop
                                  ? -details.delta.dy
                                  : details.delta.dy),
                        ),
                      );
                      session.updateStage(
                        stage.copyWith(
                          offset:
                              offset +
                              Offset(
                                resizeFromLeft
                                    ? stage.size.width - nextSize.width
                                    : 0,
                                resizeFromTop
                                    ? stage.size.height - nextSize.height
                                    : 0,
                              ),
                          size: nextSize,
                        ),
                      );
                    },
                    child: child,
                  ),
                ),
                Positioned(
                  left: offset.dx,
                  top: offset.dy + size.height + _selectionLabelGap,
                  child: _SelectionSizeLabel(size: stage.size),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SelectionSizeLabel extends StatelessWidget {
  const _SelectionSizeLabel({required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    final label = '${size.width.round()} × ${size.height.round()} px';
    final colors = context.theme.colors;
    return IgnorePointer(
      child: Semantics(
        label:
            'Selection size ${size.width.round()} by ${size.height.round()} pixels',
        child: DecoratedBox(
          key: const ValueKey('detail-selection-size'),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colors.primaryForeground),
            ),
          ),
        ),
      ),
    );
  }
}

class _Artboard extends StatelessWidget {
  const _Artboard({
    super.key,
    required this.child,
    required this.bezel,
    required this.onMove,
    required this.onResize,
  });

  final Widget child;
  final DesyPreviewBezel? bezel;
  final GestureDragUpdateCallback onMove;
  final void Function(DragUpdateDetails details, _ArtboardCorner corner)
  onResize;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: context.theme.colors.primary),
    ),
    child: Stack(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.move,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: onMove,
            child: SizedBox.expand(
              child: ClipRect(
                child: Center(
                  child: bezel == null
                      ? DesyFittedPreview(child: child)
                      : _DeviceBezel(bezel: bezel!, child: child),
                ),
              ),
            ),
          ),
        ),
        for (final corner in _ArtboardCorner.values)
          _ArtboardHandle(corner: corner, onResize: onResize),
      ],
    ),
  );
}

class _DeviceBezel extends StatelessWidget {
  const _DeviceBezel({required this.bezel, required this.child});

  final DesyPreviewBezel bezel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final device = bezel.device;
    return Semantics(
      label: '${bezel.label} preview bezel',
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: device.frameSize.width,
          height: device.frameSize.height,
          child: DeviceFrame(
            device: device,
            screen: Align(alignment: Alignment.center, child: child),
          ),
        ),
      ),
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

extension on DesyPreviewBezel {
  String get label => switch (this) {
    DesyPreviewBezel.iPhone15Pro => 'iPhone 15 Pro',
    DesyPreviewBezel.iPadPro11 => 'iPad Pro 11',
  };
}

enum _ArtboardCorner { topLeft, topRight, bottomLeft, bottomRight }

class _ArtboardHandle extends StatelessWidget {
  const _ArtboardHandle({required this.corner, required this.onResize});

  final _ArtboardCorner corner;
  final void Function(DragUpdateDetails details, _ArtboardCorner corner)
  onResize;

  @override
  Widget build(BuildContext context) {
    final isLeft =
        corner == _ArtboardCorner.topLeft ||
        corner == _ArtboardCorner.bottomLeft;
    final isTop =
        corner == _ArtboardCorner.topLeft || corner == _ArtboardCorner.topRight;
    final cursor = (isLeft == isTop)
        ? SystemMouseCursors.resizeUpLeftDownRight
        : SystemMouseCursors.resizeUpRightDownLeft;
    return Positioned(
      left: isLeft ? -1 : null,
      top: isTop ? -1 : null,
      right: isLeft ? null : -1,
      bottom: isTop ? null : -1,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) => onResize(details, corner),
          child: SizedBox(
            width: 20,
            height: 20,
            child: Align(
              alignment: Alignment(isLeft ? -1 : 1, isTop ? -1 : 1),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: context.theme.colors.background,
                  border: Border.all(
                    color: context.theme.colors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

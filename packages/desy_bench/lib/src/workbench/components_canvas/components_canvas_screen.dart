// This screen is an internal workbench module, not consumer-facing package API.
// ignore_for_file: public_member_api_docs

import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_box_transform/flutter_box_transform.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../registry.dart';
import '../presentation/component_knob_panel.dart';
import '../widget_preview.dart';
import '../workbench_session.dart';
import 'components_canvas_controller.dart';

/// A local composition surface built entirely from named registry instances.
///
/// The palette presents every named component instance as a live preview.
/// Canvas state stays ephemeral.
class DesyComponentsCanvas extends StatefulWidget {
  const DesyComponentsCanvas({
    super.key,
    required this.session,
    required this.onBack,
    this.controller,
  });

  final DesyWorkbenchSession session;
  final VoidCallback onBack;
  final DesyComponentsCanvasController? controller;

  @override
  State<DesyComponentsCanvas> createState() => _DesyComponentsCanvasState();
}

class _DesyComponentsCanvasState extends State<DesyComponentsCanvas> {
  late final DesyComponentsCanvasController _controller =
      widget.controller ?? DesyComponentsCanvasController();
  late final bool _ownsController = widget.controller == null;

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nodes = _controller.nodes.watch(context);
    final selectedId = _controller.selectedId.watch(context);
    final themeIndex = widget.session.activeThemeIndex.watch(context);
    final theme = widget.session.registry.themes[themeIndex];
    final instances = widget.session.registry.allComponentInstances;
    final selectedNode = selectedId == null ? null : nodes[selectedId];
    final selectedInstance = selectedNode?.isComponent != true
        ? null
        : _instanceFor(instances, selectedNode!.instanceId!);

    return SelectionContainer.disabled(
      key: const ValueKey('sketch-selection-disabled'),
      // The Sketch is a drag surface, not a document. Keep all of its live
      // responsive panels out of the shell's document-selection registrar;
      // selection remains available in the persistent catalogue chrome.
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SketchHeader(onBack: widget.onBack, onClear: _controller.clear),
            const SizedBox(height: 12),
            _SketchPreviewToolbar(onAddArtboard: _controller.addArtboard),
            const SizedBox(height: 12),
            Expanded(
              child: _SketchWorkspace(
                palette: _ComponentPalette(
                  registry: widget.session.registry,
                  theme: theme,
                  onSelect: _addInstance,
                ),
                outline: _CanvasOutline(
                  nodes: nodes.values.toList().reversed,
                  instances: instances,
                  selectedId: selectedId,
                  onSelect: _controller.select,
                ),
                canvas: _CanvasStage(
                  instances: instances,
                  nodes: nodes,
                  selectedId: selectedId,
                  theme: theme,
                  controller: _controller,
                ),
                inspector: selectedNode == null
                    ? null
                    : selectedNode.isArtboard
                    ? _CanvasArtboardInspector(
                        node: selectedNode,
                        controller: _controller,
                      )
                    : selectedInstance == null
                    ? null
                    : _CanvasInspector(
                        node: selectedNode,
                        instance: selectedInstance,
                        controller: _controller,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addInstance(DesyRegisteredComponentInstance instance) {
    final values = <String, Object>{
      for (final knob in instance.component.knobs) knob.id: knob.initial,
      ...instance.instance.knobValues.entries,
    };
    _controller.add(instance.id, knobValues: values);
  }

  DesyRegisteredComponentInstance? _instanceFor(
    List<DesyRegisteredComponentInstance> instances,
    String id,
  ) {
    for (final instance in instances) {
      if (instance.id == id) return instance;
    }
    return null;
  }
}

/// Adds editable visual device bezels to the composition.
class _SketchPreviewToolbar extends StatelessWidget {
  const _SketchPreviewToolbar({required this.onAddArtboard});

  final ValueChanged<DesyCanvasArtboard> onAddArtboard;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      key: const ValueKey('sketch-preview-toolbar'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: colors.secondary,
        border: Border.all(color: colors.border),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          const Text('Add bezel'),
          _button(
            label: 'iPhone 15 Pro',
            value: DesyCanvasArtboard.iPhone15Pro,
          ),
          _button(label: 'iPad Pro 11', value: DesyCanvasArtboard.iPadPro11),
        ],
      ),
    );
  }

  Widget _button({required String label, required DesyCanvasArtboard value}) =>
      DesyButton(
        key: ValueKey('sketch-add-artboard-${value.name}'),
        size: DesyButtonSize.xs,
        mainAxisSize: MainAxisSize.min,
        variant: DesyButtonVariant.outline,
        onPress: () => onAddArtboard(value),
        child: Text(label),
      );
}

class _SketchWorkspace extends StatelessWidget {
  const _SketchWorkspace({
    required this.palette,
    required this.outline,
    required this.canvas,
    required this.inspector,
  });

  final Widget palette;
  final Widget outline;
  final Widget canvas;
  final Widget? inspector;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final details = inspector;
      if (constraints.maxWidth < 620) {
        return Column(
          children: [
            SizedBox(
              height: 260,
              child: _SketchSidebar(palette: palette, outline: outline),
            ),
            const SizedBox(height: 12),
            Expanded(child: canvas),
            if (details != null) ...[
              const SizedBox(height: 12),
              SizedBox(height: 250, child: details),
            ],
          ],
        );
      }
      if (constraints.maxWidth < 1000) {
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 230,
                    child: _SketchSidebar(palette: palette, outline: outline),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: canvas),
                ],
              ),
            ),
            if (details != null) ...[
              const SizedBox(height: 16),
              SizedBox(height: 250, child: details),
            ],
          ],
        );
      }
      return Row(
        children: [
          SizedBox(
            width: 260,
            child: _SketchSidebar(palette: palette, outline: outline),
          ),
          const SizedBox(width: 16),
          Expanded(child: canvas),
          if (details != null) ...[
            const SizedBox(width: 16),
            SizedBox(width: 300, child: details),
          ],
        ],
      );
    },
  );
}

class _SketchSidebar extends StatelessWidget {
  const _SketchSidebar({required this.palette, required this.outline});

  final Widget palette;
  final Widget outline;

  @override
  Widget build(BuildContext context) => DesyTabs(
    key: const ValueKey('sketch-sidebar-tabs'),
    expands: true,
    children: [
      DesyTabEntry(
        label: Semantics(
          label: 'Components',
          button: true,
          child: const Icon(
            DesyIcons.boxes,
            key: ValueKey('sketch-tab-components'),
            size: 16,
          ),
        ),
        child: palette,
      ),
      DesyTabEntry(
        label: Semantics(
          label: 'Layers',
          button: true,
          child: const Icon(
            DesyIcons.layers,
            key: ValueKey('sketch-tab-layers'),
            size: 16,
          ),
        ),
        child: outline,
      ),
    ],
  );
}

class _SketchHeader extends StatelessWidget {
  const _SketchHeader({required this.onBack, required this.onClear});

  final VoidCallback onBack;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesyButton(
            variant: DesyButtonVariant.ghost,
            size: DesyButtonSize.sm,
            mainAxisSize: MainAxisSize.min,
            onPress: onBack,
            child: const Row(
              children: [
                Icon(DesyIcons.arrowLeft, size: 16),
                SizedBox(width: 6),
                Text('Back'),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const DesyKeyboardShortcutLabel(
            keys: ['Esc'],
            semanticLabel: 'Escape returns to the atlas',
          ),
        ],
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('COMPOSITION', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(
              'Screen sketch',
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ],
        ),
      ),
      DesyButton.icon(
        variant: DesyButtonVariant.outline,
        size: DesyButtonSize.sm,
        onPress: onClear,
        child: const Icon(DesyIcons.layers),
      ),
    ],
  );
}

class _ComponentPalette extends StatelessWidget {
  const _ComponentPalette({
    required this.registry,
    required this.theme,
    required this.onSelect,
  });

  final DesyRegistry registry;
  final DesyTheme theme;
  final ValueChanged<DesyRegisteredComponentInstance> onSelect;

  @override
  Widget build(BuildContext context) {
    final instances = registry.allComponentInstances;
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final tileExtent = (132 + (textScale.clamp(1, 2) - 1) * 36).toDouble();
    return DesyCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('COMPONENTS', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(
              '${instances.length} elements · choose to add',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: instances.isEmpty
                  ? const Center(child: Text('No component instances yet'))
                  : GridView.builder(
                      key: const ValueKey('sketch-component-grid'),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: tileExtent,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: instances.length,
                      itemBuilder: (context, index) => _ComponentPreviewTile(
                        instance: instances[index],
                        theme: theme,
                        height: tileExtent - 24,
                        onSelect: onSelect,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComponentPreviewTile extends StatelessWidget {
  const _ComponentPreviewTile({
    required this.instance,
    required this.theme,
    required this.height,
    required this.onSelect,
  });

  final DesyRegisteredComponentInstance instance;
  final DesyTheme theme;
  final double height;
  final ValueChanged<DesyRegisteredComponentInstance> onSelect;

  @override
  Widget build(BuildContext context) => DesyButton(
    key: ValueKey('palette-instance-${instance.id}'),
    semanticsLabel:
        'Add ${instance.componentName}, ${instance.instance.name} to sketch',
    semanticsTooltip: 'Add to sketch',
    variant: DesyButtonVariant.outline,
    size: DesyButtonSize.xs,
    onPress: () => onSelect(instance),
    child: SizedBox(
      width: 76,
      height: height,
      child: Column(
        children: [
          Expanded(
            child: ClipRect(
              child: IgnorePointer(
                child: DesyFittedPreview(
                  key: ValueKey('palette-preview-${instance.id}'),
                  child: DesyWidgetPreview(
                    theme: theme,
                    builder: instance.build,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            instance.instance.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            instance.componentName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    ),
  );
}

class _CanvasInspector extends StatelessWidget {
  const _CanvasInspector({
    required this.node,
    required this.instance,
    required this.controller,
  });

  final DesyCanvasNode node;
  final DesyRegisteredComponentInstance instance;
  final DesyComponentsCanvasController controller;

  @override
  Widget build(BuildContext context) => DesyCard(
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('INSTANCE', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(
          instance.instance.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          instance.component.name,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (instance.instance.description case final description?) ...[
          const SizedBox(height: 12),
          Text(description, style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: 24),
        Text('Knobs', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        if (instance.component.knobs.isEmpty)
          Text(
            'No knobs declared.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        DesyComponentKnobPanel(
          knobs: instance.component.knobs,
          values: node.knobValues,
          onChanged: (knob, value) =>
              controller.setKnob(node.id, knob.id, value),
        ),
        const SizedBox(height: 16),
        DesyButton(
          variant: DesyButtonVariant.outline,
          size: DesyButtonSize.sm,
          onPress: () => controller.remove(node.id),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
}

class _CanvasArtboardInspector extends StatelessWidget {
  const _CanvasArtboardInspector({
    required this.node,
    required this.controller,
  });

  final DesyCanvasNode node;
  final DesyComponentsCanvasController controller;

  @override
  Widget build(BuildContext context) => DesyCard(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BEZEL', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            node.artboard!.label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'A visual canvas item. Components can overlap it, but remain independent layers.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          DesyButton(
            variant: DesyButtonVariant.outline,
            size: DesyButtonSize.sm,
            onPress: () => controller.remove(node.id),
            child: const Text('Remove bezel'),
          ),
        ],
      ),
    ),
  );
}

/// A compact layer-like view of the current, ephemeral composition.
///
/// This is intentionally derived from canvas nodes rather than from the
/// registry, so selecting it can never create a second source of truth.
class _CanvasOutline extends StatelessWidget {
  const _CanvasOutline({
    required this.nodes,
    required this.instances,
    required this.selectedId,
    required this.onSelect,
  });

  final Iterable<DesyCanvasNode> nodes;
  final List<DesyRegisteredComponentInstance> instances;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final placedNodes = nodes.toList(growable: false);
    return DesyCard(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LAYERS', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 2),
            Text(
              '${placedNodes.length} element${placedNodes.length == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Expanded(
              child: placedNodes.isEmpty
                  ? Center(
                      child: Text(
                        'Placed elements appear here.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  : ListView.builder(
                      itemCount: placedNodes.length,
                      itemBuilder: (context, index) {
                        final node = placedNodes[index];
                        if (node.isArtboard) {
                          return DesyTile(
                            key: ValueKey('canvas-node-${node.id}'),
                            selected: selectedId == node.id,
                            onPress: () => onSelect(node.id),
                            prefix: Icon(node.artboard!.icon, size: 16),
                            title: Text(node.artboard!.label),
                            subtitle: const Text('Bezel'),
                          );
                        }
                        final instance = _instanceFor(node.instanceId!);
                        if (instance == null) return const SizedBox.shrink();
                        return DesyTile(
                          key: ValueKey('canvas-node-${node.id}'),
                          selected: selectedId == node.id,
                          onPress: () => onSelect(node.id),
                          prefix: const Icon(DesyIcons.boxes, size: 16),
                          title: Text(
                            instance.instance.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            instance.component.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  DesyRegisteredComponentInstance? _instanceFor(String id) {
    for (final instance in instances) {
      if (instance.id == id) return instance;
    }
    return null;
  }
}

class _CanvasStage extends StatelessWidget {
  const _CanvasStage({
    required this.instances,
    required this.nodes,
    required this.selectedId,
    required this.theme,
    required this.controller,
  });

  final List<DesyRegisteredComponentInstance> instances;
  final Map<String, DesyCanvasNode> nodes;
  final String? selectedId;
  final DesyTheme theme;
  final DesyComponentsCanvasController controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final clampingRect = Rect.fromLTWH(
        0,
        0,
        constraints.maxWidth,
        constraints.maxHeight,
      );
      // Bounds normalization can update watched nodes, so apply layout-driven
      // stage changes after this build has completed.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => controller.setStageBounds(clampingRect),
      );
      return DecoratedBox(
        decoration: BoxDecoration(
          color:
              theme.previewBackgroundColor ?? context.theme.colors.background,
        ),
        child: CustomPaint(
          painter: _CanvasGridPainter(
            minorColor: context.theme.colors.border,
            majorColor: context.theme.colors.mutedForeground,
          ),
          child: Stack(
            key: const ValueKey('sketch-stage'),
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  key: const ValueKey('sketch-background'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => controller.select(null),
                ),
              ),
              if (nodes.isEmpty)
                const Center(
                  child: Text('Choose an instance from the palette.'),
                ),
              for (final node in nodes.values)
                if (node.isArtboard)
                  _CanvasTransformableNode(
                    node: node,
                    selected: selectedId == node.id,
                    clampingRect: clampingRect,
                    minSize: const Size(8, 8),
                    controller: controller,
                    child: _CanvasArtboard(artboardNode: node, theme: theme),
                  )
                else if (_instanceFor(node.instanceId!) case final instance?)
                  _CanvasTransformableNode(
                    node: node,
                    selected: selectedId == node.id,
                    clampingRect: clampingRect,
                    minSize: const Size(8, 8),
                    controller: controller,
                    child: _CanvasElement(
                      instance: instance,
                      node: node,
                      theme: theme,
                      selected: selectedId == node.id,
                    ),
                  ),
            ],
          ),
        ),
      );
    },
  );

  DesyRegisteredComponentInstance? _instanceFor(String id) {
    for (final instance in instances) {
      if (instance.id == id) return instance;
    }
    return null;
  }
}

/// A flat, freely overlapping canvas layer with minimal Figma-like handles.
class _CanvasTransformableNode extends StatelessWidget {
  const _CanvasTransformableNode({
    required this.node,
    required this.selected,
    required this.clampingRect,
    required this.minSize,
    required this.controller,
    required this.child,
  });

  final DesyCanvasNode node;
  final bool selected;
  final Rect clampingRect;
  final Size minSize;
  final DesyComponentsCanvasController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TransformableBox(
      key: ValueKey(node.id),
      rect: node.rect,
      flip: node.flip,
      clampingRect: clampingRect,
      constraints: BoxConstraints(
        minWidth: minSize.width,
        minHeight: minSize.height,
      ),
      allowContentFlipping: false,
      allowFlippingWhileResizing: false,
      handleAlignment: HandleAlignment.inside,
      handleTapSize: 18,
      resizable: selected,
      draggable: selected,
      visibleHandles: selected ? const {...HandlePosition.values} : const {},
      enabledHandles: selected ? const {...HandlePosition.values} : const {},
      onTap: () => controller.select(node.id),
      onChanged: (result, _) {
        final snapped = _CanvasGrid.snapRect(result.rect);
        if (node.isArtboard) {
          final isTranslation =
              (result.rect.width - node.rect.width).abs() < 0.001 &&
              (result.rect.height - node.rect.height).abs() < 0.001;
          controller.update(
            node.copyWith(
              rect: isTranslation
                  ? Rect.fromLTWH(
                      snapped.left,
                      snapped.top,
                      node.rect.width,
                      node.rect.height,
                    )
                  : DesyCanvasGeometry.lockFrameAspect(
                      node,
                      snapped,
                      clampingRect: clampingRect,
                    ),
              flip: result.flip,
            ),
          );
        } else {
          controller.update(node.copyWith(rect: snapped, flip: result.flip));
        }
      },
      cornerHandleBuilder: (context, handle) => DefaultCornerHandle(
        handle: handle,
        size: 6,
        decoration: BoxDecoration(
          color: context.theme.colors.background,
          borderRadius: BorderRadius.circular(1),
          border: Border.all(color: context.theme.colors.primary, width: 1.25),
        ),
      ),
      sideHandleBuilder: (context, handle) => DefaultSideHandle(
        handle: handle,
        length: 6,
        thickness: 6,
        decoration: BoxDecoration(
          color: context.theme.colors.primary,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
      contentBuilder: (context, rect, flip) => Listener(
        key: ValueKey('canvas-hit-${node.id}'),
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => controller.select(node.id),
        child: IgnorePointer(child: child),
      ),
    );
  }
}

class _CanvasArtboard extends StatelessWidget {
  const _CanvasArtboard({required this.artboardNode, required this.theme});

  final DesyCanvasNode artboardNode;
  final DesyTheme theme;

  DeviceInfo get _device =>
      DesyCanvasGeometry.deviceFor(artboardNode.artboard!);

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: FittedBox(
      fit: BoxFit.fill,
      child: SizedBox(
        width: _device.frameSize.width,
        height: _device.frameSize.height,
        child: DeviceFrame(
          device: _device,
          screen: ColoredBox(
            color:
                theme.previewBackgroundColor ??
                Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
    ),
  );
}

extension on DesyCanvasArtboard {
  String get label => switch (this) {
    DesyCanvasArtboard.iPhone15Pro => 'iPhone 15 Pro',
    DesyCanvasArtboard.iPadPro11 => 'iPad Pro 11',
  };

  IconData get icon => switch (this) {
    DesyCanvasArtboard.iPhone15Pro => DesyIcons.smartphone,
    DesyCanvasArtboard.iPadPro11 => DesyIcons.tablet,
  };
}

/// The shared geometry unit for the lightweight composition grid.
class _CanvasGrid {
  static const step = 8.0;
  static const majorStep = step * 8;

  static Rect snapRect(Rect rect) => Rect.fromLTWH(
    _snap(rect.left),
    _snap(rect.top),
    _snap(rect.width),
    _snap(rect.height),
  );

  static double _snap(double value) => (value / step).round() * step;
}

class _CanvasGridPainter extends CustomPainter {
  const _CanvasGridPainter({
    required this.minorColor,
    required this.majorColor,
  });

  final Color minorColor;
  final Color majorColor;

  @override
  void paint(Canvas canvas, Size size) {
    final minor = Paint()
      ..color = minorColor.withAlpha(40)
      ..strokeWidth = 0.5;
    final major = Paint()
      ..color = majorColor.withAlpha(50)
      ..strokeWidth = 1;

    for (var x = 0.0; x <= size.width; x += _CanvasGrid.step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        x % _CanvasGrid.majorStep == 0 ? major : minor,
      );
    }
    for (var y = 0.0; y <= size.height; y += _CanvasGrid.step) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        y % _CanvasGrid.majorStep == 0 ? major : minor,
      );
    }
  }

  @override
  bool shouldRepaint(_CanvasGridPainter oldDelegate) =>
      oldDelegate.minorColor != minorColor ||
      oldDelegate.majorColor != majorColor;
}

/// A placed component has no Desy-owned card or title bar. The only chrome is
/// the selection outline drawn while editing; the actual widget stays wholly
/// consumer-owned and receives loose constraints inside its composition frame.
class _CanvasElement extends StatelessWidget {
  const _CanvasElement({
    required this.instance,
    required this.node,
    required this.theme,
    required this.selected,
  });

  final DesyRegisteredComponentInstance instance;
  final DesyCanvasNode node;
  final DesyTheme theme;
  final bool selected;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ClipRect(
        child: Align(
          alignment: Alignment.topLeft,
          child: DesyFittedPreview(
            child: DesyWidgetPreview(
              theme: theme,
              builder: (context) => instance.component.buildWithKnobs == null
                  ? instance.component.buildInstance(context, instance.instance)
                  : instance.component.buildWithKnobs!(
                      context,
                      DesyKnobValues(node.knobValues),
                    ),
            ),
          ),
        ),
      ),
      if (selected)
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: context.theme.colors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
    ],
  );
}

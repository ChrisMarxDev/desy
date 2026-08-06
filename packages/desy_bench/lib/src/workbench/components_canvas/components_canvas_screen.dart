// This screen is an internal workbench module, not consumer-facing package API.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_box_transform/flutter_box_transform.dart';
import 'package:device_preview/device_preview.dart';
import 'package:forui/forui.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../keyboard_shortcut_label.dart';
import '../../registry.dart';
import '../presentation/component_knob_panel.dart';
import '../widget_preview.dart';
import '../workbench_session.dart';
import 'components_canvas_controller.dart';

/// A local composition surface built entirely from named registry instances.
///
/// The palette preserves catalogue folders, then component names, with actual
/// named instances as its only selectable leaves. Canvas state stays ephemeral.
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

/// Adds editable device-screen artboards to the composition.
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
          const Text('Add artboard'),
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
      FButton(
        key: ValueKey('sketch-add-artboard-${value.name}'),
        size: FButtonSizeVariant.xs,
        mainAxisSize: MainAxisSize.min,
        variant: FButtonVariant.outline,
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
  Widget build(BuildContext context) => FTabs(
    key: const ValueKey('sketch-sidebar-tabs'),
    expands: true,
    children: [
      FTabEntry(
        label: Semantics(
          label: 'Assets',
          button: true,
          child: const Icon(
            FLucideIcons.boxes,
            key: ValueKey('sketch-tab-assets'),
            size: 16,
          ),
        ),
        child: palette,
      ),
      FTabEntry(
        label: Semantics(
          label: 'Layers',
          button: true,
          child: const Icon(
            FLucideIcons.layers,
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
          FButton(
            variant: FButtonVariant.ghost,
            size: FButtonSizeVariant.sm,
            mainAxisSize: MainAxisSize.min,
            onPress: onBack,
            child: const Row(
              children: [
                Icon(FLucideIcons.arrowLeft, size: 16),
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
      FButton.icon(
        variant: FButtonVariant.outline,
        size: FButtonSizeVariant.sm,
        onPress: onClear,
        child: const Icon(FLucideIcons.layers),
      ),
    ],
  );
}

class _ComponentPalette extends StatelessWidget {
  const _ComponentPalette({required this.registry, required this.onSelect});

  final DesyRegistry registry;
  final ValueChanged<DesyRegisteredComponentInstance> onSelect;

  @override
  Widget build(BuildContext context) => FCard(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ASSETS', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            'Registry folders · instance leaves',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: _PaletteFolderView(
                registry: registry,
                folders: registry.folders,
                components: registry.components,
                onSelect: onSelect,
                root: true,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PaletteFolderView extends StatelessWidget {
  const _PaletteFolderView({
    required this.registry,
    required this.folders,
    required this.components,
    required this.onSelect,
    required this.root,
  });

  final DesyRegistry registry;
  final List<DesyFolder> folders;
  final List<DesyComponent> components;
  final ValueChanged<DesyRegisteredComponentInstance> onSelect;
  final bool root;

  @override
  Widget build(BuildContext context) => FAccordion(
    children: [
      for (final child in folders)
        FAccordionItem(
          key: ValueKey('palette-folder-${child.id}'),
          initiallyExpanded: root,
          title: Row(
            children: [
              const Icon(FLucideIcons.folder, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(child.name, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: _PaletteFolderView(
              registry: registry,
              folders: child.children,
              components: child.components,
              onSelect: onSelect,
              root: false,
            ),
          ),
        ),
      for (final component in components)
        FAccordionItem(
          key: ValueKey('palette-component-${component.id}'),
          title: Row(
            children: [
              const Icon(FLucideIcons.boxes, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(component.name)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final instance in component.instances.map(
                  (instance) => DesyRegisteredComponentInstance(
                    component: component,
                    instance: instance,
                  ),
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: FButton(
                      key: ValueKey('palette-instance-${instance.id}'),
                      variant: FButtonVariant.outline,
                      size: FButtonSizeVariant.sm,
                      mainAxisSize: MainAxisSize.min,
                      onPress: () => onSelect(instance),
                      child: SizedBox(
                        width: 128,
                        child: Text(
                          instance.instance.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
    ],
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
  Widget build(BuildContext context) => FCard(
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
        FButton(
          variant: FButtonVariant.outline,
          size: FButtonSizeVariant.sm,
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
  Widget build(BuildContext context) => FCard(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ARTBOARD', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            node.artboard!.label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Components placed on this artboard use its real device screen coordinates.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          FButton(
            variant: FButtonVariant.outline,
            size: FButtonSizeVariant.sm,
            onPress: () => controller.remove(node.id),
            child: const Text('Remove artboard'),
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
    return FCard(
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
                          return FTile(
                            key: ValueKey('canvas-node-${node.id}'),
                            selected: selectedId == node.id,
                            onPress: () => onSelect(node.id),
                            prefix: Icon(node.artboard!.icon, size: 16),
                            title: Text(node.artboard!.label),
                            subtitle: const Text('Artboard'),
                          );
                        }
                        final instance = _instanceFor(node.instanceId!);
                        if (instance == null) return const SizedBox.shrink();
                        return FTile(
                          key: ValueKey('canvas-node-${node.id}'),
                          selected: selectedId == node.id,
                          onPress: () => onSelect(node.id),
                          prefix: const Icon(FLucideIcons.boxes, size: 16),
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
      // Rebuild while a drag is in flight without making the node switch
      // between free and attached interaction subtrees.
      controller.interactionSceneRects.watch(context);
      controller.movingComponentId.watch(context);
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
              // An artboard and its attached children are one z-order group.
              // Its child visuals and hit layers must stay below later nodes.
              for (final node in nodes.values)
                if (node.isArtboard) ...[
                  _CanvasTransformableNode(
                    node: node,
                    selected: selectedId == node.id,
                    clampingRect: clampingRect,
                    minSize: const Size(8, 8),
                    controller: controller,
                    child: _CanvasArtboard(
                      artboardNode: node,
                      theme: theme,
                      children: [
                        for (final child in nodes.values)
                          if (child.parentArtboardId == node.id)
                            if (!controller.isMovingComponent(child.id))
                              if (_instanceFor(child.instanceId!)
                                  case final instance?)
                                _AttachedCanvasElement(
                                  node: child,
                                  instance: instance,
                                  theme: theme,
                                ),
                      ],
                    ),
                  ),
                  for (final child in nodes.values)
                    if (child.parentArtboardId == node.id)
                      if (_instanceFor(child.instanceId!) case final instance?)
                        _CanvasTransformableNode(
                          node: child,
                          rect: controller.interactionSceneRectFor(child),
                          selected: selectedId == child.id,
                          clampingRect: clampingRect,
                          minSize: const Size(8, 8),
                          controller: controller,
                          child: controller.isMovingComponent(child.id)
                              ? _CanvasElement(
                                  instance: instance,
                                  node: child,
                                  theme: theme,
                                  selected: selectedId == child.id,
                                )
                              : const SizedBox.expand(),
                        ),
                ] else if (node.parentArtboardId == null)
                  if (_instanceFor(node.instanceId!) case final instance?)
                    _CanvasTransformableNode(
                      node: node,
                      rect: controller.interactionSceneRectFor(node),
                      selected: selectedId == node.id,
                      clampingRect: clampingRect,
                      minSize: const Size(8, 8),
                      controller: controller,
                      // Attached nodes render inside DeviceFrame.screen. This
                      // stage overlay owns only interaction chrome, avoiding
                      // nested transformed boxes and ambiguous inverse mapping.
                      child: node.parentArtboardId == null
                          ? _CanvasElement(
                              instance: instance,
                              node: node,
                              theme: theme,
                              selected: selectedId == node.id,
                            )
                          : const SizedBox.expand(),
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
    this.rect,
    required this.selected,
    required this.clampingRect,
    required this.minSize,
    required this.controller,
    required this.child,
  });

  final DesyCanvasNode node;
  final Rect? rect;
  final bool selected;
  final Rect clampingRect;
  final Size minSize;
  final DesyComponentsCanvasController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final nodeRect = rect ?? node.rect;
    final hitTestPathBuilder = _hitTestPathBuilder(nodeRect);
    if (hitTestPathBuilder != null) {
      return _PathTransformableNode(
        node: node,
        rect: nodeRect,
        selected: selected,
        clampingRect: clampingRect,
        controller: controller,
        pathBuilder: hitTestPathBuilder,
        child: child,
      );
    }
    return TransformableBox(
      key: ValueKey(node.id),
      rect: nodeRect,
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
      onDragStart: node.isComponent
          ? (_) => controller.beginComponentMove(node)
          : null,
      onDragUpdate: node.isComponent
          ? (result, _) => controller.updateComponentMove(
              node.copyWith(flip: result.flip),
              _CanvasGrid.snapRect(result.rect),
            )
          : null,
      onDragEnd: node.isComponent
          ? (_) => controller.endComponentMove(node)
          : null,
      onDragCancel: node.isComponent
          ? () => controller.endComponentMove(node)
          : null,
      onChanged: (result, _) {
        final snapped = _CanvasGrid.snapRect(result.rect);
        if (node.isArtboard) {
          controller.update(
            node.copyWith(
              rect: DesyCanvasGeometry.lockFrameAspect(
                node,
                snapped,
                clampingRect: clampingRect,
              ),
              flip: result.flip,
            ),
          );
        } else if (!controller.isMovingComponent(node.id)) {
          controller.updateComponentFromSceneRect(
            node.copyWith(flip: result.flip),
            snapped,
          );
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

  Path Function(Size)? _hitTestPathBuilder(Rect nodeRect) {
    if (node.isArtboard) {
      return (size) => DesyCanvasGeometry.screenPathInFrame(node, size);
    }
    final parentId = node.parentArtboardId;
    final parent = parentId == null ? null : controller.nodes.value[parentId];
    if (parent?.isArtboard != true) return null;
    return (size) =>
        DesyCanvasGeometry.screenPathInScene(parent!).shift(-nodeRect.topLeft);
  }
}

/// Lets a transformed device be painted as a full physical frame while making
/// only its real screen path interactive.
///
/// This is positioned directly in the canvas stack; placing a render proxy
/// around TransformableBox would break that widget's internal Positioned.
class _PathTransformableNode extends StatefulWidget {
  const _PathTransformableNode({
    required this.node,
    required this.rect,
    required this.selected,
    required this.clampingRect,
    required this.controller,
    required this.pathBuilder,
    required this.child,
  });

  final DesyCanvasNode node;
  final Rect rect;
  final bool selected;
  final Rect clampingRect;
  final DesyComponentsCanvasController controller;
  final Path Function(Size) pathBuilder;
  final Widget child;

  @override
  State<_PathTransformableNode> createState() => _PathTransformableNodeState();
}

class _PathTransformableNodeState extends State<_PathTransformableNode> {
  Rect? _gestureStart;
  Offset? _gestureOrigin;

  @override
  Widget build(BuildContext context) => Positioned.fromRect(
    key: ValueKey(widget.node.id),
    rect: widget.rect,
    child: _PathHitTestGate(
      pathBuilder: widget.pathBuilder,
      allowHandleHits: widget.selected,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            dragStartBehavior: DragStartBehavior.down,
            onTap: () => widget.controller.select(widget.node.id),
            onPanStart: widget.selected ? _startMoveGesture : null,
            onPanUpdate: widget.selected ? _move : null,
            onPanEnd: widget.selected ? (_) => _endMoveGesture() : null,
            onPanCancel: _endMoveGesture,
            child: Listener(
              key: ValueKey('canvas-hit-${widget.node.id}'),
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => widget.controller.select(widget.node.id),
              child: IgnorePointer(child: widget.child),
            ),
          ),
          if (widget.selected)
            for (final handle in _CanvasHandle.values)
              _CanvasResizeHandle(
                handleKey: ValueKey(
                  'canvas-handle-${widget.node.id}-${handle.name}',
                ),
                handle: handle,
                onPanStart: _startResizeGesture,
                onPanUpdate: (details) => _resize(handle, details),
                onPanEnd: _endGesture,
              ),
        ],
      ),
    ),
  );

  void _startMoveGesture(DragStartDetails details) {
    if (!widget.node.isArtboard) {
      widget.controller.beginComponentMove(widget.node);
    }
    _startGesture(details);
  }

  void _startResizeGesture(DragStartDetails details) {
    _startGesture(details);
  }

  void _startGesture(DragStartDetails details) {
    _gestureStart = widget.rect;
    _gestureOrigin = details.globalPosition;
  }

  void _move(DragUpdateDetails details) {
    final start = _gestureStart;
    final origin = _gestureOrigin;
    if (start == null || origin == null) return;
    final shifted = start.shift(details.globalPosition - origin);
    if (!widget.node.isArtboard) {
      widget.controller.updateComponentMove(
        widget.node,
        _CanvasGrid.snapRect(shifted),
      );
      return;
    }

    final bounds = widget.clampingRect;
    final maximumLeft = bounds.right - start.width;
    final maximumTop = bounds.bottom - start.height;
    final left = maximumLeft >= bounds.left
        ? shifted.left.clamp(bounds.left, maximumLeft).toDouble()
        : bounds.left;
    final top = maximumTop >= bounds.top
        ? shifted.top.clamp(bounds.top, maximumTop).toDouble()
        : bounds.top;
    widget.controller.update(
      widget.node.copyWith(
        // Translation keeps physical frame geometry byte-for-byte unchanged;
        // only resize handles enter the aspect-locking path below.
        rect: Rect.fromLTWH(left, top, start.width, start.height),
      ),
    );
  }

  void _resize(_CanvasHandle handle, DragUpdateDetails details) {
    final start = _gestureStart;
    final origin = _gestureOrigin;
    if (start == null || origin == null) return;
    final delta = details.globalPosition - origin;
    var left = start.left;
    var top = start.top;
    var right = start.right;
    var bottom = start.bottom;
    if (handle.isLeft) left += delta.dx;
    if (handle.isRight) right += delta.dx;
    if (handle.isTop) top += delta.dy;
    if (handle.isBottom) bottom += delta.dy;
    if (right - left < 8) {
      if (handle.isLeft) left = right - 8;
      if (handle.isRight) right = left + 8;
    }
    if (bottom - top < 8) {
      if (handle.isTop) top = bottom - 8;
      if (handle.isBottom) bottom = top + 8;
    }
    _update(Rect.fromLTRB(left, top, right, bottom));
  }

  void _update(Rect rect) {
    final snapped = _CanvasGrid.snapRect(rect);
    final minimumWidth = widget.clampingRect.width.clamp(0.0, 8.0).toDouble();
    final minimumHeight = widget.clampingRect.height.clamp(0.0, 8.0).toDouble();
    final clamped = Rect.fromLTRB(
      snapped.left.clamp(
        widget.clampingRect.left,
        widget.clampingRect.right - minimumWidth,
      ),
      snapped.top.clamp(
        widget.clampingRect.top,
        widget.clampingRect.bottom - minimumHeight,
      ),
      snapped.right.clamp(
        widget.clampingRect.left + minimumWidth,
        widget.clampingRect.right,
      ),
      snapped.bottom.clamp(
        widget.clampingRect.top + minimumHeight,
        widget.clampingRect.bottom,
      ),
    );
    if (widget.node.isArtboard) {
      widget.controller.update(
        widget.node.copyWith(
          rect: DesyCanvasGeometry.lockFrameAspect(
            widget.node,
            clamped,
            clampingRect: widget.clampingRect,
          ),
        ),
      );
    } else {
      widget.controller.updateComponentFromSceneRect(widget.node, clamped);
    }
  }

  void _endMoveGesture() {
    if (!widget.node.isArtboard) {
      widget.controller.endComponentMove(widget.node);
    }
    _endGesture();
  }

  void _endGesture() {
    _gestureStart = null;
    _gestureOrigin = null;
  }
}

enum _CanvasHandle {
  topLeft(isLeft: true, isTop: true),
  top(isRight: true, isTop: true),
  topRight(isRight: true, isTop: true),
  right(isRight: true),
  bottomRight(isRight: true, isBottom: true),
  bottom(isBottom: true),
  bottomLeft(isLeft: true, isBottom: true),
  left(isLeft: true);

  const _CanvasHandle({
    this.isLeft = false,
    this.isTop = false,
    this.isRight = false,
    this.isBottom = false,
  });

  final bool isLeft;
  final bool isTop;
  final bool isRight;
  final bool isBottom;
}

class _CanvasResizeHandle extends StatelessWidget {
  const _CanvasResizeHandle({
    required this.handleKey,
    required this.handle,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  /// The key is intentionally on the pointer listener rather than its Align
  /// parent so gesture tests (and tooling) resolve the actual hit target.
  final Key handleKey;
  final _CanvasHandle handle;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final VoidCallback onPanEnd;

  @override
  Widget build(BuildContext context) {
    const size = 18.0;
    final alignment = switch (handle) {
      _CanvasHandle.topLeft => Alignment.topLeft,
      _CanvasHandle.top => Alignment.topCenter,
      _CanvasHandle.topRight => Alignment.topRight,
      _CanvasHandle.right => Alignment.centerRight,
      _CanvasHandle.bottomRight => Alignment.bottomRight,
      _CanvasHandle.bottom => Alignment.bottomCenter,
      _CanvasHandle.bottomLeft => Alignment.bottomLeft,
      _CanvasHandle.left => Alignment.centerLeft,
    };
    return Align(
      alignment: alignment,
      child: GestureDetector(
        key: handleKey,
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: (_) => onPanEnd(),
        onPanCancel: onPanEnd,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: context.theme.colors.background,
              borderRadius: BorderRadius.circular(1),
              border: Border.all(
                color: context.theme.colors.primary,
                width: 1.25,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PathHitTestGate extends SingleChildRenderObjectWidget {
  const _PathHitTestGate({
    required super.child,
    required this.pathBuilder,
    required this.allowHandleHits,
  });

  final Path Function(Size)? pathBuilder;
  final bool allowHandleHits;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderPathHitTestGate(
        pathBuilder: pathBuilder,
        allowHandleHits: allowHandleHits,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPathHitTestGate renderObject,
  ) {
    renderObject
      ..pathBuilder = pathBuilder
      ..allowHandleHits = allowHandleHits;
  }
}

class _RenderPathHitTestGate extends RenderProxyBox {
  _RenderPathHitTestGate({
    required Path Function(Size)? pathBuilder,
    required bool allowHandleHits,
  }) : _pathBuilder = pathBuilder,
       _allowHandleHits = allowHandleHits;

  Path Function(Size)? _pathBuilder;
  bool _allowHandleHits;

  set pathBuilder(Path Function(Size)? value) {
    if (_pathBuilder == value) return;
    _pathBuilder = value;
    markNeedsPaint();
  }

  set allowHandleHits(bool value) {
    if (_allowHandleHits == value) return;
    _allowHandleHits = value;
    markNeedsPaint();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final pathBuilder = _pathBuilder;
    if (pathBuilder == null) return super.hitTest(result, position: position);
    final inScreen = pathBuilder(size).contains(position);
    if (!inScreen && !(_allowHandleHits && _isHandleHit(position))) {
      return false;
    }
    return super.hitTest(result, position: position);
  }

  bool _isHandleHit(Offset position) {
    const hitSize = 18.0;
    final centers = [
      Offset.zero,
      Offset(size.width / 2, 0),
      Offset(size.width, 0),
      Offset(size.width, size.height / 2),
      size.bottomRight(Offset.zero),
      Offset(size.width / 2, size.height),
      Offset(0, size.height),
      Offset(0, size.height / 2),
    ];
    return centers.any(
      (center) => Rect.fromCenter(
        center: center,
        width: hitSize,
        height: hitSize,
      ).contains(position),
    );
  }
}

class _CanvasArtboard extends StatelessWidget {
  const _CanvasArtboard({
    required this.artboardNode,
    required this.theme,
    required this.children,
  });

  final DesyCanvasNode artboardNode;
  final DesyTheme theme;
  final List<Widget> children;

  DeviceInfo get _device =>
      DesyCanvasGeometry.deviceFor(artboardNode.artboard!);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: _device.frameSize.width,
    height: _device.frameSize.height,
    child: DeviceFrame(
      device: _device,
      screen: SizedBox(
        width: _device.screenSize.width,
        height: _device.screenSize.height,
        child: Stack(clipBehavior: Clip.hardEdge, children: children),
      ),
    ),
  );
}

/// Consumer components attached to an artboard are painted at their actual
/// logical device coordinates. DeviceFrame supplies the simulated MediaQuery
/// and clips this stack to the real screen path.
class _AttachedCanvasElement extends StatelessWidget {
  const _AttachedCanvasElement({
    required this.node,
    required this.instance,
    required this.theme,
  });

  final DesyCanvasNode node;
  final DesyRegisteredComponentInstance instance;
  final DesyTheme theme;

  @override
  Widget build(BuildContext context) => Positioned.fromRect(
    rect: node.rect,
    // DeviceFrame supplies the full device MediaQuery, while this positioned
    // node supplies the component's logical layout bounds. The frame is the
    // only device-to-stage scale; do not fit a second device-sized canvas here.
    child: DesyWidgetPreview(
      theme: theme,
      builder: (context) => instance.component.buildWithKnobs == null
          ? instance.component.buildInstance(context, instance.instance)
          : instance.component.buildWithKnobs!(
              context,
              DesyKnobValues(node.knobValues),
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
    DesyCanvasArtboard.iPhone15Pro => FLucideIcons.smartphone,
    DesyCanvasArtboard.iPadPro11 => FLucideIcons.tablet,
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

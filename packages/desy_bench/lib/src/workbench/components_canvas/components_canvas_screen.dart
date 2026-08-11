// This screen is an internal workbench module, not consumer-facing package API.
// ignore_for_file: public_member_api_docs

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_box_transform/flutter_box_transform.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../device_preview.dart';
import '../../registry.dart';
import '../presentation/component_knob_panel.dart';
import '../presentation/desy_drag_box.dart';
import '../widget_preview.dart';
import '../workbench_session.dart';
import 'components_canvas_controller.dart';
import 'snapping/snap_models.dart';

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
  final _sketchFocusNode = FocusNode(debugLabel: 'Sketch canvas');
  var _repaintRainbowEnabled = kDebugMode ? debugRepaintRainbowEnabled : false;

  @override
  void dispose() {
    _sketchFocusNode.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeIndex = widget.session.activeThemeIndex.watch(context);
    final theme = widget.session.registry.themes[themeIndex];
    final instances = widget.session.registry.allComponentInstances;
    final spacingEntries = widget.session.registry.allMeasurements
        .where(
          (entry) =>
              entry.kind == DesyNumericKind.spacing &&
              entry.unit == DesyNumberUnit.dp,
        )
        .toList(growable: false);
    final gridStep = _controller.gridStep.watch(context);
    return Focus(
      focusNode: _sketchFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _sketchFocusNode.requestFocus(),
        child: SelectionContainer.disabled(
          key: const ValueKey('sketch-selection-disabled'),
          // The Sketch is a drag surface, not a document. Keep all of its live
          // responsive panels out of the shell's document-selection registrar;
          // selection remains available in the persistent catalogue chrome.
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SketchHeader(
                  onBack: widget.onBack,
                  onClear: _controller.clear,
                ),
                const SizedBox(height: 12),
                _SketchPreviewToolbar(
                  spacingEntries: spacingEntries,
                  onAddArtboard: _controller.addArtboard,
                  onAddLayout: (preset, spacing) => _controller.addLayout(
                    preset,
                    spacingEntryId: spacing?.id,
                    spacing: spacing?.value ?? 0,
                  ),
                  repaintRainbowEnabled: _repaintRainbowEnabled,
                  onToggleRepaintRainbow: _toggleRepaintRainbow,
                  gridStep: gridStep,
                  onGridStepChanged: _controller.setGridStep,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _ReactiveSketchWorkspace(
                    registry: widget.session.registry,
                    instances: instances,
                    spacingEntries: spacingEntries,
                    theme: theme,
                    controller: _controller,
                    onAddInstance: _addInstance,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleRepaintRainbow() {
    if (!kDebugMode) return;
    setState(() {
      _repaintRainbowEnabled = !_repaintRainbowEnabled;
      debugRepaintRainbowEnabled = _repaintRainbowEnabled;
    });
    if (!_repaintRainbowEnabled) {
      for (final renderView in RendererBinding.instance.renderViews) {
        renderView.markNeedsPaint();
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_isEditingText()) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.backspace ||
        event.logicalKey == LogicalKeyboardKey.delete) {
      final selected = _controller.selectedId.value;
      if (selected == null) return KeyEventResult.ignored;
      _controller.remove(selected);
      return KeyEventResult.handled;
    }
    final step = _controller.gridStep.value;
    final multiplier = HardwareKeyboard.instance.isShiftPressed ? 4.0 : 1.0;
    final delta = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => Offset(-step * multiplier, 0),
      LogicalKeyboardKey.arrowRight => Offset(step * multiplier, 0),
      LogicalKeyboardKey.arrowUp => Offset(0, -step * multiplier),
      LogicalKeyboardKey.arrowDown => Offset(0, step * multiplier),
      _ => null,
    };
    if (delta == null || !_controller.moveSelectedBy(delta)) {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  bool _isEditingText() {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext == null) return false;
    return focusContext.widget is EditableText ||
        focusContext.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  void _addInstance(
    DesyRegisteredComponentInstance instance, {
    Offset? center,
  }) {
    final values = instance.component.valuesFor(instance.instanceId);
    _controller.add(
      instance.id,
      knobValues: values,
      defaultSize: instance.component.defaultSize,
      center: center,
    );
  }
}

typedef _DropSketchInstance =
    void Function(DesyRegisteredComponentInstance instance, Offset center);

class _ReactiveSketchWorkspace extends StatelessWidget {
  const _ReactiveSketchWorkspace({
    required this.registry,
    required this.instances,
    required this.spacingEntries,
    required this.theme,
    required this.controller,
    required this.onAddInstance,
  });

  final DesyRegistry registry;
  final List<DesyRegisteredComponentInstance> instances;
  final List<DesyNumericEntry> spacingEntries;
  final DesyTheme theme;
  final DesyComponentsCanvasController controller;
  final void Function(
    DesyRegisteredComponentInstance instance, {
    Offset? center,
  })
  onAddInstance;

  @override
  Widget build(BuildContext context) {
    final hasSelection = controller.selectedId.watch(context) != null;
    return _SketchWorkspace(
      palette: RepaintBoundary(
        child: _ComponentPalette(
          registry: registry,
          theme: theme,
          onSelect: onAddInstance,
        ),
      ),
      outline: _ReactiveCanvasOutline(
        instances: instances,
        controller: controller,
      ),
      canvas: _ReactiveCanvasStage(
        registry: registry,
        instances: instances,
        theme: theme,
        controller: controller,
        onDropInstance: (instance, center) =>
            onAddInstance(instance, center: center),
      ),
      inspector: hasSelection
          ? _ReactiveCanvasInspector(
              registry: registry,
              instances: instances,
              spacingEntries: spacingEntries,
              controller: controller,
            )
          : null,
    );
  }
}

class _ReactiveCanvasOutline extends StatelessWidget {
  const _ReactiveCanvasOutline({
    required this.instances,
    required this.controller,
  });

  final List<DesyRegisteredComponentInstance> instances;
  final DesyComponentsCanvasController controller;

  @override
  Widget build(BuildContext context) {
    final nodes = controller.nodes.watch(context);
    final selectedId = controller.selectedId.watch(context);
    return RepaintBoundary(
      child: _CanvasOutline(
        nodes: nodes.values.toList().reversed,
        instances: instances,
        selectedId: selectedId,
        onSelect: controller.select,
      ),
    );
  }
}

class _ReactiveCanvasStage extends StatelessWidget {
  const _ReactiveCanvasStage({
    required this.registry,
    required this.instances,
    required this.theme,
    required this.controller,
    required this.onDropInstance,
  });

  final DesyRegistry registry;
  final List<DesyRegisteredComponentInstance> instances;
  final DesyTheme theme;
  final DesyComponentsCanvasController controller;
  final _DropSketchInstance onDropInstance;

  @override
  Widget build(BuildContext context) {
    final nodes = controller.nodes.watch(context);
    final selectedId = controller.selectedId.watch(context);
    final gridStep = controller.gridStep.watch(context);
    return RepaintBoundary(
      key: const ValueKey('sketch-stage-repaint-boundary'),
      child: _CanvasStage(
        registry: registry,
        instances: instances,
        nodes: nodes,
        selectedId: selectedId,
        theme: theme,
        controller: controller,
        gridStep: gridStep,
        onDropInstance: onDropInstance,
      ),
    );
  }
}

class _ReactiveCanvasInspector extends StatelessWidget {
  const _ReactiveCanvasInspector({
    required this.registry,
    required this.instances,
    required this.spacingEntries,
    required this.controller,
  });

  final DesyRegistry registry;
  final List<DesyRegisteredComponentInstance> instances;
  final List<DesyNumericEntry> spacingEntries;
  final DesyComponentsCanvasController controller;

  @override
  Widget build(BuildContext context) {
    final nodes = controller.nodes.watch(context);
    final selectedId = controller.selectedId.watch(context);
    final selectedNode = selectedId == null ? null : nodes[selectedId];
    if (selectedNode == null) return const SizedBox.shrink();
    if (selectedNode.isArtboard) {
      return _CanvasArtboardInspector(
        node: selectedNode,
        controller: controller,
      );
    }
    if (selectedNode.isLayout) {
      return _CanvasLayoutInspector(
        node: selectedNode,
        spacingEntries: spacingEntries,
        controller: controller,
      );
    }
    final selectedInstance = _instanceFor(instances, selectedNode.instanceId!);
    if (selectedInstance == null) return const SizedBox.shrink();
    return _CanvasInspector(
      registry: registry,
      node: selectedNode,
      instance: selectedInstance,
      controller: controller,
    );
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
typedef _AddSketchLayout =
    void Function(DesyCanvasLayoutPreset preset, DesyNumericEntry? spacing);

class _SketchPreviewToolbar extends StatefulWidget {
  const _SketchPreviewToolbar({
    required this.spacingEntries,
    required this.onAddArtboard,
    required this.onAddLayout,
    required this.repaintRainbowEnabled,
    required this.onToggleRepaintRainbow,
    required this.gridStep,
    required this.onGridStepChanged,
  });

  final List<DesyNumericEntry> spacingEntries;
  final ValueChanged<DesyDevicePreset> onAddArtboard;
  final _AddSketchLayout onAddLayout;
  final bool repaintRainbowEnabled;
  final VoidCallback onToggleRepaintRainbow;
  final double gridStep;
  final ValueChanged<double> onGridStepChanged;

  @override
  State<_SketchPreviewToolbar> createState() => _SketchPreviewToolbarState();
}

class _SketchPreviewToolbarState extends State<_SketchPreviewToolbar> {
  static const _gridPresets = <double>[1, 2, 4, 8, 12, 16, 24, 32];
  var _spacingIndex = 0;
  late var _gridOption = _gridOptionFor(widget.gridStep);
  var _gridInputValid = true;

  @override
  void didUpdateWidget(covariant _SketchPreviewToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gridStep != widget.gridStep) {
      _gridOption = _gridOptionFor(widget.gridStep);
      _gridInputValid = true;
    }
  }

  DesyNumericEntry? get _spacing => widget.spacingEntries.isEmpty
      ? null
      : widget.spacingEntries[_spacingIndex.clamp(
          0,
          widget.spacingEntries.length - 1,
        )];

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Add layout'),
                const SizedBox(width: 6),
                if (widget.spacingEntries.isNotEmpty)
                  SizedBox(
                    width: 180,
                    child: DesySelect<int>.rich(
                      key: const ValueKey('sketch-spacing-select'),
                      control: DesySelectControl.lifted(
                        value: _spacingIndex,
                        onChange: (index) {
                          if (index != null) {
                            setState(() => _spacingIndex = index);
                          }
                        },
                      ),
                      format: (index) =>
                          widget.spacingEntries[index].displayValue,
                      children: [
                        for (final (index, entry)
                            in widget.spacingEntries.indexed)
                          DesySelectItem.item(
                            key: ValueKey('sketch-spacing-${entry.id}'),
                            value: index,
                            title: Text(entry.name),
                            subtitle: Text(entry.displayValue),
                          ),
                      ],
                    ),
                  )
                else
                  DesyBadge(child: const Text('No registered spacing · 0 dp')),
                for (final preset in DesyCanvasLayoutPreset.values) ...[
                  const SizedBox(width: 6),
                  DesyButton(
                    key: ValueKey('sketch-add-layout-${preset.name}'),
                    semanticsLabel:
                        'Add ${preset.label} with ${_spacing?.displayValue ?? '0 dp'} spacing',
                    size: DesyButtonSize.xs,
                    mainAxisSize: MainAxisSize.min,
                    variant: DesyButtonVariant.outline,
                    onPress: () => widget.onAddLayout(preset, _spacing),
                    child: Text(preset.label),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Add bezel'),
                const SizedBox(width: 6),
                _artboardButton(
                  label: 'iPhone 15 Pro',
                  value: DesyDevicePreset.iPhone15Pro,
                ),
                const SizedBox(width: 6),
                _artboardButton(
                  label: 'iPad Pro 11',
                  value: DesyDevicePreset.iPadPro11,
                ),
                const SizedBox(width: 16),
                const Text('Grid'),
                const SizedBox(width: 6),
                SizedBox(
                  width: 104,
                  child: DesySelect<int>.rich(
                    key: const ValueKey('sketch-grid-preset'),
                    control: DesySelectControl.lifted(
                      value: _gridOption,
                      onChange: (index) {
                        if (index == null) return;
                        setState(() => _gridOption = index);
                        if (index < _gridPresets.length) {
                          widget.onGridStepChanged(_gridPresets[index]);
                        }
                      },
                    ),
                    format: (index) => index < _gridPresets.length
                        ? '${_gridPresets[index].toInt()} px'
                        : 'Custom',
                    children: [
                      for (final (index, step) in _gridPresets.indexed)
                        DesySelectItem.item(
                          value: index,
                          title: Text('${step.toInt()} px'),
                        ),
                      DesySelectItem.item(
                        value: _gridPresets.length,
                        title: const Text('Custom'),
                        subtitle: const Text('Enter 1–256 px'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 62,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.background,
                    border: Border.all(
                      color: _gridInputValid
                          ? colors.border
                          : colors.destructive,
                    ),
                  ),
                  child: DesyTextField(
                    key: const ValueKey('sketch-grid-custom'),
                    label: 'Custom grid size in pixels',
                    value: widget.gridStep.toInt().toString(),
                    errorText: _gridInputValid
                        ? null
                        : 'Enter a whole number from 1 to 256',
                    keyboardType: TextInputType.number,
                    onChanged: _setCustomGrid,
                    onSubmitted: _setCustomGrid,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('px'),
                if (kDebugMode) ...[
                  const SizedBox(width: 12),
                  DesyButton(
                    key: const ValueKey('sketch-repaint-rainbow'),
                    semanticsLabel: widget.repaintRainbowEnabled
                        ? 'Disable repaint rainbow'
                        : 'Enable repaint rainbow',
                    semanticsTooltip:
                        'Draw a changing border around every layer that repaints',
                    variant: widget.repaintRainbowEnabled
                        ? DesyButtonVariant.secondary
                        : DesyButtonVariant.outline,
                    size: DesyButtonSize.xs,
                    mainAxisSize: MainAxisSize.min,
                    onPress: widget.onToggleRepaintRainbow,
                    child: Text(
                      widget.repaintRainbowEnabled
                          ? 'Rainbow on'
                          : 'Repaint rainbow',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _artboardButton({
    required String label,
    required DesyDevicePreset value,
  }) => DesyButton(
    key: ValueKey('sketch-add-artboard-${value.name}'),
    size: DesyButtonSize.xs,
    mainAxisSize: MainAxisSize.min,
    variant: DesyButtonVariant.outline,
    onPress: () => widget.onAddArtboard(value),
    child: Text(label),
  );

  void _setCustomGrid(String text) {
    final value = int.tryParse(text);
    final valid = value != null && value >= 1 && value <= 256;
    setState(() {
      _gridInputValid = valid;
      if (valid && !_gridPresets.contains(value.toDouble())) {
        _gridOption = _gridPresets.length;
      }
    });
    if (valid) widget.onGridStepChanged(value.toDouble());
  }

  static int _gridOptionFor(double step) {
    final index = _gridPresets.indexOf(step);
    return index < 0 ? _gridPresets.length : index;
  }
}

class _SketchWorkspace extends StatefulWidget {
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
  State<_SketchWorkspace> createState() => _SketchWorkspaceState();
}

class _SketchWorkspaceState extends State<_SketchWorkspace> {
  static const _minimumSidebarWidth = 210.0;
  static const _maximumSidebarWidth = 520.0;
  static const _minimumCanvasWidth = 320.0;

  var _sidebarWidth = 260.0;
  var _resizingSidebar = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final details = widget.inspector;
      if (constraints.maxWidth < 620) {
        return ListView(
          children: [
            SizedBox(
              height: 260,
              child: _SketchSidebar(
                palette: widget.palette,
                outline: widget.outline,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: constraints.maxHeight.clamp(320, 520).toDouble(),
              child: widget.canvas,
            ),
            if (details != null) ...[
              const SizedBox(height: 12),
              SizedBox(height: 250, child: details),
            ],
          ],
        );
      }
      final inspectorWidth = constraints.maxWidth < 1000 || details == null
          ? 0.0
          : 316.0;
      final maximumSidebarWidth =
          (constraints.maxWidth - _minimumCanvasWidth - inspectorWidth - 20)
              .clamp(_minimumSidebarWidth, _maximumSidebarWidth)
              .toDouble();
      final sidebarWidth = _sidebarWidth.clamp(
        _minimumSidebarWidth,
        maximumSidebarWidth,
      );
      if (constraints.maxWidth < 1000) {
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: sidebarWidth,
                    child: _SketchSidebar(
                      palette: widget.palette,
                      outline: widget.outline,
                    ),
                  ),
                  DesyResizeDivider(
                    key: const ValueKey('sketch-sidebar-resize-handle'),
                    axis: Axis.vertical,
                    value: sidebarWidth,
                    semanticsLabel: 'Resize component palette',
                    onResizeStart: () =>
                        setState(() => _resizingSidebar = true),
                    onResize: (delta) => setState(
                      () => _sidebarWidth = (sidebarWidth + delta).clamp(
                        _minimumSidebarWidth,
                        maximumSidebarWidth,
                      ),
                    ),
                    onResizeEnd: () => setState(() => _resizingSidebar = false),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: widget.canvas),
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
          AnimatedContainer(
            duration: _resizingSidebar
                ? Duration.zero
                : const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            width: sidebarWidth,
            child: _SketchSidebar(
              palette: widget.palette,
              outline: widget.outline,
            ),
          ),
          DesyResizeDivider(
            key: const ValueKey('sketch-sidebar-resize-handle'),
            axis: Axis.vertical,
            value: sidebarWidth,
            semanticsLabel: 'Resize component palette',
            onResizeStart: () => setState(() => _resizingSidebar = true),
            onResize: (delta) => setState(
              () => _sidebarWidth = (sidebarWidth + delta).clamp(
                _minimumSidebarWidth,
                maximumSidebarWidth,
              ),
            ),
            onResizeEnd: () => setState(() => _resizingSidebar = false),
          ),
          const SizedBox(width: 12),
          Expanded(child: widget.canvas),
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

class _ComponentPalette extends StatefulWidget {
  const _ComponentPalette({
    required this.registry,
    required this.theme,
    required this.onSelect,
  });

  final DesyRegistry registry;
  final DesyTheme theme;
  final ValueChanged<DesyRegisteredComponentInstance> onSelect;

  @override
  State<_ComponentPalette> createState() => _ComponentPaletteState();
}

class _ComponentPaletteState extends State<_ComponentPalette> {
  static const _minimumTileWidth = 104.0;
  static const _tileSpacing = 8.0;

  var _query = '';

  @override
  Widget build(BuildContext context) {
    final allInstances = widget.registry.allComponentInstances;
    final normalizedQuery = _query.trim().toLowerCase();
    final instances = normalizedQuery.isEmpty
        ? allInstances
        : allInstances
              .where(
                (entry) => [
                  entry.id,
                  entry.componentName,
                  entry.name,
                ].any((value) => value.toLowerCase().contains(normalizedQuery)),
              )
              .toList(growable: false);
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
              normalizedQuery.isEmpty
                  ? '${allInstances.length} elements · choose to add'
                  : '${instances.length} of ${allInstances.length} elements',
              key: const ValueKey('sketch-component-filter-count'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            DesyTextField(
              key: const ValueKey('sketch-component-filter'),
              label: 'Filter components',
              hintText: 'Filter components',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(right: 7),
                child: Icon(DesyIcons.component, size: 14),
              ),
              value: _query,
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: instances.isEmpty
                  ? Center(
                      child: Text(
                        allInstances.isEmpty
                            ? 'No component instances yet'
                            : 'No components match “${_query.trim()}”.',
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final columnCount =
                            ((constraints.maxWidth + _tileSpacing) /
                                    (_minimumTileWidth + _tileSpacing))
                                .floor()
                                .clamp(1, instances.length)
                                .toInt();
                        return GridView.builder(
                          key: const ValueKey('sketch-component-grid'),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columnCount,
                                mainAxisExtent: tileExtent,
                                crossAxisSpacing: _tileSpacing,
                                mainAxisSpacing: _tileSpacing,
                              ),
                          itemCount: instances.length,
                          itemBuilder: (context, index) =>
                              _ComponentPreviewTile(
                                registry: widget.registry,
                                instance: instances[index],
                                theme: widget.theme,
                                height: tileExtent - 24,
                                onSelect: widget.onSelect,
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
}

class _ComponentPreviewTile extends StatelessWidget {
  const _ComponentPreviewTile({
    required this.registry,
    required this.instance,
    required this.theme,
    required this.height,
    required this.onSelect,
  });

  final DesyRegistry registry;
  final DesyRegisteredComponentInstance instance;
  final DesyTheme theme;
  final double height;
  final ValueChanged<DesyRegisteredComponentInstance> onSelect;

  @override
  Widget build(BuildContext context) =>
      Draggable<DesyRegisteredComponentInstance>(
        key: ValueKey('palette-drag-${instance.id}'),
        data: instance,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: .9,
            child: SizedBox(
              width: 132,
              child: DesyCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(DesyIcons.component, size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          instance.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: .35, child: _tile(context)),
        child: _tile(context),
      );

  Widget _tile(BuildContext context) => DesyButton(
    key: ValueKey('palette-instance-${instance.id}'),
    semanticsLabel: 'Add ${instance.componentName}, ${instance.name} to sketch',
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
                    builder: (context) => instance.build(
                      context,
                      widgets: registry.widgetBuilder,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            instance.name,
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
    required this.registry,
    required this.node,
    required this.instance,
    required this.controller,
  });

  final DesyRegistry registry;
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
        Text(instance.name, style: Theme.of(context).textTheme.titleMedium),
        Text(
          instance.component.name,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        Text('Knobs', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        if (instance.component.knobDefinitions.isEmpty)
          Text(
            'No knobs declared.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        DesyComponentKnobPanel(
          registry: registry,
          knobs: instance.component.knobDefinitions,
          values: node.knobValues,
          onChanged: (definition, value) =>
              controller.setKnob(node.id, definition.id, value),
        ),
        const SizedBox(height: 16),
        if (node.parentArtboardId != null) ...[
          Text(
            'Rendered in the device’s logical viewport and clipped to its screen.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          DesyButton(
            variant: DesyButtonVariant.outline,
            size: DesyButtonSize.sm,
            onPress: () => controller.detachFromArtboard(node.id),
            child: const Text('Move to canvas'),
          ),
          const SizedBox(height: 8),
        ],
        DesyButton(
          variant: DesyButtonVariant.outline,
          size: DesyButtonSize.sm,
          onPress: () => controller.resetToNormalSize(node.id),
          child: const Text('Reset size'),
        ),
        const SizedBox(height: 8),
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
            'A functional device artboard. Components placed inside use its fixed logical viewport, pixel ratio, and safe-area values.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          DesyButton(
            variant: DesyButtonVariant.outline,
            size: DesyButtonSize.sm,
            onPress: () => controller.resetToNormalSize(node.id),
            child: const Text('Reset size'),
          ),
          const SizedBox(height: 8),
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

class _CanvasLayoutInspector extends StatelessWidget {
  const _CanvasLayoutInspector({
    required this.node,
    required this.spacingEntries,
    required this.controller,
  });

  final DesyCanvasNode node;
  final List<DesyNumericEntry> spacingEntries;
  final DesyComponentsCanvasController controller;

  @override
  Widget build(BuildContext context) {
    final currentIndex = spacingEntries.indexWhere(
      (entry) => entry.id == node.spacingEntryId,
    );
    return DesyCard(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('LAYOUT', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            node.layoutPreset!.label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${node.layoutPreset!.slotCount} legal slots · ephemeral sketch structure',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          if (spacingEntries.isEmpty)
            DesyBadge(child: const Text('Gap 0 dp · no registered spacing'))
          else
            DesySelect<int>.rich(
              key: ValueKey('layout-spacing-${node.id}'),
              control: DesySelectControl.lifted(
                value: currentIndex < 0 ? 0 : currentIndex,
                onChange: (index) {
                  if (index == null) return;
                  final entry = spacingEntries[index];
                  controller.setLayoutSpacing(
                    node.id,
                    spacingEntryId: entry.id,
                    spacing: entry.value,
                  );
                },
              ),
              label: const Text('Gap'),
              description: const Text(
                'Values come from the active registry’s Measurements entries.',
              ),
              format: (index) => spacingEntries[index].displayValue,
              children: [
                for (final (index, entry) in spacingEntries.indexed)
                  DesySelectItem.item(
                    value: index,
                    title: Text(entry.name),
                    subtitle: Text(entry.displayValue),
                  ),
              ],
            ),
          const SizedBox(height: 20),
          Text(
            'Select this layout, then choose component instances from the palette to fill its open slots.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          DesyButton(
            variant: DesyButtonVariant.outline,
            size: DesyButtonSize.sm,
            onPress: () => controller.remove(node.id),
            child: const Text('Remove layout'),
          ),
        ],
      ),
    );
  }
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
                        if (node.isLayout) {
                          final filled = placedNodes
                              .where(
                                (candidate) =>
                                    candidate.parentLayoutId == node.id,
                              )
                              .length;
                          return DesyTile(
                            key: ValueKey('canvas-node-${node.id}'),
                            selected: selectedId == node.id,
                            onPress: () => onSelect(node.id),
                            prefix: const Icon(DesyIcons.layoutGrid, size: 16),
                            title: Text(node.layoutPreset!.label),
                            subtitle: Text(
                              '$filled of ${node.layoutPreset!.slotCount} slots · ${node.spacing?.toStringAsFixed(0)} dp gap',
                            ),
                          );
                        }
                        final instance = _instanceFor(node.instanceId!);
                        if (instance == null) return const SizedBox.shrink();
                        final parentArtboard = node.parentArtboardId == null
                            ? null
                            : placedNodes
                                  .where(
                                    (candidate) =>
                                        candidate.id == node.parentArtboardId,
                                  )
                                  .firstOrNull;
                        return DesyTile(
                          key: ValueKey('canvas-node-${node.id}'),
                          selected: selectedId == node.id,
                          onPress: () => onSelect(node.id),
                          prefix: const Icon(DesyIcons.boxes, size: 16),
                          title: Text(
                            instance.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            node.parentLayoutId != null
                                ? '${instance.component.name} · Slot ${(node.slotIndex ?? 0) + 1}'
                                : parentArtboard != null
                                ? '${instance.component.name} · ${parentArtboard.artboard!.label}'
                                : instance.component.name,
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
    required this.registry,
    required this.instances,
    required this.nodes,
    required this.selectedId,
    required this.theme,
    required this.controller,
    required this.gridStep,
    required this.onDropInstance,
  });

  final DesyRegistry registry;
  final List<DesyRegisteredComponentInstance> instances;
  final Map<String, DesyCanvasNode> nodes;
  final String? selectedId;
  final DesyTheme theme;
  final DesyComponentsCanvasController controller;
  final double gridStep;
  final _DropSketchInstance onDropInstance;

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.setStageBounds(clampingRect);
        controller.prepareSnapSceneIndex();
      });
      return Builder(
        builder: (stageContext) => DragTarget<DesyRegisteredComponentInstance>(
          key: const ValueKey('sketch-drop-target'),
          onWillAcceptWithDetails: (_) => true,
          onAcceptWithDetails: (details) {
            final renderBox = stageContext.findRenderObject() as RenderBox;
            onDropInstance(
              details.data,
              renderBox.globalToLocal(details.offset),
            );
          },
          builder: (context, candidates, rejected) => DecoratedBox(
            decoration: BoxDecoration(
              color:
                  theme.previewBackgroundColor ??
                  context.theme.colors.background,
              border: candidates.isEmpty
                  ? null
                  : Border.all(
                      color: context.theme.colors.desy.signal,
                      width: 2,
                    ),
            ),
            child: CustomPaint(
              painter: _CanvasGridPainter(
                minorColor: context.theme.colors.border,
                majorColor: context.theme.colors.mutedForeground,
                step: gridStep,
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
                      child: Text(
                        'Choose or drag an instance from the palette.',
                      ),
                    ),
                  for (final nodeId in nodes.keys)
                    _ReactiveCanvasNode(
                      key: ValueKey('canvas-node-signal-$nodeId'),
                      nodeId: nodeId,
                      committedNodes: nodes,
                      selectedId: selectedId,
                      clampingRect: clampingRect,
                      registry: registry,
                      instances: instances,
                      theme: theme,
                      controller: controller,
                    ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        key: const ValueKey('sketch-snap-guides-repaint'),
                        child: ValueListenableBuilder<List<DesySnapGuide>>(
                          valueListenable: controller.activeSnapGuides,
                          builder: (context, guides, _) => CustomPaint(
                            key: const ValueKey('sketch-snap-guides'),
                            painter: _CanvasSnapGuidePainter(
                              guides: guides,
                              color: context.theme.colors.desy.signal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ReactiveCanvasNode extends StatelessWidget {
  const _ReactiveCanvasNode({
    super.key,
    required this.nodeId,
    required this.committedNodes,
    required this.selectedId,
    required this.clampingRect,
    required this.registry,
    required this.instances,
    required this.theme,
    required this.controller,
  });

  final String nodeId;
  final Map<String, DesyCanvasNode> committedNodes;
  final String? selectedId;
  final Rect clampingRect;
  final DesyRegistry registry;
  final List<DesyRegisteredComponentInstance> instances;
  final DesyTheme theme;
  final DesyComponentsCanvasController controller;

  @override
  Widget build(BuildContext context) {
    final signal = controller.nodeListenable(nodeId);
    final committedNode = committedNodes[nodeId];
    if (signal == null || committedNode == null) {
      return const SizedBox.shrink();
    }
    final content = _contentFor(committedNode);
    if (content == null) return const SizedBox.shrink();
    return ValueListenableBuilder<DesyCanvasNode>(
      valueListenable: signal,
      child: content,
      builder: (context, node, child) => _CanvasNodeFrame(
        node: node,
        selected: selectedId == node.id,
        clampingRect: clampingRect,
        minSize: node.isLayout ? const Size(160, 120) : const Size(8, 8),
        controller: controller,
        child: child!,
      ),
    );
  }

  Widget? _contentFor(DesyCanvasNode node) {
    if (node.isArtboard) {
      return _CanvasArtboard(
        artboardNode: node,
        children: _artboardChildren(node.id),
        registry: registry,
        instances: instances,
        selectedId: selectedId,
        theme: theme,
        controller: controller,
      );
    }
    if (node.isLayout) {
      return _CanvasLayout(
        node: node,
        children: _layoutChildren(node.id),
        registry: registry,
        instances: instances,
        selectedId: selectedId,
        theme: theme,
        controller: controller,
      );
    }
    if (node.parentLayoutId != null || node.parentArtboardId != null) {
      return null;
    }
    final instance = _instanceFor(node.instanceId!);
    if (instance == null) return null;
    return _CanvasElement(
      registry: registry,
      instance: instance,
      node: node,
      theme: theme,
      selected: selectedId == node.id,
      controller: controller,
    );
  }

  DesyRegisteredComponentInstance? _instanceFor(String id) {
    for (final instance in instances) {
      if (instance.id == id) return instance;
    }
    return null;
  }

  List<DesyCanvasNode> _layoutChildren(String layoutId) =>
      committedNodes.values
          .where((node) => node.parentLayoutId == layoutId)
          .toList(growable: false)
        ..sort((a, b) => (a.slotIndex ?? 0).compareTo(b.slotIndex ?? 0));

  List<DesyCanvasNode> _artboardChildren(String artboardId) => committedNodes
      .values
      .where((node) => node.parentArtboardId == artboardId)
      .toList(growable: false);
}

/// A flat, freely overlapping canvas layer with minimal Figma-like handles.
class _CanvasNodeFrame extends StatelessWidget {
  const _CanvasNodeFrame({
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
    return RepaintBoundary(
      key: ValueKey('sketch-node-repaint-${node.id}'),
      child: DesyDragBox(
        geometry: DesyDragBoxGeometry(rect: node.rect, flip: node.flip),
        clampingRect: clampingRect,
        constraints: BoxConstraints(
          minWidth: minSize.width,
          minHeight: minSize.height,
        ),
        frameKey: ValueKey(node.id),
        contentKey: ValueKey('canvas-hit-${node.id}'),
        resizeHandleKeyPrefix: 'canvas-resize-${node.id}',
        selected: selected,
        onSelect: () => controller.select(node.id),
        onDoubleTap: node.isLayout
            ? null
            : () => controller.resetToNormalSize(node.id),
        onInteractionStart: (_) => controller.beginSnapInteraction(node.id),
        geometryResolver: _resolveGeometry,
        onInteractionEnd: (_) => controller.endSnapInteraction(),
        onChanged: (geometry) {
          final current = controller.nodeValue(node.id);
          if (current != null && current.rect.size != geometry.rect.size) {
            controller.declareManual(node.id);
          }
          controller.updateTransient(_nodeFor(geometry));
        },
        onChangeEnd: (geometry) =>
            controller.commitInteraction(_nodeFor(geometry)),
        label: selected
            ? DesyDragBoxLabel(
                key: ValueKey('sketch-node-label-${node.id}'),
                size: node.rect.size,
                identifier: node.instanceId ?? node.id,
              )
            : null,
        ignoreChildPointer: !node.isArtboard,
        child: DecoratedBox(
          decoration: selected
              ? BoxDecoration(
                  border: Border.all(
                    color: context.theme.colors.desy.signal.withValues(
                      alpha: .48,
                    ),
                  ),
                )
              : const BoxDecoration(),
          child: RepaintBoundary(child: child),
        ),
      ),
    );
  }

  DesyCanvasNode _nodeFor(DesyDragBoxGeometry geometry) {
    final current = controller.nodeValue(node.id) ?? node;
    return current.copyWith(rect: geometry.rect, flip: geometry.flip);
  }

  DesyDragBoxGeometry _resolveGeometry(
    DesyDragBoxGeometry geometry,
    DesyDragBoxInteraction interaction,
  ) {
    final current = controller.nodeValue(node.id) ?? node;
    final operation = interaction.kind == DesyDragBoxInteractionKind.move
        ? DesySnapOperation.move
        : DesySnapOperation.resize;
    final edges = _snapEdgesFor(interaction.handle);
    var proposed = geometry.rect;
    double? aspectRatio;
    if (current.isArtboard && operation == DesySnapOperation.resize) {
      final initial = current.copyWith(rect: interaction.initialRect);
      proposed = DesyCanvasGeometry.lockFrameAspect(
        initial,
        proposed,
        clampingRect: clampingRect,
      );
      aspectRatio = DesyCanvasGeometry.deviceFor(
        current.artboard!,
      ).frameSize.aspectRatio;
    }
    final result = controller.resolveSnap(
      node.id,
      DesySnapRequest(
        rect: proposed,
        operation: operation,
        edges: edges,
        bounds: clampingRect,
        minimumSize: minSize,
        aspectRatio: aspectRatio,
      ),
    );
    return DesyDragBoxGeometry(rect: result.rect, flip: geometry.flip);
  }
}

DesySnapEdges _snapEdgesFor(HandlePosition handle) => switch (handle) {
  HandlePosition.topLeft => const DesySnapEdges(left: true, top: true),
  HandlePosition.top => const DesySnapEdges(top: true),
  HandlePosition.topRight => const DesySnapEdges(right: true, top: true),
  HandlePosition.left => const DesySnapEdges(left: true),
  HandlePosition.right => const DesySnapEdges(right: true),
  HandlePosition.bottomLeft => const DesySnapEdges(left: true, bottom: true),
  HandlePosition.bottom => const DesySnapEdges(bottom: true),
  HandlePosition.bottomRight => const DesySnapEdges(right: true, bottom: true),
  HandlePosition.none => const DesySnapEdges(),
};

class _CanvasArtboard extends StatelessWidget {
  const _CanvasArtboard({
    required this.artboardNode,
    required this.children,
    required this.registry,
    required this.instances,
    required this.selectedId,
    required this.theme,
    required this.controller,
  });

  final DesyCanvasNode artboardNode;
  final List<DesyCanvasNode> children;
  final DesyRegistry registry;
  final List<DesyRegisteredComponentInstance> instances;
  final String? selectedId;
  final DesyTheme theme;
  final DesyComponentsCanvasController controller;

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: DesyDevicePreview(
      device: artboardNode.artboard!,
      child: ColoredBox(
        color:
            theme.previewBackgroundColor ??
            Theme.of(context).colorScheme.surface,
        child: Stack(
          key: ValueKey('canvas-artboard-screen-${artboardNode.id}'),
          clipBehavior: Clip.hardEdge,
          children: [
            for (final child in children)
              _ReactiveArtboardChild(
                key: ValueKey('canvas-artboard-child-${child.id}'),
                node: child,
                artboard: artboardNode,
                registry: registry,
                instances: instances,
                selected: selectedId == child.id,
                theme: theme,
                controller: controller,
              ),
          ],
        ),
      ),
    ),
  );
}

class _ReactiveArtboardChild extends StatelessWidget {
  const _ReactiveArtboardChild({
    super.key,
    required this.node,
    required this.artboard,
    required this.registry,
    required this.instances,
    required this.selected,
    required this.theme,
    required this.controller,
  });

  final DesyCanvasNode node;
  final DesyCanvasNode artboard;
  final DesyRegistry registry;
  final List<DesyRegisteredComponentInstance> instances;
  final bool selected;
  final DesyTheme theme;
  final DesyComponentsCanvasController controller;

  @override
  Widget build(BuildContext context) {
    final signal = controller.nodeListenable(node.id);
    final instance = instances
        .where((candidate) => candidate.id == node.instanceId)
        .firstOrNull;
    if (signal == null || instance == null) return const SizedBox.shrink();
    final screenSize = artboard.artboard!.screenSize;
    final interactionBounds = Rect.fromLTRB(
      -screenSize.width,
      -screenSize.height,
      screenSize.width * 2,
      screenSize.height * 2,
    );
    return ValueListenableBuilder<DesyCanvasNode>(
      valueListenable: signal,
      child: _CanvasElement(
        registry: registry,
        instance: instance,
        node: node,
        theme: theme,
        selected: selected,
        controller: controller,
      ),
      builder: (context, current, child) => DesyDragBox(
        geometry: DesyDragBoxGeometry(rect: current.rect, flip: current.flip),
        clampingRect: interactionBounds,
        constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
        frameKey: ValueKey(current.id),
        contentKey: ValueKey('canvas-hit-${current.id}'),
        resizeHandleKeyPrefix: 'canvas-resize-${current.id}',
        selected: selected,
        onSelect: () => controller.select(current.id),
        onDoubleTap: () => controller.resetToNormalSize(current.id),
        onChanged: (geometry) => controller.updateTransient(
          current.copyWith(rect: geometry.rect, flip: geometry.flip),
        ),
        onChangeEnd: (geometry) => controller.commitArtboardChildInteraction(
          current.copyWith(rect: geometry.rect, flip: geometry.flip),
          artboard,
        ),
        label: selected
            ? DesyDragBoxLabel(
                key: ValueKey('sketch-node-label-${current.id}'),
                size: current.rect.size,
                identifier: current.instanceId!,
              )
            : null,
        child: DecoratedBox(
          decoration: selected
              ? BoxDecoration(
                  border: Border.all(
                    color: context.theme.colors.desy.signal.withValues(
                      alpha: .48,
                    ),
                  ),
                )
              : const BoxDecoration(),
          child: child,
        ),
      ),
    );
  }
}

class _CanvasLayout extends StatelessWidget {
  const _CanvasLayout({
    required this.node,
    required this.children,
    required this.registry,
    required this.instances,
    required this.selectedId,
    required this.theme,
    required this.controller,
  });

  final DesyCanvasNode node;
  final List<DesyCanvasNode> children;
  final DesyRegistry registry;
  final List<DesyRegisteredComponentInstance> instances;
  final String? selectedId;
  final DesyTheme theme;
  final DesyComponentsCanvasController controller;

  @override
  Widget build(BuildContext context) {
    final preset = node.layoutPreset!;
    final gap = node.spacing!;
    final colors = context.theme.colors;
    return DecoratedBox(
      key: ValueKey('canvas-layout-${node.id}'),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(gap),
        child: switch (preset) {
          DesyCanvasLayoutPreset.singleColumn => _column(
            List.generate(preset.slotCount, _slot),
            gap,
          ),
          DesyCanvasLayoutPreset.twoColumn => _row(
            List.generate(preset.slotCount, _slot),
            gap,
          ),
          DesyCanvasLayoutPreset.threeColumnGrid => _fixedGrid(
            columns: 3,
            slots: preset.slotCount,
            gap: gap,
          ),
          DesyCanvasLayoutPreset.responsiveCardGrid => LayoutBuilder(
            builder: (context, constraints) => _fixedGrid(
              columns: constraints.maxWidth >= 560
                  ? 3
                  : constraints.maxWidth >= 320
                  ? 2
                  : 1,
              slots: preset.slotCount,
              gap: gap,
            ),
          ),
          DesyCanvasLayoutPreset.repeatedListRows => _column(
            List.generate(preset.slotCount, _slot),
            gap,
          ),
          DesyCanvasLayoutPreset.form => _column(
            List.generate(preset.slotCount, _slot),
            gap,
          ),
        },
      ),
    );
  }

  Widget _fixedGrid({
    required int columns,
    required int slots,
    required double gap,
  }) {
    final rowCount = (slots / columns).ceil();
    return _column([
      for (var row = 0; row < rowCount; row++)
        _row([
          for (var column = 0; column < columns; column++)
            if (row * columns + column < slots)
              _slot(row * columns + column)
            else
              const SizedBox.shrink(),
        ], gap),
    ], gap);
  }

  Widget _row(List<Widget> children, double gap) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: _withGaps(children, gap, Axis.horizontal),
  );

  Widget _column(List<Widget> children, double gap) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: _withGaps(children, gap, Axis.vertical),
  );

  List<Widget> _withGaps(List<Widget> children, double gap, Axis direction) => [
    for (final (index, child) in children.indexed) ...[
      if (index > 0)
        SizedBox(
          width: direction == Axis.horizontal ? gap : 0,
          height: direction == Axis.vertical ? gap : 0,
        ),
      Expanded(child: child),
    ],
  ];

  Widget _slot(int index) {
    DesyCanvasNode? child;
    for (final candidate in children) {
      if (candidate.slotIndex == index) {
        child = candidate;
        break;
      }
    }
    final instance = child == null ? null : _instanceFor(child.instanceId!);
    return _CanvasLayoutSlot(
      key: ValueKey('canvas-layout-${node.id}-slot-$index'),
      index: index,
      gap: node.spacing!,
      child: child == null || instance == null
          ? null
          : _CanvasElement(
              registry: registry,
              instance: instance,
              node: child,
              theme: theme,
              selected: selectedId == child.id,
              controller: controller,
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

class _CanvasLayoutSlot extends StatelessWidget {
  const _CanvasLayoutSlot({
    super.key,
    required this.index,
    required this.gap,
    required this.child,
  });

  final int index;
  final double gap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Semantics(
      label: child == null
          ? 'Empty layout slot ${index + 1}'
          : 'Filled layout slot ${index + 1}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.secondary,
          border: Border.all(color: colors.border),
        ),
        child:
            child ??
            Center(
              child: Text(
                'Slot ${index + 1}\n${gap.toStringAsFixed(0)} dp rhythm',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
              ),
            ),
      ),
    );
  }
}

extension on DesyDevicePreset {
  IconData get icon => switch (this) {
    DesyDevicePreset.iPhone15Pro => DesyIcons.smartphone,
    DesyDevicePreset.iPadPro11 => DesyIcons.tablet,
  };
}

class _CanvasGridPainter extends CustomPainter {
  const _CanvasGridPainter({
    required this.minorColor,
    required this.majorColor,
    required this.step,
  });

  final Color minorColor;
  final Color majorColor;
  final double step;

  @override
  void paint(Canvas canvas, Size size) {
    final minor = Paint()
      ..color = minorColor.withAlpha(40)
      ..strokeWidth = 0.5;
    final major = Paint()
      ..color = majorColor.withAlpha(50)
      ..strokeWidth = 1;

    final showMinor = step >= 4;
    final paintedStep = showMinor ? step : step * 8;
    final majorEvery = showMinor ? 8 : 1;
    for (
      var index = 0, x = 0.0;
      x <= size.width;
      index++, x = index * paintedStep
    ) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        index % majorEvery == 0 ? major : minor,
      );
    }
    for (
      var index = 0, y = 0.0;
      y <= size.height;
      index++, y = index * paintedStep
    ) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        index % majorEvery == 0 ? major : minor,
      );
    }
  }

  @override
  bool shouldRepaint(_CanvasGridPainter oldDelegate) =>
      oldDelegate.minorColor != minorColor ||
      oldDelegate.majorColor != majorColor ||
      oldDelegate.step != step;
}

class _CanvasSnapGuidePainter extends CustomPainter {
  const _CanvasSnapGuidePainter({required this.guides, required this.color});

  final List<DesySnapGuide> guides;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (guides.isEmpty) return;
    final paint = Paint()
      ..color = color.withValues(alpha: .82)
      ..strokeWidth = 1;
    for (final guide in guides) {
      const extension = 6.0;
      if (guide.axis == DesySnapAxis.x) {
        canvas.drawLine(
          Offset(guide.coordinate, guide.start - extension),
          Offset(guide.coordinate, guide.end + extension),
          paint,
        );
      } else {
        canvas.drawLine(
          Offset(guide.start - extension, guide.coordinate),
          Offset(guide.end + extension, guide.coordinate),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CanvasSnapGuidePainter oldDelegate) =>
      !identical(oldDelegate.guides, guides) || oldDelegate.color != color;
}

/// A placed component has no Desy-owned card or title bar. The only chrome is
/// the selection outline drawn while editing; the actual widget stays wholly
/// consumer-owned and receives loose constraints inside its composition frame.
class _CanvasElement extends StatelessWidget {
  const _CanvasElement({
    required this.registry,
    required this.instance,
    required this.node,
    required this.theme,
    required this.selected,
    required this.controller,
  });

  final DesyRegistry registry;
  final DesyRegisteredComponentInstance instance;
  final DesyCanvasNode node;
  final DesyTheme theme;
  final bool selected;
  final DesyComponentsCanvasController controller;

  @override
  Widget build(BuildContext context) {
    final preview = DesyWidgetPreview(
      theme: theme,
      builder: (context) => instance.component.buildWithValues(
        context,
        node.knobValues,
        widgets: registry.widgetBuilder,
      ),
    );
    // Without a declared size the drag box auto-fits to the content's natural
    // size after the first real layout pass.
    final measured = instance.component.defaultSize == null
        ? DesyContentSizeProbe(
            onNaturalSize: (size) => controller.fitToContent(node.id, size),
            child: preview,
          )
        : preview;
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: Align(alignment: Alignment.topLeft, child: measured),
        ),
        if (selected)
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: context.theme.colors.desy.signal.withValues(
                    alpha: .32,
                  ),
                  width: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

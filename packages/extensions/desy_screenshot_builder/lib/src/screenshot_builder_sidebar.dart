part of 'screenshot_builder_extension.dart';

class _ScreenshotSidebar extends StatelessWidget {
  const _ScreenshotSidebar({
    required this.canvas,
    required this.layers,
    required this.backgroundColor,
    required this.extension,
    required this.selectedTheme,
    required this.exporting,
    required this.status,
    required this.onExit,
    required this.onAdd,
    required this.onPickImage,
    required this.onExport,
    required this.onCanvasSizeChanged,
    required this.onThemeChanged,
    required this.onBackgroundChanged,
    required this.onToggleHidden,
  });

  final ObjectCanvasController<DesyScreenshotLayer> canvas;
  final List<DesyScreenshotLayer> layers;
  final Color? backgroundColor;
  final DesyWorkspaceExtensionContext extension;
  final DesyTheme selectedTheme;
  final bool exporting;
  final String? status;
  final VoidCallback? onExit;
  final ValueChanged<_PalettePayload> onAdd;
  final VoidCallback onPickImage;
  final VoidCallback onExport;
  final ValueChanged<Size> onCanvasSizeChanged;
  final void Function(String themeId, {Color? defaultBackground})
  onThemeChanged;
  final ValueChanged<Color?> onBackgroundChanged;
  final ValueChanged<String> onToggleHidden;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.theme.colors.desy.panel,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
          child: Row(
            children: [
              if (onExit != null) ...[
                DesyButton.icon(
                  key: const ValueKey('screenshot-builder-exit'),
                  size: DesyButtonSize.xs,
                  variant: DesyButtonVariant.ghost,
                  semanticsLabel: 'Back to workspace',
                  onPress: onExit,
                  child: const Icon(DesyIcons.arrowLeft, size: 15),
                ),
                const SizedBox(width: 8),
              ],
              const Expanded(
                child: Text(
                  'Screenshot builder',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const DesyBadge(child: Text('EXPERIMENTAL')),
            ],
          ),
        ),
        Expanded(
          child: DesyTabs(
            expands: true,
            children: [
              DesyTabEntry(
                label: const Text('Elements', key: ValueKey('elements-tab')),
                child: _ElementsPanel(
                  extension: extension,
                  onAdd: onAdd,
                  onPickImage: onPickImage,
                ),
              ),
              DesyTabEntry(
                label: const Text('Scene', key: ValueKey('scene-tab')),
                child: _ScenePanel(
                  canvas: canvas,
                  layers: layers,
                  onToggleHidden: onToggleHidden,
                ),
              ),
              DesyTabEntry(
                label: const Text('Page', key: ValueKey('page-tab')),
                child: _PagePanel(
                  canvas: canvas,
                  backgroundColor: backgroundColor,
                  extension: extension,
                  selectedTheme: selectedTheme,
                  exporting: exporting,
                  status: status,
                  onExport: onExport,
                  onCanvasSizeChanged: onCanvasSizeChanged,
                  onThemeChanged: onThemeChanged,
                  onBackgroundChanged: onBackgroundChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ElementsPanel extends StatefulWidget {
  const _ElementsPanel({
    required this.extension,
    required this.onAdd,
    required this.onPickImage,
  });

  final DesyWorkspaceExtensionContext extension;
  final ValueChanged<_PalettePayload> onAdd;
  final VoidCallback onPickImage;

  @override
  State<_ElementsPanel> createState() => _ElementsPanelState();
}

class _ElementsPanelState extends State<_ElementsPanel> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final normalized = _query.trim().toLowerCase();
    final instances = widget.extension.registry.allComponentInstances
        .where(
          (instance) =>
              normalized.isEmpty ||
              instance.name.toLowerCase().contains(normalized) ||
              instance.componentName.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
    return ListView(
      key: const ValueKey('screenshot-elements-panel'),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'ADD TO CANVAS',
          style: context.theme.typography.body.xs.copyWith(
            color: context.theme.colors.mutedForeground,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _PaletteTile(
                key: const ValueKey('add-text-element'),
                payload: const _TextPalettePayload(),
                icon: DesyIcons.type,
                title: 'Text',
                subtitle: 'Registry type + color',
                onAdd: widget.onAdd,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DesyButton(
                key: const ValueKey('add-image-element'),
                variant: DesyButtonVariant.outline,
                size: DesyButtonSize.sm,
                prefix: const Icon(DesyIcons.image, size: 15),
                onPress: widget.onPickImage,
                child: const Text('Image'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        DesyTextField(
          key: const ValueKey('screenshot-element-search'),
          label: 'Search widget instances',
          hintText: 'Search widgets',
          prefixIcon: const Icon(DesyIcons.search, size: 15),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 12),
        Text(
          '${instances.length} WIDGET INSTANCE${instances.length == 1 ? '' : 'S'}',
          style: context.theme.typography.body.xs.copyWith(
            color: context.theme.colors.mutedForeground,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        if (instances.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No matching registered widget instances.'),
          )
        else
          for (final instance in instances) ...[
            _PaletteTile(
              key: ValueKey('add-widget-${instance.id}'),
              payload: _WidgetPalettePayload(instance),
              icon: instance.component.icon ?? DesyIcons.component,
              title: instance.name,
              subtitle: instance.componentName,
              onAdd: widget.onAdd,
            ),
            const SizedBox(height: 6),
          ],
        const SizedBox(height: 16),
        Text(
          'Drag items onto the canvas, or click to add them in the center. Drop image files anywhere in the canvas area.',
          style: context.theme.typography.body.sm.copyWith(
            color: context.theme.colors.mutedForeground,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    super.key,
    required this.payload,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onAdd,
  });

  final _PalettePayload payload;
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueChanged<_PalettePayload> onAdd;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final contentWidth =
          (constraints.maxWidth.isFinite ? constraints.maxWidth - 28 : 180.0)
              .clamp(72.0, 280.0);
      final tile = DesyButton(
        variant: DesyButtonVariant.outline,
        size: DesyButtonSize.sm,
        mainAxisAlignment: MainAxisAlignment.start,
        onPress: () => onAdd(payload),
        child: SizedBox(
          width: contentWidth,
          child: Row(
            children: [
              Icon(icon, size: 15),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.theme.typography.body.xs.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      return Draggable<_PalettePayload>(
        data: payload,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.theme.colors.desy.panel,
                border: Border.all(color: context.theme.colors.desy.signal),
                borderRadius: BorderRadius.circular(
                  DesyDesignSystemTokens.radiusSm,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(title),
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: .4, child: tile),
        child: tile,
      );
    },
  );
}

class _ScenePanel extends StatelessWidget {
  const _ScenePanel({
    required this.canvas,
    required this.layers,
    required this.onToggleHidden,
  });

  final ObjectCanvasController<DesyScreenshotLayer> canvas;
  final List<DesyScreenshotLayer> layers;
  final ValueChanged<String> onToggleHidden;

  @override
  Widget build(BuildContext context) {
    final topFirst = layers.reversed.toList(growable: false);
    return ListView(
      key: const ValueKey('screenshot-scene-panel'),
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'LAYERS',
                  style: context.theme.typography.body.xs.copyWith(
                    color: context.theme.colors.mutedForeground,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Text('${layers.length}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (topFirst.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'The scene is empty. Add widgets, images, or text from Elements.',
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          )
        else
          for (final layer in topFirst)
            _LayerRow(
              layer: layer,
              canvas: canvas,
              onToggleHidden: onToggleHidden,
            ),
      ],
    );
  }
}

class _ScreenshotLayerInspector extends StatelessWidget {
  const _ScreenshotLayerInspector({
    required this.canvas,
    required this.selectedLayer,
    required this.extension,
    required this.onSetKnob,
    required this.onSetText,
    required this.onSetTextTypography,
    required this.onSetTextColor,
    required this.onSetTextAlign,
    required this.onToggleHidden,
  });

  final ObjectCanvasController<DesyScreenshotLayer> canvas;
  final DesyScreenshotLayer? selectedLayer;
  final DesyWorkspaceExtensionContext extension;
  final void Function(String id, String knobId, Object value) onSetKnob;
  final void Function(String id, String value) onSetText;
  final void Function(String id, String? typographyId) onSetTextTypography;
  final void Function(String id, String? colorId) onSetTextColor;
  final void Function(String id, TextAlign textAlign) onSetTextAlign;
  final ValueChanged<String> onToggleHidden;

  @override
  Widget build(BuildContext context) {
    final layer = selectedLayer;
    final imageSize = layer is DesyScreenshotImageLayer
        ? canvas.geometryFor(layer.id).paintBounds.size
        : null;
    return ColoredBox(
      key: const ValueKey('screenshot-layer-inspector'),
      color: context.theme.colors.background,
      child: layer == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Select an element to edit its properties.',
                  key: const ValueKey('screenshot-layer-inspector-empty'),
                  textAlign: TextAlign.center,
                  style: context.theme.typography.body.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                    height: 1.4,
                  ),
                ),
              ),
            )
          : ListView(
              key: const ValueKey('screenshot-layer-inspector-content'),
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROPERTIES',
                        style: context.theme.typography.body.xs.copyWith(
                          color: context.theme.colors.mutedForeground,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        layer.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.theme.typography.body.md.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _SelectedLayerActions(
                  layer: layer,
                  canvas: canvas,
                  onToggleHidden: onToggleHidden,
                ),
                const SizedBox(height: 8),
                switch (layer) {
                  final DesyScreenshotWidgetLayer widgetLayer =>
                    _WidgetInspector(
                      layer: widgetLayer,
                      registry: extension.registry,
                      onSetKnob: onSetKnob,
                    ),
                  final DesyScreenshotTextLayer textLayer => _TextInspector(
                    layer: textLayer,
                    registry: extension.registry,
                    onSetText: onSetText,
                    onSetTypography: onSetTextTypography,
                    onSetColor: onSetTextColor,
                    onSetAlign: onSetTextAlign,
                  ),
                  final DesyScreenshotImageLayer imageLayer => DesyKnobSheet(
                    segments: [
                      DesyKnobSegment(
                        title: 'IMAGE',
                        children: [
                          DesyTextValueKnobRow(
                            label: 'File',
                            value: imageLayer.name,
                          ),
                          DesyTextValueKnobRow(
                            label: 'Size',
                            value:
                                '${imageSize!.width.round()} × ${imageSize.height.round()}',
                          ),
                        ],
                      ),
                    ],
                  ),
                  _ => const SizedBox.shrink(),
                },
              ],
            ),
    );
  }
}

class _LayerRow extends StatelessWidget {
  const _LayerRow({
    required this.layer,
    required this.canvas,
    required this.onToggleHidden,
  });

  final DesyScreenshotLayer layer;
  final ObjectCanvasController<DesyScreenshotLayer> canvas;
  final ValueChanged<String> onToggleHidden;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: DesyButton(
            key: ValueKey('select-layer-${layer.id}'),
            selected: canvas.selectedObjectIds.contains(layer.id),
            variant: canvas.selectedObjectIds.contains(layer.id)
                ? DesyButtonVariant.secondary
                : DesyButtonVariant.ghost,
            size: DesyButtonSize.sm,
            mainAxisAlignment: MainAxisAlignment.start,
            onPress: layer.hidden
                ? null
                : () => canvas.setSelectedObjects([layer.id]),
            child: Text(
              layer.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DesyButton(
          key: ValueKey('toggle-layer-${layer.id}'),
          size: DesyButtonSize.xs,
          variant: DesyButtonVariant.ghost,
          mainAxisSize: MainAxisSize.min,
          semanticsLabel: layer.hidden
              ? 'Show ${layer.name}'
              : 'Hide ${layer.name}',
          onPress: () => onToggleHidden(layer.id),
          child: Text(layer.hidden ? 'Show' : 'Hide'),
        ),
      ],
    ),
  );
}

class _SelectedLayerActions extends StatelessWidget {
  const _SelectedLayerActions({
    required this.layer,
    required this.canvas,
    required this.onToggleHidden,
  });

  final DesyScreenshotLayer layer;
  final ObjectCanvasController<DesyScreenshotLayer> canvas;
  final ValueChanged<String> onToggleHidden;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        DesyButton(
          key: const ValueKey('layer-backward'),
          size: DesyButtonSize.xs,
          variant: DesyButtonVariant.outline,
          mainAxisSize: MainAxisSize.min,
          onPress: () => canvas.moveObjectsBackward([layer.id]),
          child: const Text('Backward'),
        ),
        DesyButton(
          key: const ValueKey('layer-forward'),
          size: DesyButtonSize.xs,
          variant: DesyButtonVariant.outline,
          mainAxisSize: MainAxisSize.min,
          onPress: () => canvas.moveObjectsForward([layer.id]),
          child: const Text('Forward'),
        ),
        DesyButton(
          key: const ValueKey('layer-hide'),
          size: DesyButtonSize.xs,
          variant: DesyButtonVariant.outline,
          mainAxisSize: MainAxisSize.min,
          onPress: () => onToggleHidden(layer.id),
          child: Text(layer.hidden ? 'Show' : 'Hide'),
        ),
        DesyButton(
          key: const ValueKey('layer-delete'),
          size: DesyButtonSize.xs,
          variant: DesyButtonVariant.destructive,
          mainAxisSize: MainAxisSize.min,
          onPress: () => canvas.removeObjects([layer.id]),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

class _WidgetInspector extends StatelessWidget {
  const _WidgetInspector({
    required this.layer,
    required this.registry,
    required this.onSetKnob,
  });

  final DesyScreenshotWidgetLayer layer;
  final DesyRegistry registry;
  final void Function(String id, String knobId, Object value) onSetKnob;

  @override
  Widget build(BuildContext context) {
    final instance = registry.resolveComponentInstance(layer.instanceId);
    if (instance == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('The registered widget instance is no longer available.'),
      );
    }
    return DesyKnobSheet(
      segments: [
        DesyKnobSegment(
          title: 'WIDGET',
          children: [
            DesyTextValueKnobRow(label: 'Instance', value: instance.name),
          ],
        ),
        if (instance.component.knobDefinitions.isNotEmpty)
          DesyKnobSegment(
            title: 'KNOBS',
            children: [
              for (final knob in instance.component.knobDefinitions)
                _ScreenshotKnobControl(
                  registry: registry,
                  definition: knob,
                  value: layer.knobValues[knob.id] ?? knob.initial,
                  onChanged: (value) => onSetKnob(layer.id, knob.id, value),
                ),
            ],
          ),
      ],
    );
  }
}

class _ScreenshotKnobControl extends StatelessWidget {
  const _ScreenshotKnobControl({
    required this.registry,
    required this.definition,
    required this.value,
    required this.onChanged,
  });

  final DesyRegistry registry;
  final KnobDefinition<Object> definition;
  final Object value;
  final ValueChanged<Object> onChanged;

  @override
  Widget build(BuildContext context) => switch (definition.kind) {
    DesyKnobKind.boolean => DesyBooleanKnobRow(
      label: definition.name,
      description: definition.description,
      value: value as bool,
      onChanged: onChanged,
    ),
    DesyKnobKind.string => DesyTextKnobRow(
      label: definition.name,
      description: definition.description,
      value: value as String,
      onChanged: onChanged,
    ),
    DesyKnobKind.choice => DesyChoiceKnobRow(
      label: definition.name,
      description: definition.description,
      value: value as String,
      options: definition.options,
      onChanged: onChanged,
    ),
    DesyKnobKind.number => DesyNumericKnobRow(
      label: definition.name,
      description: definition.description,
      value: (value as num).toDouble(),
      unit: definition.unit!,
      step: definition.step!,
      minimum: definition.minimum!,
      maximum: definition.maximum!,
      onChanged: onChanged,
    ),
    DesyKnobKind.dateTime => DesyDateTimeKnobRow(
      label: definition.name,
      description: definition.description,
      value: value as DateTime,
      onChanged: onChanged,
    ),
    DesyKnobKind.color => DesyColorKnobRow(
      label: definition.name,
      description: definition.description,
      value: value as Color,
      onChanged: onChanged,
      onPick: () => unawaited(_pickColor(context)),
    ),
    DesyKnobKind.widgetInstance => _singleInstanceControl(context),
    DesyKnobKind.widgetInstances => _multipleInstanceControl(),
    DesyKnobKind.event => DesyKnobRow(
      label: definition.name,
      description: definition.description,
      control: const DesyBadge(
        variant: DesyBadgeVariant.secondary,
        child: Text('Event'),
      ),
    ),
  };

  Widget _singleInstanceControl(BuildContext context) {
    final id = switch (value) {
      final String id => id,
      final DesyInstanceId id => id.value,
      _ => '',
    };
    final instance = registry.resolveComponentInstance(id);
    return DesyInstanceKnobRow(
      label: definition.name,
      description: definition.description,
      instanceName: instance == null
          ? id
          : '${instance.componentName} · ${instance.name}',
      onPress: () => unawaited(_pickSingleInstance(context, id)),
    );
  }

  Widget _multipleInstanceControl() {
    final selected = switch (value) {
      final Iterable<Object?> values => values.whereType<String>().toList(),
      final DesyInstanceIds values => [
        for (final id in values.values) id.value,
      ],
      _ => <String>[],
    };
    final options = _legalInstances();
    return DesyKnobRow(
      label: definition.name,
      description: definition.description,
      expandControl: true,
      control: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final instance in options)
            DesyCheckbox(
              value: selected.contains(instance.id),
              label: Text('${instance.componentName} · ${instance.name}'),
              onChanged: (enabled) {
                final next = [...selected];
                if (enabled) {
                  if (!next.contains(instance.id)) next.add(instance.id);
                } else {
                  next.remove(instance.id);
                }
                onChanged(next);
              },
            ),
        ],
      ),
    );
  }

  List<DesyRegisteredComponentInstance> _legalInstances() {
    final all = registry.allComponentInstances;
    if (definition.options.isEmpty) return all;
    return all
        .where((instance) => definition.options.contains(instance.id))
        .toList(growable: false);
  }

  Future<void> _pickSingleInstance(BuildContext context, String current) async {
    final result = await showDesyDialog<String>(
      context: context,
      builder: (context, animation) => DesyDialog(
        animation: animation,
        semanticsLabel: 'Choose ${definition.name}',
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 620),
        builder: (context, style) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Choose ${definition.name}', style: style.titleTextStyle),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    for (final instance in _legalInstances())
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: DesyButton(
                          selected: instance.id == current,
                          variant: instance.id == current
                              ? DesyButtonVariant.secondary
                              : DesyButtonVariant.outline,
                          mainAxisAlignment: MainAxisAlignment.start,
                          onPress: () => Navigator.of(context).pop(instance.id),
                          child: Text(
                            '${instance.componentName} · ${instance.name}',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null) onChanged(result);
  }

  Future<void> _pickColor(BuildContext context) async {
    final result = await showDesyDialog<Color>(
      context: context,
      builder: (context, animation) => DesyDialog(
        animation: animation,
        semanticsLabel: 'Choose ${definition.name} color',
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 600),
        builder: (context, style) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Registered colors', style: style.titleTextStyle),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    for (final color in registry.allColors)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: DesyButton(
                          variant: DesyButtonVariant.outline,
                          mainAxisAlignment: MainAxisAlignment.start,
                          prefix: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: color.color,
                              border: Border.all(
                                color: context.theme.colors.border,
                              ),
                            ),
                          ),
                          onPress: () => Navigator.of(context).pop(color.color),
                          child: Text(color.name),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null) onChanged(result);
  }
}

class _TextInspector extends StatelessWidget {
  const _TextInspector({
    required this.layer,
    required this.registry,
    required this.onSetText,
    required this.onSetTypography,
    required this.onSetColor,
    required this.onSetAlign,
  });

  final DesyScreenshotTextLayer layer;
  final DesyRegistry registry;
  final void Function(String id, String value) onSetText;
  final void Function(String id, String? typographyId) onSetTypography;
  final void Function(String id, String? colorId) onSetColor;
  final void Function(String id, TextAlign textAlign) onSetAlign;

  @override
  Widget build(BuildContext context) => DesyKnobSheet(
    segments: [
      DesyKnobSegment(
        title: 'TEXT',
        children: [
          DesyTextKnobRow(
            key: const ValueKey('text-content-control'),
            label: 'Content',
            value: layer.text,
            onChanged: (value) => onSetText(layer.id, value),
          ),
          DesyKnobRow(
            label: 'Alignment',
            control: _TextAlignmentControl(
              value: layer.textAlign,
              onChanged: (value) => onSetAlign(layer.id, value),
            ),
          ),
          if (registry.allFonts.isEmpty)
            const DesyTextValueKnobRow(
              label: 'Style',
              value: 'No registered typography styles',
            )
          else
            DesyKnobRow(
              label: 'Style',
              expandControl: true,
              control: DesySelect<String>.rich(
                key: const ValueKey('text-style-control'),
                control: DesySelectControl.lifted(
                  value: layer.typographyId,
                  onChange: (value) => onSetTypography(layer.id, value),
                ),
                format: (id) => registry.allFonts
                    .firstWhere((entry) => entry.id == id)
                    .name,
                children: [
                  for (final entry in registry.allFonts)
                    DesySelectItem.item(
                      value: entry.id,
                      title: Text(entry.name),
                      subtitle: entry.value == null ? null : Text(entry.value!),
                    ),
                ],
              ),
            ),
          if (registry.allColors.isEmpty)
            const DesyTextValueKnobRow(
              label: 'Color',
              value: 'No registered colors',
            )
          else
            DesyKnobRow(
              label: 'Color',
              expandControl: true,
              control: DesySelect<String>.rich(
                key: const ValueKey('text-color-control'),
                control: DesySelectControl.lifted(
                  value: layer.colorId,
                  onChange: (value) => onSetColor(layer.id, value),
                ),
                format: (id) => registry.allColors
                    .firstWhere((entry) => entry.id == id)
                    .name,
                children: [
                  for (final entry in registry.allColors)
                    DesySelectItem.item(
                      value: entry.id,
                      title: Text(entry.name),
                      prefix: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: entry.color,
                          border: Border.all(
                            color: context.theme.colors.border,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    ],
  );
}

class _TextAlignmentControl extends StatelessWidget {
  const _TextAlignmentControl({required this.value, required this.onChanged});

  final TextAlign value;
  final ValueChanged<TextAlign> onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.theme.colors.secondary,
      border: Border.all(color: context.theme.colors.border),
      borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusSm),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TextAlignmentButton(
          key: const ValueKey('text-align-left-control'),
          value: TextAlign.left,
          selected: value == TextAlign.left || value == TextAlign.start,
          icon: DesyIcons.alignLeft,
          label: 'Align left',
          onChanged: onChanged,
        ),
        _TextAlignmentButton(
          key: const ValueKey('text-align-center-control'),
          value: TextAlign.center,
          selected: value == TextAlign.center,
          icon: DesyIcons.alignCenter,
          label: 'Align center',
          onChanged: onChanged,
        ),
        _TextAlignmentButton(
          key: const ValueKey('text-align-right-control'),
          value: TextAlign.right,
          selected: value == TextAlign.right || value == TextAlign.end,
          icon: DesyIcons.alignRight,
          label: 'Align right',
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

class _TextAlignmentButton extends StatelessWidget {
  const _TextAlignmentButton({
    super.key,
    required this.value,
    required this.selected,
    required this.icon,
    required this.label,
    required this.onChanged,
  });

  final TextAlign value;
  final bool selected;
  final IconData icon;
  final String label;
  final ValueChanged<TextAlign> onChanged;

  @override
  Widget build(BuildContext context) => DesyButton.icon(
    size: DesyButtonSize.xs,
    variant: selected ? DesyButtonVariant.secondary : DesyButtonVariant.ghost,
    selected: selected,
    semanticsLabel: label,
    onPress: () => onChanged(value),
    child: Icon(icon, size: 14),
  );
}

class _PageSizePreset {
  const _PageSizePreset({
    required this.id,
    required this.name,
    required this.size,
  });

  final String id;
  final String name;
  final Size size;
}

class _PagePanel extends StatelessWidget {
  const _PagePanel({
    required this.canvas,
    required this.backgroundColor,
    required this.extension,
    required this.selectedTheme,
    required this.exporting,
    required this.status,
    required this.onExport,
    required this.onCanvasSizeChanged,
    required this.onThemeChanged,
    required this.onBackgroundChanged,
  });

  static const transparentId = '__transparent__';
  static const themeBackgroundId = '__theme_background__';
  static const customPresetId = '__custom__';
  static const presets = [
    _PageSizePreset(
      id: 'default-social',
      name: 'Default',
      size: Size(1200, 630),
    ),
    _PageSizePreset(id: 'iphone-17', name: 'iPhone 17', size: Size(402, 874)),
    _PageSizePreset(
      id: 'iphone-16-17-pro',
      name: 'iPhone 16 & 17 Pro',
      size: Size(402, 874),
    ),
    _PageSizePreset(id: 'iphone-16', name: 'iPhone 16', size: Size(393, 852)),
    _PageSizePreset(
      id: 'iphone-16-17-pro-max',
      name: 'iPhone 16 & 17 Pro Max',
      size: Size(440, 956),
    ),
    _PageSizePreset(
      id: 'iphone-16-plus',
      name: 'iPhone 16 Plus',
      size: Size(430, 932),
    ),
    _PageSizePreset(id: 'iphone-air', name: 'iPhone Air', size: Size(420, 912)),
    _PageSizePreset(
      id: 'iphone-14-15-pro-max',
      name: 'iPhone 14 & 15 Pro Max',
      size: Size(430, 932),
    ),
    _PageSizePreset(
      id: 'iphone-14-15-pro',
      name: 'iPhone 14 & 15 Pro',
      size: Size(393, 852),
    ),
    _PageSizePreset(
      id: 'iphone-13-14',
      name: 'iPhone 13 & 14',
      size: Size(390, 844),
    ),
    _PageSizePreset(
      id: 'iphone-14-plus',
      name: 'iPhone 14 Plus',
      size: Size(428, 926),
    ),
    _PageSizePreset(
      id: 'android-compact',
      name: 'Android Compact',
      size: Size(412, 917),
    ),
    _PageSizePreset(
      id: 'android-medium',
      name: 'Android Medium',
      size: Size(700, 840),
    ),
  ];

  final ObjectCanvasController<DesyScreenshotLayer> canvas;
  final Color? backgroundColor;
  final DesyWorkspaceExtensionContext extension;
  final DesyTheme selectedTheme;
  final bool exporting;
  final String? status;
  final VoidCallback onExport;
  final ValueChanged<Size> onCanvasSizeChanged;
  final void Function(String themeId, {Color? defaultBackground})
  onThemeChanged;
  final ValueChanged<Color?> onBackgroundChanged;

  String get _backgroundId {
    if (backgroundColor == null) return transparentId;
    for (final entry in extension.registry.allColors) {
      if (entry.color.toARGB32() == backgroundColor!.toARGB32()) {
        return entry.id;
      }
    }
    return themeBackgroundId;
  }

  String get _presetId {
    final width = canvas.canvasSize.width.round();
    final height = canvas.canvasSize.height.round();
    for (final preset in presets) {
      if (preset.size.width.round() == width &&
          preset.size.height.round() == height) {
        return preset.id;
      }
    }
    return customPresetId;
  }

  @override
  Widget build(BuildContext context) => ListView(
    key: const ValueKey('screenshot-page-panel'),
    padding: const EdgeInsets.all(16),
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              'PAGE',
              style: context.theme.typography.body.xs.copyWith(
                color: context.theme.colors.mutedForeground,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
          SizedBox(
            width: 190,
            child: DesySelect<String>.rich(
              key: const ValueKey('page-size-preset-control'),
              label: const Text('Preset'),
              control: DesySelectControl.lifted(
                value: _presetId,
                onChange: (id) {
                  if (id == null || id == customPresetId) return;
                  final preset = presets.firstWhere(
                    (preset) => preset.id == id,
                  );
                  onCanvasSizeChanged(preset.size);
                },
              ),
              format: (id) {
                if (id == customPresetId) return 'Custom';
                final preset = presets.firstWhere((preset) => preset.id == id);
                return preset.name;
              },
              children: [
                const DesySelectItem.item(
                  value: customPresetId,
                  title: Text('Custom'),
                ),
                for (final preset in presets)
                  DesySelectItem.item(
                    value: preset.id,
                    title: Text(preset.name),
                    subtitle: Text(
                      '${preset.size.width.round()} × ${preset.size.height.round()}',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _DimensionField(
              key: const ValueKey('page-width-control'),
              label: 'Width',
              value: canvas.canvasSize.width.round(),
              onChanged: (value) => onCanvasSizeChanged(
                Size(value.toDouble(), canvas.canvasSize.height),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _DimensionField(
              key: const ValueKey('page-height-control'),
              label: 'Height',
              value: canvas.canvasSize.height.round(),
              onChanged: (value) => onCanvasSizeChanged(
                Size(canvas.canvasSize.width, value.toDouble()),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      DesySelect<String>.rich(
        key: const ValueKey('page-theme-control'),
        label: const Text('Consumer theme'),
        control: DesySelectControl.lifted(
          value: selectedTheme.id,
          onChange: (id) {
            if (id == null) return;
            final theme = extension.registry.themes.firstWhere(
              (theme) => theme.id == id,
            );
            onThemeChanged(id, defaultBackground: theme.previewBackgroundColor);
          },
        ),
        format: (id) => extension.registry.themes
            .firstWhere((theme) => theme.id == id)
            .name,
        children: [
          for (final theme in extension.registry.themes)
            DesySelectItem.item(value: theme.id, title: Text(theme.name)),
        ],
      ),
      const SizedBox(height: 12),
      DesySelect<String>.rich(
        key: const ValueKey('page-background-control'),
        label: const Text('Background'),
        control: DesySelectControl.lifted(
          value: _backgroundId,
          onChange: (id) {
            if (id == null) return;
            if (id == transparentId) {
              onBackgroundChanged(null);
              return;
            }
            if (id == themeBackgroundId) {
              onBackgroundChanged(selectedTheme.previewBackgroundColor);
              return;
            }
            onBackgroundChanged(
              extension.registry.allColors
                  .firstWhere((entry) => entry.id == id)
                  .color,
            );
          },
        ),
        format: (id) => switch (id) {
          transparentId => 'Transparent',
          themeBackgroundId => 'Theme background',
          _ =>
            extension.registry.allColors
                .firstWhere((entry) => entry.id == id)
                .name,
        },
        children: [
          const DesySelectItem.item(
            value: transparentId,
            title: Text('Transparent'),
          ),
          const DesySelectItem.item(
            value: themeBackgroundId,
            title: Text('Theme background'),
          ),
          for (final entry in extension.registry.allColors)
            DesySelectItem.item(
              value: entry.id,
              title: Text(entry.name),
              prefix: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: entry.color,
                  border: Border.all(color: context.theme.colors.border),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 24),
      DesyButton(
        key: const ValueKey('export-screenshot'),
        size: DesyButtonSize.md,
        prefix: const Icon(DesyIcons.camera, size: 16),
        onPress: exporting ? null : onExport,
        child: Text(exporting ? 'Exporting…' : 'Export PNG'),
      ),
      if (status != null) ...[
        const SizedBox(height: 10),
        Semantics(
          liveRegion: true,
          child: Text(
            status!,
            style: context.theme.typography.body.sm.copyWith(
              color: context.theme.colors.mutedForeground,
              height: 1.4,
            ),
          ),
        ),
      ],
      const SizedBox(height: 18),
      Text(
        'Exports exactly ${canvas.canvasSize.width.round()} × ${canvas.canvasSize.height.round()} pixels. Scene state is discarded when this workbench session ends.',
        style: context.theme.typography.body.sm.copyWith(
          color: context.theme.colors.mutedForeground,
          height: 1.4,
        ),
      ),
    ],
  );
}

class _DimensionField extends StatelessWidget {
  const _DimensionField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: context.theme.typography.body.sm),
      const SizedBox(height: 6),
      DesyTextField(
        label: '$label in pixels',
        value: '$value',
        keyboardType: TextInputType.number,
        onChanged: (input) {
          final parsed = int.tryParse(input.trim());
          if (parsed != null &&
              parsed >= _ScreenshotBuilderScreenState._minimumCanvasExtent &&
              parsed <= _ScreenshotBuilderScreenState._maximumCanvasExtent) {
            onChanged(parsed);
          }
        },
      ),
    ],
  );
}

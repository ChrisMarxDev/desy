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
  final VoidCallback onExport;
  final ValueChanged<Size> onCanvasSizeChanged;
  final void Function(String themeId, {Color? defaultBackground})
  onThemeChanged;
  final ValueChanged<Color?> onBackgroundChanged;
  final ValueChanged<String> onToggleHidden;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return DecoratedBox(
      key: const ValueKey('screenshot-sidebar'),
      decoration: BoxDecoration(
        color: colors.desy.panel,
        border: Border(bottom: BorderSide(color: colors.desy.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.desy.divider)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
              child: Row(
                children: [
                  if (onExit != null) ...[
                    DesyButton.icon(
                      key: const ValueKey('screenshot-builder-exit'),
                      size: DesyButtonSize.xs,
                      variant: DesyButtonVariant.ghost,
                      semanticsLabel: 'Back to workspace',
                      onPress: onExit,
                      child: const Icon(DesyIcons.arrowLeft, size: 14),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      'Screenshot builder',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.theme.typography.body.sm.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  DesyBadge(
                    variant: DesyBadgeVariant.secondary,
                    child: Text(
                      'Experimental',
                      style: context.theme.typography.body.xs,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: DesyTabs(
              expands: true,
              children: [
                DesyTabEntry(
                  label: const Text('Layers', key: ValueKey('scene-tab')),
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
}

class _ScreenshotActionBar extends StatelessWidget {
  const _ScreenshotActionBar({
    required this.extension,
    required this.onAdd,
    required this.onPickImage,
  });

  final DesyWorkspaceExtensionContext extension;
  final ValueChanged<_PalettePayload> onAdd;
  final VoidCallback onPickImage;

  Future<void> _openCatalog(BuildContext context) async {
    final payload = await showDesyDialog<_PalettePayload>(
      context: context,
      builder: (context, animation) =>
          _ComponentCatalogDialog(animation: animation, extension: extension),
    );
    if (payload != null) onAdd(payload);
  }

  @override
  Widget build(BuildContext context) => DesyActionDock(
    key: const ValueKey('screenshot-action-bar'),
    groups: [
      DesyActionDockGroup(
        label: 'Add elements',
        actions: [
          DesyActionDockAction(
            key: const ValueKey('add-text-element'),
            icon: DesyIcons.type,
            label: 'Text',
            description: 'Add a text layer',
            onPressed: () => onAdd(const _TextPalettePayload()),
          ),
          DesyActionDockAction(
            key: const ValueKey('open-screenshot-catalog'),
            icon: DesyIcons.layoutGrid,
            label: 'Component',
            description: 'Open the component catalog',
            onPressed: () => unawaited(_openCatalog(context)),
          ),
          DesyActionDockAction(
            key: const ValueKey('add-image-element'),
            icon: DesyIcons.image,
            label: 'Image',
            description: 'Add an image layer',
            onPressed: onPickImage,
          ),
        ],
      ),
      DesyActionDockGroup(
        label: 'Mockups',
        actions: [
          DesyActionDockAction(
            key: const ValueKey('open-screenshot-mockups'),
            icon: DesyIcons.smartphone,
            label: 'Mockup',
            description: 'Add status bars and bezels',
            onPressed: () => unawaited(_openMockups(context)),
          ),
        ],
      ),
    ],
  );

  Future<void> _openMockups(BuildContext context) async {
    final payload = await showDesyDialog<_PalettePayload>(
      context: context,
      builder: (context, animation) => _MockupDialog(animation: animation),
    );
    if (payload != null) onAdd(payload);
  }
}

class _MockupDialog extends StatelessWidget {
  const _MockupDialog({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => DesyDialog(
    animation: animation,
    semanticsLabel: 'Choose mockup widget',
    constraints: const BoxConstraints(maxWidth: 360),
    builder: (context, style) => Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Mockups', style: style.titleTextStyle)),
              DesyButton.icon(
                size: DesyButtonSize.xs,
                variant: DesyButtonVariant.ghost,
                semanticsLabel: 'Close mockups',
                onPress: () => Navigator.of(context).pop(),
                child: const Icon(DesyIcons.x, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final kind in _MiscWidgetKind.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: DesyButton(
                key: ValueKey('add-misc-${kind.name}'),
                variant: DesyButtonVariant.outline,
                size: DesyButtonSize.sm,
                mainAxisAlignment: MainAxisAlignment.start,
                prefix: Icon(kind.icon, size: 14),
                onPress: () =>
                    Navigator.of(context).pop(_MiscPalettePayload(kind)),
                child: SizedBox(
                  width: 220,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(kind.label),
                      Text(
                        kind.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.theme.typography.body.xs.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _ComponentCatalogDialog extends StatefulWidget {
  const _ComponentCatalogDialog({
    required this.animation,
    required this.extension,
  });

  final Animation<double> animation;
  final DesyWorkspaceExtensionContext extension;

  @override
  State<_ComponentCatalogDialog> createState() =>
      _ComponentCatalogDialogState();
}

class _ComponentCatalogDialogState extends State<_ComponentCatalogDialog> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final normalized = _query.trim().toLowerCase();
    final components = widget.extension.registry.components
        .where((component) => _matches(component, normalized))
        .toList(growable: false);
    return DesyDialog(
      animation: widget.animation,
      semanticsLabel: 'Open catalog',
      constraints: const BoxConstraints(maxWidth: 960, maxHeight: 760),
      builder: (context, style) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HOME', style: context.theme.typography.body.xs),
                      const SizedBox(height: 4),
                      Text('All', style: style.titleTextStyle),
                    ],
                  ),
                ),
                DesyButton.icon(
                  key: const ValueKey('close-screenshot-catalog'),
                  size: DesyButtonSize.sm,
                  variant: DesyButtonVariant.ghost,
                  semanticsLabel: 'Close catalog',
                  onPress: () => Navigator.of(context).pop(),
                  child: const Icon(DesyIcons.x, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DesyTextField(
              key: const ValueKey('screenshot-catalog-search'),
              label: 'Search components',
              hintText: 'Search components',
              prefixIcon: const Icon(DesyIcons.search, size: 15),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 18),
            Text(
              'COMPONENTS',
              style: context.theme.typography.body.xs.copyWith(
                color: context.theme.colors.mutedForeground,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: components.isEmpty
                  ? Center(
                      child: Text(
                        'No matching components.',
                        style: style.bodyTextStyle.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      ),
                    )
                  : GridView.builder(
                      key: const ValueKey('screenshot-catalog-grid'),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 280,
                            mainAxisExtent: 236,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                          ),
                      itemCount: components.length,
                      itemBuilder: (context, index) => _CatalogComponentCard(
                        component: components[index],
                        extension: widget.extension,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool _matches(DesyRegistryComponent component, String normalized) {
    if (normalized.isEmpty) return true;
    final description = component.description ?? '';
    return component.name.toLowerCase().contains(normalized) ||
        component.id.toLowerCase().contains(normalized) ||
        component.path.toLowerCase().contains(normalized) ||
        component.category.toLowerCase().contains(normalized) ||
        description.toLowerCase().contains(normalized);
  }
}

class _CatalogComponentCard extends StatelessWidget {
  const _CatalogComponentCard({
    required this.component,
    required this.extension,
  });

  final DesyRegistryComponent component;
  final DesyWorkspaceExtensionContext extension;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    button: true,
    label: 'Add ${component.name}',
    child: GestureDetector(
      key: ValueKey('screenshot-catalog-component-${component.id}'),
      excludeFromSemantics: true,
      onTap: () =>
          Navigator.of(context).pop(_ComponentPalettePayload(component)),
      child: DesyCatalogueCard(
        identifier: component.id,
        preview: ClipRect(
          child: DesyWidgetPreview(
            theme: extension.activeTheme,
            builder: (previewContext) => ColoredBox(
              color:
                  extension.activeTheme.previewBackgroundColor ??
                  Theme.of(previewContext).scaffoldBackgroundColor,
              child: Center(
                child: DesyFittedPreview(
                  child: Builder(
                    builder: (context) => component.preview(
                      context,
                      extension.registry.widgetBuilder,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
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
    return Column(
      key: const ValueKey('screenshot-scene-panel'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
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
              Text(
                '${layers.length}',
                style: context.theme.typography.body.xs.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: topFirst.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'The scene is empty.',
                      style: context.theme.typography.body.xs.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                )
              : ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.only(bottom: 10),
                  itemCount: topFirst.length,
                  onReorderItem: (oldIndex, newIndex) =>
                      _reorderLayer(topFirst, oldIndex, newIndex),
                  itemBuilder: (context, index) {
                    final layer = topFirst[index];
                    return _LayerRow(
                      key: ValueKey('layer-row-${layer.id}'),
                      index: index,
                      layer: layer,
                      canvas: canvas,
                      onToggleHidden: onToggleHidden,
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _reorderLayer(
    List<DesyScreenshotLayer> topFirst,
    int oldIndex,
    int newIndex,
  ) {
    final next = [for (final layer in topFirst) layer.id];
    final moved = next.removeAt(oldIndex);
    next.insert(newIndex.clamp(0, next.length), moved);
    canvas.reorderObjects(next.reversed.toList(growable: false));
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
  });

  final ObjectCanvasController<DesyScreenshotLayer> canvas;
  final DesyScreenshotLayer? selectedLayer;
  final DesyWorkspaceExtensionContext extension;
  final void Function(String id, String knobId, Object value) onSetKnob;
  final void Function(String id, String value) onSetText;
  final void Function(String id, String? typographyId) onSetTextTypography;
  final void Function(String id, String? colorId) onSetTextColor;
  final void Function(String id, TextAlign textAlign) onSetTextAlign;

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
                  final _ScreenshotMiscLayer miscLayer => DesyKnobSheet(
                    segments: [
                      DesyKnobSegment(
                        title: 'MISC',
                        children: [
                          DesyTextValueKnobRow(
                            label: 'Widget',
                            value: miscLayer.kind.label,
                          ),
                          DesyTextValueKnobRow(
                            label: 'Size',
                            value:
                                '${canvas.geometryFor(miscLayer.id).paintBounds.width.round()} × '
                                '${canvas.geometryFor(miscLayer.id).paintBounds.height.round()}',
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
    super.key,
    required this.index,
    required this.layer,
    required this.canvas,
    required this.onToggleHidden,
  });

  final int index;
  final DesyScreenshotLayer layer;
  final ObjectCanvasController<DesyScreenshotLayer> canvas;
  final ValueChanged<String> onToggleHidden;

  @override
  Widget build(BuildContext context) {
    final selected = canvas.selectedObjectIds.contains(layer.id);
    final colors = context.theme.colors;
    final textColor = layer.hidden ? colors.mutedForeground : colors.foreground;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? colors.desy.signalSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusSm),
        ),
        child: Row(
          children: [
            Expanded(
              child: DesyButton(
                key: ValueKey('select-layer-${layer.id}'),
                selected: selected,
                variant: DesyButtonVariant.ghost,
                size: DesyButtonSize.xs,
                mainAxisAlignment: MainAxisAlignment.start,
                prefix: Icon(_iconFor(layer), size: 13, color: textColor),
                onPress: layer.hidden
                    ? null
                    : () => canvas.setSelectedObjects([layer.id]),
                child: Text(
                  layer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.typography.body.xs.copyWith(
                    color: textColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
            ReorderableDragStartListener(
              index: index,
              child: Icon(
                DesyIcons.chevronsUpDown,
                size: 13,
                color: colors.mutedForeground,
              ),
            ),
            const SizedBox(width: 2),
            DesyButton(
              key: ValueKey('toggle-layer-${layer.id}'),
              size: DesyButtonSize.xs,
              variant: DesyButtonVariant.ghost,
              mainAxisSize: MainAxisSize.min,
              semanticsLabel: layer.hidden
                  ? 'Show ${layer.name}'
                  : 'Hide ${layer.name}',
              onPress: () => onToggleHidden(layer.id),
              child: Text(
                layer.hidden ? 'Show' : 'Hide',
                style: context.theme.typography.body.xs.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ),
            DesyButton.icon(
              key: ValueKey('delete-layer-${layer.id}'),
              size: DesyButtonSize.xs,
              variant: DesyButtonVariant.ghost,
              semanticsLabel: 'Delete ${layer.name}',
              onPress: () => canvas.removeObjects([layer.id]),
              child: const Icon(DesyIcons.trash, size: 13),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(DesyScreenshotLayer layer) => switch (layer) {
    DesyScreenshotWidgetLayer() => DesyIcons.component,
    DesyScreenshotImageLayer() => DesyIcons.image,
    DesyScreenshotTextLayer() => DesyIcons.type,
    _ScreenshotMiscLayer(:final kind) => kind.icon,
    _ => DesyIcons.layers,
  };
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
    final component = registry.componentById(layer.componentId);
    if (component == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('The registered component is no longer available.'),
      );
    }
    final instanceId = layer.instanceId;
    final instance = instanceId == null
        ? null
        : registry.resolveComponentInstance(instanceId);
    return DesyKnobSheet(
      segments: [
        DesyKnobSegment(
          title: 'WIDGET',
          children: [
            DesyTextValueKnobRow(label: 'Component', value: component.name),
            if (instance != null)
              DesyTextValueKnobRow(label: 'Instance', value: instance.name),
          ],
        ),
        if (component.knobDefinitions.isNotEmpty)
          DesyKnobSegment(
            title: 'KNOBS',
            children: [
              for (final knob in component.knobDefinitions)
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
      id: 'instagram-square',
      name: 'Instagram',
      size: Size.square(500),
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

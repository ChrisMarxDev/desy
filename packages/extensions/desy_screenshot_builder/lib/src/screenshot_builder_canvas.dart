part of 'screenshot_builder_extension.dart';

class _CanvasViewport extends StatelessWidget {
  const _CanvasViewport({
    required this.scene,
    required this.extension,
    required this.selectedTheme,
    required this.boundaryKey,
    required this.stageKey,
    required this.transform,
    required this.dropActive,
    required this.onViewportSize,
    required this.onAcceptPalette,
    required this.onFit,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  static const stageMargin = 320.0;

  final DesyScreenshotSceneController scene;
  final DesyWorkspaceExtensionContext extension;
  final DesyTheme selectedTheme;
  final GlobalKey boundaryKey;
  final GlobalKey stageKey;
  final TransformationController transform;
  final bool dropActive;
  final ValueChanged<Size> onViewportSize;
  final void Function(_PalettePayload payload, Offset position) onAcceptPalette;
  final VoidCallback onFit;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
      onViewportSize(viewportSize);
      return Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: transform,
              constrained: false,
              minScale: .1,
              maxScale: 4,
              boundaryMargin: const EdgeInsets.all(2400),
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: scene.canvasSize.width + stageMargin * 2,
                height: scene.canvasSize.height + stageMargin * 2,
                child: Stack(
                  children: [
                    Positioned(
                      left: stageMargin,
                      top: stageMargin,
                      child: _ScreenshotStage(
                        scene: scene,
                        extension: extension,
                        selectedTheme: selectedTheme,
                        boundaryKey: boundaryKey,
                        stageKey: stageKey,
                        onAcceptPalette: onAcceptPalette,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: _CanvasToolbar(
              scene: scene,
              transform: transform,
              onFit: onFit,
              onZoomIn: onZoomIn,
              onZoomOut: onZoomOut,
            ),
          ),
          if (dropActive)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.theme.colors.desy.signalSurface.withValues(
                      alpha: .78,
                    ),
                    border: Border.all(
                      color: context.theme.colors.desy.signal,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: DesyBadge(
                      variant: DesyBadgeVariant.secondary,
                      child: const Text('DROP IMAGES ON THE CANVAS'),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _CanvasToolbar extends StatefulWidget {
  const _CanvasToolbar({
    required this.scene,
    required this.transform,
    required this.onFit,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final DesyScreenshotSceneController scene;
  final TransformationController transform;
  final VoidCallback onFit;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  State<_CanvasToolbar> createState() => _CanvasToolbarState();
}

class _CanvasToolbarState extends State<_CanvasToolbar> {
  @override
  void initState() {
    super.initState();
    widget.transform.addListener(_changed);
  }

  @override
  void didUpdateWidget(covariant _CanvasToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transform == widget.transform) return;
    oldWidget.transform.removeListener(_changed);
    widget.transform.addListener(_changed);
  }

  @override
  void dispose() {
    widget.transform.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final zoom = (widget.transform.value.getMaxScaleOnAxis() * 100).round();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.theme.colors.desy.panel,
        border: Border.all(color: context.theme.colors.desy.divider),
        borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DesyButton.icon(
              size: DesyButtonSize.xs,
              variant: DesyButtonVariant.ghost,
              semanticsLabel: 'Zoom out',
              onPress: widget.onZoomOut,
              child: const Icon(DesyIcons.minus, size: 14),
            ),
            SizedBox(
              width: 52,
              child: Text('$zoom%', textAlign: TextAlign.center),
            ),
            DesyButton.icon(
              size: DesyButtonSize.xs,
              variant: DesyButtonVariant.ghost,
              semanticsLabel: 'Zoom in',
              onPress: widget.onZoomIn,
              child: const Icon(DesyIcons.plus, size: 14),
            ),
            const SizedBox(width: 4),
            DesyButton(
              size: DesyButtonSize.xs,
              variant: DesyButtonVariant.ghost,
              mainAxisSize: MainAxisSize.min,
              onPress: widget.onFit,
              child: const Text('Fit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScreenshotStage extends StatelessWidget {
  const _ScreenshotStage({
    required this.scene,
    required this.extension,
    required this.selectedTheme,
    required this.boundaryKey,
    required this.stageKey,
    required this.onAcceptPalette,
  });

  final DesyScreenshotSceneController scene;
  final DesyWorkspaceExtensionContext extension;
  final DesyTheme selectedTheme;
  final GlobalKey boundaryKey;
  final GlobalKey stageKey;
  final void Function(_PalettePayload payload, Offset position) onAcceptPalette;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
    key: stageKey,
    size: scene.canvasSize,
    child: DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
        border: Border.all(color: context.theme.colors.desy.divider),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (scene.backgroundColor == null)
            const Positioned.fill(child: _TransparentGrid()),
          RepaintBoundary(
            key: boundaryKey,
            child: SizedBox.fromSize(
              size: scene.canvasSize,
              child: selectedTheme.wrap(
                context,
                Builder(
                  builder: (previewContext) => ColoredBox(
                    color: scene.backgroundColor ?? Colors.transparent,
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        for (final layer in scene.layers)
                          if (!layer.hidden)
                            _ScreenshotLayerContent(
                              key: ValueKey('screenshot-content-${layer.id}'),
                              layer: layer,
                              registry: extension.registry,
                              scene: scene,
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DragTarget<_PalettePayload>(
              onAcceptWithDetails: (details) {
                final box = stageKey.currentContext?.findRenderObject();
                final local = box is RenderBox
                    ? box.globalToLocal(details.offset)
                    : scene.canvasSize.center(Offset.zero);
                onAcceptPalette(details.data, local);
              },
              builder: (context, candidates, rejected) => GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => scene.select(null),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final layer in scene.layers)
                      if (!layer.hidden)
                        _LayerSelectionFrame(
                          key: ValueKey('screenshot-selection-${layer.id}'),
                          layer: layer,
                          scene: scene,
                          stageKey: stageKey,
                        ),
                    if (candidates.isNotEmpty)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: context.theme.colors.desy.signalSurface
                                  .withValues(alpha: .42),
                              border: Border.all(
                                color: context.theme.colors.desy.signal,
                                width: 2,
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
        ],
      ),
    ),
  );
}

class _ScreenshotLayerContent extends StatelessWidget {
  const _ScreenshotLayerContent({
    super.key,
    required this.layer,
    required this.registry,
    required this.scene,
  });

  final DesyScreenshotLayer layer;
  final DesyRegistry registry;
  final DesyScreenshotSceneController scene;

  @override
  Widget build(BuildContext context) => Positioned.fromRect(
    rect: layer.rect,
    child: IgnorePointer(child: _buildLayer(context)),
  );

  Widget _buildLayer(BuildContext context) => switch (layer) {
    final DesyScreenshotWidgetLayer widgetLayer => _buildWidget(
      context,
      widgetLayer,
    ),
    final DesyScreenshotImageLayer imageLayer => Image.memory(
      imageLayer.bytes,
      fit: BoxFit.fill,
      gaplessPlayback: true,
      semanticLabel: imageLayer.name,
    ),
    final DesyScreenshotTextLayer textLayer => _buildText(context, textLayer),
    _ => const SizedBox.shrink(),
  };

  Widget _buildWidget(
    BuildContext context,
    DesyScreenshotWidgetLayer widgetLayer,
  ) {
    final instance = registry.resolveComponentInstance(widgetLayer.instanceId);
    if (instance == null) {
      return Center(child: Text('Missing ${widgetLayer.instanceId}'));
    }
    Widget buildRealWidget() => Builder(
      builder: (context) => instance.component.buildWithValues(
        context,
        widgetLayer.knobValues,
        widgets: registry.widgetBuilder,
      ),
    );
    if (widgetLayer.awaitingNaturalSize) {
      return OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: 0,
        minHeight: 0,
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: _MeasureSize(
          onChange: (size) => scene.setNaturalWidgetSize(widgetLayer.id, size),
          child: buildRealWidget(),
        ),
      );
    }
    final logicalSize = widgetLayer.logicalSize;
    return OverflowBox(
      alignment: Alignment.topLeft,
      minWidth: logicalSize.width,
      minHeight: logicalSize.height,
      maxWidth: logicalSize.width,
      maxHeight: logicalSize.height,
      child: Transform.scale(
        alignment: Alignment.topLeft,
        scale: widgetLayer.scale,
        child: SizedBox.fromSize(size: logicalSize, child: buildRealWidget()),
      ),
    );
  }

  Widget _buildText(BuildContext context, DesyScreenshotTextLayer textLayer) {
    DesyTypographyEntry? typography;
    for (final entry in registry.allFonts) {
      if (entry.id == textLayer.typographyId) typography = entry;
    }
    DesyColorEntry? color;
    for (final entry in registry.allColors) {
      if (entry.id == textLayer.colorId) color = entry;
    }
    final text =
        typography?.builder(context, textLayer.text) ??
        Text(textLayer.text, style: Theme.of(context).textTheme.bodyMedium);
    return Align(
      alignment: Alignment.topLeft,
      child: ClipRect(
        child: color == null
            ? text
            : ColorFiltered(
                colorFilter: ColorFilter.mode(color.color, BlendMode.srcIn),
                child: text,
              ),
      ),
    );
  }
}

class _LayerSelectionFrame extends StatefulWidget {
  const _LayerSelectionFrame({
    super.key,
    required this.layer,
    required this.scene,
    required this.stageKey,
  });

  final DesyScreenshotLayer layer;
  final DesyScreenshotSceneController scene;
  final GlobalKey stageKey;

  @override
  State<_LayerSelectionFrame> createState() => _LayerSelectionFrameState();
}

class _LayerSelectionFrameState extends State<_LayerSelectionFrame> {
  Offset? _dragAnchor;

  Offset? _stageLocal(Offset global) {
    final box = widget.stageKey.currentContext?.findRenderObject();
    return box is RenderBox ? box.globalToLocal(global) : null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.scene.selectedId == widget.layer.id;
    final signal = context.theme.colors.desy.signal;
    return Positioned.fromRect(
      rect: widget.layer.rect,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => widget.scene.select(widget.layer.id),
        onPanStart: (details) {
          widget.scene.select(widget.layer.id);
          final local = _stageLocal(details.globalPosition);
          if (local != null) _dragAnchor = local - widget.layer.rect.topLeft;
        },
        onPanUpdate: (details) {
          final local = _stageLocal(details.globalPosition);
          final anchor = _dragAnchor;
          if (local != null && anchor != null) {
            widget.scene.move(widget.layer.id, local - anchor);
          }
        },
        onPanEnd: (_) => _dragAnchor = null,
        onPanCancel: () => _dragAnchor = null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? signal : Colors.transparent,
              width: selected ? 2 : 1,
            ),
          ),
          child: selected
              ? Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: -2,
                      top: -24,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: signal,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            child: Text(
                              widget.layer.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -9,
                      bottom: -9,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeDownRight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanUpdate: (details) {
                            final local = _stageLocal(details.globalPosition);
                            if (local != null) {
                              widget.scene.resize(
                                widget.layer.id,
                                Size(
                                  local.dx - widget.layer.rect.left,
                                  local.dy - widget.layer.rect.top,
                                ),
                              );
                            }
                          },
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: signal,
                              border: Border.all(color: Colors.white, width: 2),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }
}

class _TransparentGrid extends StatelessWidget {
  const _TransparentGrid();

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _TransparentGridPainter(
      light: context.theme.colors.desy.panel,
      dark: context.theme.colors.desy.panelSubtle,
    ),
  );
}

class _TransparentGridPainter extends CustomPainter {
  const _TransparentGridPainter({required this.light, required this.dark});

  final Color light;
  final Color dark;

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 12.0;
    final paint = Paint();
    for (var y = 0.0; y < size.height; y += cell) {
      for (var x = 0.0; x < size.width; x += cell) {
        paint.color = ((x / cell).floor() + (y / cell).floor()).isEven
            ? light
            : dark;
        canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TransparentGridPainter oldDelegate) =>
      oldDelegate.light != light || oldDelegate.dark != dark;
}

class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, required super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasureSize(onChange);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderMeasureSize renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onChange);

  ValueChanged<Size> onChange;
  Size? _reported;

  @override
  void performLayout() {
    super.performLayout();
    if (_reported == size) return;
    _reported = size;
    WidgetsBinding.instance.addPostFrameCallback((_) => onChange(size));
  }
}

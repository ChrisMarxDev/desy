part of 'screenshot_builder_extension.dart';

class _CanvasViewport extends StatelessWidget {
  const _CanvasViewport({
    super.key,
    required this.scene,
    required this.extension,
    required this.selectedTheme,
    required this.dropActive,
    required this.onViewportSize,
    required this.onAcceptPalette,
    required this.onFit,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final DesyScreenshotSceneController scene;
  final DesyWorkspaceExtensionContext extension;
  final DesyTheme selectedTheme;
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
            child: Builder(
              builder: (viewportContext) => DragTarget<_PalettePayload>(
                onAcceptWithDetails: (details) {
                  final box = viewportContext.findRenderObject();
                  final viewportPosition = box is RenderBox
                      ? box.globalToLocal(details.offset)
                      : viewportSize.center(Offset.zero);
                  onAcceptPalette(
                    details.data,
                    scene.canvas.viewportController.toScene(viewportPosition),
                  );
                },
                builder: (context, candidates, rejected) => Stack(
                  children: [
                    Positioned.fill(
                      child: selectedTheme.wrap(
                        context,
                        ObjectCanvas<DesyScreenshotLayer>(
                          key: const ValueKey('screenshot-object-canvas'),
                          controller: scene.canvas,
                          minScale: .1,
                          maxScale: 4,
                          viewportBoundaryMargin: const EdgeInsets.all(2400),
                          style: ObjectCanvasStyle(
                            viewportColor: context.theme.colors.desy.canvas,
                            canvasColor:
                                scene.backgroundColor ?? Colors.transparent,
                            selectionColor: context.theme.colors.desy.signal,
                            guideColor: context.theme.colors.desy.signal,
                            marqueeFillColor: context
                                .theme
                                .colors
                                .desy
                                .signalSurface
                                .withValues(alpha: .24),
                            marqueeStrokeColor:
                                context.theme.colors.desy.signal,
                          ),
                          underlayBuilder: scene.backgroundColor == null
                              ? (context, controller) =>
                                    const _TransparentGrid()
                              : null,
                          overlayBuilder: (context, controller) =>
                              IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: context.theme.colors.desy.divider,
                                    ),
                                  ),
                                ),
                              ),
                          objectVisibility: (object) => !object.data.hidden,
                          semanticLabelBuilder: (object) => object.data.name,
                          objectBuilder: (context, object) => IgnorePointer(
                            child: _ScreenshotLayerContent(
                              object: object,
                              registry: extension.registry,
                              scene: scene,
                            ),
                          ),
                        ),
                      ),
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
          Positioned(
            top: 16,
            right: 16,
            child: _CanvasToolbar(
              transform: scene.canvas.viewportController,
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
    required this.transform,
    required this.onFit,
    required this.onZoomIn,
    required this.onZoomOut,
  });

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

class _ScreenshotLayerContent extends StatelessWidget {
  const _ScreenshotLayerContent({
    required this.object,
    required this.registry,
    required this.scene,
  });

  final CanvasObject<DesyScreenshotLayer> object;
  final DesyRegistry registry;
  final DesyScreenshotSceneController scene;

  DesyScreenshotLayer get layer => object.data;

  @override
  Widget build(BuildContext context) => switch (layer) {
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
    return SizedBox.fromSize(
      size: object.geometry.size,
      child: buildRealWidget(),
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

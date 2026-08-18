part of 'screenshot_builder_extension.dart';

class _CanvasViewport extends StatelessWidget {
  const _CanvasViewport({
    super.key,
    required this.canvas,
    required this.backgroundColor,
    required this.extension,
    required this.selectedTheme,
    required this.dropActive,
    required this.zoom,
    required this.onZoomOut,
    required this.onZoomIn,
    required this.onAcceptPalette,
  });

  final ObjectCanvasController<DesyScreenshotLayer> canvas;
  final Color? backgroundColor;
  final DesyWorkspaceExtensionContext extension;
  final DesyTheme selectedTheme;
  final bool dropActive;
  final double zoom;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;
  final void Function(_PalettePayload payload, Offset position) onAcceptPalette;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
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
                    canvas.viewportController.toScene(viewportPosition),
                  );
                },
                builder: (context, candidates, rejected) => Stack(
                  children: [
                    Positioned.fill(
                      child: ObjectCanvas<DesyScreenshotLayer>(
                        key: const ValueKey('screenshot-object-canvas'),
                        controller: canvas,
                        minScale:
                            _ScreenshotBuilderScreenState._minimumViewportZoom,
                        maxScale:
                            _ScreenshotBuilderScreenState._maximumViewportZoom,
                        viewportBoundaryMargin: const EdgeInsets.all(2400),
                        marqueeSelectionEnabled: false,
                        style: ObjectCanvasStyle(
                          viewportColor: context.theme.colors.desy.canvas,
                          canvasColor: backgroundColor ?? Colors.transparent,
                          selectionColor: context.theme.colors.desy.signal,
                          guideColor: context.theme.colors.desy.signal,
                          marqueeFillColor: context
                              .theme
                              .colors
                              .desy
                              .signalSurface
                              .withValues(alpha: .24),
                          marqueeStrokeColor: context.theme.colors.desy.signal,
                        ),
                        underlayBuilder: backgroundColor == null
                            ? (context, controller) => const _TransparentGrid()
                            : null,
                        overlayBuilder: (context, controller) => IgnorePointer(
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
                            selectedTheme: selectedTheme,
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
            right: 16,
            bottom: 16,
            child: DesyZoomDock(
              keyPrefix: 'screenshot-canvas',
              zoom: zoom,
              onZoomOut: onZoomOut,
              onZoomIn: onZoomIn,
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

class _ScreenshotLayerContent extends StatelessWidget {
  const _ScreenshotLayerContent({
    required this.object,
    required this.registry,
    required this.selectedTheme,
  });

  final CanvasObject<DesyScreenshotLayer> object;
  final DesyRegistry registry;
  final DesyTheme selectedTheme;

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
    return selectedTheme.wrap(
      context,
      Builder(
        builder: (context) => instance.component.buildWithValues(
          context,
          widgetLayer.knobValues,
          widgets: registry.widgetBuilder,
        ),
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
    final text = selectedTheme.wrap(
      context,
      DefaultTextStyle.merge(
        textAlign: textLayer.textAlign,
        child: Builder(
          builder: (context) =>
              typography?.builder(context, textLayer.text) ??
              Text(
                textLayer.text,
                textAlign: textLayer.textAlign,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
        ),
      ),
    );
    final colored = color == null
        ? text
        : ColorFiltered(
            colorFilter: ColorFilter.mode(color.color, BlendMode.srcIn),
            child: text,
          );
    return LayoutBuilder(
      builder: (context, constraints) => ClipRect(
        child: Align(
          alignment: _textBoxAlignment(textLayer.textAlign),
          child: SizedBox(width: constraints.maxWidth, child: colored),
        ),
      ),
    );
  }

  Alignment _textBoxAlignment(TextAlign textAlign) => switch (textAlign) {
    TextAlign.center => Alignment.topCenter,
    TextAlign.right || TextAlign.end => Alignment.topRight,
    TextAlign.left || TextAlign.start || TextAlign.justify => Alignment.topLeft,
  };
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

import 'package:desy_core/desy_core.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

/// Renders one GenUI surface inside exactly one real consumer theme wrapper.
class DesyGenUiSurface extends StatelessWidget {
  /// Creates a themed surface backed by [controller].
  const DesyGenUiSurface({
    super.key,
    required this.controller,
    required this.surfaceId,
    required this.theme,
    this.defaultBuilder,
  });

  /// Controller that owns the live A2UI surface.
  final SurfaceController controller;

  /// ID of the surface to render.
  final String surfaceId;

  /// Consumer theme applied once around the whole generated tree.
  final DesyTheme theme;

  /// Optional placeholder shown before a definition is available.
  final WidgetBuilder? defaultBuilder;

  @override
  Widget build(BuildContext context) => theme.wrap(
    context,
    Surface(
      surfaceContext: controller.contextFor(surfaceId),
      defaultBuilder: defaultBuilder,
    ),
  );
}

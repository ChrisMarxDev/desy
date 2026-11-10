import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:desy_core/desy_core.dart';
import 'package:flutter/material.dart';

/// Renders one A2UI surface inside exactly one real consumer theme wrapper.
class DesyGenUiSurface extends StatefulWidget {
  /// Creates a themed surface backed by [controller].
  const DesyGenUiSurface({
    super.key,
    required this.controller,
    required this.surfaceId,
    required this.theme,
    this.defaultBuilder,
  });

  /// Processor that owns the live A2UI surface.
  final MessageProcessor<ComponentImplementation> controller;

  /// ID of the surface to render.
  final String surfaceId;

  /// Consumer theme applied once around the whole generated tree.
  final DesyTheme theme;

  /// Optional placeholder shown before the surface is created.
  final WidgetBuilder? defaultBuilder;

  @override
  State<DesyGenUiSurface> createState() => _DesyGenUiSurfaceState();
}

class _DesyGenUiSurfaceState extends State<DesyGenUiSurface> {
  SurfaceModel<ComponentImplementation>? _surface;
  final _subscriptions = <Subscription>[];

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(DesyGenUiSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.surfaceId != widget.surfaceId) {
      _unsubscribe();
      _subscribe();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  // The processor creates a surface only when `createSurface` arrives, so
  // follow its creation and deletion to swap the placeholder and the surface.
  void _subscribe() {
    final model = widget.controller.model;
    _surface = model.getSurface(widget.surfaceId);
    _subscriptions
      ..add(
        model.onSurfaceCreated.subscribe((surface) {
          if (surface.id == widget.surfaceId) {
            setState(() => _surface = surface);
          }
        }),
      )
      ..add(
        model.onSurfaceDeleted.subscribe((id) {
          if (id == widget.surfaceId) setState(() => _surface = null);
        }),
      );
  }

  void _unsubscribe() {
    for (final subscription in _subscriptions) {
      subscription.unsubscribe();
    }
    _subscriptions.clear();
  }

  @override
  Widget build(BuildContext context) {
    final surface = _surface;
    return widget.theme.wrap(
      context,
      surface == null
          ? Builder(
              builder: (context) =>
                  widget.defaultBuilder?.call(context) ??
                  const SizedBox.shrink(),
            )
          : A2uiSurface(key: ObjectKey(surface), surface: surface),
    );
  }
}

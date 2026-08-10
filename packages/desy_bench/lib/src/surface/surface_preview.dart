import 'package:flutter/widgets.dart';

import '../registry.dart';
import 'surface_dsl.dart';

/// Renders a validated local Desy DSL prototype with real registry components.
///
/// This widget is intentionally a preview boundary, not an SDUI runtime. The
/// supplied [surface] is local typed data, while the consumer registry remains
/// the only source of component builders, knob contracts, and theme context.
class DesySurfacePreview extends StatelessWidget {
  /// Creates a registry-backed surface preview.
  const DesySurfacePreview({
    super.key,
    required this.registry,
    required this.surface,
    this.theme,
  });

  /// Consumer registry used for every component and measurement lookup.
  final DesyRegistry registry;

  /// Parsed Desy DSL document.
  final DesySurfaceDocument surface;

  /// Consumer theme for the preview; the registry's first theme is the default.
  final DesyTheme? theme;

  @override
  Widget build(BuildContext context) {
    final issues = DesySurfaceValidator(registry).validate(surface);
    final errors = issues.where((issue) => issue.isError).toList();
    if (errors.isNotEmpty) {
      return ErrorWidget.withDetails(
        message: errors.join('\n'),
        error: FlutterError('Invalid Desy surface "${surface.id}".'),
      );
    }
    final activeTheme = theme ?? registry.themes.first;
    return activeTheme.wrap(
      context,
      Builder(
        builder: (previewContext) =>
            _DesySurfaceRenderer(registry).build(previewContext, surface.root),
      ),
    );
  }
}

final class _DesySurfaceRenderer {
  const _DesySurfaceRenderer(this.registry);

  final DesyRegistry registry;

  Widget build(BuildContext context, DesySurfaceNode node) => switch (node) {
    DesySurfaceComponent() => _component(context, node),
    DesySurfaceRow() => Row(
      mainAxisAlignment: node.mainAxisAlignment,
      crossAxisAlignment: node.crossAxisAlignment,
      mainAxisSize: node.mainAxisSize,
      children: _withGaps(context, node.children, node.gap, Axis.horizontal),
    ),
    DesySurfaceColumn() => Column(
      mainAxisAlignment: node.mainAxisAlignment,
      crossAxisAlignment: node.crossAxisAlignment,
      mainAxisSize: node.mainAxisSize,
      children: _withGaps(context, node.children, node.gap, Axis.vertical),
    ),
    DesySurfaceStack() => Stack(
      alignment: node.alignment,
      fit: node.fit,
      children: [for (final child in node.children) build(context, child)],
    ),
    DesySurfacePadding() => Padding(
      padding: _edgeInsets(node.padding),
      child: build(context, node.child),
    ),
    DesySurfaceScroll() => _DesySurfaceScrollView(
      axis: node.axis,
      scrollbar: node.scrollbar,
      child: build(context, node.child),
    ),
    DesySurfaceSpacer() => SizedBox(
      width: _length(node.width),
      height: _length(node.height),
    ),
  };

  Widget _component(BuildContext context, DesySurfaceComponent node) {
    final component = registry.allComponents.firstWhere(
      (candidate) => candidate.id == node.component,
    );
    if (node.instance case final String instance) {
      if (node.knobs.isEmpty) {
        return component.buildInstance(
          context,
          instance,
          registry.widgetBuilder,
        );
      }
      return component.buildWithValues(context, {
        ...component.valuesFor(instance),
        ...node.knobs,
      }, widgets: registry.widgetBuilder);
    }
    if (node.knobs.isEmpty) {
      return component.preview(context, registry.widgetBuilder);
    }
    return component.buildWithValues(
      context,
      node.knobs,
      widgets: registry.widgetBuilder,
    );
  }

  List<Widget> _withGaps(
    BuildContext context,
    List<DesySurfaceNode> nodes,
    DesySurfaceLength? gap,
    Axis axis,
  ) {
    if (nodes.isEmpty) return const [];
    final extent = _length(gap) ?? 0;
    return [
      for (final (index, node) in nodes.indexed) ...[
        if (index > 0)
          SizedBox(
            width: axis == Axis.horizontal ? extent : null,
            height: axis == Axis.vertical ? extent : null,
          ),
        build(context, node),
      ],
    ];
  }

  EdgeInsets _edgeInsets(DesySurfaceInsets insets) => EdgeInsets.fromLTRB(
    _length(insets.left) ?? 0,
    _length(insets.top) ?? 0,
    _length(insets.right) ?? 0,
    _length(insets.bottom) ?? 0,
  );

  double? _length(DesySurfaceLength? length) => switch (length) {
    null => null,
    DesySurfacePixels() => length.value,
    DesySurfaceMeasurement() =>
      registry.measurements
          .firstWhere((measurement) => measurement.id == length.id)
          .value,
  };
}

class _DesySurfaceScrollView extends StatefulWidget {
  const _DesySurfaceScrollView({
    required this.axis,
    required this.scrollbar,
    required this.child,
  });

  final Axis axis;
  final bool scrollbar;
  final Widget child;

  @override
  State<_DesySurfaceScrollView> createState() => _DesySurfaceScrollViewState();
}

class _DesySurfaceScrollViewState extends State<_DesySurfaceScrollView> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scrollView = SingleChildScrollView(
      key: ValueKey('surface-scroll-${widget.axis.name}'),
      controller: _controller,
      scrollDirection: widget.axis,
      child: widget.child,
    );
    if (!widget.scrollbar) return scrollView;
    return RawScrollbar(
      controller: _controller,
      thumbVisibility: true,
      child: scrollView,
    );
  }
}

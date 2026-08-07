// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart' show Theme;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../registry.dart';

/// Makes the currently selected design-system theme available to every
/// preview below the workbench shell.
///
/// The bench's own Forui chrome deliberately remains outside this scope. A
/// theme switch therefore rebuilds all consumer previews together without
/// letting a consumer's theme leak into navigation or workbench controls.
class DesyPreviewThemeScope extends InheritedWidget {
  const DesyPreviewThemeScope({
    required this.theme,
    required super.child,
    super.key,
  });

  final DesyTheme theme;

  static DesyTheme? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<DesyPreviewThemeScope>()
      ?.theme;

  @override
  bool updateShouldNotify(DesyPreviewThemeScope oldWidget) =>
      oldWidget.theme.id != theme.id;
}

/// Builds a registered preview below the selected application's theme wrapper.
///
/// The workbench itself intentionally stays outside this wrapper. This keeps
/// application theme context scoped to the actual widget being inspected.
class DesyWidgetPreview extends StatelessWidget {
  const DesyWidgetPreview({
    required this.theme,
    required this.builder,
    this.withThemeBackground = false,
    super.key,
  });

  final DesyTheme theme;
  final WidgetBuilder builder;

  /// Whether this bounded preview should include the consumer theme's scaffold
  /// background behind the natural-size widget.
  final bool withThemeBackground;

  @override
  Widget build(BuildContext context) {
    final activeTheme = DesyPreviewThemeScope.maybeOf(context) ?? theme;
    return activeTheme.wrap(
      context,
      Builder(
        builder: (previewContext) => withThemeBackground
            ? ColoredBox(
                color:
                    activeTheme.previewBackgroundColor ??
                    Theme.of(previewContext).scaffoldBackgroundColor,
                child: Align(child: builder(previewContext)),
              )
            : builder(previewContext),
      ),
    );
  }
}

/// Measures a consumer preview at a usable logical size, then scales that
/// completed result down to its Desy-owned display frame.
///
/// The finite loose pass preserves a widget's true preferred size up to the
/// cap, so intrinsic widgets (text, icons, padded composites) render at
/// faithful dimensions while greedy widgets settle within the cap instead of
/// overflowing. All catalogue surfaces (atlas, palette, sidebar) share this
/// measurement so thumbnails stay consistent. Interactive sketch nodes
/// deliberately do not use it: their resize rectangle supplies the real
/// logical constraints so responsive widget behavior stays inspectable.
class DesyFittedPreview extends StatelessWidget {
  const DesyFittedPreview({required this.child, super.key});

  final Widget child;

  static const _maximumLogicalSize = Size(1024, 768);

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: _LogicalPreviewMeasurement(
      maximumSize: _maximumLogicalSize,
      child: child,
    ),
  );
}

/// Gives a preview a finite, large measurement pass without taking up that
/// whole maximum size itself. This preserves [Align]'s natural-size behaviour
/// for ordinary components and gives responsive components meaningful bounds.
class _LogicalPreviewMeasurement extends SingleChildRenderObjectWidget {
  const _LogicalPreviewMeasurement({
    required this.maximumSize,
    required super.child,
  });

  final Size maximumSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderLogicalPreviewMeasurement(maximumSize);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderLogicalPreviewMeasurement renderObject,
  ) {
    renderObject.maximumSize = maximumSize;
  }
}

class _RenderLogicalPreviewMeasurement extends RenderProxyBox {
  _RenderLogicalPreviewMeasurement(this._maximumSize);

  Size _maximumSize;

  set maximumSize(Size value) {
    if (_maximumSize == value) return;
    _maximumSize = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.constrain(Size.zero);
      return;
    }
    // A finite, large measurement pass. Intrinsic widgets (text, icons, padded
    // composites) hold their true preferred size here; greedy widgets that
    // would fill unbounded space settle within the cap instead of overflowing.
    child.layout(BoxConstraints.loose(_maximumSize), parentUsesSize: true);
    size = constraints.constrain(child.size);
  }
}

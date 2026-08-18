import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import 'desy_design_system_scope.dart';
import 'desy_visual_tokens.dart';

/// A single interactive boundary between two resizable workbench regions.
///
/// The component owns the visible hairline and the larger pointer hit target,
/// so callers should not add a second divider beside it. A vertical divider
/// changes width; a horizontal divider changes height.
class DesyResizeDivider extends StatefulWidget {
  /// Creates an interactive resize divider.
  const DesyResizeDivider({
    super.key,
    required this.axis,
    required this.value,
    required this.semanticsLabel,
    required this.onResize,
    this.onResizeStart,
    this.onResizeEnd,
    this.keyboardStep = 24,
  }) : assert(keyboardStep > 0);

  /// The direction in which the divider line is painted.
  ///
  /// [Axis.vertical] resizes horizontally and [Axis.horizontal] resizes
  /// vertically.
  final Axis axis;

  /// The current size of the region controlled by this divider.
  final double value;

  /// The accessible name of the region being resized.
  final String semanticsLabel;

  /// Reports incremental drag and keyboard resize deltas.
  final ValueChanged<double> onResize;

  /// Called when a pointer resize begins.
  final VoidCallback? onResizeStart;

  /// Called when a pointer resize ends or is cancelled.
  final VoidCallback? onResizeEnd;

  /// The resize delta used by one keyboard or semantic increment.
  final double keyboardStep;

  @override
  State<DesyResizeDivider> createState() => _DesyResizeDividerState();
}

class _DesyResizeDividerState extends State<DesyResizeDivider> {
  final _focusNode = FocusNode(debugLabel: 'Desy resize divider');
  var _hovered = false;
  var _dragging = false;

  bool get _active => _hovered || _dragging || _focusNode.hasFocus;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _resize(double delta) => widget.onResize(delta);

  void _startDrag() {
    _focusNode.requestFocus();
    widget.onResizeStart?.call();
    setState(() => _dragging = true);
  }

  void _finishDrag() {
    widget.onResizeEnd?.call();
    setState(() => _dragging = false);
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final negativeKey = widget.axis == Axis.vertical
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowUp;
    final positiveKey = widget.axis == Axis.vertical
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowDown;
    if (event.logicalKey == negativeKey) {
      _resize(-widget.keyboardStep);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == positiveKey) {
      _resize(widget.keyboardStep);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final vertical = widget.axis == Axis.vertical;
    final hitSize = DesyDesignSystemTokens.resizeDividerHitSize;
    final lineColor = _active
        ? context.theme.colors.desy.signal
        : context.theme.colors.border;
    final line = SizedBox(
      width: vertical ? DesyDesignSystemTokens.hairline : double.infinity,
      height: vertical ? double.infinity : DesyDesignSystemTokens.hairline,
      child: ColoredBox(color: lineColor),
    );

    return Semantics(
      container: true,
      label: widget.semanticsLabel,
      value: '${widget.value.round()} pixels',
      increasedValue: '${(widget.value + widget.keyboardStep).round()} pixels',
      decreasedValue: '${(widget.value - widget.keyboardStep).round()} pixels',
      onIncrease: () => _resize(widget.keyboardStep),
      onDecrease: () => _resize(-widget.keyboardStep),
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: (_) => setState(() {}),
        onKeyEvent: (_, event) => _handleKeyEvent(event),
        child: MouseRegion(
          cursor: vertical
              ? SystemMouseCursors.resizeColumn
              : SystemMouseCursors.resizeRow,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: vertical ? (_) => _startDrag() : null,
            onHorizontalDragUpdate: vertical
                ? (details) => _resize(details.delta.dx)
                : null,
            onHorizontalDragEnd: vertical ? (_) => _finishDrag() : null,
            onHorizontalDragCancel: vertical ? _finishDrag : null,
            onVerticalDragStart: vertical ? null : (_) => _startDrag(),
            onVerticalDragUpdate: vertical
                ? null
                : (details) => _resize(details.delta.dy),
            onVerticalDragEnd: vertical ? null : (_) => _finishDrag(),
            onVerticalDragCancel: vertical ? null : _finishDrag,
            child: SizedBox(
              width: vertical ? hitSize : double.infinity,
              height: vertical ? double.infinity : hitSize,
              child: Center(child: line),
            ),
          ),
        ),
      ),
    );
  }
}

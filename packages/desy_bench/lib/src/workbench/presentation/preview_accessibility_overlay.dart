// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Paints accessibility review aids from the semantics of one preview root.
///
/// The child is given an explicit semantic boundary, so Desy shell controls
/// never become candidates for the labels or hit-target highlights.
class DesyPreviewAccessibilityOverlay extends StatefulWidget {
  const DesyPreviewAccessibilityOverlay({
    super.key,
    required this.child,
    required this.showLabels,
    required this.showHitTargets,
    required this.passingColor,
    required this.undersizedColor,
    required this.unlabeledColor,
    required this.labelColor,
    required this.labelBackgroundColor,
    this.minimumHitTargetSize = 44,
  });

  final Widget child;
  final bool showLabels;
  final bool showHitTargets;
  final Color passingColor;
  final Color undersizedColor;
  final Color unlabeledColor;
  final Color labelColor;
  final Color labelBackgroundColor;
  final double minimumHitTargetSize;

  @override
  State<DesyPreviewAccessibilityOverlay> createState() =>
      _DesyPreviewAccessibilityOverlayState();
}

class _DesyPreviewAccessibilityOverlayState
    extends State<DesyPreviewAccessibilityOverlay>
    with WidgetsBindingObserver {
  final _semanticBoundaryKey = GlobalKey();
  PipelineOwner? _pipelineOwner;
  SemanticsHandle? _semanticsHandle;
  List<_DesyPreviewSemanticsNode> _nodes = const [];
  bool _refreshScheduled = false;

  bool get _enabled => widget.showLabels || widget.showHitTargets;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_enabled) _enableSemantics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_enabled) _listenForSemanticsUpdates();
  }

  @override
  void didUpdateWidget(covariant DesyPreviewAccessibilityOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_enabled && !(oldWidget.showLabels || oldWidget.showHitTargets)) {
      _enableSemantics();
      _listenForSemanticsUpdates();
    } else if (!_enabled &&
        (oldWidget.showLabels || oldWidget.showHitTargets)) {
      _disableSemantics();
    }
  }

  @override
  void didChangeMetrics() => _scheduleRefresh();

  @override
  void dispose() {
    _pipelineOwner?.semanticsOwner?.removeListener(_scheduleRefresh);
    _semanticsHandle?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _enableSemantics() {
    _semanticsHandle ??= SemanticsBinding.instance.ensureSemantics();
    _scheduleRefresh();
  }

  void _disableSemantics() {
    _pipelineOwner?.semanticsOwner?.removeListener(_scheduleRefresh);
    _pipelineOwner = null;
    _semanticsHandle?.dispose();
    _semanticsHandle = null;
    if (_nodes.isNotEmpty) setState(() => _nodes = const []);
  }

  void _listenForSemanticsUpdates() {
    final owner = View.pipelineOwnerOf(context);
    if (owner == _pipelineOwner) return;
    _pipelineOwner?.semanticsOwner?.removeListener(_scheduleRefresh);
    owner.semanticsOwner?.addListener(_scheduleRefresh);
    _pipelineOwner = owner;
    _scheduleRefresh();
  }

  void _scheduleRefresh() {
    if (!_enabled || _refreshScheduled) return;
    _refreshScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _refreshScheduled = false;
      if (!mounted || !_enabled) return;
      final renderObject = _semanticBoundaryKey.currentContext
          ?.findRenderObject();
      final semantics = renderObject?.debugSemantics;
      final nodes = semantics == null
          ? const <_DesyPreviewSemanticsNode>[]
          : _collectNodes(semantics, widget.minimumHitTargetSize);
      if (!_sameNodes(_nodes, nodes)) setState(() => _nodes = nodes);
    }, debugLabel: 'DesyPreviewAccessibilityOverlay.refresh');
  }

  @override
  Widget build(BuildContext context) => Semantics(
    key: _semanticBoundaryKey,
    container: true,
    explicitChildNodes: true,
    child: CustomPaint(
      foregroundPainter: _enabled
          ? _DesyPreviewAccessibilityPainter(
              nodes: _nodes,
              showLabels: widget.showLabels,
              showHitTargets: widget.showHitTargets,
              passingColor: widget.passingColor,
              undersizedColor: widget.undersizedColor,
              unlabeledColor: widget.unlabeledColor,
              labelColor: widget.labelColor,
              labelBackgroundColor: widget.labelBackgroundColor,
            )
          : null,
      child: widget.child,
    ),
  );
}

List<_DesyPreviewSemanticsNode> _collectNodes(
  SemanticsNode root,
  double minimumHitTargetSize,
) {
  final nodes = <_DesyPreviewSemanticsNode>[];

  void visit(SemanticsNode node, Matrix4 transform) {
    final data = node.getSemanticsData();
    final label = _labelFor(data);
    final rect = MatrixUtils.transformRect(transform, node.rect);
    final actionable = _isActionable(data);
    if (label.isNotEmpty || actionable) {
      nodes.add(
        _DesyPreviewSemanticsNode(
          rect: rect,
          label: label,
          actionable: actionable,
          passesMinimumHitTarget:
              rect.width >= minimumHitTargetSize &&
              rect.height >= minimumHitTargetSize,
        ),
      );
    }
    node.visitChildren((child) {
      final childTransform = Matrix4.copy(transform);
      if (child.transform case final transform?) {
        childTransform.multiply(transform);
      }
      visit(child, childTransform);
      return true;
    });
  }

  visit(root, Matrix4.identity());
  return List.unmodifiable(nodes);
}

String _labelFor(SemanticsData data) {
  final label = data.label.trim();
  if (label.isNotEmpty) return label;
  return data.tooltip.trim();
}

bool _isActionable(SemanticsData data) =>
    data.hasAction(SemanticsAction.tap) ||
    data.hasAction(SemanticsAction.longPress) ||
    data.hasAction(SemanticsAction.increase) ||
    data.hasAction(SemanticsAction.decrease) ||
    data.hasAction(SemanticsAction.dismiss);

bool _sameNodes(
  List<_DesyPreviewSemanticsNode> current,
  List<_DesyPreviewSemanticsNode> next,
) {
  if (current.length != next.length) return false;
  for (var index = 0; index < current.length; index++) {
    if (current[index] != next[index]) return false;
  }
  return true;
}

class _DesyPreviewSemanticsNode {
  const _DesyPreviewSemanticsNode({
    required this.rect,
    required this.label,
    required this.actionable,
    required this.passesMinimumHitTarget,
  });

  final Rect rect;
  final String label;
  final bool actionable;
  final bool passesMinimumHitTarget;

  @override
  bool operator ==(Object other) =>
      other is _DesyPreviewSemanticsNode &&
      other.rect == rect &&
      other.label == label &&
      other.actionable == actionable &&
      other.passesMinimumHitTarget == passesMinimumHitTarget;

  @override
  int get hashCode =>
      Object.hash(rect, label, actionable, passesMinimumHitTarget);
}

class _DesyPreviewAccessibilityPainter extends CustomPainter {
  const _DesyPreviewAccessibilityPainter({
    required this.nodes,
    required this.showLabels,
    required this.showHitTargets,
    required this.passingColor,
    required this.undersizedColor,
    required this.unlabeledColor,
    required this.labelColor,
    required this.labelBackgroundColor,
  });

  final List<_DesyPreviewSemanticsNode> nodes;
  final bool showLabels;
  final bool showHitTargets;
  final Color passingColor;
  final Color undersizedColor;
  final Color unlabeledColor;
  final Color labelColor;
  final Color labelBackgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final node in nodes) {
      if (showHitTargets && node.actionable) _paintHitTarget(canvas, node);
      if (showLabels && node.label.isNotEmpty) _paintLabel(canvas, node, size);
    }
    canvas.restore();
  }

  void _paintHitTarget(Canvas canvas, _DesyPreviewSemanticsNode node) {
    final color = node.label.isEmpty
        ? unlabeledColor
        : node.passesMinimumHitTarget
        ? passingColor
        : undersizedColor;
    final rect = node.rect.deflate(.5);
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: .14),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color,
    );
    if (node.label.isEmpty) _paintLabel(canvas, node, rect.size);
  }

  void _paintLabel(
    Canvas canvas,
    _DesyPreviewSemanticsNode node,
    Size canvasSize,
  ) {
    final text = node.label.isEmpty ? 'Unlabelled control' : node.label;
    final maxWidth = (canvasSize.width - node.rect.left - 4).clamp(24, 240.0);
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: labelColor,
          fontSize: 10,
          height: 1.1,
          backgroundColor: labelBackgroundColor.withValues(alpha: .88),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth.toDouble());
    painter.paint(canvas, node.rect.topLeft + const Offset(2, 2));
  }

  @override
  bool shouldRepaint(covariant _DesyPreviewAccessibilityPainter oldDelegate) =>
      oldDelegate.nodes != nodes ||
      oldDelegate.showLabels != showLabels ||
      oldDelegate.showHitTargets != showHitTargets ||
      oldDelegate.passingColor != passingColor ||
      oldDelegate.undersizedColor != undersizedColor ||
      oldDelegate.unlabeledColor != unlabeledColor ||
      oldDelegate.labelColor != labelColor ||
      oldDelegate.labelBackgroundColor != labelBackgroundColor;
}

// Internal pure-geometry Sketch snapping engine.
// ignore_for_file: public_member_api_docs

import 'dart:math' as math;
import 'dart:ui';

import 'snap_models.dart';
import 'snap_session.dart';

class DesySnapEngine {
  const DesySnapEngine();

  DesySnapResult resolve(DesySnapSession session, DesySnapRequest request) {
    final x = _resolveAxis(session, request, DesySnapAxis.x);
    final y = _resolveAxis(session, request, DesySnapAxis.y);
    var usedX = x;
    var usedY = y;
    Rect corrected;
    final ratio = request.aspectRatio;
    if (request.operation == DesySnapOperation.resize &&
        ratio != null &&
        ratio.isFinite &&
        ratio > 0) {
      final direct = _applyCorrections(request, x, y);
      if (_ratioMatches(direct, ratio)) {
        corrected = direct;
      } else {
        final driver = _aspectDriver(x, y, request.edges);
        if (driver == DesySnapAxis.x) {
          usedY = const _AxisResolution.none();
          session.setLock(DesySnapAxis.y, null);
        } else {
          usedX = const _AxisResolution.none();
          session.setLock(DesySnapAxis.x, null);
        }
        corrected = _applyAspectCorrection(
          request,
          driver == DesySnapAxis.x ? usedX : usedY,
          driver,
          ratio,
        );
      }
    } else {
      corrected = _applyCorrections(request, usedX, usedY);
    }
    corrected = _constrain(corrected, request);

    final guides = <DesySnapGuide>[
      if (usedX.source == DesySnapSource.element &&
          _coordinateFor(
                corrected,
                DesySnapAxis.x,
                usedX.movingKind!,
              ).difference(usedX.targetCoordinate!).abs() <
              0.01)
        _guideFor(session, corrected, usedX, DesySnapAxis.x),
      if (usedY.source == DesySnapSource.element &&
          _coordinateFor(
                corrected,
                DesySnapAxis.y,
                usedY.movingKind!,
              ).difference(usedY.targetCoordinate!).abs() <
              0.01)
        _guideFor(session, corrected, usedY, DesySnapAxis.y),
    ];
    return DesySnapResult(
      rect: corrected,
      guides: List.unmodifiable(guides),
      xSource: usedX.source,
      ySource: usedY.source,
      examinedAnchors: x.examinedAnchors + y.examinedAnchors,
    );
  }

  _AxisResolution _resolveAxis(
    DesySnapSession session,
    DesySnapRequest request,
    DesySnapAxis axis,
  ) {
    final movingKinds = _movingKinds(request, axis);
    if (movingKinds.isEmpty) return const _AxisResolution.none();
    final configuration = session.configuration;
    final lock = session.lockFor(axis);
    if (lock != null && movingKinds.contains(lock.movingKind)) {
      final moving = _coordinateFor(request.rect, axis, lock.movingKind);
      final correction = lock.targetCoordinate - moving;
      if (correction.abs() <= configuration.releaseCanvasDistance &&
          _correctionFits(request, axis, correction)) {
        return _AxisResolution(
          correction: correction,
          source: DesySnapSource.element,
          movingKind: lock.movingKind,
          targetKind: lock.targetKind,
          targetCoordinate: lock.targetCoordinate,
          targetId: lock.targetId,
        );
      }
    }
    session.setLock(axis, null);

    _Candidate? best;
    var examined = 0;
    for (final movingKind in movingKinds) {
      final moving = _coordinateFor(request.rect, axis, movingKind);
      session.index.visitNear(
        axis,
        moving,
        configuration.acquireCanvasDistance,
        (target) {
          examined++;
          if (target.target.id == session.excludedTargetId) return;
          if (!_compatible(movingKind, target.kind)) return;
          final correction = target.coordinate - moving;
          if (!_correctionFits(request, axis, correction)) return;
          final candidate = _Candidate(
            correction: correction,
            movingKind: movingKind,
            target: target,
          );
          if (best == null || candidate.precedes(best!)) best = candidate;
        },
      );
    }
    if (best case final winner?) {
      session.setLock(
        axis,
        DesySnapLock(
          axis: axis,
          movingKind: winner.movingKind,
          targetKind: winner.target.kind,
          targetCoordinate: winner.target.coordinate,
          targetId: winner.target.target.id,
        ),
      );
      return _AxisResolution(
        correction: winner.correction,
        source: DesySnapSource.element,
        movingKind: winner.movingKind,
        targetKind: winner.target.kind,
        targetCoordinate: winner.target.coordinate,
        targetId: winner.target.target.id,
        examinedAnchors: examined,
      );
    }

    final gridKind = request.operation == DesySnapOperation.move
        ? DesySnapAnchorKind.leading
        : movingKinds.first;
    final coordinate = _coordinateFor(request.rect, axis, gridKind);
    final grid = configuration.gridStep;
    var correction = (coordinate / grid).round() * grid - coordinate;
    if (!_correctionFits(request, axis, correction)) correction = 0;
    return _AxisResolution(
      correction: correction,
      source: DesySnapSource.grid,
      movingKind: gridKind,
      examinedAnchors: examined,
    );
  }

  static List<DesySnapAnchorKind> _movingKinds(
    DesySnapRequest request,
    DesySnapAxis axis,
  ) {
    if (request.operation == DesySnapOperation.move) {
      return DesySnapAnchorKind.values;
    }
    final edges = request.edges;
    return switch (axis) {
      DesySnapAxis.x => [
        if (edges.left) DesySnapAnchorKind.leading,
        if (edges.right) DesySnapAnchorKind.trailing,
      ],
      DesySnapAxis.y => [
        if (edges.top) DesySnapAnchorKind.leading,
        if (edges.bottom) DesySnapAnchorKind.trailing,
      ],
    };
  }

  static bool _compatible(
    DesySnapAnchorKind moving,
    DesySnapAnchorKind target,
  ) =>
      moving == DesySnapAnchorKind.center || target == DesySnapAnchorKind.center
      ? moving == DesySnapAnchorKind.center &&
            target == DesySnapAnchorKind.center
      : true;

  static double _coordinateFor(
    Rect rect,
    DesySnapAxis axis,
    DesySnapAnchorKind kind,
  ) => switch ((axis, kind)) {
    (DesySnapAxis.x, DesySnapAnchorKind.leading) => rect.left,
    (DesySnapAxis.x, DesySnapAnchorKind.center) => rect.center.dx,
    (DesySnapAxis.x, DesySnapAnchorKind.trailing) => rect.right,
    (DesySnapAxis.y, DesySnapAnchorKind.leading) => rect.top,
    (DesySnapAxis.y, DesySnapAnchorKind.center) => rect.center.dy,
    (DesySnapAxis.y, DesySnapAnchorKind.trailing) => rect.bottom,
  };

  static Rect _applyCorrections(
    DesySnapRequest request,
    _AxisResolution x,
    _AxisResolution y,
  ) {
    final rect = request.rect;
    if (request.operation == DesySnapOperation.move) {
      return rect.shift(Offset(x.correction, y.correction));
    }
    return Rect.fromLTRB(
      request.edges.left ? rect.left + x.correction : rect.left,
      request.edges.top ? rect.top + y.correction : rect.top,
      request.edges.right ? rect.right + x.correction : rect.right,
      request.edges.bottom ? rect.bottom + y.correction : rect.bottom,
    );
  }

  static bool _correctionFits(
    DesySnapRequest request,
    DesySnapAxis axis,
    double correction,
  ) {
    final empty = const _AxisResolution.none();
    final candidate = _applyCorrections(
      request,
      axis == DesySnapAxis.x ? _AxisResolution(correction: correction) : empty,
      axis == DesySnapAxis.y ? _AxisResolution(correction: correction) : empty,
    );
    if (candidate.width < request.minimumSize.width ||
        candidate.height < request.minimumSize.height) {
      return false;
    }
    final bounds = request.bounds;
    if (bounds == null) return true;
    return candidate.left >= bounds.left - 0.001 &&
        candidate.top >= bounds.top - 0.001 &&
        candidate.right <= bounds.right + 0.001 &&
        candidate.bottom <= bounds.bottom + 0.001;
  }

  static Rect _constrain(Rect rect, DesySnapRequest request) {
    final bounds = request.bounds;
    if (bounds == null) return rect;
    if (request.operation == DesySnapOperation.move) {
      final left = rect.width <= bounds.width
          ? rect.left.clamp(bounds.left, bounds.right - rect.width).toDouble()
          : bounds.left;
      final top = rect.height <= bounds.height
          ? rect.top.clamp(bounds.top, bounds.bottom - rect.height).toDouble()
          : bounds.top;
      return Rect.fromLTWH(left, top, rect.width, rect.height);
    }
    return Rect.fromLTRB(
      request.edges.left
          ? rect.left
                .clamp(bounds.left, rect.right - request.minimumSize.width)
                .toDouble()
          : rect.left,
      request.edges.top
          ? rect.top
                .clamp(bounds.top, rect.bottom - request.minimumSize.height)
                .toDouble()
          : rect.top,
      request.edges.right
          ? rect.right
                .clamp(rect.left + request.minimumSize.width, bounds.right)
                .toDouble()
          : rect.right,
      request.edges.bottom
          ? rect.bottom
                .clamp(rect.top + request.minimumSize.height, bounds.bottom)
                .toDouble()
          : rect.bottom,
    );
  }

  static bool _ratioMatches(Rect rect, double ratio) =>
      rect.height > 0 && (rect.width / rect.height - ratio).abs() < 0.0001;

  static DesySnapAxis _aspectDriver(
    _AxisResolution x,
    _AxisResolution y,
    DesySnapEdges edges,
  ) {
    if (!edges.hasVertical) return DesySnapAxis.x;
    if (!edges.hasHorizontal) return DesySnapAxis.y;
    if (x.source != y.source) {
      if (x.source == DesySnapSource.element) return DesySnapAxis.x;
      if (y.source == DesySnapSource.element) return DesySnapAxis.y;
    }
    return x.correction.abs() <= y.correction.abs()
        ? DesySnapAxis.x
        : DesySnapAxis.y;
  }

  static Rect _applyAspectCorrection(
    DesySnapRequest request,
    _AxisResolution resolution,
    DesySnapAxis driver,
    double ratio,
  ) {
    final rect = request.rect;
    final edges = request.edges;
    if (driver == DesySnapAxis.x) {
      final left = edges.left ? rect.left + resolution.correction : rect.left;
      final right = edges.right
          ? rect.right + resolution.correction
          : rect.right;
      var width = math.max((right - left).abs(), request.minimumSize.width);
      var height = math.max(width / ratio, request.minimumSize.height);
      width = height * ratio;
      final anchoredRight = edges.left && !edges.right;
      final anchoredBottom = edges.top && !edges.bottom;
      return Rect.fromLTWH(
        anchoredRight ? rect.right - width : rect.left,
        anchoredBottom ? rect.bottom - height : rect.top,
        width,
        height,
      );
    }
    final top = edges.top ? rect.top + resolution.correction : rect.top;
    final bottom = edges.bottom
        ? rect.bottom + resolution.correction
        : rect.bottom;
    var height = math.max((bottom - top).abs(), request.minimumSize.height);
    var width = math.max(height * ratio, request.minimumSize.width);
    height = width / ratio;
    final anchoredRight = edges.left && !edges.right;
    final anchoredBottom = edges.top && !edges.bottom;
    return Rect.fromLTWH(
      anchoredRight ? rect.right - width : rect.left,
      anchoredBottom ? rect.bottom - height : rect.top,
      width,
      height,
    );
  }

  static DesySnapGuide _guideFor(
    DesySnapSession session,
    Rect corrected,
    _AxisResolution resolution,
    DesySnapAxis axis,
  ) {
    final coordinate = resolution.targetCoordinate!;
    final targets = session.index.targetsAt(axis, coordinate);
    var start = axis == DesySnapAxis.x ? corrected.top : corrected.left;
    var end = axis == DesySnapAxis.x ? corrected.bottom : corrected.right;
    for (final target in targets) {
      if (axis == DesySnapAxis.x) {
        start = math.min(start, target.rect.top);
        end = math.max(end, target.rect.bottom);
      } else {
        start = math.min(start, target.rect.left);
        end = math.max(end, target.rect.right);
      }
    }
    return DesySnapGuide(
      axis: axis,
      coordinate: coordinate,
      start: start,
      end: end,
      targetIds: List.unmodifiable(targets.map((target) => target.id)),
    );
  }
}

class _AxisResolution {
  const _AxisResolution({
    this.correction = 0,
    this.source = DesySnapSource.none,
    this.movingKind,
    this.targetKind,
    this.targetCoordinate,
    this.targetId,
    this.examinedAnchors = 0,
  });

  const _AxisResolution.none() : this();

  final double correction;
  final DesySnapSource source;
  final DesySnapAnchorKind? movingKind;
  final DesySnapAnchorKind? targetKind;
  final double? targetCoordinate;
  final String? targetId;
  final int examinedAnchors;
}

class _Candidate {
  const _Candidate({
    required this.correction,
    required this.movingKind,
    required this.target,
  });

  final double correction;
  final DesySnapAnchorKind movingKind;
  final DesySnapAnchor target;

  bool precedes(_Candidate other) {
    final distance = correction.abs().compareTo(other.correction.abs());
    if (distance != 0) return distance < 0;
    final relationship = _relationshipPriority().compareTo(
      other._relationshipPriority(),
    );
    if (relationship != 0) return relationship < 0;
    final id = target.target.id.compareTo(other.target.target.id);
    if (id != 0) return id < 0;
    final moving = movingKind.index.compareTo(other.movingKind.index);
    if (moving != 0) return moving < 0;
    return target.kind.index < other.target.kind.index;
  }

  int _relationshipPriority() {
    if (movingKind == DesySnapAnchorKind.center) return 2;
    return movingKind == target.kind ? 0 : 1;
  }
}

extension on double {
  double difference(double other) => this - other;
}

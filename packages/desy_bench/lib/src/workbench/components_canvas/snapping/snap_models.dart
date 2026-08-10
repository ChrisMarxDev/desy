// Internal Sketch snapping geometry.
// ignore_for_file: public_member_api_docs

import 'dart:ui';

enum DesySnapAxis { x, y }

enum DesySnapAnchorKind { leading, center, trailing }

enum DesySnapOperation { move, resize }

enum DesySnapSource { none, grid, element }

class DesySnapConfiguration {
  const DesySnapConfiguration({
    required this.gridStep,
    this.screenScale = 1,
    this.acquireDistance = 6,
    this.releaseDistance = 10,
  }) : assert(gridStep >= 1 && gridStep <= 256),
       assert(screenScale > 0),
       assert(acquireDistance >= 0),
       assert(releaseDistance >= acquireDistance);

  final double gridStep;

  /// Screen pixels represented by one canvas coordinate unit.
  final double screenScale;
  final double acquireDistance;
  final double releaseDistance;

  double get acquireCanvasDistance => acquireDistance / screenScale;
  double get releaseCanvasDistance => releaseDistance / screenScale;
}

class DesySnapEdges {
  const DesySnapEdges({
    this.left = false,
    this.top = false,
    this.right = false,
    this.bottom = false,
  });

  final bool left;
  final bool top;
  final bool right;
  final bool bottom;

  bool get hasHorizontal => left || right;
  bool get hasVertical => top || bottom;
}

class DesySnapTarget {
  const DesySnapTarget({required this.id, required this.rect});

  final String id;
  final Rect rect;
}

class DesySnapAnchor {
  const DesySnapAnchor({
    required this.axis,
    required this.kind,
    required this.coordinate,
    required this.target,
  });

  final DesySnapAxis axis;
  final DesySnapAnchorKind kind;
  final double coordinate;
  final DesySnapTarget target;
}

class DesySnapLock {
  const DesySnapLock({
    required this.axis,
    required this.movingKind,
    required this.targetKind,
    required this.targetCoordinate,
    required this.targetId,
  });

  final DesySnapAxis axis;
  final DesySnapAnchorKind movingKind;
  final DesySnapAnchorKind targetKind;
  final double targetCoordinate;
  final String targetId;
}

class DesySnapGuide {
  const DesySnapGuide({
    required this.axis,
    required this.coordinate,
    required this.start,
    required this.end,
    required this.targetIds,
  });

  final DesySnapAxis axis;
  final double coordinate;
  final double start;
  final double end;
  final List<String> targetIds;
}

class DesySnapRequest {
  const DesySnapRequest({
    required this.rect,
    required this.operation,
    this.edges = const DesySnapEdges(),
    this.bounds,
    this.minimumSize = const Size(1, 1),
    this.aspectRatio,
  });

  final Rect rect;
  final DesySnapOperation operation;
  final DesySnapEdges edges;
  final Rect? bounds;
  final Size minimumSize;

  /// An authoritative resize ratio. The proposed [rect] is expected to have
  /// already been normalized to this ratio before candidate lookup.
  final double? aspectRatio;
}

class DesySnapResult {
  const DesySnapResult({
    required this.rect,
    required this.guides,
    required this.xSource,
    required this.ySource,
    required this.examinedAnchors,
  });

  final Rect rect;
  final List<DesySnapGuide> guides;
  final DesySnapSource xSource;
  final DesySnapSource ySource;

  /// Number of indexed anchors visited by the tolerance-window lookup.
  final int examinedAnchors;

  bool get hasElementSnap =>
      xSource == DesySnapSource.element || ySource == DesySnapSource.element;
}

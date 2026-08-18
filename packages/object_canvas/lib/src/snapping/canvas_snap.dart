import 'dart:ui';

/// Identifies a canvas coordinate axis.
enum CanvasSnapAxis {
  /// The horizontal axis.
  x,

  /// The vertical axis.
  y,
}

/// Identifies an edge or center anchor along one axis.
enum CanvasSnapAnchorKind {
  /// The left or top edge.
  leading,

  /// The center coordinate.
  center,

  /// The right or bottom edge.
  trailing,
}

/// Identifies where a snap target originated.
enum CanvasSnapSource {
  /// A finite canvas boundary or center.
  canvas,

  /// Another object in the scene.
  object,

  /// A regular grid line.
  grid,

  /// A host-defined target.
  custom,
}

/// A visual alignment guide produced by snapping.
class CanvasSnapGuide {
  /// Creates a guide spanning [start] through [end].
  const CanvasSnapGuide({
    required this.axis,
    required this.coordinate,
    required this.start,
    required this.end,
    required this.source,
    required this.targetIds,
  });

  /// The axis perpendicular to the guide.
  final CanvasSnapAxis axis;

  /// The guide coordinate on [axis].
  final double coordinate;

  /// The start of the guide on the opposite axis.
  final double start;

  /// The end of the guide on the opposite axis.
  final double end;

  /// The kind of target that produced the guide.
  final CanvasSnapSource source;

  /// Stable identifiers of targets represented by the guide.
  final List<String> targetIds;
}

/// Immutable geometry supplied to snap-index strategies for one object.
class CanvasSnapSceneObject {
  /// Creates scene geometry for an object.
  const CanvasSnapSceneObject({required this.id, required this.bounds});

  /// The object's stable identifier.
  final String id;

  /// The object's axis-aligned painted bounds.
  final Rect bounds;
}

/// Immutable stable geometry used to build a snap index.
class CanvasSnapScene {
  /// Creates a snapping scene.
  const CanvasSnapScene({required this.canvasBounds, required this.objects});

  /// The finite canvas bounds.
  final Rect canvasBounds;

  /// The stable objects present when the index is built.
  final List<CanvasSnapSceneObject> objects;
}

/// Adds stable scene metadata to an index. It is never invoked during a drag.
abstract interface class CanvasSnapStrategy {
  /// Adds stable snap metadata from [scene] to [builder].
  void buildIndex(CanvasSnapScene scene, CanvasSnapIndexBuilder builder);
}

/// Adds object edges and centers to a snap index.
class CanvasObjectSnapStrategy implements CanvasSnapStrategy {
  /// Creates an object strategy using [priority] to break equal-distance ties.
  const CanvasObjectSnapStrategy({this.priority = 10});

  /// The tie-breaking priority; lower values win.
  final int priority;

  @override
  void buildIndex(CanvasSnapScene scene, CanvasSnapIndexBuilder builder) {
    for (final object in scene.objects) {
      builder.addRect(
        id: object.id,
        rect: object.bounds,
        source: CanvasSnapSource.object,
        priority: priority,
      );
    }
  }
}

/// Adds canvas edges and centers to a snap index.
class CanvasBoundarySnapStrategy implements CanvasSnapStrategy {
  /// Creates a boundary strategy using [priority] for equal-distance ties.
  const CanvasBoundarySnapStrategy({this.priority = 0});

  /// The tie-breaking priority; lower values win.
  final int priority;

  @override
  void buildIndex(CanvasSnapScene scene, CanvasSnapIndexBuilder builder) {
    builder.addRect(
      id: r'$canvas',
      rect: scene.canvasBounds,
      source: CanvasSnapSource.canvas,
      priority: priority,
    );
  }
}

/// Adds regularly spaced horizontal and vertical lines to a snap index.
class CanvasGridSnapStrategy implements CanvasSnapStrategy {
  /// Creates a grid strategy with logical [step] spacing.
  const CanvasGridSnapStrategy({this.step = 8, this.priority = 100})
    : assert(step > 0);

  /// The distance between adjacent grid lines in canvas coordinates.
  final double step;

  /// The tie-breaking priority; lower values win.
  final int priority;

  @override
  void buildIndex(CanvasSnapScene scene, CanvasSnapIndexBuilder builder) {
    final bounds = scene.canvasBounds;
    for (var x = bounds.left; x <= bounds.right; x += step) {
      builder.addLine(
        id: r'$grid-x-' + x.toString(),
        axis: CanvasSnapAxis.x,
        coordinate: x,
        spanStart: bounds.top,
        spanEnd: bounds.bottom,
        source: CanvasSnapSource.grid,
        priority: priority,
        matchesAnyAnchor: true,
      );
    }
    for (var y = bounds.top; y <= bounds.bottom; y += step) {
      builder.addLine(
        id: r'$grid-y-' + y.toString(),
        axis: CanvasSnapAxis.y,
        coordinate: y,
        spanStart: bounds.left,
        spanEnd: bounds.right,
        source: CanvasSnapSource.grid,
        priority: priority,
        matchesAnyAnchor: true,
      );
    }
  }
}

/// Configures stable snap sources and screen-space interaction thresholds.
class CanvasSnapConfiguration {
  /// Creates a snap configuration.
  CanvasSnapConfiguration({
    List<CanvasSnapStrategy> strategies = const [
      CanvasBoundarySnapStrategy(),
      CanvasObjectSnapStrategy(),
      CanvasGridSnapStrategy(),
    ],
    this.acquireDistance = 6,
    this.releaseDistance = 10,
  }) : strategies = List.unmodifiable(strategies),
       assert(acquireDistance >= 0),
       assert(releaseDistance >= acquireDistance);

  /// Strategies run when stable scene geometry is indexed.
  final List<CanvasSnapStrategy> strategies;

  /// Screen-pixel distance, converted by the active viewport scale.
  final double acquireDistance;

  /// Screen-pixel distance at which an acquired target is released.
  final double releaseDistance;
}

/// Collects stable anchors before producing an immutable [CanvasSnapIndex].
class CanvasSnapIndexBuilder {
  final List<CanvasSnapAnchor> _anchors = [];

  /// Adds leading, center, and trailing anchors for both axes of [rect].
  void addRect({
    required String id,
    required Rect rect,
    required CanvasSnapSource source,
    required int priority,
  }) {
    for (final kind in CanvasSnapAnchorKind.values) {
      addLine(
        id: id,
        axis: CanvasSnapAxis.x,
        coordinate: _coordinate(rect, CanvasSnapAxis.x, kind),
        spanStart: rect.top,
        spanEnd: rect.bottom,
        source: source,
        priority: priority,
        kind: kind,
      );
      addLine(
        id: id,
        axis: CanvasSnapAxis.y,
        coordinate: _coordinate(rect, CanvasSnapAxis.y, kind),
        spanStart: rect.left,
        spanEnd: rect.right,
        source: source,
        priority: priority,
        kind: kind,
      );
    }
  }

  /// Adds one anchor line to the index being built.
  void addLine({
    required String id,
    required CanvasSnapAxis axis,
    required double coordinate,
    required double spanStart,
    required double spanEnd,
    required CanvasSnapSource source,
    required int priority,
    CanvasSnapAnchorKind kind = CanvasSnapAnchorKind.leading,
    bool matchesAnyAnchor = false,
  }) {
    _anchors.add(
      CanvasSnapAnchor(
        id: id,
        axis: axis,
        kind: kind,
        coordinate: coordinate,
        spanStart: spanStart,
        spanEnd: spanEnd,
        source: source,
        priority: priority,
        matchesAnyAnchor: matchesAnyAnchor,
      ),
    );
  }

  /// Builds an immutable, axis-sorted index from collected anchors.
  CanvasSnapIndex build() => CanvasSnapIndex._(_anchors);
}

/// One immutable target coordinate in a snap index.
class CanvasSnapAnchor {
  /// Creates a snap anchor.
  const CanvasSnapAnchor({
    required this.id,
    required this.axis,
    required this.kind,
    required this.coordinate,
    required this.spanStart,
    required this.spanEnd,
    required this.source,
    required this.priority,
    required this.matchesAnyAnchor,
  });

  /// The stable identifier of the source target.
  final String id;

  /// The axis on which [coordinate] lies.
  final CanvasSnapAxis axis;

  /// The edge or center represented by the anchor.
  final CanvasSnapAnchorKind kind;

  /// The target coordinate along [axis].
  final double coordinate;

  /// The source geometry's start on the opposite axis.
  final double spanStart;

  /// The source geometry's end on the opposite axis.
  final double spanEnd;

  /// The kind of source geometry.
  final CanvasSnapSource source;

  /// The tie-breaking priority; lower values win.
  final int priority;

  /// Whether any moving anchor kind may align to this anchor.
  final bool matchesAnyAnchor;
}

/// An immutable, sorted lookup structure for stable snap anchors.
class CanvasSnapIndex {
  CanvasSnapIndex._(Iterable<CanvasSnapAnchor> anchors)
    : _x = _sorted(anchors.where((anchor) => anchor.axis == CanvasSnapAxis.x)),
      _y = _sorted(anchors.where((anchor) => anchor.axis == CanvasSnapAxis.y));

  final List<CanvasSnapAnchor> _x;
  final List<CanvasSnapAnchor> _y;

  /// The number of horizontal and vertical anchors in the index.
  int get anchorCount => _x.length + _y.length;

  /// Visits anchors within [tolerance] of [coordinate] on [axis].
  void visitNear(
    CanvasSnapAxis axis,
    double coordinate,
    double tolerance,
    void Function(CanvasSnapAnchor anchor) visitor,
  ) {
    final anchors = axis == CanvasSnapAxis.x ? _x : _y;
    final lower = coordinate - tolerance;
    final upper = coordinate + tolerance;
    var index = _lowerBound(anchors, lower);
    while (index < anchors.length && anchors[index].coordinate <= upper) {
      visitor(anchors[index]);
      index++;
    }
  }

  static List<CanvasSnapAnchor> _sorted(Iterable<CanvasSnapAnchor> anchors) =>
      List<CanvasSnapAnchor>.of(anchors)..sort((a, b) {
        final coordinate = a.coordinate.compareTo(b.coordinate);
        if (coordinate != 0) return coordinate;
        final priority = a.priority.compareTo(b.priority);
        if (priority != 0) return priority;
        return a.id.compareTo(b.id);
      });

  static int _lowerBound(List<CanvasSnapAnchor> anchors, double value) {
    var low = 0;
    var high = anchors.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (anchors[middle].coordinate < value) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }
}

/// Mutable gesture-local snapping state, including hysteresis locks.
class CanvasSnapSession {
  /// Creates a session over a precomputed [index].
  CanvasSnapSession({
    required this.index,
    required Set<String> excludedObjectIds,
    required this.configuration,
  }) : excludedObjectIds = Set.unmodifiable(excludedObjectIds);

  /// Stable anchors computed before the gesture began.
  final CanvasSnapIndex index;

  /// Object identifiers that cannot act as targets during this gesture.
  final Set<String> excludedObjectIds;

  /// Strategies and distance thresholds captured for this gesture.
  final CanvasSnapConfiguration configuration;
  _CanvasSnapLock? _xLock;
  _CanvasSnapLock? _yLock;
}

/// The corrected bounds and guides produced by a snap calculation.
class CanvasSnapResult {
  /// Creates a snap result.
  const CanvasSnapResult({
    required this.bounds,
    required this.guides,
    required this.examinedAnchors,
  });

  /// The corrected bounds, optionally constrained to the canvas.
  final Rect bounds;

  /// Guides describing acquired targets.
  final List<CanvasSnapGuide> guides;

  /// The number of nearby anchors examined by the calculation.
  final int examinedAnchors;
}

/// Identifies the edges controlled by a resize gesture.
class CanvasResizeEdges {
  /// Creates an edge set.
  const CanvasResizeEdges({
    this.left = false,
    this.top = false,
    this.right = false,
    this.bottom = false,
  });

  /// Whether the left edge is controlled.
  final bool left;

  /// Whether the top edge is controlled.
  final bool top;

  /// Whether the right edge is controlled.
  final bool right;

  /// Whether the bottom edge is controlled.
  final bool bottom;
}

/// Resolves indexed snapping for ephemeral move and resize previews.
class CanvasSnapEngine {
  /// Creates a stateless snap resolver.
  const CanvasSnapEngine();

  /// Snaps [proposedBounds] for a move gesture.
  ///
  /// Set [constrainToCanvas] to false when the canvas permits overflow.
  CanvasSnapResult resolveMove(
    CanvasSnapSession session,
    Rect proposedBounds, {
    required Rect canvasBounds,
    double screenScale = 1,
    bool constrainToCanvas = true,
  }) {
    assert(screenScale > 0);
    final x = _resolveAxis(
      session,
      proposedBounds,
      CanvasSnapAxis.x,
      screenScale,
      CanvasSnapAnchorKind.values,
    );
    final y = _resolveAxis(
      session,
      proposedBounds,
      CanvasSnapAxis.y,
      screenScale,
      CanvasSnapAnchorKind.values,
    );
    final snapped = proposedBounds.shift(Offset(x.correction, y.correction));
    final constrained = constrainToCanvas
        ? _constrainMove(snapped, canvasBounds)
        : snapped;
    return CanvasSnapResult(
      bounds: constrained,
      guides: [
        if (x.anchor != null &&
            (_coordinate(constrained, CanvasSnapAxis.x, x.movingKind!) -
                        x.anchor!.coordinate)
                    .abs() <
                0.01)
          _guide(proposedBounds, x, CanvasSnapAxis.x),
        if (y.anchor != null &&
            (_coordinate(constrained, CanvasSnapAxis.y, y.movingKind!) -
                        y.anchor!.coordinate)
                    .abs() <
                0.01)
          _guide(proposedBounds, y, CanvasSnapAxis.y),
      ],
      examinedAnchors: x.examined + y.examined,
    );
  }

  /// Snaps controlled [edges] of [proposedBounds] for a resize gesture.
  ///
  /// Set [constrainToCanvas] to false when the canvas permits overflow.
  CanvasSnapResult resolveResize(
    CanvasSnapSession session,
    Rect proposedBounds, {
    required CanvasResizeEdges edges,
    required Rect canvasBounds,
    required Size minimumSize,
    double screenScale = 1,
    bool constrainToCanvas = true,
  }) {
    final xKinds = [
      if (edges.left) CanvasSnapAnchorKind.leading,
      if (edges.right) CanvasSnapAnchorKind.trailing,
    ];
    final yKinds = [
      if (edges.top) CanvasSnapAnchorKind.leading,
      if (edges.bottom) CanvasSnapAnchorKind.trailing,
    ];
    final x = _resolveAxis(
      session,
      proposedBounds,
      CanvasSnapAxis.x,
      screenScale,
      xKinds,
    );
    final y = _resolveAxis(
      session,
      proposedBounds,
      CanvasSnapAxis.y,
      screenScale,
      yKinds,
    );
    final snapped = Rect.fromLTRB(
      edges.left ? proposedBounds.left + x.correction : proposedBounds.left,
      edges.top ? proposedBounds.top + y.correction : proposedBounds.top,
      edges.right ? proposedBounds.right + x.correction : proposedBounds.right,
      edges.bottom
          ? proposedBounds.bottom + y.correction
          : proposedBounds.bottom,
    );
    final constrained = constrainToCanvas
        ? Rect.fromLTRB(
            edges.left
                ? snapped.left
                      .clamp(
                        canvasBounds.left,
                        snapped.right - minimumSize.width,
                      )
                      .toDouble()
                : snapped.left,
            edges.top
                ? snapped.top
                      .clamp(
                        canvasBounds.top,
                        snapped.bottom - minimumSize.height,
                      )
                      .toDouble()
                : snapped.top,
            edges.right
                ? snapped.right
                      .clamp(
                        snapped.left + minimumSize.width,
                        canvasBounds.right,
                      )
                      .toDouble()
                : snapped.right,
            edges.bottom
                ? snapped.bottom
                      .clamp(
                        snapped.top + minimumSize.height,
                        canvasBounds.bottom,
                      )
                      .toDouble()
                : snapped.bottom,
          )
        : snapped;
    return CanvasSnapResult(
      bounds: constrained,
      guides: [
        if (x.anchor != null && x.movingKind != null)
          _guide(constrained, x, CanvasSnapAxis.x),
        if (y.anchor != null && y.movingKind != null)
          _guide(constrained, y, CanvasSnapAxis.y),
      ],
      examinedAnchors: x.examined + y.examined,
    );
  }

  _CanvasAxisResolution _resolveAxis(
    CanvasSnapSession session,
    Rect bounds,
    CanvasSnapAxis axis,
    double screenScale,
    List<CanvasSnapAnchorKind> movingKinds,
  ) {
    final acquire = session.configuration.acquireDistance / screenScale;
    final release = session.configuration.releaseDistance / screenScale;
    final lock = axis == CanvasSnapAxis.x ? session._xLock : session._yLock;
    if (lock != null) {
      final moving = _coordinate(bounds, axis, lock.movingKind);
      final correction = lock.anchor.coordinate - moving;
      if (correction.abs() <= release) {
        return _CanvasAxisResolution(
          correction: correction,
          movingKind: lock.movingKind,
          anchor: lock.anchor,
        );
      }
      if (axis == CanvasSnapAxis.x) {
        session._xLock = null;
      } else {
        session._yLock = null;
      }
    }

    _CanvasCandidate? best;
    var examined = 0;
    for (final movingKind in movingKinds) {
      final moving = _coordinate(bounds, axis, movingKind);
      session.index.visitNear(axis, moving, acquire, (anchor) {
        examined++;
        if (session.excludedObjectIds.contains(anchor.id)) return;
        if (!anchor.matchesAnyAnchor && !_compatible(movingKind, anchor.kind)) {
          return;
        }
        final candidate = _CanvasCandidate(
          correction: anchor.coordinate - moving,
          movingKind: movingKind,
          anchor: anchor,
        );
        if (best == null || candidate.precedes(best!)) best = candidate;
      });
    }
    final winner = best;
    if (winner == null) return _CanvasAxisResolution(examined: examined);
    final nextLock = _CanvasSnapLock(
      movingKind: winner.movingKind,
      anchor: winner.anchor,
    );
    if (axis == CanvasSnapAxis.x) {
      session._xLock = nextLock;
    } else {
      session._yLock = nextLock;
    }
    return _CanvasAxisResolution(
      correction: winner.correction,
      movingKind: winner.movingKind,
      anchor: winner.anchor,
      examined: examined,
    );
  }

  static bool _compatible(
    CanvasSnapAnchorKind moving,
    CanvasSnapAnchorKind target,
  ) =>
      moving == CanvasSnapAnchorKind.center ||
          target == CanvasSnapAnchorKind.center
      ? moving == CanvasSnapAnchorKind.center &&
            target == CanvasSnapAnchorKind.center
      : true;

  static Rect _constrainMove(Rect rect, Rect bounds) {
    final left = rect.width <= bounds.width
        ? rect.left.clamp(bounds.left, bounds.right - rect.width).toDouble()
        : bounds.left;
    final top = rect.height <= bounds.height
        ? rect.top.clamp(bounds.top, bounds.bottom - rect.height).toDouble()
        : bounds.top;
    return Rect.fromLTWH(left, top, rect.width, rect.height);
  }

  static CanvasSnapGuide _guide(
    Rect movingBounds,
    _CanvasAxisResolution resolution,
    CanvasSnapAxis axis,
  ) {
    final anchor = resolution.anchor!;
    final movingStart = axis == CanvasSnapAxis.x
        ? movingBounds.top
        : movingBounds.left;
    final movingEnd = axis == CanvasSnapAxis.x
        ? movingBounds.bottom
        : movingBounds.right;
    return CanvasSnapGuide(
      axis: axis,
      coordinate: anchor.coordinate,
      start: movingStart < anchor.spanStart ? movingStart : anchor.spanStart,
      end: movingEnd > anchor.spanEnd ? movingEnd : anchor.spanEnd,
      source: anchor.source,
      targetIds: [anchor.id],
    );
  }
}

class _CanvasCandidate {
  const _CanvasCandidate({
    required this.correction,
    required this.movingKind,
    required this.anchor,
  });

  final double correction;
  final CanvasSnapAnchorKind movingKind;
  final CanvasSnapAnchor anchor;

  bool precedes(_CanvasCandidate other) {
    if (anchor.priority != other.anchor.priority) {
      return anchor.priority < other.anchor.priority;
    }
    final distance = correction.abs().compareTo(other.correction.abs());
    if (distance != 0) return distance < 0;
    return anchor.id.compareTo(other.anchor.id) < 0;
  }
}

class _CanvasSnapLock {
  const _CanvasSnapLock({required this.movingKind, required this.anchor});

  final CanvasSnapAnchorKind movingKind;
  final CanvasSnapAnchor anchor;
}

class _CanvasAxisResolution {
  const _CanvasAxisResolution({
    this.correction = 0,
    this.movingKind,
    this.anchor,
    this.examined = 0,
  });

  final double correction;
  final CanvasSnapAnchorKind? movingKind;
  final CanvasSnapAnchor? anchor;
  final int examined;
}

double _coordinate(Rect rect, CanvasSnapAxis axis, CanvasSnapAnchorKind kind) =>
    switch ((axis, kind)) {
      (CanvasSnapAxis.x, CanvasSnapAnchorKind.leading) => rect.left,
      (CanvasSnapAxis.x, CanvasSnapAnchorKind.center) => rect.center.dx,
      (CanvasSnapAxis.x, CanvasSnapAnchorKind.trailing) => rect.right,
      (CanvasSnapAxis.y, CanvasSnapAnchorKind.leading) => rect.top,
      (CanvasSnapAxis.y, CanvasSnapAnchorKind.center) => rect.center.dy,
      (CanvasSnapAxis.y, CanvasSnapAnchorKind.trailing) => rect.bottom,
    };

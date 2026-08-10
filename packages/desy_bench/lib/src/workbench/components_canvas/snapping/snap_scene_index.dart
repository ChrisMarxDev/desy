// Internal Sketch snapping index.
// ignore_for_file: public_member_api_docs

import 'snap_models.dart';

class DesySnapSceneIndex {
  DesySnapSceneIndex(Iterable<DesySnapTarget> targets)
    : _targets = List.unmodifiable(targets) {
    _xBuckets = _buildBuckets(_targets, DesySnapAxis.x);
    _yBuckets = _buildBuckets(_targets, DesySnapAxis.y);
  }

  final List<DesySnapTarget> _targets;
  late final List<_CoordinateBucket> _xBuckets;
  late final List<_CoordinateBucket> _yBuckets;

  int get targetCount => _targets.length;

  /// Logical anchors represented by the coordinate buckets.
  int get anchorCount => _targets.length * 6;

  /// Compact representatives consulted by candidate lookup.
  int get indexedAnchorCount =>
      _xBuckets.fold(0, (count, bucket) => count + bucket.anchors.length) +
      _yBuckets.fold(0, (count, bucket) => count + bucket.anchors.length);

  void visitNear(
    DesySnapAxis axis,
    double coordinate,
    double tolerance,
    void Function(DesySnapAnchor anchor) visitor,
  ) {
    final buckets = _forAxis(axis);
    final minimum = coordinate - tolerance;
    final maximum = coordinate + tolerance;
    var index = _lowerBound(buckets, minimum);
    while (index < buckets.length) {
      final bucket = buckets[index];
      if (bucket.coordinate > maximum) break;
      // Every target at this coordinate would produce the same correction.
      // One stable representative per anchor kind is sufficient for ranking;
      // the full target set stays on the bucket for guide rendering.
      for (final anchor in bucket.anchors) {
        visitor(anchor);
      }
      index++;
    }
  }

  List<DesySnapTarget> targetsAt(
    DesySnapAxis axis,
    double coordinate, {
    double epsilon = 0.000001,
  }) {
    final buckets = _forAxis(axis);
    var index = _lowerBound(buckets, coordinate - epsilon);
    final byId = <String, DesySnapTarget>{};
    while (index < buckets.length) {
      final bucket = buckets[index];
      if (bucket.coordinate > coordinate + epsilon) break;
      for (final target in bucket.targets) {
        byId[target.id] = target;
      }
      index++;
    }
    final result = byId.values.toList(growable: false)
      ..sort((a, b) => a.id.compareTo(b.id));
    return result;
  }

  List<_CoordinateBucket> _forAxis(DesySnapAxis axis) =>
      axis == DesySnapAxis.x ? _xBuckets : _yBuckets;

  static List<_CoordinateBucket> _buildBuckets(
    List<DesySnapTarget> targets,
    DesySnapAxis axis,
  ) {
    final grouped = <double, List<DesySnapAnchor>>{};
    for (final target in targets) {
      for (final anchor in _anchorsFor(target, axis)) {
        (grouped[anchor.coordinate] ??= []).add(anchor);
      }
    }
    final buckets = <_CoordinateBucket>[];
    for (final entry in grouped.entries) {
      entry.value.sort(_compareAnchors);
      final representatives = <DesySnapAnchorKind, DesySnapAnchor>{};
      final targetsById = <String, DesySnapTarget>{};
      for (final anchor in entry.value) {
        representatives.putIfAbsent(anchor.kind, () => anchor);
        targetsById[anchor.target.id] = anchor.target;
      }
      final anchors = representatives.values.toList(growable: false)
        ..sort((a, b) => a.kind.index.compareTo(b.kind.index));
      final bucketTargets = targetsById.values.toList(growable: false)
        ..sort((a, b) => a.id.compareTo(b.id));
      buckets.add(
        _CoordinateBucket(
          coordinate: entry.key,
          anchors: List.unmodifiable(anchors),
          targets: List.unmodifiable(bucketTargets),
        ),
      );
    }
    buckets.sort((a, b) => a.coordinate.compareTo(b.coordinate));
    return List.unmodifiable(buckets);
  }

  static Iterable<DesySnapAnchor> _anchorsFor(
    DesySnapTarget target,
    DesySnapAxis axis,
  ) sync* {
    final rect = target.rect;
    final coordinates = axis == DesySnapAxis.x
        ? (rect.left, rect.center.dx, rect.right)
        : (rect.top, rect.center.dy, rect.bottom);
    yield DesySnapAnchor(
      axis: axis,
      kind: DesySnapAnchorKind.leading,
      coordinate: coordinates.$1,
      target: target,
    );
    yield DesySnapAnchor(
      axis: axis,
      kind: DesySnapAnchorKind.center,
      coordinate: coordinates.$2,
      target: target,
    );
    yield DesySnapAnchor(
      axis: axis,
      kind: DesySnapAnchorKind.trailing,
      coordinate: coordinates.$3,
      target: target,
    );
  }

  static int _compareAnchors(DesySnapAnchor a, DesySnapAnchor b) {
    final id = a.target.id.compareTo(b.target.id);
    if (id != 0) return id;
    return a.kind.index.compareTo(b.kind.index);
  }

  static int _lowerBound(List<_CoordinateBucket> buckets, double coordinate) {
    var low = 0;
    var high = buckets.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      if (buckets[middle].coordinate < coordinate) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }
}

class _CoordinateBucket {
  const _CoordinateBucket({
    required this.coordinate,
    required this.anchors,
    required this.targets,
  });

  final double coordinate;
  final List<DesySnapAnchor> anchors;
  final List<DesySnapTarget> targets;
}

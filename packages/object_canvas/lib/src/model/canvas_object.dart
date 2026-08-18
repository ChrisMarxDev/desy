import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/widgets.dart' show Alignment;

import 'canvas_policy.dart';

/// The geometry of an object in canvas coordinates.
///
/// [size] is the real layout size supplied to the child. [scale] is a paint
/// transform and therefore does not change those layout constraints.
class CanvasObjectGeometry {
  /// Creates object geometry in canvas coordinates.
  const CanvasObjectGeometry({
    required this.position,
    required this.size,
    this.rotation = 0,
    this.scale = 1,
    this.pivot = Alignment.center,
  });

  /// The logical top-left layout position in canvas coordinates.
  final Offset position;

  /// The real widget layout constraints before paint transforms.
  final Size size;

  /// The clockwise paint rotation in radians.
  final double rotation;

  /// The uniform paint scale applied without changing [size].
  final double scale;

  /// The alignment used as the rotation and scale origin.
  final Alignment pivot;

  /// The untransformed logical layout bounds.
  Rect get layoutBounds => position & size;

  /// Axis-aligned bounds after scale and rotation around [pivot].
  Rect get paintBounds {
    final corners = paintCorners;
    final first = corners.first;
    var left = first.dx;
    var top = first.dy;
    var right = first.dx;
    var bottom = first.dy;
    for (final corner in corners.skip(1)) {
      left = math.min(left, corner.dx);
      top = math.min(top, corner.dy);
      right = math.max(right, corner.dx);
      bottom = math.max(bottom, corner.dy);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// The transformed corners in clockwise order from the logical top left.
  List<Offset> get paintCorners {
    final localPivot = Offset(
      (pivot.x + 1) * size.width / 2,
      (pivot.y + 1) * size.height / 2,
    );
    final cosine = math.cos(rotation);
    final sine = math.sin(rotation);
    return <Offset>[
          Offset.zero,
          Offset(size.width, 0),
          Offset(size.width, size.height),
          Offset(0, size.height),
        ]
        .map((corner) {
          final relative = (corner - localPivot) * scale;
          return position +
              localPivot +
              Offset(
                relative.dx * cosine - relative.dy * sine,
                relative.dx * sine + relative.dy * cosine,
              );
        })
        .toList(growable: false);
  }

  /// Creates a copy with the supplied geometry fields replaced.
  CanvasObjectGeometry copyWith({
    Offset? position,
    Size? size,
    double? rotation,
    double? scale,
    Alignment? pivot,
  }) => CanvasObjectGeometry(
    position: position ?? this.position,
    size: size ?? this.size,
    rotation: rotation ?? this.rotation,
    scale: scale ?? this.scale,
    pivot: pivot ?? this.pivot,
  );

  @override
  bool operator ==(Object other) =>
      other is CanvasObjectGeometry &&
      other.position == position &&
      other.size == size &&
      other.rotation == rotation &&
      other.scale == scale &&
      other.pivot == pivot;

  @override
  int get hashCode => Object.hash(position, size, rotation, scale, pivot);
}

/// One typed object in the canvas document.
class CanvasObject<T> {
  /// Creates a typed canvas object.
  const CanvasObject({
    required this.id,
    required this.data,
    required this.geometry,
    this.constraints,
    this.capabilities,
  });

  /// The stable identifier used by selection, actions, and rendering.
  final String id;

  /// Application-owned data used to render the object.
  final T data;

  /// The object's committed geometry.
  final CanvasObjectGeometry geometry;

  /// Optional object-specific override. The controller defaults are used when
  /// this is null.
  final CanvasObjectConstraints? constraints;

  /// Optional object-specific override. The controller defaults are used when
  /// this is null.
  final CanvasObjectCapabilities? capabilities;

  /// Creates a copy with the supplied object fields replaced.
  CanvasObject<T> copyWith({
    String? id,
    T? data,
    CanvasObjectGeometry? geometry,
    CanvasObjectConstraints? constraints,
    CanvasObjectCapabilities? capabilities,
  }) => CanvasObject<T>(
    id: id ?? this.id,
    data: data ?? this.data,
    geometry: geometry ?? this.geometry,
    constraints: constraints ?? this.constraints,
    capabilities: capabilities ?? this.capabilities,
  );
}

/// An object together with its stable index in paint order.
class IndexedCanvasObject<T> {
  /// Creates an indexed object entry.
  const IndexedCanvasObject({required this.index, required this.object});

  /// The object's zero-based index in paint order.
  final int index;

  /// The canvas object at [index].
  final CanvasObject<T> object;
}

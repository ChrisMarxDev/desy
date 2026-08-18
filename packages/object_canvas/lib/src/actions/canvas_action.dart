import 'dart:ui';

import 'package:flutter/widgets.dart' show Alignment;

import '../model/canvas_object.dart';

/// One changed field with exact values for deterministic apply and revert.
class CanvasFieldPatch<V> {
  /// Creates a field patch from [before] to [after].
  const CanvasFieldPatch({required this.before, required this.after});

  /// The value restored by a revert.
  final V before;

  /// The value written by an apply.
  final V after;
}

/// A sparse, reversible patch for geometry fields.
class CanvasObjectGeometryPatch {
  /// Creates a sparse geometry patch.
  const CanvasObjectGeometryPatch({
    this.position,
    this.size,
    this.rotation,
    this.scale,
    this.pivot,
  });

  /// Computes the changed fields between two geometry values.
  factory CanvasObjectGeometryPatch.between(
    CanvasObjectGeometry before,
    CanvasObjectGeometry after,
  ) => CanvasObjectGeometryPatch(
    position: before.position == after.position
        ? null
        : CanvasFieldPatch(before: before.position, after: after.position),
    size: before.size == after.size
        ? null
        : CanvasFieldPatch(before: before.size, after: after.size),
    rotation: before.rotation == after.rotation
        ? null
        : CanvasFieldPatch(before: before.rotation, after: after.rotation),
    scale: before.scale == after.scale
        ? null
        : CanvasFieldPatch(before: before.scale, after: after.scale),
    pivot: before.pivot == after.pivot
        ? null
        : CanvasFieldPatch(before: before.pivot, after: after.pivot),
  );

  /// The position change, or `null` when unchanged.
  final CanvasFieldPatch<Offset>? position;

  /// The logical size change, or `null` when unchanged.
  final CanvasFieldPatch<Size>? size;

  /// The rotation change, or `null` when unchanged.
  final CanvasFieldPatch<double>? rotation;

  /// The paint scale change, or `null` when unchanged.
  final CanvasFieldPatch<double>? scale;

  /// The transform pivot change, or `null` when unchanged.
  final CanvasFieldPatch<Alignment>? pivot;

  /// Whether the patch contains no changed fields.
  bool get isEmpty =>
      position == null &&
      size == null &&
      rotation == null &&
      scale == null &&
      pivot == null;

  /// Applies changed fields to [value].
  CanvasObjectGeometry applyTo(CanvasObjectGeometry value) => value.copyWith(
    position: position?.after,
    size: size?.after,
    rotation: rotation?.after,
    scale: scale?.after,
    pivot: pivot?.after,
  );

  /// Restores changed fields on [value].
  CanvasObjectGeometry revertOn(CanvasObjectGeometry value) => value.copyWith(
    position: position?.before,
    size: size?.before,
    rotation: rotation?.before,
    scale: scale?.before,
    pivot: pivot?.before,
  );
}

/// Associates a reversible geometry patch with an object.
class CanvasGeometryChange {
  /// Creates an object geometry change.
  const CanvasGeometryChange({required this.objectId, required this.patch});

  /// The target object's stable identifier.
  final String objectId;

  /// The sparse geometry patch to apply or revert.
  final CanvasObjectGeometryPatch patch;
}

/// Associates a complete geometry value with an object.
class CanvasGeometryValue {
  /// Creates an object geometry value.
  const CanvasGeometryValue({required this.objectId, required this.geometry});

  /// The target object's stable identifier.
  final String objectId;

  /// The geometry to write.
  final CanvasObjectGeometry geometry;
}

/// Associates typed application data with an object.
class CanvasDataValue<T> {
  /// Creates an object data value.
  const CanvasDataValue({required this.objectId, required this.data});

  /// The target object's stable identifier.
  final String objectId;

  /// The application data to write.
  final T data;
}

/// The document operations required by reversible canvas actions.
abstract interface class CanvasActionTarget<T> {
  /// Returns the object with [id], or throws when it does not exist.
  CanvasObject<T> requireObject(String id);

  /// Writes complete geometry [values] to their objects.
  void writeGeometries(List<CanvasGeometryValue> values);

  /// Writes application data [values] to their objects.
  void writeData(List<CanvasDataValue<T>> values);

  /// Inserts [objects] at their stored paint-order indices.
  void insertObjects(List<IndexedCanvasObject<T>> objects);

  /// Removes every object identified by [objectIds].
  void removeObjects(List<String> objectIds);

  /// Replaces paint order with [objectIds].
  void writeObjectOrder(List<String> objectIds);
}

/// Categorizes a reversible document action.
enum CanvasActionKind {
  /// Changes object geometry.
  transform,

  /// Inserts objects.
  add,

  /// Removes objects.
  remove,

  /// Changes application-owned object data.
  data,

  /// Changes object paint order.
  reorder,

  /// Applies several actions as one history entry.
  composite,
}

/// A deterministic, reversible canvas document change.
abstract class CanvasAction<T> {
  /// Creates an action described by [label].
  const CanvasAction({required this.label});

  /// The human-readable history label.
  final String label;

  /// The action category.
  CanvasActionKind get kind;

  /// The stable identifiers affected by the action.
  List<String> get objectIds;

  /// Whether applying this action would make no change.
  bool get isEmpty;

  /// Applies the action to [target].
  void apply(CanvasActionTarget<T> target);

  /// Reverts the action on [target].
  void revert(CanvasActionTarget<T> target);
}

/// A reversible sparse geometry change for one or more objects.
class CanvasTransformAction<T> extends CanvasAction<T> {
  /// Creates a transform action, omitting empty [changes].
  CanvasTransformAction({
    required List<CanvasGeometryChange> changes,
    super.label = 'Transform',
  }) : changes = List.unmodifiable(
         changes.where((change) => !change.patch.isEmpty),
       );

  /// The geometry changes applied together.
  final List<CanvasGeometryChange> changes;

  @override
  CanvasActionKind get kind => CanvasActionKind.transform;

  @override
  List<String> get objectIds =>
      List.unmodifiable(changes.map((change) => change.objectId));

  @override
  bool get isEmpty => changes.isEmpty;

  @override
  void apply(CanvasActionTarget<T> target) => target.writeGeometries([
    for (final change in changes)
      CanvasGeometryValue(
        objectId: change.objectId,
        geometry: change.patch.applyTo(
          target.requireObject(change.objectId).geometry,
        ),
      ),
  ]);

  @override
  void revert(CanvasActionTarget<T> target) => target.writeGeometries([
    for (final change in changes)
      CanvasGeometryValue(
        objectId: change.objectId,
        geometry: change.patch.revertOn(
          target.requireObject(change.objectId).geometry,
        ),
      ),
  ]);
}

/// A reversible insertion of one or more objects.
class CanvasAddAction<T> extends CanvasAction<T> {
  /// Creates an add action for indexed [objects].
  CanvasAddAction({
    required List<IndexedCanvasObject<T>> objects,
    super.label = 'Add objects',
  }) : objects = List.unmodifiable(objects);

  /// The objects and insertion indices captured by the action.
  final List<IndexedCanvasObject<T>> objects;

  @override
  CanvasActionKind get kind => CanvasActionKind.add;

  @override
  List<String> get objectIds =>
      List.unmodifiable(objects.map((entry) => entry.object.id));

  @override
  bool get isEmpty => objects.isEmpty;

  @override
  void apply(CanvasActionTarget<T> target) => target.insertObjects(objects);

  @override
  void revert(CanvasActionTarget<T> target) => target.removeObjects(objectIds);
}

/// A reversible removal of one or more objects.
class CanvasRemoveAction<T> extends CanvasAction<T> {
  /// Creates a remove action for indexed [objects].
  CanvasRemoveAction({
    required List<IndexedCanvasObject<T>> objects,
    super.label = 'Remove objects',
  }) : objects = List.unmodifiable(objects);

  /// The objects and original indices captured by the action.
  final List<IndexedCanvasObject<T>> objects;

  @override
  CanvasActionKind get kind => CanvasActionKind.remove;

  @override
  List<String> get objectIds =>
      List.unmodifiable(objects.map((entry) => entry.object.id));

  @override
  bool get isEmpty => objects.isEmpty;

  @override
  void apply(CanvasActionTarget<T> target) => target.removeObjects(objectIds);

  @override
  void revert(CanvasActionTarget<T> target) => target.insertObjects(objects);
}

/// A reversible application-data change for one or more objects.
class CanvasDataAction<T> extends CanvasAction<T> {
  /// Creates a data action from paired [before] and [after] values.
  CanvasDataAction({
    required List<CanvasDataValue<T>> before,
    required List<CanvasDataValue<T>> after,
    super.label = 'Change objects',
  }) : assert(before.length == after.length),
       before = List.unmodifiable(before),
       after = List.unmodifiable(after);

  /// The values restored when the action is reverted.
  final List<CanvasDataValue<T>> before;

  /// The values written when the action is applied.
  final List<CanvasDataValue<T>> after;

  @override
  CanvasActionKind get kind => CanvasActionKind.data;

  @override
  List<String> get objectIds =>
      List.unmodifiable(after.map((value) => value.objectId));

  @override
  bool get isEmpty => after.isEmpty;

  @override
  void apply(CanvasActionTarget<T> target) => target.writeData(after);

  @override
  void revert(CanvasActionTarget<T> target) => target.writeData(before);
}

/// A reversible change to object paint order.
class CanvasReorderAction<T> extends CanvasAction<T> {
  /// Creates an order change from [before] to [after].
  CanvasReorderAction({
    required List<String> before,
    required List<String> after,
    super.label = 'Reorder objects',
  }) : before = List.unmodifiable(before),
       after = List.unmodifiable(after);

  /// The paint order restored by a revert.
  final List<String> before;

  /// The paint order written by an apply.
  final List<String> after;

  @override
  CanvasActionKind get kind => CanvasActionKind.reorder;

  @override
  List<String> get objectIds => after;

  @override
  bool get isEmpty => _listsEqual(before, after);

  @override
  void apply(CanvasActionTarget<T> target) => target.writeObjectOrder(after);

  @override
  void revert(CanvasActionTarget<T> target) => target.writeObjectOrder(before);
}

/// Several reversible changes represented as one history entry.
class CanvasCompositeAction<T> extends CanvasAction<T> {
  /// Creates a composite action, omitting empty [actions].
  CanvasCompositeAction({
    required List<CanvasAction<T>> actions,
    super.label = 'Edit objects',
  }) : actions = List.unmodifiable(actions.where((action) => !action.isEmpty));

  /// The child actions in application order.
  final List<CanvasAction<T>> actions;

  @override
  CanvasActionKind get kind => CanvasActionKind.composite;

  @override
  List<String> get objectIds =>
      List.unmodifiable(actions.expand((action) => action.objectIds).toSet());

  @override
  bool get isEmpty => actions.isEmpty;

  @override
  void apply(CanvasActionTarget<T> target) {
    for (final action in actions) {
      action.apply(target);
    }
  }

  @override
  void revert(CanvasActionTarget<T> target) {
    for (final action in actions.reversed) {
      action.revert(target);
    }
  }
}

bool _listsEqual<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}

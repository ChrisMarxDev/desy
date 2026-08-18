import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart' hide Image;
import 'package:undo/undo.dart';

import '../actions/canvas_action.dart';
import '../model/canvas_object.dart';
import '../model/canvas_policy.dart';
import '../snapping/canvas_snap.dart';

/// Identifies the direct-manipulation gesture active on the canvas.
enum CanvasTransformKind {
  /// Moves one or more objects in canvas coordinates.
  move,

  /// Changes one object's logical widget size.
  layoutResize,

  /// Changes one object's paint scale.
  transformScale,

  /// Rotates one object around its pivot.
  rotate,
}

/// Identifies why an action was most recently applied or reverted.
enum CanvasActionPhase {
  /// A new action was committed.
  commit,

  /// An action was reverted by undo.
  undo,

  /// A reverted action was applied again by redo.
  redo,
}

/// Reports the latest action processed by canvas history.
class CanvasActionEvent<T> {
  /// Creates an action event.
  const CanvasActionEvent({required this.action, required this.phase});

  /// The action that was processed.
  final CanvasAction<T> action;

  /// The history operation that processed [action].
  final CanvasActionPhase phase;
}

/// The sole owner of document, selection, preview, viewport, and history state.
class ObjectCanvasController<T> extends ChangeNotifier {
  /// Creates a controller for a finite canvas document.
  ///
  /// Object lists and callbacks live on the controller so the [ObjectCanvas]
  /// widget remains a replaceable view over this state.
  ObjectCanvasController({
    required Size canvasSize,
    List<CanvasObject<T>> objects = const [],
    this.defaults = const CanvasObjectDefaults(),
    this.historyLimit = 100,
    this.multiSelectionEnabled = true,
    this.onSelectionChanged,
    CanvasOverflow overflow = CanvasOverflow.deny,
    CanvasTransformMode transformMode = CanvasTransformMode.layoutResize,
    CanvasSnapConfiguration? snapConfiguration,
  }) : assert(historyLimit >= 0),
       _canvasSize = canvasSize,
       _objects = List.of(objects),
       _overflow = overflow,
       _transformMode = transformMode,
       _snapConfiguration = snapConfiguration ?? CanvasSnapConfiguration(),
       _history = ChangeStack(limit: historyLimit - 1) {
    _validateCanvasSize(canvasSize);
    _validateDocument();
    _target = _ControllerActionTarget<T>(this);
    viewportController = TransformationController();
    _rebuildSnapIndex();
  }

  /// Controller-wide object policies used when objects have no overrides.
  final CanvasObjectDefaults defaults;

  /// The maximum number of committed actions retained for undo and redo.
  final int historyLimit;

  /// Whether selection may contain more than one object.
  final bool multiSelectionEnabled;

  /// Called after the selected object identifiers change.
  final ValueChanged<Set<String>>? onSelectionChanged;
  final ChangeStack _history;
  late final CanvasActionTarget<T> _target;

  /// Controls the camera transform between viewport and canvas coordinates.
  late final TransformationController viewportController;
  GlobalKey? _renderBoundaryKey;

  Size _canvasSize;
  List<CanvasObject<T>> _objects;
  final LinkedHashSet<String> _selectedIds = LinkedHashSet();
  CanvasOverflow _overflow;
  CanvasTransformMode _transformMode;
  CanvasSnapConfiguration _snapConfiguration;
  late CanvasSnapIndex _snapIndex;
  int _snapIndexRevision = 0;
  List<CanvasSnapGuide> _snapGuides = const [];
  int _lastExaminedSnapAnchors = 0;
  _TransformSession? _transformSession;
  CanvasActionPhase _nextHistoryPhase = CanvasActionPhase.commit;
  CanvasActionEvent<T>? _lastActionEvent;

  /// The finite logical extent of the canvas.
  Size get canvasSize => _canvasSize;

  /// An immutable snapshot of objects in back-to-front paint order.
  List<CanvasObject<T>> get objects => List.unmodifiable(_objects);

  /// An immutable snapshot of selected object identifiers.
  Set<String> get selectedObjectIds => Set.unmodifiable(_selectedIds);

  /// How finite canvas bounds constrain and paint objects.
  CanvasOverflow get overflow => _overflow;

  /// Selected objects in document paint order.
  List<CanvasObject<T>> get selectedObjects => List.unmodifiable(
    _objects.where((object) => _selectedIds.contains(object.id)),
  );

  /// The active resize interpretation.
  CanvasTransformMode get transformMode => _transformMode;

  /// The snapping strategies and thresholds used for new gestures.
  CanvasSnapConfiguration get snapConfiguration => _snapConfiguration;

  /// A revision incremented whenever stable snap geometry is rebuilt.
  int get snapIndexRevision => _snapIndexRevision;

  /// Guides produced by the latest ephemeral transform preview.
  List<CanvasSnapGuide> get snapGuides => _snapGuides;

  /// The number of indexed anchors examined by the latest snap calculation.
  int get lastExaminedSnapAnchors => _lastExaminedSnapAnchors;

  /// Whether a draft-only transform gesture is active.
  bool get hasActiveTransform => _transformSession != null;

  /// Whether an earlier committed action can be reverted.
  bool get canUndo => _history.canUndo;

  /// Whether a reverted action can be applied again.
  bool get canRedo => _history.canRedo;

  /// The most recently committed, undone, or redone action event.
  CanvasActionEvent<T>? get lastActionEvent => _lastActionEvent;

  /// The current uniform camera scale.
  double get viewportScale => viewportController.value.getMaxScaleOnAxis();

  /// Renders the mounted canvas content to an image at [pixelRatio].
  ///
  /// Throws a [StateError] when no [ObjectCanvas] using this controller is
  /// mounted, and an [ArgumentError] for a non-positive pixel ratio.
  Future<Image> renderToImage({double pixelRatio = 1}) async {
    if (!pixelRatio.isFinite || pixelRatio <= 0) {
      throw ArgumentError.value(pixelRatio, 'pixelRatio', 'Must be positive.');
    }
    final boundary = _renderBoundaryKey?.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw StateError('ObjectCanvas must be mounted before rendering.');
    }
    return boundary.toImage(pixelRatio: pixelRatio);
  }

  /// Renders the mounted canvas content as PNG bytes at [pixelRatio].
  Future<Uint8List> renderPng({double pixelRatio = 1}) async {
    final image = await renderToImage(pixelRatio: pixelRatio);
    try {
      final data = await image.toByteData(format: ImageByteFormat.png);
      if (data == null) {
        throw StateError('Flutter could not encode the canvas.');
      }
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      image.dispose();
    }
  }

  @internal
  /// Attaches the render boundary owned by a mounted [ObjectCanvas].
  void attachRenderBoundary(GlobalKey key) {
    _renderBoundaryKey = key;
  }

  @internal
  /// Detaches a render boundary previously supplied by [attachRenderBoundary].
  void detachRenderBoundary(GlobalKey key) {
    if (identical(_renderBoundaryKey, key)) _renderBoundaryKey = null;
  }

  /// Returns the object with [id].
  ///
  /// Throws an [ArgumentError] when no object has that identifier.
  CanvasObject<T> requireObject(String id) {
    final index = _objects.indexWhere((object) => object.id == id);
    if (index < 0) throw ArgumentError.value(id, 'id', 'Unknown object id');
    return _objects[index];
  }

  /// Returns draft geometry during a transform, otherwise committed geometry.
  CanvasObjectGeometry geometryFor(String id) =>
      _transformSession?.drafts[id] ?? requireObject(id).geometry;

  /// Resolves object-specific constraints or the controller [defaults].
  CanvasObjectConstraints constraintsFor(String id) =>
      requireObject(id).constraints ?? defaults.constraints;

  /// Resolves object-specific capabilities or the controller [defaults].
  CanvasObjectCapabilities capabilitiesFor(String id) =>
      requireObject(id).capabilities ?? defaults.capabilities;

  /// Sets how subsequent resize handles interpret pointer movement.
  void setTransformMode(CanvasTransformMode mode) {
    if (_transformMode == mode) return;
    cancelTransform();
    _transformMode = mode;
    notifyListeners();
  }

  /// Changes how objects may cross and paint beyond the finite canvas bounds.
  ///
  /// This is a view and interaction policy, so changing it does not create a
  /// history entry. Existing object geometry is preserved.
  void setOverflow(CanvasOverflow value) {
    if (_overflow == value) return;
    cancelTransform();
    _overflow = value;
    notifyListeners();
  }

  /// Changes the finite canvas extent to [value].
  void setCanvasSize(Size value) {
    _validateCanvasSize(value);
    if (_canvasSize == value) return;
    cancelTransform();
    _canvasSize = value;
    _rebuildSnapIndex();
    notifyListeners();
  }

  /// Replaces snapping strategies and thresholds for subsequent gestures.
  void setSnapConfiguration(CanvasSnapConfiguration value) {
    if (identical(_snapConfiguration, value)) return;
    cancelTransform();
    _snapConfiguration = value;
    _rebuildSnapIndex();
    notifyListeners();
  }

  /// Selects [objectIds] according to [mode].
  ///
  /// Non-selectable objects are ignored. When [multiSelectionEnabled] is
  /// false, at most one supplied object becomes selected.
  void selectObjects(
    List<String> objectIds, {
    CanvasSelectionMode mode = CanvasSelectionMode.replace,
  }) {
    var selectable = objectIds
        .where((id) => capabilitiesFor(id).selectable)
        .toList(growable: false);
    if (!multiSelectionEnabled && selectable.length > 1) {
      selectable = [selectable.first];
    }
    final before = Set<String>.of(_selectedIds);
    switch (mode) {
      case CanvasSelectionMode.replace:
        _selectedIds
          ..clear()
          ..addAll(selectable);
      case CanvasSelectionMode.add:
        _selectedIds.addAll(selectable);
      case CanvasSelectionMode.toggle:
        for (final id in selectable) {
          if (!_selectedIds.remove(id)) _selectedIds.add(id);
        }
      case CanvasSelectionMode.remove:
        _selectedIds.removeAll(selectable);
    }
    if (!multiSelectionEnabled && _selectedIds.length > 1) {
      final selectedId = selectable.isEmpty
          ? _selectedIds.first
          : selectable.last;
      _selectedIds
        ..clear()
        ..add(selectedId);
    }
    if (!setEquals(before, _selectedIds)) _selectionDidChange();
  }

  /// Replaces the selection from host UI such as an inspector or scene panel.
  void setSelectedObjects(List<String> objectIds) => selectObjects(objectIds);

  /// Clears the current selection.
  void clearSelection() {
    if (_selectedIds.isEmpty) return;
    _selectedIds.clear();
    _selectionDidChange();
  }

  /// Adds [objects] as one undoable action, optionally starting at [atIndex].
  void addObjects(List<CanvasObject<T>> objects, {int? atIndex}) {
    if (objects.isEmpty) return;
    final existing = _objects.map((object) => object.id).toSet();
    final incoming = <String>{};
    for (final object in objects) {
      _validateObject(object);
      if (existing.contains(object.id) || !incoming.add(object.id)) {
        throw ArgumentError.value(object.id, 'objects', 'Duplicate object id');
      }
    }
    final start = (atIndex ?? _objects.length).clamp(0, _objects.length);
    perform(
      CanvasAddAction<T>(
        objects: [
          for (var index = 0; index < objects.length; index++)
            IndexedCanvasObject(index: start + index, object: objects[index]),
        ],
      ),
    );
  }

  /// Adds one application data object with canvas-owned initial placement.
  ///
  /// When [center] is supplied, the object is centered there in canvas
  /// coordinates. Otherwise [position] is used as the desired top-left, falling
  /// back to the canvas center. With [CanvasOverflow.deny], the initial bounds
  /// are clamped inside the finite canvas.
  void addObjectData({
    required String id,
    required T data,
    required Size size,
    Offset? position,
    Offset? center,
    CanvasObjectConstraints? constraints,
    CanvasObjectCapabilities? capabilities,
    int? atIndex,
    bool select = true,
  }) {
    if (position != null && center != null) {
      throw ArgumentError('Use either position or center, not both.');
    }
    final objectConstraints = constraints ?? defaults.constraints;
    final fittedSize = _fitSizeForPlacement(
      _constrainSize(size, objectConstraints),
    );
    final desiredPosition =
        position ??
        (center == null
            ? Offset(
                (_canvasSize.width - fittedSize.width) / 2,
                (_canvasSize.height - fittedSize.height) / 2,
              )
            : center - fittedSize.center(Offset.zero));
    final object = CanvasObject<T>(
      id: id,
      data: data,
      geometry: CanvasObjectGeometry(
        position: _placementPosition(desiredPosition, fittedSize),
        size: fittedSize,
      ),
      constraints: constraints,
      capabilities: capabilities,
    );
    addObjects([object], atIndex: atIndex);
    if (select) setSelectedObjects([id]);
  }

  /// Removes [objectIds] as one undoable action.
  void removeObjects(List<String> objectIds) {
    final ids = objectIds.toSet();
    if (ids.isEmpty) return;
    final removed = <IndexedCanvasObject<T>>[];
    for (var index = 0; index < _objects.length; index++) {
      final object = _objects[index];
      if (ids.contains(object.id)) {
        removed.add(IndexedCanvasObject(index: index, object: object));
      }
    }
    perform(CanvasRemoveAction<T>(objects: removed));
  }

  /// Replaces application data as one undoable action.
  void updateData(
    List<CanvasDataValue<T>> values, {
    String label = 'Change objects',
  }) {
    final before = <CanvasDataValue<T>>[];
    final after = <CanvasDataValue<T>>[];
    final seen = <String>{};
    for (final value in values) {
      if (!seen.add(value.objectId)) {
        throw ArgumentError.value(
          value.objectId,
          'values',
          'Duplicate object id',
        );
      }
      final current = requireObject(value.objectId).data;
      if (current == value.data) continue;
      before.add(CanvasDataValue(objectId: value.objectId, data: current));
      after.add(value);
    }
    perform(CanvasDataAction<T>(before: before, after: after, label: label));
  }

  /// Replaces committed geometry as one undoable action.
  void updateGeometries(
    List<CanvasGeometryValue> values, {
    String label = 'Transform',
  }) {
    final changes = <CanvasGeometryChange>[];
    final seen = <String>{};
    for (final value in values) {
      if (!seen.add(value.objectId)) {
        throw ArgumentError.value(
          value.objectId,
          'values',
          'Duplicate object id',
        );
      }
      final object = requireObject(value.objectId);
      final geometry = _normalizedGeometry(value.objectId, value.geometry);
      final patch = CanvasObjectGeometryPatch.between(
        object.geometry,
        geometry,
      );
      if (!patch.isEmpty) {
        changes.add(
          CanvasGeometryChange(objectId: value.objectId, patch: patch),
        );
      }
    }
    perform(CanvasTransformAction<T>(changes: changes, label: label));
  }

  /// Replaces paint order with [objectIds] as one undoable action.
  void reorderObjects(List<String> objectIds) {
    if (objectIds.length != _objects.length ||
        objectIds.toSet().length != _objects.length) {
      throw ArgumentError(
        'Object order must contain every object id exactly once.',
      );
    }
    for (final id in objectIds) {
      requireObject(id);
    }
    perform(
      CanvasReorderAction<T>(
        before: _objects.map((object) => object.id).toList(),
        after: objectIds,
      ),
    );
  }

  /// Moves [objectIds] above every object not in the input, preserving their
  /// relative paint order. The result is one undoable reorder action.
  void bringObjectsToFront(List<String> objectIds) {
    final ids = _validatedObjectIds(objectIds);
    if (ids.isEmpty) return;
    final moving = _objects.where((object) => ids.contains(object.id));
    final remaining = _objects.where((object) => !ids.contains(object.id));
    reorderObjects([
      ...remaining.map((object) => object.id),
      ...moving.map((object) => object.id),
    ]);
  }

  /// Moves [objectIds] below every object not in the input, preserving their
  /// relative paint order. The result is one undoable reorder action.
  void sendObjectsToBack(List<String> objectIds) {
    final ids = _validatedObjectIds(objectIds);
    if (ids.isEmpty) return;
    final moving = _objects.where((object) => ids.contains(object.id));
    final remaining = _objects.where((object) => !ids.contains(object.id));
    reorderObjects([
      ...moving.map((object) => object.id),
      ...remaining.map((object) => object.id),
    ]);
  }

  /// Moves each selected run one paint-order step toward the front.
  void moveObjectsForward(List<String> objectIds) {
    final ids = _validatedObjectIds(objectIds);
    final order = _objects.map((object) => object.id).toList();
    for (var index = order.length - 2; index >= 0; index--) {
      if (ids.contains(order[index]) && !ids.contains(order[index + 1])) {
        final value = order[index];
        order[index] = order[index + 1];
        order[index + 1] = value;
      }
    }
    reorderObjects(order);
  }

  /// Moves each selected run one paint-order step toward the back.
  void moveObjectsBackward(List<String> objectIds) {
    final ids = _validatedObjectIds(objectIds);
    final order = _objects.map((object) => object.id).toList();
    for (var index = 1; index < order.length; index++) {
      if (ids.contains(order[index]) && !ids.contains(order[index - 1])) {
        final value = order[index];
        order[index] = order[index - 1];
        order[index - 1] = value;
      }
    }
    reorderObjects(order);
  }

  /// Commits an arbitrary reversible [action] to history.
  void perform(CanvasAction<T> action) {
    if (action.isEmpty) return;
    if (_transformSession != null) {
      throw StateError('Commit or cancel the active transform first.');
    }
    _nextHistoryPhase = CanvasActionPhase.commit;
    _history.add<CanvasAction<T>>(
      Change<CanvasAction<T>>(
        action,
        () => _applyHistoryAction(action, apply: true),
        (value) => _applyHistoryAction(value, apply: false),
        description: action.label,
      ),
    );
  }

  /// Reverts the most recently committed action, when available.
  void undo() {
    if (!_history.canUndo) return;
    cancelTransform();
    _nextHistoryPhase = CanvasActionPhase.undo;
    _history.undo();
  }

  /// Reapplies the most recently reverted action, when available.
  void redo() {
    if (!_history.canRedo) return;
    cancelTransform();
    _nextHistoryPhase = CanvasActionPhase.redo;
    _history.redo();
  }

  /// Removes all undo and redo entries without changing the document.
  void clearHistory() {
    _history.clearHistory();
    notifyListeners();
  }

  /// Starts a draft-only transform. Canonical object geometry is untouched.
  void beginTransform(CanvasTransformKind kind, List<String> objectIds) {
    if (_transformSession != null) {
      throw StateError('A transform is already active.');
    }
    final uniqueIds = objectIds.toSet().toList(growable: false);
    if (uniqueIds.isEmpty) throw ArgumentError('A transform needs an object.');
    if (kind != CanvasTransformKind.move && uniqueIds.length != 1) {
      throw ArgumentError(
        'Only move supports multiple selected objects in V1.',
      );
    }
    for (final id in uniqueIds) {
      final capability = capabilitiesFor(id);
      final allowed = switch (kind) {
        CanvasTransformKind.move => capability.movable,
        CanvasTransformKind.layoutResize => capability.resizable,
        CanvasTransformKind.transformScale => capability.scalable,
        CanvasTransformKind.rotate => capability.rotatable,
      };
      if (!allowed) throw StateError('$kind is disabled for $id.');
    }
    final initial = <String, CanvasObjectGeometry>{
      for (final id in uniqueIds) id: requireObject(id).geometry,
    };
    _transformSession = _TransformSession(
      kind: kind,
      objectIds: uniqueIds,
      initial: initial,
      drafts: Map.of(initial),
      snapSession: CanvasSnapSession(
        index: _snapIndex,
        excludedObjectIds: uniqueIds.toSet(),
        configuration: _snapConfiguration,
      ),
    );
    _snapGuides = const [];
    _lastExaminedSnapAnchors = 0;
    notifyListeners();
  }

  /// Replaces draft geometries for the active transform without touching
  /// history or committed objects.
  void previewGeometries(List<CanvasGeometryValue> values) {
    final session = _transformSession;
    if (session == null) throw StateError('No transform is active.');
    for (final value in values) {
      if (!session.initial.containsKey(value.objectId)) {
        throw ArgumentError.value(
          value.objectId,
          'values',
          'Not in active transform',
        );
      }
      session.drafts[value.objectId] = _normalizedGeometry(
        value.objectId,
        value.geometry,
      );
    }
    notifyListeners();
  }

  /// Snaps and constrains [proposedBounds] for an active resize preview.
  Rect resolveResizePreview(
    String objectId,
    Rect proposedBounds, {
    required CanvasResizeEdges edges,
    double screenScale = 1,
    bool snap = true,
  }) {
    final session = _transformSession;
    if (session == null || !session.initial.containsKey(objectId)) {
      throw StateError('The object is not in an active transform.');
    }
    if (!snap) {
      _snapGuides = const [];
      _lastExaminedSnapAnchors = 0;
      return proposedBounds;
    }
    final result = const CanvasSnapEngine().resolveResize(
      session.snapSession,
      proposedBounds,
      edges: edges,
      canvasBounds: Offset.zero & _canvasSize,
      minimumSize: constraintsFor(objectId).minSize,
      screenScale: screenScale,
      constrainToCanvas: _overflow == CanvasOverflow.deny,
    );
    _snapGuides = result.guides;
    _lastExaminedSnapAnchors = result.examinedAnchors;
    return result.bounds;
  }

  /// Moves every active object by the same delta from its gesture-start value.
  void previewMoveBy(Offset delta, {double screenScale = 1, bool snap = true}) {
    final session = _transformSession;
    if (session == null || session.kind != CanvasTransformKind.move) {
      throw StateError('No move transform is active.');
    }
    var corrected = delta;
    final initialHull = _unionBounds(
      session.initial.values.map((geometry) => geometry.paintBounds),
    );
    final bounds = Offset.zero & _canvasSize;
    final proposed = initialHull.shift(delta);
    if (snap) {
      final result = const CanvasSnapEngine().resolveMove(
        session.snapSession,
        proposed,
        canvasBounds: bounds,
        screenScale: screenScale,
        constrainToCanvas: _overflow == CanvasOverflow.deny,
      );
      corrected = result.bounds.topLeft - initialHull.topLeft;
      _snapGuides = result.guides;
      _lastExaminedSnapAnchors = result.examinedAnchors;
    } else if (_overflow == CanvasOverflow.deny) {
      if (initialHull.width <= bounds.width) {
        if (proposed.left < bounds.left) {
          corrected += Offset(bounds.left - proposed.left, 0);
        }
        if (proposed.right > bounds.right) {
          corrected += Offset(bounds.right - proposed.right, 0);
        }
      }
      if (initialHull.height <= bounds.height) {
        if (proposed.top < bounds.top) {
          corrected += Offset(0, bounds.top - proposed.top);
        }
        if (proposed.bottom > bounds.bottom) {
          corrected += Offset(0, bounds.bottom - proposed.bottom);
        }
      }
    }
    if (!snap) {
      _snapGuides = const [];
      _lastExaminedSnapAnchors = 0;
    }
    for (final entry in session.initial.entries) {
      session.drafts[entry.key] = entry.value.copyWith(
        position: entry.value.position + corrected,
      );
    }
    notifyListeners();
  }

  /// Converts the final draft into exactly one history entry.
  void commitTransform({String? label}) {
    final session = _transformSession;
    if (session == null) return;
    final changes = <CanvasGeometryChange>[];
    for (final id in session.objectIds) {
      final patch = CanvasObjectGeometryPatch.between(
        session.initial[id]!,
        session.drafts[id]!,
      );
      if (!patch.isEmpty) {
        changes.add(CanvasGeometryChange(objectId: id, patch: patch));
      }
    }
    _transformSession = null;
    _snapGuides = const [];
    _lastExaminedSnapAnchors = 0;
    final action = CanvasTransformAction<T>(
      changes: changes,
      label: label ?? _labelFor(session.kind, changes.length),
    );
    if (action.isEmpty) {
      notifyListeners();
      return;
    }
    perform(action);
  }

  /// Discards the active draft transform without creating a history entry.
  void cancelTransform() {
    if (_transformSession == null) return;
    _transformSession = null;
    _snapGuides = const [];
    _lastExaminedSnapAnchors = 0;
    notifyListeners();
  }

  void _applyHistoryAction(CanvasAction<T> action, {required bool apply}) {
    if (apply) {
      action.apply(_target);
    } else {
      action.revert(_target);
    }
    if (_actionAffectsSnapIndex(action)) _rebuildSnapIndex();
    _lastActionEvent = CanvasActionEvent(
      action: action,
      phase: _nextHistoryPhase,
    );
    _nextHistoryPhase = CanvasActionPhase.commit;
    notifyListeners();
  }

  CanvasObjectGeometry _normalizedGeometry(
    String id,
    CanvasObjectGeometry value,
  ) {
    if (!value.position.dx.isFinite ||
        !value.position.dy.isFinite ||
        !value.rotation.isFinite ||
        !value.scale.isFinite ||
        value.scale <= 0) {
      throw ArgumentError.value(
        value,
        'geometry',
        'Geometry must be finite with scale > 0.',
      );
    }
    final constrained = _constrainSize(value.size, constraintsFor(id));
    return value.copyWith(size: constrained);
  }

  Size _constrainSize(Size value, CanvasObjectConstraints constraints) {
    final constrained = constraints.constrain(value);
    if (!constrained.width.isFinite ||
        !constrained.height.isFinite ||
        constrained.width <= 0 ||
        constrained.height <= 0) {
      throw ArgumentError.value(
        value,
        'geometry.size',
        'Size must be finite and positive.',
      );
    }
    return constrained;
  }

  Offset _placementPosition(Offset desiredPosition, Size size) {
    if (_overflow != CanvasOverflow.deny) return desiredPosition;
    return Offset(
      desiredPosition.dx.clamp(0, math.max(0, _canvasSize.width - size.width)),
      desiredPosition.dy.clamp(
        0,
        math.max(0, _canvasSize.height - size.height),
      ),
    );
  }

  Size _fitSizeForPlacement(Size size) {
    if (_overflow != CanvasOverflow.deny) return size;
    return Size(
      math.min(size.width, _canvasSize.width),
      math.min(size.height, _canvasSize.height),
    );
  }

  void _validateDocument() {
    final ids = <String>{};
    for (final object in _objects) {
      _validateObject(object);
      if (!ids.add(object.id)) {
        throw ArgumentError.value(object.id, 'objects', 'Duplicate object id');
      }
    }
  }

  void _validateObject(CanvasObject<T> object) {
    if (object.id.isEmpty) throw ArgumentError('Object ids must not be empty.');
    final geometry = object.geometry;
    if (!geometry.position.dx.isFinite ||
        !geometry.position.dy.isFinite ||
        !geometry.size.width.isFinite ||
        !geometry.size.height.isFinite ||
        geometry.size.width <= 0 ||
        geometry.size.height <= 0 ||
        !geometry.rotation.isFinite ||
        !geometry.scale.isFinite ||
        geometry.scale <= 0) {
      throw ArgumentError.value(
        geometry,
        'object.geometry',
        'Invalid geometry.',
      );
    }
  }

  static void _validateCanvasSize(Size size) {
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      throw ArgumentError.value(
        size,
        'canvasSize',
        'Canvas size must be finite and positive.',
      );
    }
  }

  static Rect _unionBounds(Iterable<Rect> bounds) {
    final iterator = bounds.iterator;
    if (!iterator.moveNext()) return Rect.zero;
    var result = iterator.current;
    while (iterator.moveNext()) {
      result = result.expandToInclude(iterator.current);
    }
    return result;
  }

  Set<String> _validatedObjectIds(List<String> objectIds) {
    final ids = objectIds.toSet();
    for (final id in ids) {
      requireObject(id);
    }
    return ids;
  }

  static String _labelFor(CanvasTransformKind kind, int count) =>
      switch (kind) {
        CanvasTransformKind.move => count == 1 ? 'Move object' : 'Move objects',
        CanvasTransformKind.layoutResize => 'Resize object',
        CanvasTransformKind.transformScale => 'Scale object',
        CanvasTransformKind.rotate => 'Rotate object',
      };

  bool _actionAffectsSnapIndex(CanvasAction<T> action) => switch (action.kind) {
    CanvasActionKind.transform ||
    CanvasActionKind.add ||
    CanvasActionKind.remove => true,
    CanvasActionKind.composite =>
      (action as CanvasCompositeAction<T>).actions.any(_actionAffectsSnapIndex),
    CanvasActionKind.data || CanvasActionKind.reorder => false,
  };

  void _rebuildSnapIndex() {
    final builder = CanvasSnapIndexBuilder();
    final scene = CanvasSnapScene(
      canvasBounds: Offset.zero & _canvasSize,
      objects: [
        for (final object in _objects)
          CanvasSnapSceneObject(
            id: object.id,
            bounds: object.geometry.paintBounds,
          ),
      ],
    );
    for (final strategy in _snapConfiguration.strategies) {
      strategy.buildIndex(scene, builder);
    }
    _snapIndex = builder.build();
    _snapIndexRevision++;
  }

  void _writeGeometries(List<CanvasGeometryValue> values) {
    final replacements = {
      for (final value in values) value.objectId: value.geometry,
    };
    _objects = [
      for (final object in _objects)
        if (replacements[object.id] case final geometry?)
          object.copyWith(geometry: geometry)
        else
          object,
    ];
  }

  void _writeData(List<CanvasDataValue<T>> values) {
    final replacements = {
      for (final value in values) value.objectId: value.data,
    };
    _objects = [
      for (final object in _objects)
        if (replacements.containsKey(object.id))
          object.copyWith(data: replacements[object.id] as T)
        else
          object,
    ];
  }

  void _insertObjects(List<IndexedCanvasObject<T>> values) {
    final sorted = values.toList()..sort((a, b) => a.index.compareTo(b.index));
    for (final value in sorted) {
      final index = value.index.clamp(0, _objects.length);
      _objects.insert(index, value.object);
    }
  }

  void _removeObjects(List<String> objectIds) {
    final ids = objectIds.toSet();
    _objects.removeWhere((object) => ids.contains(object.id));
    final selectedCount = _selectedIds.length;
    _selectedIds.removeAll(ids);
    if (_selectedIds.length != selectedCount) {
      _selectionDidChange(notifyControllerListeners: false);
    }
  }

  void _selectionDidChange({bool notifyControllerListeners = true}) {
    onSelectionChanged?.call(Set.unmodifiable(_selectedIds));
    if (notifyControllerListeners) notifyListeners();
  }

  void _writeObjectOrder(List<String> objectIds) {
    final byId = {for (final object in _objects) object.id: object};
    _objects = [for (final id in objectIds) byId[id]!];
  }

  @override
  void dispose() {
    viewportController.dispose();
    super.dispose();
  }
}

class _TransformSession {
  _TransformSession({
    required this.kind,
    required this.objectIds,
    required this.initial,
    required this.drafts,
    required this.snapSession,
  });

  final CanvasTransformKind kind;
  final List<String> objectIds;
  final Map<String, CanvasObjectGeometry> initial;
  final Map<String, CanvasObjectGeometry> drafts;
  final CanvasSnapSession snapSession;
}

class _ControllerActionTarget<T> implements CanvasActionTarget<T> {
  const _ControllerActionTarget(this.controller);

  final ObjectCanvasController<T> controller;

  @override
  CanvasObject<T> requireObject(String id) => controller.requireObject(id);

  @override
  void writeGeometries(List<CanvasGeometryValue> values) =>
      controller._writeGeometries(values);

  @override
  void writeData(List<CanvasDataValue<T>> values) =>
      controller._writeData(values);

  @override
  void insertObjects(List<IndexedCanvasObject<T>> objects) =>
      controller._insertObjects(objects);

  @override
  void removeObjects(List<String> objectIds) =>
      controller._removeObjects(objectIds);

  @override
  void writeObjectOrder(List<String> objectIds) =>
      controller._writeObjectOrder(objectIds);
}

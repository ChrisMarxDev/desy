// The controller is internal workbench infrastructure. Its public surface is
// intentionally documented at the type level rather than as consumer API.
// ignore_for_file: public_member_api_docs

import 'dart:collection';
import 'dart:ui';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_box_transform/flutter_box_transform.dart';
import 'package:state_beacon/state_beacon.dart';

/// The kind of local layer represented on a composition canvas.
enum DesyCanvasNodeKind { component, artboard, layout }

/// The small initial set of visual device bezels available in a composition.
enum DesyCanvasArtboard { iPhone15Pro, iPadPro11 }

/// Workbench-owned layout structures that can receive registry instances.
///
/// These are ephemeral composition aids, not consumer registry declarations or
/// a persisted screen-manifest format.
enum DesyCanvasLayoutPreset {
  singleColumn,
  twoColumn,
  threeColumnGrid,
  responsiveCardGrid,
  repeatedListRows,
  form,
}

extension DesyCanvasLayoutPresetContract on DesyCanvasLayoutPreset {
  String get label => switch (this) {
    DesyCanvasLayoutPreset.singleColumn => 'Single column',
    DesyCanvasLayoutPreset.twoColumn => 'Two-column split',
    DesyCanvasLayoutPreset.threeColumnGrid => 'Three-column grid',
    DesyCanvasLayoutPreset.responsiveCardGrid => 'Responsive card grid',
    DesyCanvasLayoutPreset.repeatedListRows => 'Repeated list rows',
    DesyCanvasLayoutPreset.form => 'Form layout',
  };

  int get slotCount => switch (this) {
    DesyCanvasLayoutPreset.singleColumn => 3,
    DesyCanvasLayoutPreset.twoColumn => 2,
    DesyCanvasLayoutPreset.threeColumnGrid => 6,
    DesyCanvasLayoutPreset.responsiveCardGrid => 6,
    DesyCanvasLayoutPreset.repeatedListRows => 4,
    DesyCanvasLayoutPreset.form => 4,
  };

  Size get initialSize => switch (this) {
    DesyCanvasLayoutPreset.singleColumn => const Size(360, 480),
    DesyCanvasLayoutPreset.twoColumn => const Size(640, 360),
    DesyCanvasLayoutPreset.threeColumnGrid => const Size(720, 440),
    DesyCanvasLayoutPreset.responsiveCardGrid => const Size(720, 440),
    DesyCanvasLayoutPreset.repeatedListRows => const Size(560, 480),
    DesyCanvasLayoutPreset.form => const Size(520, 480),
  };
}

/// The ephemeral arrangement of one layer on the canvas.
///
/// This is intentionally not a registry model and is never persisted. It is a
/// sketching aid for exploring composition, not a screen-definition format.
class DesyCanvasNode {
  DesyCanvasNode.component({
    required this.id,
    required this.instanceId,
    required this.rect,
    Map<String, Object> knobValues = const {},
    this.parentLayoutId,
    this.slotIndex,
    this.flip = Flip.none,
  }) : kind = DesyCanvasNodeKind.component,
       artboard = null,
       layoutPreset = null,
       spacingEntryId = null,
       spacing = null,
       knobValues = UnmodifiableMapView(Map.of(knobValues));

  const DesyCanvasNode.artboard({
    required this.id,
    required this.artboard,
    required this.rect,
    this.flip = Flip.none,
  }) : kind = DesyCanvasNodeKind.artboard,
       instanceId = null,
       layoutPreset = null,
       spacingEntryId = null,
       spacing = null,
       parentLayoutId = null,
       slotIndex = null,
       knobValues = const {};

  const DesyCanvasNode.layout({
    required this.id,
    required this.layoutPreset,
    required this.rect,
    required this.spacing,
    this.spacingEntryId,
    this.flip = Flip.none,
  }) : kind = DesyCanvasNodeKind.layout,
       instanceId = null,
       artboard = null,
       parentLayoutId = null,
       slotIndex = null,
       knobValues = const {};

  /// Unique local node ID. It allows the same named instance more than once.
  final String id;

  final DesyCanvasNodeKind kind;

  /// Registry-scoped ID of the component instance rendered by this node.
  final String? instanceId;

  /// Device frame rendered by a visual bezel node.
  final DesyCanvasArtboard? artboard;

  /// The selected workbench layout contract for a structural canvas node.
  final DesyCanvasLayoutPreset? layoutPreset;

  /// Stable registry ID of the spacing primitive used by a layout.
  final String? spacingEntryId;

  /// Snapshot of the consumer-declared spacing value used by a layout.
  final double? spacing;

  /// Ephemeral parent structure for a component placed into a legal slot.
  final String? parentLayoutId;

  /// Zero-based slot occupied inside [parentLayoutId].
  final int? slotIndex;

  final Rect rect;

  final Map<String, Object> knobValues;
  final Flip flip;

  DesyCanvasNode copyWith({
    Rect? rect,
    Map<String, Object>? knobValues,
    Flip? flip,
    String? spacingEntryId,
    double? spacing,
  }) => switch (kind) {
    DesyCanvasNodeKind.component => DesyCanvasNode.component(
      id: id,
      instanceId: instanceId!,
      rect: rect ?? this.rect,
      knobValues: knobValues ?? this.knobValues,
      parentLayoutId: parentLayoutId,
      slotIndex: slotIndex,
      flip: flip ?? this.flip,
    ),
    DesyCanvasNodeKind.artboard => DesyCanvasNode.artboard(
      id: id,
      artboard: artboard!,
      rect: rect ?? this.rect,
      flip: flip ?? this.flip,
    ),
    DesyCanvasNodeKind.layout => DesyCanvasNode.layout(
      id: id,
      layoutPreset: layoutPreset!,
      rect: rect ?? this.rect,
      spacingEntryId: spacingEntryId ?? this.spacingEntryId,
      spacing: spacing ?? this.spacing!,
      flip: flip ?? this.flip,
    ),
  };

  DesyCanvasNode placedIn({required String layoutId, required int slot}) {
    if (!isComponent) return this;
    return DesyCanvasNode.component(
      id: id,
      instanceId: instanceId!,
      rect: rect,
      knobValues: knobValues,
      parentLayoutId: layoutId,
      slotIndex: slot,
      flip: flip,
    );
  }

  bool get isComponent => kind == DesyCanvasNodeKind.component;
  bool get isArtboard => kind == DesyCanvasNodeKind.artboard;
  bool get isLayout => kind == DesyCanvasNodeKind.layout;
}

/// Disposable, local-only state for [DesyComponentsCanvas].
///
/// A controller can be supplied by a parent that wants the arrangement to
/// survive navigation during the current app session. Desy deliberately does
/// not write it to disk yet.
class DesyComponentsCanvasController with BeaconController {
  late final nodes = B.writable<Map<String, DesyCanvasNode>>({});
  late final selectedId = B.writable<String?>(null);
  final _nodeSignals = <String, ValueNotifier<DesyCanvasNode>>{};
  var _nextNode = 0;
  Rect? _stageBounds;

  /// The live interaction state for one existing node.
  ///
  /// The shared [nodes] map changes only when structure or committed data
  /// changes. Drag and resize frames update this node-scoped listenable so an
  /// interaction never invalidates every canvas element.
  ValueListenable<DesyCanvasNode>? nodeListenable(String nodeId) =>
      _nodeSignals[nodeId];

  DesyCanvasNode? nodeValue(String nodeId) => _nodeSignals[nodeId]?.value;

  void setStageBounds(Rect bounds) {
    final previous = _stageBounds;
    if (previous == bounds) return;
    final hasArtboards = nodes.value.values.any((node) => node.isArtboard);
    if (!_hasPositiveExtent(bounds) && hasArtboards) {
      // A zero layout pass is transitional. Keep the last usable bounds and
      // frame geometry so the next positive pass can recover exactly.
      return;
    }
    _stageBounds = bounds;
    final becameKnown = previous == null;
    final becameUsable =
        previous != null &&
        !_hasPositiveExtent(previous) &&
        _hasPositiveExtent(bounds);
    final shrank =
        previous != null &&
        (bounds.width < previous.width || bounds.height < previous.height);
    if (!becameKnown && !becameUsable && !shrank) return;

    Map<String, DesyCanvasNode>? normalized;
    for (final entry in nodes.value.entries) {
      final node = entry.value;
      if (!node.isArtboard) continue;
      final needsInitialRecovery =
          becameUsable && (node.rect.width <= 0 || node.rect.height <= 0);
      if (!needsInitialRecovery && _isContainedBy(bounds, node.rect)) continue;
      normalized ??= Map<String, DesyCanvasNode>.from(nodes.value);
      final candidate = needsInitialRecovery
          ? _readableFrameRect(node)
          : node.rect;
      normalized[entry.key] = node.copyWith(
        rect: _clampFrameToStage(candidate),
      );
    }
    if (normalized != null) _replaceNodes(normalized);
  }

  /// Adds one named instance and returns its ephemeral canvas-node ID.
  String add(String instanceId, {Map<String, Object> knobValues = const {}}) {
    final index = nodes.value.length;
    final nodeId = '$instanceId#${_nextNode++}';
    final selected = selectedId.value == null
        ? null
        : nodes.value[selectedId.value];
    final layout = selected?.isLayout == true
        ? selected
        : selected?.parentLayoutId == null
        ? null
        : nodes.value[selected!.parentLayoutId];
    final slot = layout == null ? null : _firstAvailableSlot(layout);
    final node = DesyCanvasNode.component(
      id: nodeId,
      instanceId: instanceId,
      knobValues: knobValues,
      parentLayoutId: slot == null ? null : layout!.id,
      slotIndex: slot,
      rect: Rect.fromLTWH(
        48.0 + (index % 3) * 44,
        44.0 + (index % 3) * 36,
        220,
        120,
      ),
    );
    _replaceNodes({...nodes.value, nodeId: node});
    selectedId.value = nodeId;
    return nodeId;
  }

  /// Adds one ephemeral structural layout and selects it for slot insertion.
  String addLayout(
    DesyCanvasLayoutPreset preset, {
    required double spacing,
    String? spacingEntryId,
  }) {
    final index = nodes.value.length;
    final nodeId = 'layout.${preset.name}#${_nextNode++}';
    final size = preset.initialSize;
    final node = DesyCanvasNode.layout(
      id: nodeId,
      layoutPreset: preset,
      spacingEntryId: spacingEntryId,
      spacing: spacing,
      rect: _fitRectToStage(
        Rect.fromLTWH(
          40.0 + (index % 3) * 24,
          40.0 + (index % 3) * 24,
          size.width,
          size.height,
        ),
      ),
    );
    _replaceNodes({...nodes.value, nodeId: node});
    selectedId.value = nodeId;
    return nodeId;
  }

  void setLayoutSpacing(
    String nodeId, {
    required String? spacingEntryId,
    required double spacing,
  }) {
    final node = nodes.value[nodeId];
    if (node == null || !node.isLayout) return;
    _replaceNodes({
      ...nodes.value,
      nodeId: DesyCanvasNode.layout(
        id: node.id,
        layoutPreset: node.layoutPreset!,
        rect: node.rect,
        spacingEntryId: spacingEntryId,
        spacing: spacing,
        flip: node.flip,
      ),
    });
  }

  /// Adds a device frame as one regular, selectable canvas layer.
  String addArtboard(DesyCanvasArtboard artboard) {
    final index = nodes.value.length;
    final nodeId = 'artboard.${artboard.name}#${_nextNode++}';
    final device = DesyCanvasGeometry.deviceFor(artboard);
    // A readable initial scale. Its dimensions always preserve the physical
    // frame ratio; the logical screen size is never resized.
    final initialFrameHeight = _initialFrameHeight(device);
    final size = Size(
      initialFrameHeight * device.frameSize.width / device.frameSize.height,
      initialFrameHeight,
    );
    final node = DesyCanvasNode.artboard(
      id: nodeId,
      artboard: artboard,
      rect: _clampFrameToStage(
        Rect.fromLTWH(
          72.0 + (index % 3) * 28,
          60.0 + (index % 3) * 24,
          size.width,
          size.height,
        ),
      ),
    );
    _replaceNodes({...nodes.value, nodeId: node});
    selectedId.value = nodeId;
    return nodeId;
  }

  void update(DesyCanvasNode node) {
    if (!nodes.value.containsKey(node.id)) return;
    _replaceNodes({...nodes.value, node.id: node});
  }

  /// Publishes interaction geometry to one node without rebuilding listeners
  /// of the committed node collection.
  void updateTransient(DesyCanvasNode node) {
    final signal = _nodeSignals[node.id];
    if (signal == null) return;
    signal.value = node;
  }

  /// Stores the final interaction geometry in both the node signal and the
  /// committed collection.
  void commitInteraction(DesyCanvasNode node) {
    if (!nodes.value.containsKey(node.id)) return;
    _replaceNodes({...nodes.value, node.id: node});
  }

  void select(String? componentId) => selectedId.value = componentId;

  void setKnob(String nodeId, String knobId, Object value) {
    final node = nodes.value[nodeId];
    if (node == null || !node.isComponent) return;
    update(node.copyWith(knobValues: {...node.knobValues, knobId: value}));
  }

  void remove(String nodeId) {
    if (!nodes.value.containsKey(nodeId)) return;
    final next = Map<String, DesyCanvasNode>.from(nodes.value)..remove(nodeId);
    next.removeWhere((_, node) => node.parentLayoutId == nodeId);
    _replaceNodes(next);
    if (selectedId.value == nodeId || !next.containsKey(selectedId.value)) {
      selectedId.value = null;
    }
  }

  void clear() {
    _replaceNodes({});
    selectedId.value = null;
  }

  @override
  void dispose() {
    for (final signal in _nodeSignals.values) {
      signal.dispose();
    }
    _nodeSignals.clear();
    super.dispose();
  }

  void _replaceNodes(Map<String, DesyCanvasNode> next) {
    final removedIds = _nodeSignals.keys
        .where((nodeId) => !next.containsKey(nodeId))
        .toList(growable: false);
    for (final nodeId in removedIds) {
      _nodeSignals.remove(nodeId)?.dispose();
    }
    for (final entry in next.entries) {
      final signal = _nodeSignals[entry.key];
      if (signal == null) {
        _nodeSignals[entry.key] = ValueNotifier(entry.value);
      } else if (!identical(signal.value, entry.value)) {
        signal.value = entry.value;
      }
    }
    nodes.value = next;
  }

  double _initialFrameHeight(DeviceInfo device) {
    const readableHeight = 440.0;
    final bounds = _stageBounds;
    if (bounds == null) return readableHeight;
    final ratio = device.frameSize.width / device.frameSize.height;
    // Keep the usual breathing room when it exists, but never manufacture an
    // inverted clamp range while the stage is mounting or very compact.
    final availableHeight = bounds.height >= 16
        ? bounds.height - 16
        : bounds.height;
    final availableWidth = bounds.width >= 16
        ? bounds.width - 16
        : bounds.width;
    final maximum = availableHeight < availableWidth / ratio
        ? availableHeight
        : availableWidth / ratio;
    if (!maximum.isFinite || maximum <= 0) return 0;
    return maximum >= 8
        ? readableHeight.clamp(8.0, maximum).toDouble()
        : maximum;
  }

  int? _firstAvailableSlot(DesyCanvasNode layout) {
    final occupied = {
      for (final node in nodes.value.values)
        if (node.parentLayoutId == layout.id) node.slotIndex,
    };
    for (var slot = 0; slot < layout.layoutPreset!.slotCount; slot++) {
      if (!occupied.contains(slot)) return slot;
    }
    return null;
  }

  Rect _fitRectToStage(Rect rect) {
    final bounds = _stageBounds;
    if (bounds == null || !_hasPositiveExtent(bounds)) return _finiteRect(rect);
    final scale =
        (bounds.width / rect.width).clamp(0.0, 1.0) <
            (bounds.height / rect.height).clamp(0.0, 1.0)
        ? (bounds.width / rect.width).clamp(0.0, 1.0).toDouble()
        : (bounds.height / rect.height).clamp(0.0, 1.0).toDouble();
    final size = Size(rect.width * scale, rect.height * scale);
    return Rect.fromLTWH(
      rect.left.clamp(bounds.left, bounds.right - size.width).toDouble(),
      rect.top.clamp(bounds.top, bounds.bottom - size.height).toDouble(),
      size.width,
      size.height,
    );
  }

  Rect _clampFrameToStage(Rect rect) {
    final bounds = _stageBounds;
    if (bounds == null) return _finiteRect(rect);
    if (bounds.width <= 0 || bounds.height <= 0) {
      return Rect.fromLTWH(bounds.left, bounds.top, 0, 0);
    }
    final source = _finiteRect(rect);
    final width = source.width;
    final height = source.height;
    final scale = width > 0 && height > 0
        ? (bounds.width / width).clamp(0.0, 1.0).toDouble() <
                  (bounds.height / height).clamp(0.0, 1.0).toDouble()
              ? (bounds.width / width).clamp(0.0, 1.0).toDouble()
              : (bounds.height / height).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final fittedWidth = width * scale;
    final fittedHeight = height * scale;
    return Rect.fromLTWH(
      source.left.clamp(bounds.left, bounds.right - fittedWidth).toDouble(),
      source.top.clamp(bounds.top, bounds.bottom - fittedHeight).toDouble(),
      fittedWidth,
      fittedHeight,
    );
  }

  Rect _finiteRect(Rect rect) => Rect.fromLTWH(
    rect.left.isFinite ? rect.left : 0,
    rect.top.isFinite ? rect.top : 0,
    rect.width.isFinite && rect.width > 0 ? rect.width : 0,
    rect.height.isFinite && rect.height > 0 ? rect.height : 0,
  );

  Rect _readableFrameRect(DesyCanvasNode artboard) {
    final device = DesyCanvasGeometry.deviceFor(artboard.artboard!);
    final height = _initialFrameHeight(device);
    return Rect.fromLTWH(
      artboard.rect.left,
      artboard.rect.top,
      height * device.frameSize.width / device.frameSize.height,
      height,
    );
  }

  bool _hasPositiveExtent(Rect bounds) =>
      bounds.width.isFinite &&
      bounds.height.isFinite &&
      bounds.width > 0 &&
      bounds.height > 0;

  bool _isContainedBy(Rect bounds, Rect rect) =>
      rect.left >= bounds.left &&
      rect.top >= bounds.top &&
      rect.right <= bounds.right &&
      rect.bottom <= bounds.bottom &&
      rect.width.isFinite &&
      rect.height.isFinite &&
      rect.width >= 0 &&
      rect.height >= 0;
}

/// Coordinate conversions shared by painting, hit testing, and controller
/// updates. An artboard's scene rect is always the physical frame rectangle.
class DesyCanvasGeometry {
  static DeviceInfo deviceFor(DesyCanvasArtboard artboard) =>
      switch (artboard) {
        DesyCanvasArtboard.iPhone15Pro => Devices.ios.iPhone15Pro,
        DesyCanvasArtboard.iPadPro11 => Devices.ios.iPadPro11Inches,
      };

  static Rect lockFrameAspect(
    DesyCanvasNode artboard,
    Rect proposed, {
    Rect? clampingRect,
  }) {
    final device = deviceFor(artboard.artboard!);
    final ratio = device.frameSize.width / device.frameSize.height;
    final current = artboard.rect;
    final widthDriven =
        (proposed.width - current.width).abs() >
        (proposed.height - current.height).abs() * ratio;
    var width = widthDriven
        ? proposed.width.abs()
        : proposed.height.abs() * ratio;
    var height = width / ratio;
    final rightAnchored =
        (proposed.right - current.right).abs() <
        (proposed.left - current.left).abs();
    final bottomAnchored =
        (proposed.bottom - current.bottom).abs() <
        (proposed.top - current.top).abs();
    final bounds = clampingRect;
    if (bounds == null) {
      return Rect.fromLTWH(
        rightAnchored ? current.right - width : current.left,
        bottomAnchored ? current.bottom - height : current.top,
        width.isFinite && width > 0 ? width : 0,
        height.isFinite && height > 0 ? height : 0,
      );
    }
    if (bounds.width <= 0 || bounds.height <= 0) {
      return Rect.fromLTWH(bounds.left, bounds.top, 0, 0);
    }

    // Resize around the stationary edge. Constrain the coupled size before
    // positioning so reaching a stage edge never slides that anchor.
    final stationaryX = (rightAnchored ? current.right : current.left)
        .clamp(bounds.left, bounds.right)
        .toDouble();
    final stationaryY = (bottomAnchored ? current.bottom : current.top)
        .clamp(bounds.top, bounds.bottom)
        .toDouble();
    final horizontalCapacity = rightAnchored
        ? stationaryX - bounds.left
        : bounds.right - stationaryX;
    final verticalCapacity = bottomAnchored
        ? stationaryY - bounds.top
        : bounds.bottom - stationaryY;
    final maximumWidth = horizontalCapacity < verticalCapacity * ratio
        ? horizontalCapacity
        : verticalCapacity * ratio;
    width = width.clamp(0.0, maximumWidth > 0 ? maximumWidth : 0.0).toDouble();
    height = width / ratio;
    return Rect.fromLTWH(
      rightAnchored ? stationaryX - width : stationaryX,
      bottomAnchored ? stationaryY - height : stationaryY,
      width,
      height,
    );
  }
}

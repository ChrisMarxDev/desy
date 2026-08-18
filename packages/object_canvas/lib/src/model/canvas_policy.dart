import 'dart:ui';

/// Determines how resize handles alter an object's geometry.
enum CanvasTransformMode {
  /// Changes the widget's real layout [Size].
  layoutResize,

  /// Changes only the object's paint scale, preserving layout constraints.
  transformScale,
}

/// Determines how finite canvas bounds affect objects.
enum CanvasOverflow {
  /// Keeps direct-manipulation previews inside the canvas and clips painting.
  deny,

  /// Allows geometry outside the canvas but clips painting at its bounds.
  clip,

  /// Allows geometry outside the canvas and paints it into the viewport.
  show,
}

/// Limits the logical layout size of a canvas object.
class CanvasObjectConstraints {
  /// Creates size constraints with canvas-friendly defaults.
  const CanvasObjectConstraints({
    this.minSize = const Size(24, 24),
    this.maxSize = Size.infinite,
  });

  /// The smallest permitted logical layout size.
  final Size minSize;

  /// The largest permitted logical layout size.
  final Size maxSize;

  /// Clamps [value] to the permitted width and height ranges.
  Size constrain(Size value) => Size(
    value.width.clamp(minSize.width, maxSize.width).toDouble(),
    value.height.clamp(minSize.height, maxSize.height).toDouble(),
  );
}

/// Declares which direct-manipulation operations an object supports.
class CanvasObjectCapabilities {
  /// Creates a capability set in which every operation is enabled by default.
  const CanvasObjectCapabilities({
    this.selectable = true,
    this.movable = true,
    this.resizable = true,
    this.scalable = true,
    this.rotatable = true,
  });

  /// Creates a selectable object that cannot be transformed.
  const CanvasObjectCapabilities.locked()
    : selectable = true,
      movable = false,
      resizable = false,
      scalable = false,
      rotatable = false;

  /// Whether the object can become part of the selection.
  final bool selectable;

  /// Whether the object can be moved.
  final bool movable;

  /// Whether handles can change the object's logical layout size.
  final bool resizable;

  /// Whether handles can change the object's paint scale.
  final bool scalable;

  /// Whether the object can be rotated.
  final bool rotatable;
}

/// Supplies fallback constraints and capabilities for canvas objects.
class CanvasObjectDefaults {
  /// Creates controller-wide defaults.
  const CanvasObjectDefaults({
    this.constraints = const CanvasObjectConstraints(),
    this.capabilities = const CanvasObjectCapabilities(),
  });

  /// Constraints used when an object has no override.
  final CanvasObjectConstraints constraints;

  /// Capabilities used when an object has no override.
  final CanvasObjectCapabilities capabilities;
}

/// Describes how a selection request combines with the current selection.
enum CanvasSelectionMode {
  /// Replaces the current selection.
  replace,

  /// Adds objects to the current selection.
  add,

  /// Adds unselected objects and removes selected objects.
  toggle,

  /// Removes objects from the current selection.
  remove,
}

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

/// The Flutter compilation mode that produced a widget target.
enum DesyBuildMode {
  /// Flutter debug mode, including source creation metadata.
  debug,

  /// Flutter profile mode.
  profile,

  /// Flutter release mode.
  release,
}

/// The kind of durable or human-readable signal that can identify a widget.
enum DesyWidgetSignalKind {
  /// A Flutter widget key.
  key,

  /// A stable accessibility identifier declared by a [Semantics] widget.
  semanticsIdentifier,

  /// A semantic label.
  semanticLabel,

  /// A semantic value.
  semanticValue,

  /// A semantic hint.
  semanticHint,

  /// Visible text or a tooltip associated with the target.
  visibleText,
}

/// One searchable signal an agent can use to find a selected widget in code.
@immutable
class DesyWidgetSignal {
  /// Creates an identity signal.
  const DesyWidgetSignal({required this.kind, required this.value});

  /// The signal's semantic category.
  final DesyWidgetSignalKind kind;

  /// The concise searchable value.
  final String value;

  @override
  bool operator ==(Object other) =>
      other is DesyWidgetSignal && other.kind == kind && other.value == value;

  @override
  int get hashCode => Object.hash(kind, value);
}

/// A bounded diagnostic property captured from the selected widget.
@immutable
class DesyWidgetDiagnostic {
  /// Creates a widget diagnostic property.
  const DesyWidgetDiagnostic({required this.name, required this.value});

  /// The diagnostic property name.
  final String name;

  /// A compact string representation of the property value.
  final String value;

  @override
  bool operator ==(Object other) =>
      other is DesyWidgetDiagnostic &&
      other.name == name &&
      other.value == value;

  @override
  int get hashCode => Object.hash(name, value);
}

/// A Dart source location reported by Flutter's debug widget inspector.
@immutable
class DesySourceLocation {
  /// Creates a source location.
  const DesySourceLocation({
    required this.file,
    required this.line,
    required this.column,
  });

  /// The source file URI or path.
  final String file;

  /// The one-based source line.
  final int line;

  /// The one-based source column.
  final int column;

  @override
  String toString() => '$file:$line:$column';
}

/// Metadata for the widget selected beneath the overlay.
@immutable
class DesyWidgetTarget {
  /// Creates an immutable widget target.
  DesyWidgetTarget({
    required this.buildMode,
    required this.widgetType,
    required this.description,
    required this.widgetPath,
    required List<String> ancestorWidgetTypes,
    required this.renderObjectType,
    required this.bounds,
    required this.paintBounds,
    required this.semanticBounds,
    required List<DesyWidgetSignal> identitySignals,
    required List<DesyWidgetDiagnostic> diagnostics,
    this.renderSize,
    this.layoutConstraints,
    this.stateType,
    this.sourceLocation,
    this.widgetKey,
  }) : ancestorWidgetTypes = List.unmodifiable(ancestorWidgetTypes),
       identitySignals = List.unmodifiable(identitySignals),
       diagnostics = List.unmodifiable(diagnostics);

  /// The build mode in which this target was captured.
  final DesyBuildMode buildMode;

  /// The selected widget's runtime type.
  final String widgetType;

  /// A concise, human-readable description of the widget.
  final String description;

  /// A short ancestry path ending at the selected widget.
  final String widgetPath;

  /// Nearest-first widget ancestry, bounded to a useful depth.
  final List<String> ancestorWidgetTypes;

  /// The selected State type when the target is stateful.
  final String? stateType;

  /// The RenderObject type used for hit testing and bounds.
  final String renderObjectType;

  /// Bounds in the overlay's logical coordinate system.
  final Rect bounds;

  /// The RenderObject paint bounds in its local coordinate system.
  final Rect paintBounds;

  /// The RenderObject semantic bounds in its local coordinate system.
  final Rect semanticBounds;

  /// The RenderBox size, when the selected RenderObject is a box.
  final Size? renderSize;

  /// A compact description of the RenderBox constraints, when available.
  final String? layoutConstraints;

  /// Searchable keys, semantics, and visible content.
  final List<DesyWidgetSignal> identitySignals;

  /// Bounded, non-callback diagnostic properties.
  final List<DesyWidgetDiagnostic> diagnostics;

  /// The widget's creation location in debug mode, when Flutter reports it.
  final DesySourceLocation? sourceLocation;

  /// A concise key value, when the widget has a key.
  final String? widgetKey;
}

/// Feedback captured for one selected Flutter widget.
@immutable
class DesyAnnotation {
  /// Creates an immutable annotation.
  DesyAnnotation({
    required this.target,
    required this.comment,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// The inspected widget and its metadata.
  final DesyWidgetTarget target;

  /// The user's design request.
  final String comment;

  /// When the annotation was submitted.
  final DateTime createdAt;
}

/// Consumer-owned forwarding hook for an annotation.
typedef DesyAnnotationCallback =
    FutureOr<void> Function(DesyAnnotation annotation);

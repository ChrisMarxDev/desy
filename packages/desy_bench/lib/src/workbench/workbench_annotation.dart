import 'package:flutter/widgets.dart';

/// Coordinates scoped inspection surfaces with the workbench selection layer.
///
/// The controller is owned by the shell. It exposes only the inspection root
/// geometry; it never retains consumer [Element]s across rebuilds.
class DesyWorkbenchInspectionController {
  BuildContext? _rootContext;

  /// Registers the render root used by the shell's selection outline.
  void registerRoot(BuildContext context) => _rootContext = context;

  /// Removes a root when its owning inspection layer is disposed.
  void clearRoot(BuildContext context) {
    if (identical(_rootContext, context)) _rootContext = null;
  }

  /// Converts [renderObject]'s semantic bounds into workbench coordinates.
  Rect? boundsFor(RenderObject renderObject) {
    final root = _rootContext?.findRenderObject();
    if (root == null || !root.attached || !renderObject.attached) return null;
    final bounds = MatrixUtils.transformRect(
      renderObject.getTransformTo(root),
      renderObject.semanticBounds,
    );
    return bounds.isFinite ? bounds : null;
  }
}

/// Makes shell-owned selection services available to explicitly scoped content.
///
/// This is intentionally internal workbench infrastructure. A prototype tree
/// can select a live widget, but it cannot inspect or target workbench chrome.
class DesyWorkbenchInspectionHost extends InheritedWidget {
  /// Creates a bridge between an explicitly scoped preview and shell selection.
  const DesyWorkbenchInspectionHost({
    super.key,
    required this.controller,
    required this.screenId,
    required this.target,
    required this.onTargetSelected,
    this.inspectionActive = false,
    this.onToggleInspection,
    required super.child,
  });

  /// The current inspection-root geometry service.
  final DesyWorkbenchInspectionController controller;

  /// The route that owns the active workbench surface.
  final String screenId;

  /// The shell's current live target, if one is selected.
  final DesyWorkbenchWidgetTarget? target;

  /// Applies a source-aware target selection to the shell.
  final ValueChanged<DesyWorkbenchWidgetTarget> onTargetSelected;

  /// Whether the shell is currently picking widgets for annotation.
  final bool inspectionActive;

  /// Switches the shell's annotation-picking mode when that mode is available.
  ///
  /// A canvas consumes this optional callback for its local mode dock; it does
  /// not own a second annotation state.
  final VoidCallback? onToggleInspection;

  /// Returns the nearest inspection bridge, if this content is inspectable.
  static DesyWorkbenchInspectionHost? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DesyWorkbenchInspectionHost>();

  @override
  bool updateShouldNotify(DesyWorkbenchInspectionHost oldWidget) =>
      screenId != oldWidget.screenId ||
      target != oldWidget.target ||
      controller != oldWidget.controller ||
      inspectionActive != oldWidget.inspectionActive ||
      onToggleInspection != oldWidget.onToggleInspection;
}

/// Stable artifact context supplied by an inspectable workbench region.
///
/// The value names an existing registry artifact or a temporary Workshop
/// candidate without retaining live widget state. It lets shell-owned
/// inspection identify a selected widget in language useful to a coding agent.
class DesyWorkbenchInspectionContext {
  /// Creates context for a region containing a real rendered artifact.
  const DesyWorkbenchInspectionContext({
    required this.artifactId,
    required this.kind,
    this.label,
  });

  /// Stable consumer or Workshop identity.
  final String artifactId;

  /// Human-readable artifact category, such as `Workshop candidate`.
  final String kind;

  /// Optional concise name for the artifact.
  final String? label;
}

/// Marks an inspectable subtree with stable artifact context.
///
/// This does not provide a second inspector. The workbench shell discovers
/// the nearest scope while it picks one underlying visible widget.
class DesyWorkbenchInspectionScope extends InheritedWidget {
  /// Creates one shell-readable inspection region.
  const DesyWorkbenchInspectionScope({
    super.key,
    required this.context,
    required super.child,
  });

  /// Stable context for targets inside [child].
  final DesyWorkbenchInspectionContext context;

  @override
  bool updateShouldNotify(DesyWorkbenchInspectionScope oldWidget) =>
      context.artifactId != oldWidget.context.artifactId ||
      context.kind != oldWidget.context.kind ||
      context.label != oldWidget.context.label;
}

/// Source evidence reported by Flutter's debug inspector for one widget.
///
/// The value is deliberately serializable in shape: it never retains a live
/// [Element] or [RenderObject], which would become invalid after navigation or
/// hot reload.
class DesyWorkbenchSourceLocation {
  /// Creates one source-location record.
  const DesyWorkbenchSourceLocation({
    required this.sourcePath,
    required this.line,
    required this.column,
  });

  /// Absolute Dart source path when Flutter reports one.
  final String sourcePath;

  /// One-based source line.
  final int line;

  /// One-based source column.
  final int column;

  /// Concise source reference for a human or coding agent.
  String get reference => '$sourcePath:$line:$column';

  /// Parses Flutter inspector JSON without depending on private inspector
  /// objects in the persisted target model.
  factory DesyWorkbenchSourceLocation.fromInspectorJson(
    Map<Object?, Object?> json,
  ) {
    final rawFile = json['file'];
    final line = json['line'];
    final column = json['column'];
    if (rawFile is! String || line is! num || column is! num) {
      throw const FormatException('Incomplete Flutter creation location.');
    }
    final uri = Uri.tryParse(rawFile);
    return DesyWorkbenchSourceLocation(
      sourcePath: uri?.scheme == 'file' ? uri!.toFilePath() : rawFile,
      line: line.toInt(),
      column: column.toInt(),
    );
  }
}

/// A best-effort, source-aware widget target selected in the live workbench.
class DesyWorkbenchWidgetTarget {
  /// Creates a stable description of one visible widget.
  const DesyWorkbenchWidgetTarget({
    required this.screenId,
    required this.widgetType,
    required this.description,
    required this.widgetPath,
    required this.bounds,
    this.sourceLocation,
    this.widgetKey,
    this.inspectionContext,
  });

  /// The active route when the target was selected.
  final String screenId;

  /// The exact runtime widget class.
  final String widgetType;

  /// A concise human-readable identifier for the selected widget.
  final String description;

  /// Best-effort ancestry captured from local widget creation boundaries.
  final String widgetPath;

  /// Logical bounds relative to the workbench inspection root.
  final Rect bounds;

  /// Debug creation-site evidence when Flutter can provide it.
  final DesyWorkbenchSourceLocation? sourceLocation;

  /// Flutter key evidence when the widget declares one.
  final String? widgetKey;

  /// The nearest declared artifact context, when the selected widget belongs
  /// to a scoped registry entry or Workshop candidate.
  final DesyWorkbenchInspectionContext? inspectionContext;

  /// Preferred compact target label.
  String get displayLabel => description.isEmpty ? widgetType : description;

  /// Transport-neutral evidence for storage and review exporters.
  Map<String, Object?> toJson() => {
    'screenId': screenId,
    'widgetType': widgetType,
    'description': description,
    'widgetPath': widgetPath,
    'sourcePath': sourceLocation?.sourcePath,
    'sourceLine': sourceLocation?.line,
    'sourceColumn': sourceLocation?.column,
    'widgetKey': widgetKey,
    'artifactId': inspectionContext?.artifactId,
    'artifactKind': inspectionContext?.kind,
    'artifactLabel': inspectionContext?.label,
  };
}

/// Confidence of an annotation's visual attachment after a rebuild.
enum DesyWorkbenchAnnotationAttachment {
  /// The target was selected in the current rendered widget tree.
  attached,

  /// A hot reload or route rebuild invalidated the old visual bounds.
  ///
  /// Source and widget evidence are still retained for the agent, but a person
  /// must select the live widget again before Desy treats the annotation as
  /// visually attached.
  detached,
}

/// One committed global feedback item for the current local workbench session.
class DesyWorkbenchAnnotation {
  /// Creates a committed annotation.
  const DesyWorkbenchAnnotation({
    required this.id,
    required this.target,
    required this.comment,
    required this.createdAt,
    this.attachment = DesyWorkbenchAnnotationAttachment.attached,
  });

  /// Stable in-session sequence number.
  final int id;

  /// The selected widget evidence.
  final DesyWorkbenchWidgetTarget target;

  /// The human feedback to carry into the next agent turn.
  final String comment;

  /// The local time at which the comment was committed.
  final DateTime createdAt;

  /// Whether the original render-object geometry remains trustworthy.
  final DesyWorkbenchAnnotationAttachment attachment;

  /// Returns this note with an explicitly updated visual attachment state.
  DesyWorkbenchAnnotation copyWithAttachment(
    DesyWorkbenchAnnotationAttachment attachment,
  ) => DesyWorkbenchAnnotation(
    id: id,
    target: target,
    comment: comment,
    createdAt: createdAt,
    attachment: attachment,
  );

  /// Transport-neutral annotation payload. Visual bounds are intentionally
  /// excluded because they are invalid after navigation and hot reload.
  Map<String, Object?> toJson() => {
    'id': id,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
    'attachment': attachment.name,
    'target': target.toJson(),
  };
}

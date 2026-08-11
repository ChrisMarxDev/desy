import 'dart:convert';

import 'workbench_annotation.dart';

/// Consumer-owned persistence for a local Desy annotation review.
abstract interface class DesyAnnotationStore {
  /// Loads the current local review batch.
  Future<List<DesyWorkbenchAnnotation>> load();

  /// Replaces the current local review batch.
  Future<void> save(List<DesyWorkbenchAnnotation> annotations);
}

/// A local, process-lifetime annotation store used when no persistence is set.
class DesyInMemoryAnnotationStore implements DesyAnnotationStore {
  List<DesyWorkbenchAnnotation> _annotations = const [];

  @override
  Future<List<DesyWorkbenchAnnotation>> load() async => _annotations;

  @override
  Future<void> save(List<DesyWorkbenchAnnotation> annotations) async {
    _annotations = List.unmodifiable(annotations);
  }
}

/// A configured local review and its possible export destinations.
class DesyAnnotationWorkspace {
  /// Creates an annotation workflow independent from a particular agent.
  DesyAnnotationWorkspace({
    DesyAnnotationStore? store,
    List<DesyAnnotationExporter> exporters = const [],
  }) : store = store ?? DesyInMemoryAnnotationStore(),
       exporters = List.unmodifiable(exporters);

  /// The local source of truth for review notes.
  final DesyAnnotationStore store;

  /// Optional destinations such as a file, GitHub, Slack, or an IDE bridge.
  final List<DesyAnnotationExporter> exporters;
}

/// A serializable collection of annotations sent as one review action.
class DesyAnnotationBatch {
  /// Creates one immutable review export payload.
  DesyAnnotationBatch(List<DesyWorkbenchAnnotation> annotations)
    : annotations = List.unmodifiable(annotations);

  /// Notes included in this export.
  final List<DesyWorkbenchAnnotation> annotations;

  /// Stable, transport-neutral JSON representation.
  Map<String, Object?> toJson() => {
    'annotations': [for (final annotation in annotations) annotation.toJson()],
  };

  /// Readable source-aware review text for humans and coding agents.
  String toMarkdown() => annotations
      .map((annotation) {
        final target = annotation.target;
        final source = target.sourceLocation?.reference ?? target.widgetPath;
        return '- **${target.displayLabel}** (`$source`)\n  ${annotation.comment}';
      })
      .join('\n');

  /// Encodes [toJson] for file and HTTP adapters.
  String toJsonString() => jsonEncode(toJson());
}

/// A user-configured review destination.
abstract interface class DesyAnnotationExporter {
  /// Stable exporter identity.
  String get id;

  /// User-facing action label.
  String get label;

  /// Sends a review batch to the consumer-owned destination.
  Future<DesyAnnotationExportResult> export(DesyAnnotationBatch batch);
}

/// The outcome of one annotation export attempt.
class DesyAnnotationExportResult {
  /// Creates a successful export receipt.
  const DesyAnnotationExportResult.success({this.message}) : succeeded = true;

  /// Creates a failed export receipt without throwing through the workbench.
  const DesyAnnotationExportResult.failure({required this.message})
    : succeeded = false;

  /// Whether the destination accepted the review batch.
  final bool succeeded;

  /// Optional concise receipt or error explanation.
  final String? message;
}

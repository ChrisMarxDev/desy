import 'package:desy_bench/desy_bench.dart';
import 'package:flutter/foundation.dart';

/// Sends one immutable registry-entry annotation to a consumer-owned destination.
typedef DesyAgentAnnotationSubmit =
    Future<DesyAgentAnnotationReceipt> Function(DesyAgentAnnotation annotation);

/// An immutable comment and the registry context an agent needs to act on it.
@immutable
final class DesyAgentAnnotation {
  /// Creates an annotation submission.
  DesyAgentAnnotation({
    required this.entryId,
    required this.entryName,
    required List<String> folderIds,
    required List<String> folderNames,
    required this.activeThemeId,
    required this.comment,
    required this.createdAt,
    this.sourcePath,
  }) : folderIds = List.unmodifiable(folderIds),
       folderNames = List.unmodifiable(folderNames);

  /// Snapshots the current read-only detail context for [comment].
  factory DesyAgentAnnotation.fromContext({
    required DesyDetailExtensionContext context,
    required String comment,
    required DateTime createdAt,
  }) => DesyAgentAnnotation(
    entryId: context.entry.id,
    entryName: context.entry.name,
    folderIds: context.entry.folderIds,
    folderNames: context.entry.folderNames,
    sourcePath: context.component?.source,
    activeThemeId: context.activeTheme.id,
    comment: comment,
    createdAt: createdAt,
  );

  /// Stable registry-entry declaration ID.
  final String entryId;

  /// Human-readable registry-entry name at submission time.
  final String entryName;

  /// Stable containing folder IDs from root to leaf.
  final List<String> folderIds;

  /// Human-readable containing folder names from root to leaf.
  final List<String> folderNames;

  /// Consumer-owned source path when the entry declares one.
  final String? sourcePath;

  /// Stable ID of the preview theme active at submission time.
  final String activeThemeId;

  /// Plain-text user observation for the receiving agent.
  final String comment;

  /// Time at which the extension created the submission.
  final DateTime createdAt;

  /// Human-readable entry path derived from display names only.
  String get displayPath => [...folderNames, entryName].join(' / ');
}

/// Confirmation returned by the consumer-owned annotation destination.
@immutable
final class DesyAgentAnnotationReceipt {
  /// Creates a successful submission receipt.
  const DesyAgentAnnotationReceipt({required this.message, this.location});

  /// Human-readable confirmation shown in the detail section.
  final String message;

  /// Optional local file or hosted issue location.
  final Uri? location;
}

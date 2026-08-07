import 'dart:convert';
import 'dart:io';

import 'package:desy_agent_annotations/desy_agent_annotations.dart';
import 'package:file_selector/file_selector.dart';

/// Selects the one local Markdown file that receives dogfood annotations.
typedef DesyDogfoodAnnotationFileSelector = Future<File?> Function();

/// Indicates that the annotation file Save dialog was cancelled.
final class DesyDogfoodAnnotationFileSelectionCancelled implements Exception {
  /// Creates a retryable selection cancellation.
  const DesyDogfoodAnnotationFileSelectionCancelled();

  @override
  String toString() => 'Annotation file selection was cancelled.';
}

/// Creates the platform callback used by Desy's dogfood executable.
DesyAgentAnnotationSubmit createDesyDogfoodAnnotationSubmit() {
  if (!Platform.isMacOS) {
    return (annotation) async => DesyAgentAnnotationReceipt(
      message: 'Captured a dogfood annotation for ${annotation.componentName}.',
    );
  }
  return createDesyDogfoodAnnotationFileSubmit(
    selectFile: _selectAnnotationFile,
  );
}

Future<File?> _selectAnnotationFile() async {
  final location = await getSaveLocation(
    acceptedTypeGroups: const [
      XTypeGroup(label: 'Markdown', extensions: ['md']),
    ],
    suggestedName: 'desy-agent-annotations.md',
    confirmButtonText: 'Use annotation file',
    canCreateDirectories: true,
  );
  return location == null ? null : File(location.path);
}

/// Creates a session-scoped append callback with an injectable Save dialog.
///
/// A successful selection is cached for this callback's lifetime. Writes are
/// serialized so annotations submitted from different component details cannot
/// interleave inside the shared Markdown file.
DesyAgentAnnotationSubmit createDesyDogfoodAnnotationFileSubmit({
  required DesyDogfoodAnnotationFileSelector selectFile,
}) {
  return _DesyDogfoodAnnotationFileSink(selectFile).submit;
}

final class _DesyDogfoodAnnotationFileSink {
  _DesyDogfoodAnnotationFileSink(this._selectFile);

  final DesyDogfoodAnnotationFileSelector _selectFile;
  File? _file;
  Future<void> _writeTail = Future.value();

  Future<DesyAgentAnnotationReceipt> submit(DesyAgentAnnotation annotation) {
    final write = _writeTail.then((_) => _append(annotation));
    _writeTail = write.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return write;
  }

  Future<DesyAgentAnnotationReceipt> _append(
    DesyAgentAnnotation annotation,
  ) async {
    final file = await _annotationFile();
    await file.parent.create(recursive: true);
    final isEmpty = !await file.exists() || await file.length() == 0;
    final output = file.openWrite(mode: FileMode.append, encoding: utf8);
    try {
      if (isEmpty) {
        output.writeln('# Desy agent annotations');
        output.writeln();
        output.writeln(
          'Component-scoped notes captured from the Desy dogfood workbench.',
        );
      }
      output.write(_markdownEntry(annotation));
      await output.flush();
    } finally {
      await output.close();
    }

    return DesyAgentAnnotationReceipt(
      message: 'Appended the annotation for ${annotation.componentName}.',
      location: file.absolute.uri,
    );
  }

  Future<File> _annotationFile() async {
    final cached = _file;
    if (cached != null) return cached;
    final selected = await _selectFile();
    if (selected == null) {
      throw const DesyDogfoodAnnotationFileSelectionCancelled();
    }
    _file = selected.absolute;
    return _file!;
  }
}

String _markdownEntry(DesyAgentAnnotation annotation) {
  final source = annotation.sourcePath == null
      ? 'Not declared'
      : '`${_inline(annotation.sourcePath!)}`';
  final folderIds = annotation.folderIds.isEmpty
      ? 'Root'
      : annotation.folderIds.map((id) => '`${_inline(id)}`').join(' / ');
  return '''

## ${annotation.createdAt.toUtc().toIso8601String()} — ${annotation.componentName}

- Component ID: `${_inline(annotation.componentId)}`
- Component path: ${annotation.displayPath}
- Folder IDs: $folderIds
- Source: $source
- Active theme ID: `${_inline(annotation.activeThemeId)}`

### Comment

${annotation.comment}
''';
}

String _inline(String value) => value.replaceAll('`', r'\`');

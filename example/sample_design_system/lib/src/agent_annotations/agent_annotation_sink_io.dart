import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:desy_agent_annotations/desy_agent_annotations.dart';
import 'package:file_selector/file_selector.dart';

import 'hosted_github_issue_sink.dart';

/// Selects the repository directory that receives local annotations.
typedef DesyRepositoryDirectorySelector = Future<Directory?> Function();

/// Supplies a collision-resistant filename token.
typedef DesyAgentAnnotationNonce = String Function();

/// Indicates that the user closed the repository picker without selecting one.
final class DesyRepositorySelectionCancelledException implements Exception {
  /// Creates a retryable cancellation signal.
  const DesyRepositorySelectionCancelledException();

  @override
  String toString() => 'Repository selection was cancelled.';
}

/// Uses repository-native Markdown on macOS and remains graceful elsewhere.
DesyAgentAnnotationSubmit createSampleAgentAnnotationSubmit() {
  if (!Platform.isMacOS) return createUnconfiguredHostedGitHubIssueSubmit();
  return createRepositoryFileAgentAnnotationSubmit(
    selectRepositoryRoot: _selectRepositoryRootWithPowerbox,
  );
}

Future<Directory?> _selectRepositoryRootWithPowerbox() async {
  final path = await getDirectoryPath(confirmButtonText: 'Use repository');
  return path == null ? null : Directory(path);
}

/// Creates the sample's consumer-owned repository Markdown callback.
///
/// The selected repository is canonicalized and cached only in this callback's
/// running-session state. Cancellation is not cached, so a later submission can
/// open the macOS Powerbox picker again. The [nonce] seam exists for tests;
/// production uses a secure random 128-bit value for every allocation.
DesyAgentAnnotationSubmit createRepositoryFileAgentAnnotationSubmit({
  required DesyRepositoryDirectorySelector selectRepositoryRoot,
  DesyAgentAnnotationNonce nonce = _secureNonce,
}) {
  Directory? cachedRepositoryRoot;
  Future<Directory>? inFlightSelection;

  Future<Directory> repositoryRoot() {
    final cached = cachedRepositoryRoot;
    if (cached != null) return Future.value(cached);

    return inFlightSelection ??= () async {
      try {
        final selected = await selectRepositoryRoot();
        if (selected == null) {
          throw const DesyRepositorySelectionCancelledException();
        }
        final selectedType = await FileSystemEntity.type(
          selected.path,
          followLinks: false,
        );
        if (selectedType != FileSystemEntityType.directory) {
          throw FileSystemException(
            'The selected repository root is not a directory.',
            selected.path,
          );
        }
        final canonical = Directory(await selected.resolveSymbolicLinks());
        cachedRepositoryRoot = canonical;
        return canonical;
      } finally {
        inFlightSelection = null;
      }
    }();
  }

  return (annotation) async {
    final root = await repositoryRoot();
    final directory = await _publicationDirectory(root);
    final bytes = utf8.encode(_markdown(annotation));
    File? ownedPending;
    RandomAccessFile? handle;

    try {
      ownedPending = await _claimPendingFile(directory, nonce);
      handle = await ownedPending.open(mode: FileMode.write);
      await handle.writeFrom(bytes);
      await handle.flush();
      await handle.close();
      handle = null;

      final entry = _slug(annotation.entryId);
      final timestamp = annotation.createdAt
          .toUtc()
          .toIso8601String()
          .replaceAll(RegExp('[^0-9A-Za-z]+'), '-');
      // The final name gets a new 128-bit nonce, independent of the temporary
      // claim. Publication therefore relies on UUID-style probabilistic
      // uniqueness instead of a racy exists-then-rename check.
      final finalNonce = _validNonce(nonce());
      final published = File(
        '${directory.path}${Platform.pathSeparator}'
        '$timestamp-$entry-$finalNonce.md',
      );

      // `rename` is atomic because the owned pending file lives in the
      // destination directory. The public `.md` path appears only after every
      // byte has been flushed.
      await ownedPending.rename(published.path);
      ownedPending = null;
      return DesyAgentAnnotationReceipt(
        message: 'Saved an agent annotation for ${annotation.entryName}.',
        location: published.absolute.uri,
      );
    } catch (error, stackTrace) {
      try {
        await handle?.close();
      } catch (_) {
        // Preserve the publication failure; cleanup remains best effort.
      }
      try {
        if (ownedPending != null && await ownedPending.exists()) {
          await ownedPending.delete();
        }
      } catch (_) {
        // Preserve the publication failure; cleanup remains best effort.
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  };
}

Future<Directory> _publicationDirectory(Directory canonicalRoot) async {
  final desy = Directory('${canonicalRoot.path}${Platform.pathSeparator}.desy');
  await _createAndValidateDirectory(desy);
  final annotations = Directory(
    '${desy.path}${Platform.pathSeparator}agent_annotations',
  );
  await _createAndValidateDirectory(annotations);
  return annotations;
}

Future<void> _createAndValidateDirectory(Directory directory) async {
  final initialType = await FileSystemEntity.type(
    directory.path,
    followLinks: false,
  );
  if (initialType == FileSystemEntityType.link) {
    throw FileSystemException(
      'Refusing to publish through a symbolic link.',
      directory.path,
    );
  }
  if (initialType == FileSystemEntityType.notFound) {
    await directory.create();
  } else if (initialType != FileSystemEntityType.directory) {
    throw FileSystemException(
      'The annotation path component is not a directory.',
      directory.path,
    );
  }

  final validatedType = await FileSystemEntity.type(
    directory.path,
    followLinks: false,
  );
  if (validatedType != FileSystemEntityType.directory) {
    throw FileSystemException(
      'Refusing to publish through a replaced path component.',
      directory.path,
    );
  }
  final canonical = await directory.resolveSymbolicLinks();
  if (canonical != directory.path) {
    throw FileSystemException(
      'Refusing to publish through a redirected path component.',
      directory.path,
    );
  }
}

Future<File> _claimPendingFile(
  Directory directory,
  DesyAgentAnnotationNonce nonce,
) async {
  for (var attempt = 0; attempt < 100; attempt += 1) {
    final candidate = File(
      '${directory.path}${Platform.pathSeparator}'
      '.pending-${_validNonce(nonce())}',
    );
    try {
      await candidate.create(exclusive: true);
      return candidate;
    } on FileSystemException {
      final type = await FileSystemEntity.type(
        candidate.path,
        followLinks: false,
      );
      if (type == FileSystemEntityType.notFound) rethrow;
      // Another invocation owns this path. It must never be cleaned up here.
    }
  }
  throw FileSystemException(
    'Could not allocate an annotation pending file.',
    directory.path,
  );
}

final Random _secureRandom = Random.secure();

String _secureNonce() => List.generate(
  16,
  (_) => _secureRandom.nextInt(256).toRadixString(16).padLeft(2, '0'),
).join();

String _validNonce(String value) {
  if (!RegExp(r'^[A-Za-z0-9-]{1,128}$').hasMatch(value)) {
    throw ArgumentError.value(value, 'nonce', 'Must be a filename-safe token.');
  }
  return value;
}

String _slug(String value) {
  final normalized = value
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'(^-+|-+$)'), '');
  return normalized.isEmpty ? 'entry' : normalized;
}

String _markdown(DesyAgentAnnotation annotation) {
  final source = annotation.sourcePath == null
      ? 'Not declared'
      : '`${_inline(annotation.sourcePath!)}`';
  final folderIds = annotation.folderIds.isEmpty
      ? 'Root'
      : annotation.folderIds.map((id) => '`${_inline(id)}`').join(' / ');
  return '''# Agent annotation: ${annotation.entryName}

- Entry ID: `${_inline(annotation.entryId)}`
- Entry path: ${annotation.displayPath}
- Folder IDs: $folderIds
- Source: $source
- Active theme ID: `${_inline(annotation.activeThemeId)}`
- Created at: `${annotation.createdAt.toUtc().toIso8601String()}`

## Comment

${annotation.comment}
''';
}

String _inline(String value) => value.replaceAll('`', r'\`');

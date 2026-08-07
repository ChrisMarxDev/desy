import 'dart:io';

import 'package:desy_agent_annotations/desy_agent_annotations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_design_system/sample_design_system.dart';
import 'package:sample_design_system/src/agent_annotations/agent_annotation_sink_io.dart';

void main() {
  final annotation = DesyAgentAnnotation(
    entryId: 'harbor.button/primary',
    entryName: 'Primary button',
    folderIds: const ['components', 'components.action'],
    folderNames: const ['Components', 'Action'],
    sourcePath: 'lib/src/sample_button.dart',
    activeThemeId: 'harbor.dark',
    comment: 'Increase focus contrast before release.',
    createdAt: DateTime.utc(2026, 8, 6, 14, 15),
  );

  test(
    'repository callback atomically publishes complete randomized Markdown',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'desy-agent-annotations-',
      );
      addTearDown(() => temporary.delete(recursive: true));
      final submit = createRepositoryFileAgentAnnotationSubmit(
        selectRepositoryRoot: () async => temporary,
      );

      final first = await submit(annotation);
      final second = await submit(annotation);
      final concurrent = await Future.wait(
        List.generate(12, (_) => submit(annotation)),
      );

      expect(first.location?.scheme, 'file');
      expect(second.location?.scheme, 'file');
      expect(second.location, isNot(first.location));
      expect(
        concurrent.map((receipt) => receipt.location).toSet(),
        hasLength(12),
      );
      final firstFile = File.fromUri(first.location!);
      final secondFile = File.fromUri(second.location!);
      expect(await firstFile.exists(), isTrue);
      expect(await secondFile.exists(), isTrue);
      final markdown = await firstFile.readAsString();
      expect(markdown, contains('# Agent annotation: Primary button'));
      expect(markdown, contains('`harbor.button/primary`'));
      expect(markdown, contains('Components / Action / Primary button'));
      expect(markdown, contains('`lib/src/sample_button.dart`'));
      expect(markdown, contains('`harbor.dark`'));
      expect(markdown, contains('Increase focus contrast before release.'));

      final publicationDirectory = Directory(
        '${temporary.path}${Platform.pathSeparator}.desy${Platform.pathSeparator}agent_annotations',
      );
      final published = publicationDirectory.listSync().whereType<File>();
      expect(published, hasLength(14));
      expect(
        published.every((file) => file.path.endsWith('.md')),
        isTrue,
        reason: 'No same-directory pending file may survive publication.',
      );
      for (final file in published) {
        final snapshot = await file.readAsString();
        expect(snapshot, startsWith('# Agent annotation: Primary button'));
        expect(snapshot, endsWith('Increase focus contrast before release.\n'));
      }
      expect(
        temporary.listSync().whereType<File>().where(
          (file) => file.path.endsWith('.md'),
        ),
        isEmpty,
        reason: 'The destination is fixed below .desy; it cannot traverse.',
      );
    },
  );

  test(
    'repository selection cancellation is retryable and success is cached',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'desy-agent-selection-',
      );
      addTearDown(() => temporary.delete(recursive: true));
      var selections = 0;
      final submit = createRepositoryFileAgentAnnotationSubmit(
        selectRepositoryRoot: () async {
          selections += 1;
          return selections == 1 ? null : temporary;
        },
      );

      await expectLater(
        submit(annotation),
        throwsA(isA<DesyRepositorySelectionCancelledException>()),
      );
      await submit(annotation);
      await submit(annotation);

      expect(selections, 2);
    },
  );

  test(
    'a losing pending claim never deletes the winner and final nonce is fresh',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'desy-agent-collision-',
      );
      addTearDown(() => temporary.delete(recursive: true));
      final publicationDirectory = Directory(
        '${temporary.path}${Platform.pathSeparator}.desy'
        '${Platform.pathSeparator}agent_annotations',
      );
      await publicationDirectory.create(recursive: true);
      final otherWriter = File(
        '${publicationDirectory.path}${Platform.pathSeparator}.pending-other',
      );
      await otherWriter.writeAsString('owned by another invocation');
      final nonces = ['other', 'mine', 'final'].iterator;
      final submit = createRepositoryFileAgentAnnotationSubmit(
        selectRepositoryRoot: () async => temporary,
        nonce: () {
          if (!nonces.moveNext()) throw StateError('Unexpected nonce request.');
          return nonces.current;
        },
      );

      final receipt = await submit(annotation);

      expect(await otherWriter.readAsString(), 'owned by another invocation');
      expect(
        await File(
          '${publicationDirectory.path}${Platform.pathSeparator}.pending-mine',
        ).exists(),
        isFalse,
      );
      expect(receipt.location!.pathSegments.last, endsWith('-final.md'));
    },
  );

  test(
    'existing annotation path symlinks cannot redirect publication',
    () async {
      for (final linkedComponent in ['.desy', 'agent_annotations']) {
        final temporary = await Directory.systemTemp.createTemp(
          'desy-agent-symlink-',
        );
        final outside = await Directory.systemTemp.createTemp(
          'desy-agent-outside-',
        );
        addTearDown(() => temporary.delete(recursive: true));
        addTearDown(() => outside.delete(recursive: true));

        if (linkedComponent == '.desy') {
          await Link(
            '${temporary.path}${Platform.pathSeparator}.desy',
          ).create(outside.path);
        } else {
          final desy = Directory(
            '${temporary.path}${Platform.pathSeparator}.desy',
          );
          await desy.create();
          await Link(
            '${desy.path}${Platform.pathSeparator}agent_annotations',
          ).create(outside.path);
        }
        final submit = createRepositoryFileAgentAnnotationSubmit(
          selectRepositoryRoot: () async => temporary,
        );

        await expectLater(
          submit(annotation),
          throwsA(isA<FileSystemException>()),
          reason: linkedComponent,
        );
        expect(outside.listSync(), isEmpty, reason: linkedComponent);
      }
    },
    skip: Platform.isWindows
        ? 'Symbolic-link setup requires privileges.'
        : false,
  );

  test('sample macOS executable uses sandboxed Powerbox write access', () {
    for (final path in [
      'macos/Runner/DebugProfile.entitlements',
      'macos/Runner/Release.entitlements',
    ]) {
      final entitlements = File(path).readAsStringSync();
      expect(
        entitlements,
        contains('<key>com.apple.security.app-sandbox</key>\n\t<true/>'),
        reason: path,
      );
      expect(
        entitlements,
        contains(
          '<key>com.apple.security.files.user-selected.read-write</key>'
          '\n\t<true/>',
        ),
        reason: path,
      );
    }
  });

  test(
    'hosted GitHub seam maps a fake server result to a Uri receipt',
    () async {
      DesyAgentAnnotation? received;
      final issueUri = Uri.parse(
        'https://github.com/acme/design-system/issues/123',
      );
      final submit = createHostedGitHubIssueSubmit(
        createIssue: (value) async {
          received = value;
          return DesyHostedGitHubIssue(
            message: 'Created GitHub issue #123.',
            location: issueUri,
          );
        },
      );

      final receipt = await submit(annotation);

      expect(identical(received, annotation), isTrue);
      expect(receipt.message, 'Created GitHub issue #123.');
      expect(receipt.location, issueUri);
    },
  );

  test(
    'unconfigured hosted seam fails without embedding credentials',
    () async {
      final submit = createUnconfiguredHostedGitHubIssueSubmit();
      await expectLater(submit(annotation), throwsA(isA<StateError>()));
    },
  );
}

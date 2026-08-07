import 'dart:io';

import 'package:desy_agent_annotations/desy_agent_annotations.dart';
import 'package:desy_design_system_example/src/dogfood_annotations/dogfood_annotation_sink_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'appends every annotation to one selected local Markdown file',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'desy-dogfood-annotations-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/annotations.md');
      var selections = 0;
      final submit = createDesyDogfoodAnnotationFileSubmit(
        selectFile: () async {
          selections += 1;
          return file;
        },
      );

      final receipts = await Future.wait([
        submit(
          _annotation(id: 'desy.component.button', comment: 'Check focus.'),
        ),
        submit(
          _annotation(id: 'desy.component.card', comment: 'Check spacing.'),
        ),
      ]);

      expect(selections, 1);
      expect(receipts.map((receipt) => receipt.location), {file.absolute.uri});
      final markdown = await file.readAsString();
      expect('# Desy agent annotations'.allMatches(markdown), hasLength(1));
      expect(markdown, contains('`desy.component.button`'));
      expect(markdown, contains('Check focus.'));
      expect(markdown, contains('`desy.component.card`'));
      expect(markdown, contains('Check spacing.'));
    },
  );

  test('cancelled selection can be retried', () async {
    final directory = await Directory.systemTemp.createTemp(
      'desy-dogfood-annotations-retry-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/annotations.md');
    var selections = 0;
    final submit = createDesyDogfoodAnnotationFileSubmit(
      selectFile: () async {
        selections += 1;
        return selections == 1 ? null : file;
      },
    );

    await expectLater(
      submit(_annotation(id: 'desy.component.button', comment: 'First try.')),
      throwsA(isA<DesyDogfoodAnnotationFileSelectionCancelled>()),
    );
    final receipt = await submit(
      _annotation(id: 'desy.component.button', comment: 'Second try.'),
    );

    expect(selections, 2);
    expect(receipt.location, file.absolute.uri);
    expect(await file.readAsString(), contains('Second try.'));
  });
}

DesyAgentAnnotation _annotation({
  required String id,
  required String comment,
}) => DesyAgentAnnotation(
  entryId: id,
  entryName: id.split('.').last,
  folderIds: const ['desy.components'],
  folderNames: const ['Components'],
  sourcePath: 'package:desy_design_system/src/control_aliases.dart',
  activeThemeId: 'desy.theme.light',
  comment: comment,
  createdAt: DateTime.utc(2026, 8, 7, 10),
);

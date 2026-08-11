import 'package:desy_bench/desy_bench.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('annotation batches are source-aware and transport-neutral', () {
    const target = DesyWorkbenchWidgetTarget(
      screenId: '/entries/acme.button',
      widgetType: 'AcmeButton',
      description: 'AcmeButton',
      widgetPath: 'Column > AcmeButton',
      bounds: Rect.zero,
      sourceLocation: DesyWorkbenchSourceLocation(
        sourcePath: 'lib/src/button.dart',
        line: 42,
        column: 7,
      ),
      inspectionContext: DesyWorkbenchInspectionContext(
        artifactId: 'acme.button',
        kind: 'Component',
      ),
    );
    final batch = DesyAnnotationBatch([
      DesyWorkbenchAnnotation(
        id: 1,
        target: target,
        comment: 'Increase the tap target.',
        createdAt: DateTime.utc(2026),
      ),
    ]);

    expect(batch.toJson()['annotations'], isNotEmpty);
    expect(batch.toMarkdown(), contains('lib/src/button.dart:42:7'));
    expect(batch.toMarkdown(), contains('Increase the tap target.'));
  });
}

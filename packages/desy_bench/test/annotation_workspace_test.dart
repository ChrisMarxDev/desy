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

    final payload = batch.toJson();
    final annotation =
        (payload['annotations']! as List<Object?>).single
            as Map<String, Object?>;
    final targetPayload = annotation['target']! as Map<String, Object?>;

    expect(payload['schema'], 'desy.annotation-batch.v1');
    expect(annotation['feedback'], {'text': 'Increase the tap target.'});
    expect(targetPayload['screen'], {'id': '/entries/acme.button'});
    expect(targetPayload['widget'], {
      'type': 'AcmeButton',
      'description': 'AcmeButton',
      'path': 'Column > AcmeButton',
    });
    expect(targetPayload['source'], {
      'path': 'lib/src/button.dart',
      'line': 42,
      'column': 7,
    });
    expect(targetPayload['artifact'], {
      'id': 'acme.button',
      'kind': 'Component',
    });
    expect(targetPayload['bounds'], {
      'coordinateSpace': 'workbenchInspectionRoot',
      'left': 0.0,
      'top': 0.0,
      'width': 0.0,
      'height': 0.0,
    });
    expect(batch.toMarkdown(), contains('lib/src/button.dart:42:7'));
    expect(batch.toMarkdown(), contains('Increase the tap target.'));
  });

  test('detached annotations omit stale selection bounds', () {
    final annotation = DesyWorkbenchAnnotation(
      id: 1,
      target: const DesyWorkbenchWidgetTarget(
        screenId: '/entries/acme.button',
        widgetType: 'AcmeButton',
        description: 'AcmeButton',
        widgetPath: 'Column > AcmeButton',
        bounds: Rect.fromLTWH(20, 40, 120, 48),
      ),
      comment: 'Increase the tap target.',
      createdAt: DateTime.utc(2026),
      attachment: DesyWorkbenchAnnotationAttachment.detached,
    );

    final target = annotation.toJson()['target']! as Map<String, Object?>;

    expect(target, isNot(contains('bounds')));
  });
}

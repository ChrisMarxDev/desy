import 'package:desy_design_system/desy_design_system.dart';
import 'package:desy_design_system_example/src/desy_workshop_candidates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('declares four stable activity design directions', () {
    final candidates = buildDesyWorkshopCandidates();

    expect(candidates, hasLength(4));
    expect(candidates.map((candidate) => candidate.id), [
      'desy.annotations.review-cards',
      'desy.activity.progress-trail',
      'desy.activity.grouped-run',
      'desy.activity.terminal-digest',
    ]);
  });

  testWidgets('keeps activity cards compact and outcome focused', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final candidate = buildDesyWorkshopCandidates().first;

    await tester.pumpWidget(
      MaterialApp(
        home: DesyDesignSystemScope(
          theme: DesyDesignSystemTheme.light,
          child: Center(child: Builder(builder: candidate.builder)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Building a clearer activity stream'), findsOneWidget);
    expect(find.text('Mapped the workshop surface'), findsOneWidget);
    expect(find.byType(DesyTextField), findsNothing);
  });

  testWidgets('selected progress direction uses the real design-system trail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final candidate = buildDesyWorkshopCandidates()[1];

    await tester.pumpWidget(
      MaterialApp(
        home: DesyDesignSystemScope(
          theme: DesyDesignSystemTheme.light,
          child: Center(child: Builder(builder: candidate.builder)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DesyProgressTrail), findsOneWidget);
    expect(find.bySemanticsLabel('3 of 4 steps complete'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Current: Formatting candidate source'),
      findsOneWidget,
    );
  });
}

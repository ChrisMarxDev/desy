import 'package:desy_agent_annotations/desy_agent_annotations.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:desy_design_system_example/desy_design_system_example.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('compact dogfood previews keep their natural width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildDesyDesignSystemDogfoodApp(
        onSubmit: (_) async =>
            const DesyAgentAnnotationReceipt(message: 'Saved.'),
      ),
    );
    await tester.pumpAndSettle();

    tester
        .widget<DesySidebarItem>(
          find.byKey(const ValueKey('sidebar-folder-desy.components.actions')),
        )
        .onPress!
        .call();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Button').last);
    await tester.pumpAndSettle();
    final defaultViewer = find.byKey(
      const ValueKey('detail-instance-viewer-default'),
    );
    final specimenButton = find.descendant(
      of: defaultViewer,
      matching: find.byType(DesyButton),
    );
    final defaultArtboard = find.descendant(
      of: defaultViewer,
      matching: find.byKey(const ValueKey('detail-artboard')),
    );
    expect(
      tester.getSize(specimenButton).width,
      lessThan(tester.getSize(defaultArtboard).width),
    );

    tester
        .widget<DesySidebarItem>(
          find.byKey(const ValueKey('sidebar-folder-desy.components.feedback')),
        )
        .onPress!
        .call();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Badge').last);
    await tester.pumpAndSettle();
    final badgeViewer = find.byKey(
      const ValueKey('detail-instance-viewer-default'),
    );
    expect(
      tester
          .getSize(
            find.descendant(of: badgeViewer, matching: find.byType(DesyBadge)),
          )
          .width,
      lessThan(
        tester
            .getSize(
              find.descendant(
                of: badgeViewer,
                matching: find.byKey(const ValueKey('detail-artboard')),
              ),
            )
            .width,
      ),
    );
  });

  testWidgets('launches the dogfood registry through the real workbench', (
    tester,
  ) async {
    await tester.pumpWidget(buildDesyDesignSystemDogfoodApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('DESY BENCH'), findsOneWidget);
    expect(find.text('Atlas'), findsOneWidget);
    expect(find.text('Sketch'), findsOneWidget);
    expect(find.text('Components'), findsWidgets);
  });

  testWidgets('dogfoods agent annotations in component details', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    DesyAgentAnnotation? received;

    await tester.pumpWidget(
      buildDesyDesignSystemDogfoodApp(
        onSubmit: (annotation) async {
          received = annotation;
          return const DesyAgentAnnotationReceipt(
            message: 'Queued for the dogfood agent.',
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    tester
        .widget<DesySidebarItem>(
          find.byKey(const ValueKey('sidebar-folder-desy.components.actions')),
        )
        .onPress!
        .call();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Button').last);
    await tester.pumpAndSettle();

    expect(find.text('Agent annotation'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('agent-annotation-comment')),
      'Review the dogfood button focus treatment.',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('agent-annotation-submit')));
    await tester.pumpAndSettle();

    expect(received?.entryId, 'desy.component.button');
    expect(received?.comment, 'Review the dogfood button focus treatment.');
    expect(find.text('Queued for the dogfood agent.'), findsOneWidget);
  });

  testWidgets('dogfoods agent annotations in atom details', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    DesyAgentAnnotation? received;

    await tester.pumpWidget(
      buildDesyDesignSystemDogfoodApp(
        onSubmit: (annotation) async {
          received = annotation;
          return const DesyAgentAnnotationReceipt(
            message: 'Queued atom feedback for the dogfood agent.',
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('sidebar-entry-desy.color.background')),
      findsNothing,
    );
    tester
        .widget<DesySidebarItem>(
          find.byKey(const ValueKey('sidebar-folder-desy.atoms.colors')),
        )
        .onPress!
        .call();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Background').last);
    await tester.pumpAndSettle();

    expect(find.text('Agent annotation'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('agent-annotation-comment')),
      'Review the background atom contrast.',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('agent-annotation-submit')));
    await tester.pumpAndSettle();

    expect(received?.entryId, 'desy.color.background');
    expect(received?.entryName, 'Background');
    expect(received?.folderIds, ['desy.atoms', 'desy.atoms.colors']);
    expect(received?.sourcePath, isNull);
    expect(received?.comment, 'Review the background atom contrast.');
    expect(
      find.text('Queued atom feedback for the dogfood agent.'),
      findsOneWidget,
    );
  });

  testWidgets('dogfoods registry-backed swaps and missing-link diagnostics', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildDesyDesignSystemDogfoodApp());
    await tester.pumpAndSettle();

    tester
        .widget<DesySidebarItem>(
          find.byKey(
            const ValueKey('sidebar-folder-desy.components.navigation'),
          ),
        )
        .onPress!
        .call();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tile').last);
    await tester.pumpAndSettle();

    final swapControl = find.byKey(
      const ValueKey('instance-swap-current-suffix'),
    );
    expect(swapControl, findsOneWidget);
    await tester.tap(swapControl);
    await tester.pumpAndSettle();

    final shortcutOption = find.byKey(
      const ValueKey(
        'instance-swap-option-desy.component.shortcut-label.single-key',
      ),
    );
    expect(shortcutOption, findsOneWidget);
    await tester.tap(shortcutOption);
    await tester.pumpAndSettle();

    final defaultViewer = find.byKey(
      const ValueKey('detail-instance-viewer-default'),
    );
    expect(
      find.descendant(
        of: defaultViewer,
        matching: find.byType(DesyKeyboardShortcutLabel),
      ),
      findsOneWidget,
    );

    final gallery = find.byKey(const ValueKey('detail-instance-gallery'));
    await tester.drag(gallery, const Offset(0, -2400));
    await tester.pumpAndSettle();

    final missingScenario = find.byKey(
      const ValueKey('detail-instance-viewer-scenario-missing-suffix-instance'),
    );
    expect(missingScenario, findsOneWidget);
    final missingPlaceholder = find.descendant(
      of: missingScenario,
      matching: find.text('Missing instance'),
    );
    expect(missingPlaceholder, findsOneWidget);
    await tester.tap(missingPlaceholder);
    await tester.pumpAndSettle();

    expect(find.text('Missing component instance'), findsOneWidget);
    expect(
      find.text('desy.component.unregistered-tile-suffix.missing'),
      findsOneWidget,
    );
  });
}

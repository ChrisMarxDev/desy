import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:desy_widget_workshop/desy_widget_workshop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('declares a focused standalone workspace', () {
    final extension = _extension();

    expect(extension.id, 'widget-workshop');
    expect(extension.name, 'Workshop');
    expect(
      extension.presentation,
      DesyWorkspaceExtensionPresentation.standalone,
    );
  });

  test('source locations expose concise and complete Dart anchors', () {
    final location = DesyWorkshopSourceLocation.fromInspectorJson({
      'file': Uri.file('/repo/lib/workshop_candidates.dart').toString(),
      'line': 104,
      'column': 17,
      'name': 'Text',
    });

    expect(location.displayLabel, 'workshop_candidates.dart:104:17');
    expect(location.reference, '/repo/lib/workshop_candidates.dart:104:17');
    expect(location.name, 'Text');
  });

  testWidgets('renders repository candidates under the active registry theme', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      DesyBenchApp(registry: _registry(), extensions: [_extension()]),
    );
    await tester.pumpAndSettle();

    tester
        .widget<DesySidebarItem>(
          find.byKey(const ValueKey('workspace-extension-widget-workshop')),
        )
        .onPress!();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('widget-workshop-standalone-screen')),
      findsOneWidget,
    );
    expect(find.byType(SelectionArea), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SelectionArea),
        matching: find.byKey(
          const ValueKey('widget-workshop-standalone-screen'),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('widget-workshop-sessions-sidebar')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AnimatedPositioned>(
            find.byKey(const ValueKey('widget-workshop-floating-sessions')),
          )
          .left,
      lessThan(0),
    );
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(
              const ValueKey('widget-workshop-floating-sessions-opacity'),
            ),
          )
          .opacity,
      0,
    );
    final drawerSurface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('widget-workshop-sessions-drawer-surface')),
    );
    expect((drawerSurface.decoration as BoxDecoration).boxShadow, isNull);
    expect(find.byKey(const ValueKey('widget-workshop-back')), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('widget-workshop-sessions-toggle')),
          )
          .dy,
      greaterThan(700),
    );
    await tester.tap(
      find.byKey(const ValueKey('widget-workshop-sessions-toggle')),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AnimatedPositioned>(
            find.byKey(const ValueKey('widget-workshop-floating-sessions')),
          )
          .left,
      12,
    );
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(
              const ValueKey('widget-workshop-floating-sessions-opacity'),
            ),
          )
          .opacity,
      1,
    );
    expect(find.text('Past conversations'), findsOneWidget);
    expect(find.text('No past conversations yet.'), findsOneWidget);
    expect(find.text('Focused'), findsOneWidget);
    expect(find.text('Exploratory'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('consumer-preview-theme')),
      findsNWidgets(2),
    );
    for (final candidateId in ['focused', 'exploratory']) {
      final previewCard = find.byKey(
        ValueKey('widget-workshop-generated-preview-card-$candidateId'),
      );
      expect(previewCard, findsOneWidget);
      expect(
        find.descendant(
          of: previewCard,
          matching: find.byKey(const ValueKey('consumer-preview-theme')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: previewCard,
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: previewCard,
          matching: find.byType(DesyFittedPreview),
        ),
        findsOneWidget,
      );
    }
    final promptBorder = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const ValueKey('widget-workshop-prompt-border')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect((promptBorder.decoration as BoxDecoration).border, isNotNull);
    expect(find.text('Workshop input'), findsNothing);
    expect(
      find.byKey(const ValueKey('widget-workshop-activity-panel')),
      findsOneWidget,
    );
    expect(find.byType(DesyProgressTrail), findsOneWidget);
    expect(find.text('Ready for the next iteration'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('widget-workshop-candidates-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('widget-workshop-annotation-dock')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('widget-workshop-annotation-dock')),
        matching: find.byKey(
          const ValueKey('widget-workshop-inspection-toggle'),
        ),
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Inspect widgets'), findsOneWidget);
    expect(find.text('Inspect widgets'), findsNothing);
    expect(find.text('No annotations yet.'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('widget-workshop-candidate-components')),
      findsNothing,
      reason: 'Wide exploration must not expose component drill-down yet.',
    );
  });

  testWidgets('resizes the Codex activity panel from the split rail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: DesyDesignSystemScope(
          theme: DesyDesignSystemTheme.light,
          child: Builder(
            builder: (context) => _extension().build(
              context,
              DesyWorkspaceExtensionContext(
                registry: _registry(),
                activeTheme: _registry().themes.first,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final panel = find.byKey(const ValueKey('widget-workshop-activity-panel'));
    final before = tester.getSize(panel).width;
    await tester.drag(
      find.byKey(const ValueKey('widget-workshop-activity-resizer-horizontal')),
      const Offset(80, 0),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(panel).width, greaterThan(before));
  });

  testWidgets('selects candidate context without leaving the Workshop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: DesyDesignSystemScope(
          theme: DesyDesignSystemTheme.light,
          child: Builder(
            builder: (context) => _extension().build(
              context,
              DesyWorkspaceExtensionContext(
                registry: _registry(),
                activeTheme: _registry().themes.first,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0 selected · 0 annotations'), findsOneWidget);
    await tester.tap(find.text('Focused'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected · 0 annotations'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('widget-workshop-candidate-components')),
      findsOneWidget,
    );
    expect(find.text('Prototype label'), findsOneWidget);
    expect(find.text('Prototype part'), findsOneWidget);
    expect(find.text('Fixture badge · Default'), findsOneWidget);
    expect(find.text('Registry part'), findsOneWidget);
    expect(find.text('In registry'), findsOneWidget);

    await tester.tap(find.text('Exploratory'));
    await tester.pumpAndSettle();

    expect(find.text('2 selected · 0 annotations'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('widget-workshop-candidate-components')),
      findsNothing,
      reason: 'Component drill-down requires one decided direction.',
    );
  });

  testWidgets(
    'selects a rendered widget and opens its canvas annotation dock',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: DesyDesignSystemScope(
            theme: DesyDesignSystemTheme.light,
            child: Builder(
              builder: (context) => _extension().build(
                context,
                DesyWorkspaceExtensionContext(
                  registry: _registry(),
                  activeTheme: _registry().themes.first,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('widget-workshop-inspection-toggle')),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Stop inspecting'), findsOneWidget);
      await tester.tapAt(tester.getCenter(find.text('Focused candidate')));
      await tester.pumpAndSettle();

      expect(find.text('Text("Focused candidate") selected'), findsOneWidget);
      expect(find.text('1 selected · 0 annotations'), findsOneWidget);
      expect(find.text('Annotate Text("Focused candidate")'), findsOneWidget);
      expect(
        find.textContaining('widget_workshop_extension_test.dart:'),
        findsOneWidget,
      );
      expect(
        find.text('What should change about this widget?'),
        findsOneWidget,
      );
      final selectionStatus = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('widget-workshop-selection-status')),
      );
      final selectionLabel = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('widget-workshop-selection-label')),
      );
      expect(
        (selectionStatus.decoration as BoxDecoration).color,
        DesyVisualColors.light.signal,
      );
      expect(
        (selectionLabel.decoration as BoxDecoration).color,
        DesyVisualColors.light.signal,
      );
      expect(
        tester.testTextInput.isVisible,
        isTrue,
        reason: 'Selecting a preview widget should focus annotation entry.',
      );

      await tester.tap(
        find.byKey(const ValueKey('widget-workshop-inspection-toggle')),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Inspect widgets'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('widget-workshop-selection-status')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('widget-workshop-selection-label')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('widget-workshop-annotation-dock')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('widget-workshop-annotation-input')),
        findsNothing,
      );
    },
  );

  testWidgets('commits annotations locally before a separate Codex message', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: DesyDesignSystemScope(
          theme: DesyDesignSystemTheme.light,
          child: Builder(
            builder: (context) => _extension().build(
              context,
              DesyWorkspaceExtensionContext(
                registry: _registry(),
                activeTheme: _registry().themes.first,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('widget-workshop-inspection-toggle')),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.text('Focused candidate')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('widget-workshop-annotation-input')),
      'Make this text 10 percent larger.',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('widget-workshop-commit-annotation')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Text: Make this text 10 percent larger.'),
      findsOneWidget,
    );
    expect(find.text('Focused · 1 total'), findsOneWidget);
    expect(find.text('1 selected · 1 annotations'), findsOneWidget);
    expect(find.text('Key: focused-title').hitTestable(), findsNothing);

    await tester.tap(find.text('Text: Make this text 10 percent larger.'));
    await tester.pumpAndSettle();

    expect(find.text('Key: focused-title').hitTestable(), findsOneWidget);
    expect(find.text(r'$ codex exec …'), findsNothing);
    expect(find.text('Continue with Codex'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('widget-workshop-inspection-toggle')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Text: Make this text 10 percent larger.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('widget-workshop-annotation-input')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('widget-workshop-annotation-collapse')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('widget-workshop-annotation-input')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('widget-workshop-annotation-dock')),
      findsOneWidget,
    );
  });
}

DesyWidgetWorkshopExtension _extension() => DesyWidgetWorkshopExtension(
  configuration: DesyWidgetWorkshopConfiguration(
    projectDirectory: '.',
    candidateSourcePath: 'lib/workshop_candidates.dart',
    candidates: () => [
      DesyWorkshopCandidate(
        id: 'focused',
        title: 'Focused',
        description: 'A quiet implementation.',
        builder: _focused,
        components: const [
          DesyWorkshopCandidateComponent.prototype(
            id: 'focused.prototype-label',
            title: 'Prototype label',
            description: 'A new part still being explored.',
            prototypeBuilder: _prototypePart,
          ),
          DesyWorkshopCandidateComponent.registry(
            instanceId: 'fixture.badge.default',
          ),
        ],
      ),
      DesyWorkshopCandidate(
        id: 'exploratory',
        title: 'Exploratory',
        description: 'A more expressive implementation.',
        builder: _exploratory,
      ),
    ],
  ),
);

DesyRegistry _registry() => DesyRegistry(
  name: 'Fixture system',
  themes: [
    DesyTheme(
      id: 'fixture.light',
      name: 'Fixture light',
      wrap: (context, child) => KeyedSubtree(
        key: const ValueKey('consumer-preview-theme'),
        child: child,
      ),
    ),
  ],
  components: [
    DesyStaticComponent(
      id: 'fixture.badge',
      name: 'Fixture badge',
      instances: {'default': _registryPart},
    ),
  ],
);

Widget _focused(BuildContext context) => const SizedBox(
  width: 320,
  height: 220,
  child: Center(
    child: Text('Focused candidate', key: ValueKey('focused-title')),
  ),
);

Widget _exploratory(BuildContext context) => const SizedBox(
  width: 320,
  height: 220,
  child: Center(child: Text('Exploratory candidate')),
);

Widget _prototypePart(BuildContext context) => const Text('Prototype part');

Widget _registryPart(BuildContext context) => const Text('Registry part');

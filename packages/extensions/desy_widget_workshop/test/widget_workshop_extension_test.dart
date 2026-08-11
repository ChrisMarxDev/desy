import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:desy_widget_workshop/desy_widget_workshop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('declares a registry-backed workshop session', () {
    final extension = _extension();

    expect(extension.id, 'widget-workshop');
    expect(extension.name, 'Workshop');
    expect(
      extension.presentation,
      DesyWorkspaceExtensionPresentation.workbench,
    );
    expect(extension.currentSession.title, 'Live widget exploration');
  });

  testWidgets('starts a Workshop from the Atlas home request', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      DesyBenchApp(registry: _registry(), extensions: [_extension()]),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('atlas-home-start')), findsOneWidget);
    expect(
      tester
          .widget<DesyButton>(
            find.byKey(const ValueKey('atlas-home-start-workshop')),
          )
          .onPress,
      isNull,
    );

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('atlas-home-request')),
        matching: find.byType(EditableText),
      ),
      'Explore a calmer billing summary.',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('atlas-home-start-workshop')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('widget-workshop-screen')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<DesyTextField>(
            find.byKey(const ValueKey('widget-workshop-prompt')),
          )
          .value,
      'Explore a calmer billing summary.',
    );
  });

  testWidgets('keeps the local Workshop draft while browsing the registry', (
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
    await tester.tap(
      find.byKey(const ValueKey('sidebar-session-widget-workshop')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('widget-workshop-prompt')),
        matching: find.byType(EditableText),
      ),
      'Keep this conversation when I inspect the registry.',
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('registry-atlas-nav')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('sidebar-session-widget-workshop')),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<DesyTextField>(
            find.byKey(const ValueKey('widget-workshop-prompt')),
          )
          .value,
      'Keep this conversation when I inspect the registry.',
    );
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

    expect(
      find.byKey(const ValueKey('registry-spine-agent-rail')),
      findsOneWidget,
      reason: 'Atlas keeps the chosen desktop shell’s right-side orientation.',
    );
    expect(find.text('Context: Fixture system · Fixture light'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('sidebar-session-widget-workshop')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('widget-workshop-screen')),
      findsOneWidget,
    );
    expect(find.byType(SelectionArea), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SelectionArea),
        matching: find.byKey(const ValueKey('widget-workshop-screen')),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('workbench-sidebar')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('registry-spine-top-bar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('sidebar-sessions-footer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('sidebar-session-widget-workshop')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('standalone-workspace-extension-shell')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('registry-spine-agent-rail')),
      findsNothing,
      reason: 'Workshop owns the richer live agent rail in the same location.',
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('widget-workshop-activity-panel')),
          )
          .dx,
      greaterThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('widget-workshop-candidates-panel')),
            )
            .dx,
      ),
    );
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
      find.text('Context: Fixture system · Fixture light'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('widget-workshop-candidates-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('registry-spine-toggle-inspection')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('widget-workshop-inspection-toggle')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('widget-workshop-annotation-dock')),
      findsNothing,
    );
    expect(find.text('Ready'), findsWidgets);
    expect(
      find.byKey(const ValueKey('widget-workshop-candidate-components')),
      findsNothing,
      reason: 'Wide exploration must not expose component drill-down yet.',
    );
  });

  testWidgets('collapses and restores the shell agent sidebar', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      DesyBenchApp(registry: _registry(), extensions: [_extension()]),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('registry-spine-toggle-agent-sidebar')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('registry-spine-agent-rail')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('registry-spine-toggle-agent-sidebar')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('registry-spine-toggle-agent-sidebar')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('registry-spine-agent-rail')),
      findsOneWidget,
    );
  });

  testWidgets('registry feedback starts a fresh Workshop conversation', (
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
    await tester.tap(
      find.byKey(const ValueKey('registry-spine-toggle-inspection')),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('atlas-card-fixture.badge'))),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('workbench-annotation-input')),
        matching: find.byType(EditableText),
      ),
      'Increase the visual hierarchy.',
    );
    await tester.pump();
    tester
        .widget<DesyButton>(
          find.byKey(const ValueKey('workbench-commit-annotation')),
        )
        .onPress!();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('widget-workshop-screen')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<DesyTextField>(
            find.byKey(const ValueKey('widget-workshop-prompt')),
          )
          .value,
      contains('Improve the registered component fixture.badge'),
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
      const Offset(-80, 0),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(panel).width, greaterThan(before));
  });

  testWidgets('collapses and restores the Workshop activity sidebar', (
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
      find.byKey(const ValueKey('widget-workshop-collapse-activity')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('widget-workshop-activity-panel')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey('widget-workshop-restore-activity')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('widget-workshop-activity-panel')),
      findsOneWidget,
    );
  });

  testWidgets('uses the shared workbench annotation loop for candidates', (
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
    await tester.tap(
      find.byKey(const ValueKey('sidebar-session-widget-workshop')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('registry-spine-toggle-inspection')),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('focused-title'))),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('workbench-annotation-dock')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('widget-workshop-annotation-dock')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('workbench-annotation-input')),
      findsOneWidget,
    );

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('workbench-annotation-input')),
        matching: find.byType(EditableText),
      ),
      'Make this text 10 percent larger.',
    );
    await tester.pump();
    tester
        .widget<DesyButton>(
          find.byKey(const ValueKey('workbench-commit-annotation')),
        )
        .onPress!();
    await tester.pumpAndSettle();

    expect(find.text('1 annotations'), findsOneWidget);
    expect(
      find.textContaining('Make this text 10 percent larger.'),
      findsOneWidget,
    );
    expect(find.text('2 proposals · 1 annotations'), findsOneWidget);

    await tester.tap(find.textContaining('Make this text 10 percent larger.'));
    await tester.pumpAndSettle();
    expect(find.text('Workshop candidate: Focused'), findsOneWidget);
  });

  testWidgets('keeps proposal choice in text rather than card controls', (
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

    expect(find.text('2 proposals · 0 annotations'), findsOneWidget);
    expect(find.byType(DesyCheckbox), findsNothing);
    expect(
      find.byKey(const ValueKey('widget-workshop-candidate-components')),
      findsNothing,
      reason: 'Component drill-down starts once the agent leaves one proposal.',
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

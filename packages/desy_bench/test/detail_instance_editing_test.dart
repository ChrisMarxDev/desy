import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/presentation/detail_screen.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('selecting an instance binds its knobs to that viewer', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final component = DesyComponent(
      id: 'action',
      name: 'Action',
      knobs: (k) => (
        label: k.string('label', name: 'Label', initial: 'Default'),
        enabled: k.boolean('enabled', name: 'Enabled', initial: true),
      ),
      build: (context, knobs) =>
          Text('${knobs.label.value} · ${knobs.enabled.value}'),
      instances: (knobs) => {
        'alpha': [knobs.label('Alpha')],
        'bravo': [knobs.label('Bravo')],
      },
    );
    final registry = DesyRegistry(
      name: 'Editable instances',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [component],
    );
    final entry = registry.resolve('action')!;
    final session = DesyWorkbenchSession(registry: registry)
      ..prepareEntry(entry);
    addTearDown(session.dispose);

    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.desktop,
        child: MaterialApp(
          home: Scaffold(
            body: DesyDetailScreen(session: session, entry: entry),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Editing Default'), findsOneWidget);
    expect(find.text('Default · true'), findsOneWidget);
    expect(find.text('Alpha · true'), findsOneWidget);
    expect(find.text('Bravo · true'), findsOneWidget);

    final bravoViewer = find.byKey(
      const ValueKey('detail-instance-viewer-instance-bravo'),
    );
    await tester.scrollUntilVisible(
      bravoViewer,
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('detail-instance-gallery')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(
      find.byKey(const ValueKey('detail-instance-artboard-instance-bravo')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Editing Bravo'), findsOneWidget);
    expect(session.selectedComponentInstance.value?.instanceId, 'bravo');
    expect(session.knobValues.value, {'label': 'Bravo', 'enabled': true});
    final bravoSelector = tester.widget<Semantics>(
      find.byKey(const ValueKey('detail-instance-selector-instance-bravo')),
    );
    expect(bravoSelector.properties.selected, isTrue);

    tester.widget<FSwitch>(find.byType(FSwitch)).onChange!(false);
    await tester.pumpAndSettle();

    expect(session.knobValues.value, {'label': 'Bravo', 'enabled': false});
    expect(find.text('Bravo · false'), findsOneWidget);
    expect(find.text('Default · true'), findsOneWidget);
    expect(find.text('Alpha · true'), findsOneWidget);
    expect(session.selectedComponentInstance.value?.instanceId, 'bravo');

    final alphaViewer = find.byKey(
      const ValueKey('detail-instance-viewer-instance-alpha'),
    );
    await tester.scrollUntilVisible(
      alphaViewer,
      -300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('detail-instance-gallery')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(
      find.byKey(const ValueKey('detail-instance-artboard-instance-alpha')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Editing Alpha'), findsOneWidget);
    expect(session.selectedComponentInstance.value?.instanceId, 'alpha');
    expect(session.knobValues.value, {'label': 'Alpha', 'enabled': true});
    expect(find.text('Alpha · true'), findsOneWidget);
    expect(find.text('Bravo · true'), findsOneWidget);
    expect(find.text('Bravo · false'), findsNothing);
  });
}

Widget _wrap(BuildContext context, Widget child) => child;

import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/presentation/prototypes_screen.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('selecting a prototype changes the visible widget anatomy', (
    tester,
  ) async {
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'Prototype selection',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
        prototypes: [
          DesyPrototypeSession(
            id: 'prototype.session',
            name: 'Directions',
            prototypes: const [
              DesyPrototype(
                id: 'prototype.one',
                name: 'First direction',
                builder: _firstPrototype,
              ),
              DesyPrototype(
                id: 'prototype.two',
                name: 'Second direction',
                builder: _secondPrototype,
              ),
            ],
          ),
        ],
      ),
    );
    addTearDown(session.dispose);

    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.desktop,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 1000,
            height: 800,
            child: DesyWorkbenchInspectionHost(
              controller: DesyWorkbenchInspectionController(),
              screenId: '/prototypes/prototype.session',
              target: null,
              onTargetSelected: (_) {},
              child: DesyPrototypesScreen(
                session: session,
                prototypeSession: session.registry.prototypes.single,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Text · First anatomy'), findsOneWidget);
    expect(find.text('Text · Second anatomy'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('prototype-card-prototype.two')),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Text · First anatomy'), findsNothing);
    expect(find.text('Text · Second anatomy'), findsOneWidget);
  });
}

Widget _wrap(BuildContext context, Widget child) => child;

Widget _firstPrototype(BuildContext context) =>
    const Column(children: [Text('First anatomy')]);

Widget _secondPrototype(BuildContext context) =>
    const Column(children: [Text('Second anatomy')]);

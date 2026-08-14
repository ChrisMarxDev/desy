import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/presentation/desy_drag_box.dart';
import 'package:desy_bench/src/workbench/presentation/prototypes_screen.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'prototype sessions use canvas drag boxes and prototype-specific details',
    (tester) async {
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
                  description: 'A calmer visual direction.',
                  builder: _secondPrototype,
                ),
              ],
            ),
          ],
        ),
      );
      addTearDown(session.dispose);

      await tester.pumpWidget(
        _PrototypeHarness(
          child: DesyPrototypesScreen(
            session: session,
            prototypeSession: session.registry.prototypes.single,
          ),
        ),
      );
      await tester.pumpAndSettle();

      const prefix = 'prototypes-canvas-prototype.session';
      expect(find.byKey(const ValueKey('$prefix-viewport')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('$prefix-item-prototype.one')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('$prefix-item-prototype.two')),
        findsOneWidget,
      );
      expect(find.byType(DesyDragBox), findsNWidgets(2));
      expect(
        find.byKey(const ValueKey('prototypes-canvas-inspector')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('$prefix-content-prototype.two')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('prototypes-canvas-inspector')),
        findsOneWidget,
      );
      expect(find.text('Direction'), findsOneWidget);
      expect(find.text('prototype.two'), findsOneWidget);
      expect(find.text('A calmer visual direction.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('$prefix-selection-size-prototype.two')),
        findsOneWidget,
      );
    },
  );

  testWidgets('prototype canvas keeps a sensible initial drag-box size', (
    tester,
  ) async {
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'Prototype sizing',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
        prototypes: [
          DesyPrototypeSession(
            id: 'prototype.sizing',
            name: 'Directions',
            prototypes: const [
              DesyPrototype(
                id: 'prototype.sizing.one',
                name: 'Narrow direction',
                builder: _firstPrototype,
              ),
            ],
          ),
        ],
      ),
    );
    addTearDown(session.dispose);

    await tester.pumpWidget(
      _PrototypeHarness(
        width: 1000,
        height: 1200,
        child: DesyPrototypesScreen(
          session: session,
          prototypeSession: session.registry.prototypes.single,
        ),
      ),
    );
    await tester.pumpAndSettle();

    const prefix = 'prototypes-canvas-prototype.sizing';
    final frame = tester.getRect(
      find.byKey(const ValueKey('$prefix-frame-prototype.sizing.one')),
    );
    expect(frame.width, 380);
    expect(frame.height, 620);
  });
}

class _PrototypeHarness extends StatelessWidget {
  const _PrototypeHarness({
    required this.child,
    this.width = 1000,
    this.height = 800,
  });

  final Widget child;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => FTheme(
    data: FTheme.neutral.light.desktop,
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(width: width, height: height, child: child),
    ),
  );
}

Widget _wrap(BuildContext context, Widget child) => child;

Widget _firstPrototype(BuildContext context) =>
    const Column(children: [Text('First anatomy')]);

Widget _secondPrototype(BuildContext context) =>
    const Column(children: [Text('Second anatomy')]);

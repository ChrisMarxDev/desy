import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/presentation/measures_screen.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Measurements compare each typed kind in its own visual board', (
    tester,
  ) async {
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'Measurement boards',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
        measurements: const [
          DesyNumericEntry.spacing(
            id: 'space.content',
            name: 'Content gap',
            value: 24,
          ),
          DesyNumericEntry.radius(
            id: 'radius.panel',
            name: 'Panel radius',
            value: 16,
          ),
          DesyNumericEntry.breakpoint(
            id: 'breakpoint.compact',
            name: 'Compact threshold',
            value: 760,
          ),
        ],
      ),
    );
    addTearDown(session.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: FTheme(
          data: FTheme.neutral.light.desktop,
          child: DesyMeasuresScreen(
            session: session,
            measurements: session.registry.measurements,
          ),
        ),
      ),
    );

    for (final kind in [DesyNumericKind.spacing, DesyNumericKind.radius]) {
      expect(
        find.byKey(ValueKey('measurements-kind-${kind.name}')),
        findsOneWidget,
      );
    }
    for (final id in ['space.content', 'radius.panel']) {
      expect(find.byKey(ValueKey('measurement-$id')), findsOneWidget);
    }
    expect(
      find.text('Compare the gaps and insets that establish layout rhythm.'),
      findsOneWidget,
    );

    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('measurements-kind-breakpoint')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('measurement-breakpoint.compact')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Compare responsive thresholds across a shared viewport range.',
      ),
      findsOneWidget,
    );
    expect(find.text('320 dp'), findsOneWidget);
    expect(find.text('1440 dp'), findsOneWidget);
  });
}

Widget _wrap(BuildContext context, Widget child) => child;

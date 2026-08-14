import 'package:desy_bench/src/workbench/presentation/detail_screen.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:desy_design_system_example/desy_design_system_example.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dogfood motion autoplays the supplied signal square', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = DesyWorkbenchSession(registry: desyDesignSystemRegistry);
    addTearDown(session.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: FTheme(
          data: FTheme.neutral.light.desktop,
          child: DesyDetailScreen(
            session: session,
            entry: desyDesignSystemRegistry.resolve('desy.motion.navigation')!,
          ),
        ),
      ),
    );

    final specimen = find.byKey(const ValueKey('dogfood-motion-specimen'));
    final initialLeft = tester.getTopLeft(specimen).dx;
    await tester.pump(const Duration(milliseconds: 45));
    await tester.pump(const Duration(milliseconds: 16));
    final animatedLeft = tester.getTopLeft(specimen).dx;

    expect(animatedLeft, lessThan(initialLeft));
    expect(find.byIcon(DesyIcons.sparkles), findsOneWidget);
    final decoration =
        tester.widget<Container>(specimen).decoration! as BoxDecoration;
    expect(decoration.color, isNotNull);
  });
}

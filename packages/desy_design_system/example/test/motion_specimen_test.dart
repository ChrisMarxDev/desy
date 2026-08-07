import 'package:desy_bench/src/workbench/presentation/detail_screen.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:desy_design_system_example/desy_design_system_example.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dogfood motion autoplays with legible foreground contrast', (
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
    final initialWidth = tester.getSize(specimen).width;
    await tester.pump(const Duration(milliseconds: 45));
    final animatedWidth = tester.getSize(specimen).width;

    expect(animatedWidth, greaterThan(initialWidth));
    expect(find.text('Motion preview'), findsOneWidget);
    final label = tester.widget<Text>(find.text('Motion preview'));
    final decoration =
        tester.widget<Container>(specimen).decoration! as BoxDecoration;
    expect(label.style?.color, isNot(decoration.color));
  });
}

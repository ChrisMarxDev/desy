import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/presentation/detail_screen.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:desy_design_system_example/desy_design_system_example.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dogfood registers scrub-friendly motion as normal components', () {
    final sidebar = desyDesignSystemRegistry.resolve(
      'desy.motion.sidebar-reveal',
    )!;
    final contentSwap = desyDesignSystemRegistry.resolve(
      'desy.motion.content-swap',
    )!;
    final screenNavigation = desyDesignSystemRegistry.resolve(
      'desy.motion.screen-navigation',
    )!;

    expect(sidebar.component, isNotNull);
    expect(contentSwap.component, isNotNull);
    expect(screenNavigation.component, isNotNull);
    expect(sidebar.component, isA<DesyAnimationComponentBase>());
    expect(contentSwap.component, isA<DesyAnimationComponentBase>());
    expect(screenNavigation.component, isA<DesyAnimationComponentBase>());
  });

  testWidgets(
    'dogfood motion components own their hardcoded specimen widgets',
    (tester) async {
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
              entry: desyDesignSystemRegistry.resolve(
                'desy.motion.navigation',
              )!,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));

      expect(find.text('Inspect component'), findsOneWidget);
      expect(find.text('STABLE'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('motion-transition-instance-menu')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('motion-specimen-select')),
        findsNothing,
      );
      expect(find.text('Inspect component'), findsOneWidget);
      expect(find.text('STABLE'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 45));
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Inspect component'), findsOneWidget);
    },
  );
}

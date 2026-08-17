import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/presentation/detail_screen.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:desy_design_system_example/desy_design_system_example.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dogfood registers reusable workbench motion patterns', () {
    final sidebar = desyDesignSystemRegistry.resolve(
      'desy.motion.sidebar-reveal',
    )!;
    final contentSwap = desyDesignSystemRegistry.resolve(
      'desy.motion.content-swap',
    )!;
    final screenNavigation = desyDesignSystemRegistry.resolve(
      'desy.motion.screen-navigation',
    )!;

    expect(sidebar.source, isA<DesyMotionEntry>());
    expect((contentSwap.source as DesyMotionEntry).supportsTransition, isTrue);
    expect(
      (screenNavigation.source as DesyMotionEntry).supportsTransition,
      isTrue,
    );
  });

  testWidgets('dogfood motion exposes transition instance controls', (
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.text('Inspect component'), findsOneWidget);
    expect(find.text('STABLE'), findsOneWidget);
    final instanceMenu = find.byKey(
      const ValueKey('motion-transition-instance-menu'),
    );
    expect(instanceMenu, findsOneWidget);
    await tester.ensureVisible(instanceMenu);
    await tester.tap(
      find.descendant(of: instanceMenu, matching: find.byType(DesyButton)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Transition instances'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('motion-transition-instance-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('motion-transition-instance-2')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 45));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('Inspect component'), findsOneWidget);
  });
}

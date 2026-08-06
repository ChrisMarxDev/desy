import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/workbench_router.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

void main() {
  testWidgets(
    'the transformable sketch disables the workbench selection surface',
    (tester) async {
      final session = DesyWorkbenchSession(registry: _registry);
      final router = createDesyWorkbenchRouter(session);
      addTearDown(router.dispose);
      addTearDown(session.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => FTheme(
            data: FTheme.neutral.light.desktop,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectionArea), findsOneWidget);

      router.go('/atlas/sketch');
      await tester.pumpAndSettle();

      expect(find.text('Screen sketch'), findsOneWidget);
      expect(find.byType(SelectionArea), findsOneWidget);
      final disabledCanvas = tester.widget<SelectionContainer>(
        find.byKey(const ValueKey('sketch-selection-disabled')),
      );
      expect(disabledCanvas.delegate, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a compact workbench never mounts document selection', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = DesyWorkbenchSession(registry: _registry);
    final router = createDesyWorkbenchRouter(session);
    addTearDown(router.dispose);
    addTearDown(session.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => FTheme(
          data: FTheme.neutral.light.desktop,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SelectionArea), findsNothing);

    router.go('/atlas/sketch');
    await tester.pumpAndSettle();
    expect(find.text('Screen sketch'), findsOneWidget);
    expect(find.byType(SelectionArea), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

final _registry = DesyRegistry(
  name: 'Selection surface',
  themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
);

Widget _wrap(BuildContext context, Widget child) => child;

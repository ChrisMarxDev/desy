import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'missing instance renders an interactive diagnostic placeholder',
    (tester) async {
      final registry = DesyRegistry(
        name: 'Harbor Operations',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DesyDesignSystemThemeScope(
            theme: DesyDesignSystemTheme.light,
            child: Builder(
              builder: (context) => registry.widgetBuilder.build(
                context,
                'harbor.badge.status.missing',
              ),
            ),
          ),
        ),
      );

      final placeholder = find.byKey(
        const ValueKey(
          'missing-component-instance-harbor.badge.status.missing',
        ),
      );
      expect(placeholder, findsOneWidget);
      expect(find.text('Missing instance'), findsOneWidget);
      expect(find.byIcon(DesyIcons.triangleAlert), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Missing component instance harbor.badge.status.missing',
        ),
        findsOneWidget,
      );

      await tester.tap(placeholder);
      await tester.pumpAndSettle();

      expect(find.text('Missing component instance'), findsOneWidget);
      expect(find.textContaining('Harbor Operations'), findsOneWidget);
      expect(find.text('harbor.badge.status.missing'), findsOneWidget);
      expect(find.text('How to fix it'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Missing component instance'), findsNothing);
      expect(placeholder, findsOneWidget);
    },
  );
}

Widget _wrap(BuildContext context, Widget child) => child;

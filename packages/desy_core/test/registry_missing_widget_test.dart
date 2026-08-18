import 'package:desy_core/desy_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'missing instance renders an interactive diagnostic placeholder',
    (tester) async {
      final registry = DesyRegistry(
        name: 'Acme Design System',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => registry.widgetBuilder.build(
              context,
              'acme.badge.status.missing',
            ),
          ),
        ),
      );

      final placeholder = find.byKey(
        const ValueKey('missing-component-instance-acme.badge.status.missing'),
      );
      expect(placeholder, findsOneWidget);
      expect(find.text('Missing instance'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Missing component instance acme.badge.status.missing',
        ),
        findsOneWidget,
      );

      await tester.tap(placeholder);
      await tester.pumpAndSettle();

      expect(find.text('Missing component instance'), findsOneWidget);
      expect(find.textContaining('Acme Design System'), findsOneWidget);
      expect(find.text('acme.badge.status.missing'), findsOneWidget);
      expect(find.text('How to fix it'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Missing component instance'), findsNothing);
      expect(placeholder, findsOneWidget);
    },
  );
}

Widget _wrap(BuildContext context, Widget child) => child;

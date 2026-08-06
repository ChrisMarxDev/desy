import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/presentation/component_knob_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

void main() {
  testWidgets('instance swaps render each declared instance icon', (
    tester,
  ) async {
    final clear = DesyComponentInstance.widget(
      id: 'status.clear',
      name: 'Clear',
      icon: FLucideIcons.badgeCheck,
      builder: (_) => const SizedBox(),
    );
    final delayed = DesyComponentInstance.widget(
      id: 'status.delayed',
      name: 'Delayed',
      icon: FLucideIcons.octagonAlert,
      builder: (_) => const SizedBox(),
    );
    final knob = DesyComponentKnob(
      id: 'status',
      name: 'Status',
      initial: clear,
      options: [clear, delayed],
    );

    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.desktop,
        child: MaterialApp(
          home: Scaffold(
            body: DesyComponentKnobPanel(
              knobs: [knob],
              values: {'status': clear},
              onChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('instance-swap-current-status')),
        matching: find.byIcon(FLucideIcons.badgeCheck),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('instance-swap-current-status')),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('instance-swap-option-status.clear')),
        matching: find.byIcon(FLucideIcons.badgeCheck),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('instance-swap-option-status.delayed')),
        matching: find.byIcon(FLucideIcons.octagonAlert),
      ),
      findsOneWidget,
    );
  });
}

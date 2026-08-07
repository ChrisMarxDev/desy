import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/presentation/component_knob_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desy_design_system/desy_design_system.dart';

void main() {
  testWidgets('instance swaps render each declared instance icon', (
    tester,
  ) async {
    final clear = DesyComponentInstance(
      id: 'clear',
      name: 'Clear',
      icon: FLucideIcons.badgeCheck,
    );
    final delayed = DesyComponentInstance(
      id: 'delayed',
      name: 'Delayed',
      icon: FLucideIcons.octagonAlert,
    );
    final registry = DesyRegistry(
      name: 'Icons',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [
        DesyComponent(
          id: 'status',
          name: 'Status',
          preview: (_) => const SizedBox(),
          instances: [clear, delayed],
        ),
      ],
    );
    final knob = DesyComponentKnob(
      id: 'status',
      name: 'Status',
      initial: 'status.clear',
      options: const ['status.clear', 'status.delayed'],
    );

    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.desktop,
        child: MaterialApp(
          home: Scaffold(
            body: DesyComponentKnobPanel(
              registry: registry,
              knobs: [knob],
              values: const {'status': 'status.clear'},
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

Widget _wrap(BuildContext context, Widget child) => child;

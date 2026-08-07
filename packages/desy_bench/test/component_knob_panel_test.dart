import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/presentation/component_knob_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desy_design_system/desy_design_system.dart';

void main() {
  testWidgets('instance swaps list every registered instance to choose from', (
    tester,
  ) async {
    final registry = DesyRegistry(
      name: 'Instance swaps',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [
        DesyStaticComponent(
          id: 'status',
          name: 'Status',
          instances: {
            'clear': (_) => const SizedBox(),
            'delayed': (_) => const SizedBox(),
            'dropped': (_) => const SizedBox(),
          },
        ),
      ],
    );
    final knob = KnobDefinition(
      id: 'status',
      name: 'Status',
      kind: DesyKnobKind.widgetInstance,
      initial: const DesyInstanceId('status.clear'),
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

    await tester.tap(
      find.byKey(const ValueKey('instance-swap-current-status')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('instance-swap-option-status.clear')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('instance-swap-option-status.delayed')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('instance-swap-option-status.dropped')),
      findsOneWidget,
    );
  });
}

Widget _wrap(BuildContext context, Widget child) => child;

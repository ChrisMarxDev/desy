import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/presentation/component_knob_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desy_design_system/desy_design_system.dart';

void main() {
  testWidgets('all declared knob kinds use Desy design-system rows', (
    tester,
  ) async {
    final registry = DesyRegistry(
      name: 'Knob rows',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [
        DesyStaticComponent(
          id: 'status',
          name: 'Status',
          instances: {'clear': (_) => const SizedBox()},
        ),
      ],
    );
    final knobs = <KnobDefinition<Object>>[
      KnobDefinition(
        id: 'enabled',
        name: 'Enabled',
        kind: DesyKnobKind.boolean,
        initial: true,
      ),
      KnobDefinition(
        id: 'label',
        name: 'Label',
        kind: DesyKnobKind.string,
        initial: 'Atlas',
      ),
      KnobDefinition(
        id: 'width',
        name: 'Width',
        kind: DesyKnobKind.number,
        initial: 320.0,
        unit: 'px',
        step: 8,
        minimum: 160,
        maximum: 640,
      ),
      KnobDefinition(
        id: 'tint',
        name: 'Tint',
        kind: DesyKnobKind.color,
        initial: const Color(0xff336699),
      ),
      KnobDefinition(
        id: 'status',
        name: 'Status',
        kind: DesyKnobKind.widgetInstance,
        initial: const DesyInstanceId('status.clear'),
      ),
    ];

    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.desktop,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              child: DesyComponentKnobPanel(
                registry: registry,
                knobs: knobs,
                values: const {},
                onChanged: (_, _) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DesyBooleanKnobRow), findsOneWidget);
    expect(find.byType(DesyTextKnobRow), findsOneWidget);
    expect(find.byType(DesyNumericKnobRow), findsOneWidget);
    expect(find.byType(DesyColorKnobRow), findsOneWidget);
    expect(find.byType(DesyInstanceKnobRow), findsOneWidget);
    expect(find.byType(DesyKnobSheet), findsOneWidget);
    expect(find.byType(DesySwitch), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('color knobs emit complete ARGB edits as Color values', (
    tester,
  ) async {
    Color? changed;
    final knob = KnobDefinition(
      id: 'tint',
      name: 'Tint',
      kind: DesyKnobKind.color,
      initial: const Color(0xff336699),
    );
    final registry = DesyRegistry(
      name: 'Color knob',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
    );

    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.desktop,
        child: MaterialApp(
          home: Scaffold(
            body: DesyComponentKnobPanel(
              registry: registry,
              knobs: [knob],
              values: const {},
              onChanged: (_, value) => changed = value as Color,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('color-knob-field-Tint')),
      '#80445566',
    );

    expect(changed, const Color(0x80445566));
  });

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

  testWidgets('instance swaps honor a widget-slot allow-list', (tester) async {
    final registry = DesyRegistry(
      name: 'Restricted instance swaps',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [
        DesyStaticComponent(
          id: 'status',
          name: 'Status',
          instances: {
            'clear': (_) => const SizedBox(),
            'delayed': (_) => const SizedBox(),
          },
        ),
      ],
    );
    final knob = KnobDefinition(
      id: 'status',
      name: 'Status',
      kind: DesyKnobKind.widgetInstance,
      initial: const DesyInstanceId('status.clear'),
      options: const ['status.clear'],
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
      findsNothing,
    );
  });
}

Widget _wrap(BuildContext context, Widget child) => child;

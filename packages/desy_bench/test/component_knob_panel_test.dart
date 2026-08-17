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
        description: 'Visible copy.',
        kind: DesyKnobKind.string,
        initial: 'Atlas',
      ),
      KnobDefinition(
        id: 'visibility',
        name: 'Visibility',
        kind: DesyKnobKind.choice,
        initial: 'Automatic',
        options: const ['Automatic', 'Enabled', 'Disabled'],
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
        id: 'startsAt',
        name: 'Starts at',
        kind: DesyKnobKind.dateTime,
        initial: DateTime.utc(2026, 8, 15, 9, 30),
      ),
      KnobDefinition(
        id: 'status',
        name: 'Status',
        kind: DesyKnobKind.widgetInstance,
        initial: const DesyInstanceId('status.clear'),
      ),
      KnobDefinition(
        id: 'children',
        name: 'Children',
        kind: DesyKnobKind.widgetInstances,
        initial: DesyInstanceIds(const [DesyInstanceId('status.clear')]),
      ),
      KnobDefinition(
        id: 'submit',
        name: 'Submit',
        kind: DesyKnobKind.event,
        initial: const DesyEventBinding(),
      ),
    ];

    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.desktop,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
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
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DesyBooleanKnobRow), findsOneWidget);
    expect(find.byType(DesyTextKnobRow), findsOneWidget);
    expect(find.byType(DesyChoiceKnobRow), findsOneWidget);
    expect(find.byType(DesyNumericKnobRow), findsOneWidget);
    expect(find.byType(DesyColorKnobRow), findsOneWidget);
    expect(find.byType(DesyDateTimeKnobRow), findsOneWidget);
    expect(find.byType(DesyInstanceKnobRow), findsNWidgets(2));
    expect(find.byType(DesyKnobSheet), findsOneWidget);
    expect(find.byType(DesySwitch), findsOneWidget);
    expect(find.text('Visible copy.'), findsOneWidget);
    expect(find.text('Event'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('choice knobs render a dropdown and emit legal strings', (
    tester,
  ) async {
    String? changed;
    final component = DesyComponent(
      id: 'visibility.label',
      name: 'Visibility label',
      knobs: (k) => (
        visibility: k.choice(
          'visibility',
          options: const ['Automatic', 'Enabled', 'Disabled'],
        ),
      ),
      build: (context, knobs) => Text(knobs.visibility.value),
    );
    final registry = DesyRegistry(
      name: 'Choice knob',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [component],
    );

    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.desktop,
        child: MaterialApp(
          home: Scaffold(
            body: DesyComponentKnobPanel(
              registry: registry,
              knobs: component.knobDefinitions,
              values: const {},
              onChanged: (_, value) => changed = value as String,
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('choice-knob-select-visibility')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enabled').last);
    await tester.pumpAndSettle();

    expect(changed, 'Enabled');
  });

  testWidgets('date-time knobs emit typed edits and preserve UTC time', (
    tester,
  ) async {
    DateTime? changed;
    final knob = KnobDefinition(
      id: 'startsAt',
      name: 'Starts at',
      kind: DesyKnobKind.dateTime,
      initial: DateTime.utc(2026, 8, 15, 9, 30, 12),
    );
    final registry = DesyRegistry(
      name: 'Date-time knob',
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
              onChanged: (_, value) => changed = value as DateTime,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('date-time-knob-date-Starts at')),
      '2026-12-24',
    );

    expect(changed, DateTime.utc(2026, 12, 24, 9, 30, 12));
    expect(changed!.isUtc, isTrue);
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

  testWidgets('color picker offers registry colors and a custom picker', (
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
      name: 'Color picker',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      colors: const [
        DesyColorEntry(
          id: 'color.brand',
          name: 'Brand',
          color: Color(0xffe91e63),
        ),
      ],
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

    await tester.tap(find.byKey(const ValueKey('color-knob-picker-Tint')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('color-knob-option-tint-color.brand')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('color-knob-picker-field-tint')),
      findsOneWidget,
    );
    expect(find.text('CUSTOM COLOR'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('color-knob-option-tint-color.brand')),
    );
    await tester.pumpAndSettle();

    expect(changed, const Color(0xffe91e63));

    await tester.tap(find.byKey(const ValueKey('color-knob-picker-Tint')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('color-knob-picker-field-tint')),
      '#80112233',
    );
    await tester.tap(find.byKey(const ValueKey('color-knob-use-custom-tint')));
    await tester.pumpAndSettle();

    expect(changed, const Color(0x80112233));
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

  testWidgets('multi-instance knobs select an ordered list of children', (
    tester,
  ) async {
    final registry = DesyRegistry(
      name: 'Multi instance swaps',
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
      id: 'children',
      name: 'Children',
      kind: DesyKnobKind.widgetInstances,
      initial: DesyInstanceIds(const [DesyInstanceId('status.clear')]),
      options: const ['status.clear', 'status.delayed'],
    );
    List<String>? changed;

    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.desktop,
        child: MaterialApp(
          home: Scaffold(
            body: DesyComponentKnobPanel(
              registry: registry,
              knobs: [knob],
              values: const {
                'children': ['status.clear'],
              },
              onChanged: (_, value) => changed = value as List<String>,
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('instance-multi-current-children')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('instance-multi-option-status.delayed')),
    );
    await tester.pump();
    await tester.tap(find.text('Use 2 instances'));
    await tester.pumpAndSettle();

    expect(changed, ['status.clear', 'status.delayed']);
  });
}

Widget _wrap(BuildContext context, Widget child) => child;

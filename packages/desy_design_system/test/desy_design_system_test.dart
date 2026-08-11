import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dialog viewport spacing uses the shared panel spacing token', () {
    final style = DesyDesignSystemFoundation.themeData(
      DesyDesignSystemTheme.light,
    ).dialogStyle;

    expect(
      style.insetPadding,
      const EdgeInsets.all(DesyDesignSystemTokens.spaceLg),
    );
  });

  test('Desy themes use the bundled Roboto type family', () {
    expect(
      DesyDesignSystemTokens.fontFamily,
      'packages/desy_design_system/Roboto',
    );

    for (final variant in DesyDesignSystemTheme.values) {
      final theme = DesyDesignSystemFoundation.themeData(variant);

      expect(
        theme.typography.body.fontFamily,
        DesyDesignSystemTokens.fontFamily,
      );
      expect(
        DesyDesignSystemFoundation.materialTheme(
          variant,
        ).textTheme.bodyMedium?.fontFamily,
        DesyDesignSystemTokens.fontFamily,
      );
    }
  });

  test('Registry Spine themes separate action and inspection semantics', () {
    final light = DesyDesignSystemFoundation.themeData(
      DesyDesignSystemTheme.light,
    );
    final dark = DesyDesignSystemFoundation.themeData(
      DesyDesignSystemTheme.dark,
    );

    expect(light.colors.background, DesyVisualColors.light.canvas);
    expect(light.colors.card, DesyVisualColors.light.panel);
    expect(light.colors.border, DesyVisualColors.light.divider);
    expect(light.colors.desy.signal, DesyVisualColors.light.signal);
    expect(light.colors.primary, isNot(light.colors.desy.signal));
    expect(dark.colors.desy.signal, DesyVisualColors.dark.signal);
    expect(
      light.style.borderRadius.lg,
      const BorderRadius.all(Radius.circular(8)),
    );
  });

  testWidgets('scope supplies Desy and Material theme bridges', (tester) async {
    late Color foruiBackground;
    late Color materialBackground;

    await tester.pumpWidget(
      MaterialApp(
        home: DesyDesignSystemScope(
          theme: DesyDesignSystemTheme.dark,
          child: Builder(
            builder: (context) {
              foruiBackground = context.theme.colors.background;
              materialBackground = Theme.of(context).colorScheme.surface;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(
      foruiBackground,
      DesyDesignSystemFoundation.themeData(
        DesyDesignSystemTheme.dark,
      ).colors.background,
    );
    expect(materialBackground.computeLuminance(), lessThan(.5));
  });

  testWidgets('native text field keeps externally supplied text editable', (
    tester,
  ) async {
    var value = 'Atlas';
    await tester.pumpWidget(
      MaterialApp(
        home: DesyDesignSystemScope(
          theme: DesyDesignSystemTheme.light,
          child: DesyTextField(
            label: 'Search',
            value: value,
            onChanged: (next) => value = next,
          ),
        ),
      ),
    );

    expect(find.text('Atlas'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Components');
    expect(value, 'Components');
  });

  testWidgets('native text field owns the shared bordered field chrome', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DesyDesignSystemScope(
          theme: DesyDesignSystemTheme.light,
          child: DesyTextField(hintText: 'Message Desy'),
        ),
      ),
    );

    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, DesyVisualColors.light.panel);
    expect(decoration.border, isNotNull);
  });

  testWidgets('core controls expose Desy-owned contracts', (tester) async {
    var presses = 0;
    bool? checkboxValue;
    bool? switchValue;
    String? selectedTheme;

    await tester.pumpWidget(
      MaterialApp(
        home: DesyDesignSystemScope(
          theme: DesyDesignSystemTheme.light,
          child: Column(
            children: [
              DesyButton(
                variant: DesyButtonVariant.outline,
                size: DesyButtonSize.sm,
                onPress: () => presses++,
                child: const Text('Inspect'),
              ),
              const DesyBadge(
                variant: DesyBadgeVariant.secondary,
                child: Text('LOCAL'),
              ),
              const DesyCard(child: Text('Registry source')),
              DesyCheckbox(
                value: false,
                onChanged: (value) => checkboxValue = value,
                label: const Text('Keep candidate'),
              ),
              DesySwitch(
                label: const Text('Show evidence'),
                value: false,
                onChange: (value) => switchValue = value,
              ),
              const DesyAccordion(
                children: [
                  DesyAccordionItem(
                    title: Text('Annotation evidence'),
                    child: Text('Source-aware target'),
                  ),
                ],
              ),
              DesyTile(
                prefix: const Icon(DesyIcons.component),
                title: const Text('Source entry'),
                selected: true,
                onPress: () => presses++,
              ),
              DesySelect<String>.rich(
                control: DesySelectControl.lifted(
                  value: 'light',
                  onChange: (value) => selectedTheme = value,
                ),
                format: (value) => value,
                children: const [
                  DesySelectItem.item(value: 'light', title: Text('Light')),
                  DesySelectItem.item(value: 'dark', title: Text('Dark')),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final button = tester.widget<DesyButton>(find.byType(DesyButton));
    expect(button.variant, DesyButtonVariant.outline);
    expect(button.size, DesyButtonSize.sm);
    expect(
      tester.widget<DesyBadge>(find.byType(DesyBadge)).variant,
      DesyBadgeVariant.secondary,
    );
    expect(find.byType(DesyCard), findsOneWidget);
    expect(find.byType(DesyCheckbox), findsOneWidget);
    expect(find.byType(DesySwitch), findsOneWidget);
    expect(find.byType(DesyAccordion), findsOneWidget);
    expect(find.byType(DesyTile), findsOneWidget);
    expect(find.byType(DesySelect<String>), findsOneWidget);

    await tester.tap(find.text('Inspect'));
    await tester.pumpAndSettle();
    expect(presses, 1);

    await tester.tap(find.text('Keep candidate'));
    await tester.pumpAndSettle();
    expect(checkboxValue, isTrue);

    await tester.tap(find.text('Show evidence'));
    await tester.pumpAndSettle();
    expect(switchValue, isTrue);

    expect(find.text('Source-aware target').hitTestable(), findsNothing);
    await tester.tap(find.text('Annotation evidence'));
    await tester.pumpAndSettle();
    expect(find.text('Source-aware target').hitTestable(), findsOneWidget);

    await tester.tap(find.text('Source entry'));
    await tester.pumpAndSettle();
    expect(presses, 2);

    await tester.tap(find.text('light').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();
    expect(selectedTheme, 'dark');
  });

  testWidgets('switch keeps its label beside the toggle in a dense width', (
    tester,
  ) async {
    bool? value;

    await tester.pumpWidget(
      MaterialApp(
        home: DesyDesignSystemScope(
          theme: DesyDesignSystemTheme.light,
          child: Center(
            child: SizedBox(
              key: const ValueKey('dense-switch-frame'),
              width: 104,
              child: DesySwitch(
                label: const Text('Off'),
                value: false,
                onChange: (next) => value = next,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final controlRect = tester.getRect(
      find.byKey(const ValueKey('dense-switch-frame')),
    );
    final labelRect = tester.getRect(find.text('Off'));
    final toggleRect = tester.getRect(find.byType(CupertinoSwitch));
    expect(labelRect.left, greaterThanOrEqualTo(controlRect.left));
    expect(labelRect.right, lessThanOrEqualTo(toggleRect.left));
    expect(toggleRect.overlaps(controlRect), isTrue);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Off'));
    await tester.pumpAndSettle();
    expect(value, isTrue);
  });

  testWidgets('selected switch tracks use Desy pink', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DesyDesignSystemScope(
          theme: DesyDesignSystemTheme.light,
          child: DesySwitch(
            label: Text('Pink track'),
            value: true,
            onChange: _ignoreSwitchValue,
          ),
        ),
      ),
    );

    final element = tester.element(find.byType(FSwitch));
    final widget = tester.widget<FSwitch>(find.byType(FSwitch));
    final style = widget.style(FTheme.of(element).switchStyle);

    expect(
      style.trackColor.resolve({FSwitchVariant.selected}),
      DesyVisualColors.light.signal,
    );
  });

  testWidgets('instance knob keeps its picker inside a narrow panel', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DesyDesignSystemScope(
          theme: DesyDesignSystemTheme.light,
          child: Center(
            child: SizedBox(
              key: ValueKey('instance-knob-frame'),
              width: 280,
              child: DesyInstanceKnobRow(
                label: 'Instance name',
                instanceName: 'Default badge',
                prefix: Icon(DesyIcons.component),
                onPress: _openPicker,
              ),
            ),
          ),
        ),
      ),
    );

    final frame = tester.getRect(
      find.byKey(const ValueKey('instance-knob-frame')),
    );
    final picker = tester.getRect(find.byType(DesyTile));

    expect(picker.left, greaterThanOrEqualTo(frame.left));
    expect(picker.right, lessThanOrEqualTo(frame.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'knob sheet derives its count and its controls remain separated',
    (tester) async {
      double? numericValue;
      bool? booleanValue;

      await tester.pumpWidget(
        MaterialApp(
          home: DesyDesignSystemScope(
            theme: DesyDesignSystemTheme.light,
            child: Center(
              child: SizedBox(
                key: const ValueKey('knob-sheet-frame'),
                width: 320,
                child: DesyKnobSheet(
                  sections: [
                    DesyKnobSection(
                      label: 'LAYOUT',
                      children: [
                        DesyNumericKnobRow(
                          label: 'Width',
                          value: 320,
                          unit: 'px',
                          step: 8,
                          onChanged: (value) => numericValue = value,
                        ),
                      ],
                    ),
                    DesyKnobSection(
                      label: 'BEHAVIOR',
                      children: [
                        DesyBooleanKnobRow(
                          label: 'Clip content',
                          value: false,
                          onChanged: (value) => booleanValue = value,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Increase Width'));
      await tester.pumpAndSettle();
      expect(numericValue, 328);

      final propertyRect = tester.getRect(find.text('Clip content'));
      final switchRect = tester.getRect(find.byType(DesySwitch));
      final stateRect = tester.getRect(find.text('Off'));
      final toggleRect = tester.getRect(find.byType(CupertinoSwitch));
      expect(propertyRect.right, lessThanOrEqualTo(switchRect.left));
      expect(stateRect.right, lessThanOrEqualTo(toggleRect.left));
      expect(propertyRect.overlaps(switchRect), isFalse);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Off'));
      await tester.pumpAndSettle();
      expect(booleanValue, isTrue);
    },
  );

  testWidgets('shortcut label exposes one semantic chord', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DesyDesignSystemScope(
          theme: DesyDesignSystemTheme.light,
          child: DesyKeyboardShortcutLabel(keys: ['⌘', 'K']),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Keyboard shortcut: ⌘ plus K'),
      findsOneWidget,
    );
  });

  testWidgets(
    'catalogue card closes the preview bay with muted path metadata',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DesyDesignSystemScope(
            theme: DesyDesignSystemTheme.light,
            child: const Center(
              child: SizedBox(
                width: 280,
                height: 236,
                child: DesyCatalogueCard(
                  path: 'Actions',
                  identifier: 'desy.component.button',
                  preview: Center(child: Text('Preview')),
                ),
              ),
            ),
          ),
        ),
      );

      final path = tester.widget<Text>(find.text('ACTIONS'));
      expect(
        path.style?.color,
        DesyDesignSystemFoundation.themeData(
          DesyDesignSystemTheme.light,
        ).colors.mutedForeground,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('desy-catalogue-card-divider')))
            .height,
        1,
      );
      expect(find.text('desy.component.button'), findsOneWidget);
    },
  );

  testWidgets('progress trail exposes completion and current-step semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DesyDesignSystemScope(
          theme: DesyDesignSystemTheme.light,
          child: SizedBox(
            width: 360,
            child: DesyProgressTrail(
              items: [
                DesyProgressTrailItem(
                  title: 'Read the activity source',
                  state: DesyProgressTrailItemState.complete,
                ),
                DesyProgressTrailItem(
                  title: 'Implement the progress trail',
                  detail: 'Rendering the selected Workshop direction.',
                  metadata: 'Running',
                  state: DesyProgressTrailItemState.current,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('1 of 2 steps complete'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Complete: Read the activity source'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Current: Implement the progress trail'),
      findsOneWidget,
    );
    expect(find.text('Running'), findsOneWidget);
  });

  testWidgets(
    'progress trail keeps item geometry stable across state changes',
    (tester) async {
      Widget buildTrail(DesyProgressTrailItemState state) => MaterialApp(
        home: DesyDesignSystemScope(
          theme: DesyDesignSystemTheme.light,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 360,
              child: DesyProgressTrail(
                items: [
                  DesyProgressTrailItem(
                    title: 'Run focused checks',
                    detail: 'Formatting and focused component tests.',
                    metadata: 'Status',
                    state: state,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(buildTrail(DesyProgressTrailItemState.current));
      await tester.pumpAndSettle();

      final currentSize = tester.getSize(find.byType(DesyProgressTrail));
      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(animatedContainer.duration, DesyDesignSystemTokens.feedbackMotion);

      await tester.pumpWidget(buildTrail(DesyProgressTrailItemState.complete));
      await tester.pump();

      expect(tester.getSize(find.byType(DesyProgressTrail)), currentSize);
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(DesyProgressTrail)), currentSize);
    },
  );

  testWidgets('sidebar screen items add an arrow without becoming tree nodes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DesyDesignSystemScope(
          theme: DesyDesignSystemTheme.light,
          child: SizedBox(
            width: 248,
            height: 120,
            child: DesySidebar(
              children: const [
                DesySidebarSection(
                  label: 'Workspace',
                  children: [
                    DesySidebarItem.screen(
                      icon: Icon(DesyIcons.layoutGrid),
                      label: Text('Atlas'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Workspace'), findsOneWidget);
    expect(find.text('Atlas'), findsOneWidget);
    expect(find.byIcon(DesyIcons.chevronRight), findsOneWidget);
    expect(
      tester.widget<DesySidebarItem>(find.byType(DesySidebarItem)).children,
      isEmpty,
    );
  });

  testWidgets('selected sidebar item uses the shared signal marker', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DesyDesignSystemScope(
          theme: DesyDesignSystemTheme.light,
          child: SizedBox(
            width: 248,
            height: 120,
            child: DesySidebar(
              children: const [
                DesySidebarSection(
                  label: 'Registry',
                  children: [
                    DesySidebarItem(
                      selected: true,
                      label: Text('Primary button'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final marker = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('desy-sidebar-selection-indicator')),
    );
    expect(
      (marker.decoration as BoxDecoration).color,
      DesyVisualColors.light.signal,
    );
  });
}

void _ignoreSwitchValue(bool _) {}

void _openPicker() {}

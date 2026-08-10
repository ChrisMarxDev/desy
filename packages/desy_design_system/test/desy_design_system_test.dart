import 'package:desy_design_system/desy_design_system.dart';
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

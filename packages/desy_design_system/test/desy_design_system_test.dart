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

  test('Desy themes use the Space Grotesk type family', () {
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
              children: [
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
}

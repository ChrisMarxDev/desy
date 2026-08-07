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
      const MaterialApp(
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
}

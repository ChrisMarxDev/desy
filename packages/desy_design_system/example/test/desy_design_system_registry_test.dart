import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:desy_design_system_example/desy_design_system_example.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dogfood registry is valid and complete', () {
    expect(desyDesignSystemRegistry.validate(), isEmpty);
    expect(desyDesignSystemRegistry.themes, hasLength(2));
    expect(desyDesignSystemRegistry.allColors, hasLength(6));
    expect(desyDesignSystemRegistry.allFonts, hasLength(4));
    expect(desyDesignSystemRegistry.allMeasurements, hasLength(7));
    expect(desyDesignSystemRegistry.allMotion, hasLength(2));
    expect(desyDesignSystemRegistry.allEffects, hasLength(1));
    expect(desyDesignSystemRegistry.allIcons, hasLength(26));
    expect(desyDesignSystemRegistry.atomKinds, DesyAtomKind.values);
    expect(desyDesignSystemRegistry.allShowcases, hasLength(1));
    expect(
      desyDesignSystemRegistry.resolve('desy.icon.shapes')?.path,
      'Atoms / Icons',
    );

    expect(
      desyDesignSystemRegistry.allComponents.map((component) => component.id),
      unorderedEquals({
        'desy.component.accordion',
        'desy.component.badge',
        'desy.component.button',
        'desy.component.card',
        'desy.component.dialog',
        'desy.component.scaffold',
        'desy.component.select',
        'desy.component.shortcut-label',
        'desy.component.sidebar',
        'desy.component.sidebar-section',
        'desy.component.sidebar-item',
        'desy.component.switch',
        'desy.component.tabs',
        'desy.component.text-field',
        'desy.component.tile',
      }),
    );
    expect(
      desyDesignSystemRegistry.resolve('desy.component.sidebar')?.path,
      'Navigation / Sidebar',
    );
    for (final component in desyDesignSystemRegistry.allComponents) {
      expect(component.instances, isNotEmpty, reason: component.id);
    }
  });

  testWidgets('every catalogued component renders its production preview', (
    tester,
  ) async {
    for (final component in desyDesignSystemRegistry.allComponents) {
      await tester.pumpWidget(
        MaterialApp(
          home: DesyDesignSystemScope(
            theme: DesyDesignSystemTheme.light,
            child: Scaffold(
              body: Center(child: Builder(builder: component.preview)),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: component.id);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('tile swaps registered preset instances through the registry', (
    tester,
  ) async {
    final tile = desyDesignSystemRegistry.allComponents.singleWhere(
      (component) => component.id == 'desy.component.tile',
    );
    final suffixKnob = tile.knobs.whereType<DesyComponentKnob>().single;

    expect(suffixKnob.initial, 'desy.component.badge.default');
    expect(suffixKnob.options, const [
      'desy.component.badge.default',
      'desy.component.shortcut-label.single-key',
    ]);
    expect(tile.instances.map((instance) => instance.id), [
      'with-badge',
      'with-shortcut',
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: DesyDesignSystemScope(
          theme: DesyDesignSystemTheme.light,
          child: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => tile.buildInstance(
                  context,
                  tile.instances.last,
                  widgets: desyDesignSystemRegistry.widgetBuilder,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(DesyTile), findsOneWidget);
    expect(find.byType(DesyKeyboardShortcutLabel), findsOneWidget);
    expect(find.text('Open command menu'), findsOneWidget);
  });

  testWidgets('tile dogfoods the missing registry link diagnostic', (
    tester,
  ) async {
    final tile = desyDesignSystemRegistry.allComponents.singleWhere(
      (component) => component.id == 'desy.component.tile',
    );
    final missingScenario = tile.scenarios.singleWhere(
      (scenario) => scenario.id == 'missing-suffix-instance',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DesyDesignSystemScope(
          theme: DesyDesignSystemTheme.light,
          child: Scaffold(
            body: Center(child: Builder(builder: missingScenario.builder)),
          ),
        ),
      ),
    );

    expect(find.text('Missing instance'), findsOneWidget);
    await tester.tap(find.text('Missing instance'));
    await tester.pumpAndSettle();

    expect(find.text('Missing component instance'), findsOneWidget);
    expect(
      find.text('desy.component.unregistered-tile-suffix.missing'),
      findsOneWidget,
    );
    expect(find.textContaining('Desy Design System'), findsOneWidget);
  });
}

import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:desy_design_system_example/desy_design_system_example.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dogfood registry is valid and complete', () {
    expect(desyDesignSystemRegistry.validate(), isEmpty);
    expect(desyDesignSystemRegistry.themes, hasLength(2));
    expect(desyDesignSystemRegistry.allColors, hasLength(9));
    expect(desyDesignSystemRegistry.allFonts, hasLength(4));
    expect(desyDesignSystemRegistry.allMeasurements, hasLength(9));
    expect(desyDesignSystemRegistry.allMotion, hasLength(2));
    expect(desyDesignSystemRegistry.allEffects, hasLength(1));
    expect(desyDesignSystemRegistry.allIcons, hasLength(28));
    expect(desyDesignSystemRegistry.atomKinds, DesyAtomKind.values);
    expect(desyDesignSystemRegistry.allPrototypes, isEmpty);
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
        'desy.component.boolean-knob-row',
        'desy.component.card',
        'desy.component.catalogue-card',
        'desy.component.dialog',
        'desy.component.instance-knob-row',
        'desy.component.knob-sheet',
        'desy.component.numeric-knob-row',
        'desy.component.progress-trail',
        'desy.component.resize-divider',
        'desy.component.scaffold',
        'desy.component.select',
        'desy.component.shortcut-label',
        'desy.component.sidebar',
        'desy.component.sidebar-section',
        'desy.component.sidebar-item',
        'desy.component.switch',
        'desy.component.tabs',
        'desy.component.text-knob-row',
        'desy.component.text-field',
        'desy.component.tile',
      }),
    );
    expect(
      desyDesignSystemRegistry.resolve('desy.component.sidebar')?.path,
      'Molecules / Navigation / Sidebar',
    );
    expect(
      desyDesignSystemRegistry.resolve('desy.component.knob-sheet')?.path,
      'Molecules / Inputs / Knobs',
    );
    for (final component in desyDesignSystemRegistry.allComponents) {
      expect(component.instanceIds, isNotEmpty, reason: component.id);
      expect(
        component.knobDefinitions.isNotEmpty,
        isTrue,
        reason: component.id,
      );
    }
  });

  test('knob sheet declares every precision-sheet control', () {
    final knobSheet = desyDesignSystemRegistry.allComponents.singleWhere(
      (component) => component.id == 'desy.component.knob-sheet',
    );

    expect(knobSheet.knobDefinitions.map((definition) => definition.id), [
      'title',
      'caption',
      'width',
      'cornerRadius',
      'clipContent',
      'showLabel',
      'surfaceColor',
      'instance',
    ]);
    expect(
      knobSheet.knobDefinitions
          .where((definition) => definition.kind == DesyKnobKind.number)
          .map((definition) => definition.name),
      ['Width', 'Corner radius'],
    );
    expect(
      knobSheet.knobDefinitions.map((definition) => definition.kind).toSet(),
      {
        DesyKnobKind.string,
        DesyKnobKind.number,
        DesyKnobKind.boolean,
        DesyKnobKind.color,
        DesyKnobKind.widgetInstance,
      },
    );
  });

  test('color knob row declares a typed color control', () {
    final colorKnobRow = desyDesignSystemRegistry.allComponents.singleWhere(
      (component) => component.id == 'desy.component.color-knob-row',
    );

    expect(colorKnobRow.instanceIds, [
      'signal-surface',
      'positive',
      'disabled',
    ]);
    expect(colorKnobRow.knobDefinitions.map((definition) => definition.kind), [
      DesyKnobKind.string,
      DesyKnobKind.color,
      DesyKnobKind.boolean,
    ]);
  });

  test(
    'dogfood declares a knobless custom gradient atom as named instances',
    () {
      final atom = desyDesignSystemRegistry.allCustomAtoms.single;

      expect(atom.id, 'desy.atom.gradient.ribbon');
      expect(atom.instances.keys, ['default', 'quiet']);
      expect(atom.description, isNotEmpty);
    },
  );

  testWidgets('every catalogued component renders its production preview', (
    tester,
  ) async {
    for (final component in desyDesignSystemRegistry.allComponents) {
      await tester.pumpWidget(
        MaterialApp(
          home: DesyDesignSystemScope(
            theme: DesyDesignSystemTheme.light,
            child: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) => component.preview(
                    context,
                    desyDesignSystemRegistry.widgetBuilder,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: component.id);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('every component renders each declared preset instance', (
    tester,
  ) async {
    for (final component in desyDesignSystemRegistry.allComponents) {
      for (final instanceId in component.instanceIds) {
        await tester.pumpWidget(
          MaterialApp(
            home: DesyDesignSystemScope(
              theme: DesyDesignSystemTheme.light,
              child: Scaffold(
                body: Center(
                  child: Builder(
                    builder: (context) => component.buildInstance(
                      context,
                      instanceId,
                      desyDesignSystemRegistry.widgetBuilder,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: '${component.id}.$instanceId',
        );
        await tester.pumpWidget(const SizedBox());
      }
    }
  });

  testWidgets('tile swaps registered preset instances through the registry', (
    tester,
  ) async {
    final tile = desyDesignSystemRegistry.allComponents.singleWhere(
      (component) => component.id == 'desy.component.tile',
    );
    final suffixKnob = tile.knobDefinitions.firstWhere(
      (definition) => definition.id == 'suffix',
    );

    expect(suffixKnob.kind, DesyKnobKind.widgetInstance);
    expect(
      (suffixKnob.initial as DesyInstanceId).value,
      'desy.component.badge.default',
    );
    expect(tile.instanceIds, ['with-badge', 'with-shortcut']);

    await tester.pumpWidget(
      MaterialApp(
        home: DesyDesignSystemScope(
          theme: DesyDesignSystemTheme.light,
          child: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => tile.buildInstance(
                  context,
                  'with-shortcut',
                  desyDesignSystemRegistry.widgetBuilder,
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

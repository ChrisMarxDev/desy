import 'dart:convert';

import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:desy_design_system_example/desy_design_system_example.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dogfood registry is valid and complete', () {
    final validation = desyDesignSystemRegistry.validate();
    expect(
      validation,
      isEmpty,
      reason: validation
          .map((issue) => '${issue.id}: ${issue.message}')
          .join('\n'),
    );
    expect(desyDesignSystemRegistry.themes, hasLength(2));
    expect(desyDesignSystemRegistry.allColors, hasLength(9));
    expect(desyDesignSystemRegistry.allFonts, hasLength(4));
    expect(desyDesignSystemRegistry.allMeasurements, hasLength(9));
    expect(desyDesignSystemRegistry.allMotion, hasLength(5));
    expect(desyDesignSystemRegistry.allEffects, hasLength(1));
    expect(desyDesignSystemRegistry.allIcons, hasLength(29));
    expect(desyDesignSystemRegistry.systemProfile?.id, 'desy.system-profile');
    expect(
      desyDesignSystemRegistry.systemHeroAsset?.id,
      'desy.asset.workspace.signature.primary',
    );
    expect(desyDesignSystemRegistry.allAssets.map((asset) => asset.id), [
      'desy.asset.workspace.signature.primary',
      'desy.asset.workspace.signature.signal',
      'desy.asset.workspace.system-map',
    ]);
    expect(
      desyDesignSystemRegistry
          .asset('desy.asset.workspace.signature.primary')
          ?.assetKey,
      'web/favicon.png',
    );
    expect(desyDesignSystemRegistry.atomKinds, DesyAtomKind.values);
    expect(desyDesignSystemRegistry.allPrototypes, hasLength(2));
    expect(
      desyDesignSystemRegistry
          .prototypeSession('desy.prototype-session.annotation-inbox')
          ?.prototypes
          .map((prototype) => prototype.id),
      [
        'desy.prototype.annotation-inbox.review-sheet',
        'desy.prototype.annotation-inbox.ledger',
        'desy.prototype.annotation-inbox.focused',
      ],
    );
    expect(
      desyDesignSystemRegistry
          .prototypeSession('desy.prototype-session.knob-controls')
          ?.prototypes
          .map((prototype) => prototype.id),
      ['desy.prototype.knob-controls.divider-bands'],
    );
    expect(
      desyDesignSystemRegistry.resolve('desy.icon.shapes')?.path,
      'Atoms / Icons',
    );
    expect(
      desyDesignSystemRegistry
          .resolve('desy.asset.workspace.signature.primary')
          ?.path,
      'Atoms / Assets',
    );

    expect(
      desyDesignSystemRegistry.allComponents.map((component) => component.id),
      unorderedEquals({
        'desy.component.accordion',
        'desy.component.all-knobs',
        'desy.component.badge',
        'desy.component.button',
        'desy.component.boolean-knob-row',
        'desy.component.card',
        'desy.component.catalogue-card',
        'desy.component.chat-composer',
        'desy.component.chat-message',
        'desy.component.chat-thread',
        'desy.component.choice-knob-row',
        'desy.component.color-knob-row',
        'desy.component.date-time-knob-row',
        'desy.component.dialog',
        'desy.component.instance-knob-row',
        'desy.component.knob-sheet',
        'desy.component.numeric-knob-row',
        'desy.component.progress-trail',
        'desy.component.resize-divider',
        'desy.component.scaffold',
        'desy.component.select',
        'desy.component.sample',
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
    final sample = desyDesignSystemRegistry.resolve('desy.component.sample')!;
    expect(sample.component!.instanceIds, isEmpty);
    for (final component in desyDesignSystemRegistry.allComponents.where(
      (component) => component.id != sample.id,
    )) {
      expect(component.instanceIds, isNotEmpty, reason: component.id);
      expect(
        component.knobDefinitions.isNotEmpty,
        isTrue,
        reason: component.id,
      );
    }
  });

  test('dogfood registry exposes a JSON-ready complete snapshot', () {
    expect(desyDesignSystemRegistry.identity?.id, 'desy.design-system');
    expect(
      () => jsonEncode(DesyRegistrySnapshot(desyDesignSystemRegistry).toJson()),
      returnsNormally,
    );
  });

  test('knob sheet declares every precision-sheet control', () {
    final knobSheet = desyDesignSystemRegistry.allComponents.singleWhere(
      (component) => component.id == 'desy.component.knob-sheet',
    );

    expect(knobSheet.knobDefinitions.map((definition) => definition.id), [
      'title',
      'caption',
      'density',
      'cornerRadius',
      'clipContent',
      'scheduledAt',
      'surfaceColor',
      'instance',
    ]);
    expect(
      knobSheet.knobDefinitions
          .where((definition) => definition.kind == DesyKnobKind.number)
          .map((definition) => definition.name),
      ['Corner radius'],
    );
    expect(
      knobSheet.knobDefinitions.map((definition) => definition.kind).toSet(),
      {
        DesyKnobKind.string,
        DesyKnobKind.choice,
        DesyKnobKind.number,
        DesyKnobKind.boolean,
        DesyKnobKind.dateTime,
        DesyKnobKind.color,
        DesyKnobKind.widgetInstance,
      },
    );
    expect(
      knobSheet.instanceIds,
      containsAll(['scheduled-evening', 'scheduled-custom']),
    );
    expect(
      knobSheet.valuesFor('scheduled-custom'),
      containsPair('scheduledAt', DateTime.utc(2026, 8, 21, 14, 15)),
    );
    expect(
      knobSheet.valuesFor('scheduled-custom'),
      containsPair('surfaceColor', const Color(0x80336699)),
    );
    expect(knobSheet.valuesFor('roomy'), containsPair('density', 'Spacious'));
  });

  test('dogfood uses choice knobs for finite select and tri-state values', () {
    final select = desyDesignSystemRegistry.allComponents.singleWhere(
      (component) => component.id == 'desy.component.select',
    );
    final choiceRow = desyDesignSystemRegistry.allComponents.singleWhere(
      (component) => component.id == 'desy.component.choice-knob-row',
    );

    final theme = select.knobDefinitions.singleWhere(
      (definition) => definition.id == 'theme',
    );
    final value = choiceRow.knobDefinitions.singleWhere(
      (definition) => definition.id == 'value',
    );

    expect(theme.kind, DesyKnobKind.choice);
    expect(theme.initial, 'Workbench light');
    expect(theme.options, [
      'Workbench light',
      'Workbench dark',
      'Follow system',
    ]);
    expect(value.kind, DesyKnobKind.choice);
    expect(value.options, ['Automatic', 'Enabled', 'Disabled']);
  });

  test('all-knobs specimen tracks every available knob kind', () {
    final component = desyDesignSystemRegistry.allComponents.singleWhere(
      (component) => component.id == 'desy.component.all-knobs',
    );

    expect(component.knobDefinitions.map((definition) => definition.id), [
      'title',
      'status',
      'inset',
      'enabled',
      'scheduledAt',
      'accent',
      'leading',
      'supporting',
      'onActivate',
    ]);
    expect(
      component.knobDefinitions.map((definition) => definition.kind).toSet(),
      DesyKnobKind.values.toSet(),
    );
    expect(component.instanceIds, ['default', 'ready', 'blocked']);
    expect(component.valuesFor('ready'), containsPair('status', 'Ready'));
    expect(
      component.valuesFor('ready'),
      containsPair('supporting', ['desy.component.shortcut-label.single-key']),
    );
    expect(component.valuesFor('blocked'), containsPair('enabled', false));
  });

  test('color knob row declares a typed color control', () {
    final colorKnobRow = desyDesignSystemRegistry.allComponents.singleWhere(
      (component) => component.id == 'desy.component.color-knob-row',
    );

    expect(colorKnobRow.instanceIds, [
      'signal-surface',
      'positive',
      'custom-translucent',
      'disabled',
    ]);
    expect(colorKnobRow.knobDefinitions.map((definition) => definition.kind), [
      DesyKnobKind.string,
      DesyKnobKind.color,
      DesyKnobKind.boolean,
    ]);
  });

  test('date-time knob row declares a typed DateTime control', () {
    final dateTimeKnobRow = desyDesignSystemRegistry.allComponents.singleWhere(
      (component) => component.id == 'desy.component.date-time-knob-row',
    );

    expect(dateTimeKnobRow.instanceIds, ['default', 'evening', 'disabled']);
    expect(
      dateTimeKnobRow.knobDefinitions.map((definition) => definition.kind),
      [DesyKnobKind.string, DesyKnobKind.dateTime, DesyKnobKind.boolean],
    );
  });

  test('chat components declare composable slots and event knobs', () {
    final message = desyDesignSystemRegistry.allComponents.singleWhere(
      (component) => component.id == 'desy.component.chat-message',
    );
    final composer = desyDesignSystemRegistry.allComponents.singleWhere(
      (component) => component.id == 'desy.component.chat-composer',
    );
    final thread = desyDesignSystemRegistry.allComponents.singleWhere(
      (component) => component.id == 'desy.component.chat-thread',
    );
    final button = desyDesignSystemRegistry.allComponents.singleWhere(
      (component) => component.id == 'desy.component.button',
    );

    expect(
      message.knobDefinitions.singleWhere((knob) => knob.id == 'body').kind,
      DesyKnobKind.widgetInstance,
    );
    expect(
      composer.knobDefinitions
          .singleWhere((knob) => knob.id == 'onSubmit')
          .kind,
      DesyKnobKind.event,
    );
    expect(
      thread.knobDefinitions.singleWhere((knob) => knob.id == 'messages').kind,
      DesyKnobKind.widgetInstances,
    );
    expect(
      thread.knobDefinitions.singleWhere((knob) => knob.id == 'composer').kind,
      DesyKnobKind.widgetInstance,
    );
    expect(
      button.knobDefinitions.singleWhere((knob) => knob.id == 'onPress').kind,
      DesyKnobKind.event,
    );
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

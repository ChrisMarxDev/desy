import 'package:desy_design_system/desy_design_system.dart';
import 'package:desy_design_system_example/desy_design_system_example.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dogfood registry is valid and complete', () {
    expect(desyDesignSystemRegistry.validate(), isEmpty);
    expect(desyDesignSystemRegistry.themes, hasLength(2));
    expect(desyDesignSystemRegistry.allColors, hasLength(6));
    expect(desyDesignSystemRegistry.allTypography, hasLength(4));
    expect(desyDesignSystemRegistry.allNumbers, hasLength(7));
    expect(desyDesignSystemRegistry.allMotion, hasLength(2));
    expect(desyDesignSystemRegistry.allEffects, hasLength(1));
    expect(desyDesignSystemRegistry.allIcons, hasLength(22));
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
        'desy.component.switch',
        'desy.component.tabs',
        'desy.component.text-field',
        'desy.component.tile',
      }),
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
}

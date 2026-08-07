import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:desy_bench/desy_bench.dart';
import 'package:sample_design_system/sample_design_system.dart';

void main() {
  test(
    'sample registry declares clean typed primitives and production components',
    () {
      expect(sampleRegistry.themes, isNotEmpty);
      expect(sampleRegistry.tokens, isEmpty);
      expect(sampleRegistry.colors, isEmpty);
      expect(sampleRegistry.typography, isEmpty);
      expect(sampleRegistry.numbers, isEmpty);
      expect(sampleRegistry.components, isEmpty);
      expect(sampleRegistry.folders.map((folder) => folder.name), [
        'Atoms',
        'Components',
        'Examples',
      ]);
      final atoms = sampleRegistry.folders.firstWhere(
        (folder) => folder.name == 'Atoms',
      );
      expect(atoms.children.map((folder) => folder.name), [
        'Colors',
        'Fonts',
        'Measurements',
        'Motion',
        'Effects',
        'Assets',
      ]);
      final fonts = atoms.children.singleWhere(
        (folder) => folder.name == 'Fonts',
      );
      expect(fonts, isA<DesyTypographyFolder>());
      expect(fonts.tokens, isEmpty);
      expect(fonts.typography, isNotEmpty);
      final components = sampleRegistry.folders.firstWhere(
        (folder) => folder.name == 'Components',
      );
      expect(components.children.map((folder) => folder.name), [
        'Action',
        'Feedback',
        'Input',
        'Content',
        'Navigation',
        'Operations',
        'Guidance',
      ]);
      final operations = components.children.firstWhere(
        (folder) => folder.name == 'Operations',
      );
      expect(operations.children.map((folder) => folder.name), [
        'Overview',
        'Planning',
      ]);
      expect(
        operations.children
            .firstWhere((folder) => folder.name == 'Overview')
            .children
            .single
            .name,
        'Metrics',
      );
      final guidance = components.children.firstWhere(
        (folder) => folder.name == 'Guidance',
      );
      expect(guidance.children.single.children.single.name, 'Empty states');
      expect(
        sampleRegistry.allEntries.map((entry) => entry.id).toSet().length,
        sampleRegistry.allEntries.length,
        reason: 'Each catalogue leaf has one intentional declaration.',
      );
      expect(
        sampleRegistry.allTokens,
        isEmpty,
        reason:
            'The sample should not duplicate typed primitives as generic token specimens.',
      );
      expect(sampleRegistry.allColors, hasLength(greaterThanOrEqualTo(6)));
      expect(sampleRegistry.allTypography, hasLength(greaterThanOrEqualTo(4)));
      expect(sampleRegistry.allNumbers, hasLength(1));
      expect(
        sampleRegistry.allNumbers
            .singleWhere((entry) => entry.id == 'layout.compact')
            .kind,
        DesyNumericKind.breakpoint,
      );
      expect(sampleRegistry.allMotion, hasLength(greaterThanOrEqualTo(1)));
      expect(sampleRegistry.allEffects, hasLength(2));
      expect(sampleRegistry.allAssets, hasLength(greaterThanOrEqualTo(2)));
      expect(
        sampleRegistry.allAssets.every(
          (asset) =>
              asset.kind == DesyAssetKind.image && asset.image is AssetImage,
        ),
        isTrue,
        reason: 'Sample logos should be packaged image resources.',
      );
      expect(
        sampleRegistry.allComponents.map((component) => component.id),
        containsAll([
          'harbor.button.primary',
          'harbor.badge.status',
          'harbor.field.text',
          'harbor.row.navigation',
          'harbor.metric.operational',
          'harbor.capacity.indicator',
          'harbor.schedule.item',
          'harbor.empty-state',
        ]),
      );
      final contentCard = sampleRegistry.allComponents.firstWhere(
        (component) => component.id == 'harbor.card.content',
      );
      expect(contentCard.contract?.slots.single.name, 'trailing');
      expect(contentCard.scenarios.single.id, 'delayed');
      final instanceKnob = contentCard.knobs
          .whereType<DesyComponentKnob>()
          .single;
      expect(
        instanceKnob.options.map((instance) => instance.id),
        contains('status.delayed'),
      );
      expect(
        instanceKnob.options.every((instance) => instance.icon != null),
        isTrue,
        reason: 'Every declared instance swap should have its own icon.',
      );

      for (final component in sampleRegistry.allComponents) {
        expect(
          component.icon,
          isNotNull,
          reason: '${component.name} should demonstrate a catalogue icon.',
        );
        expect(
          component.instances,
          hasLength(greaterThanOrEqualTo(1)),
          reason: '${component.name} needs a named reusable instance.',
        );
        expect(component.instances.length, lessThanOrEqualTo(2));
      }
      expect(
        sampleRegistry.allComponentInstances.map((instance) => instance.id),
        containsAll([
          'harbor.button.primary.publish-schedule',
          'harbor.badge.status.status.clear',
          'harbor.card.content.north-quay-delayed',
          'harbor.metric.operational.available-berths',
          'harbor.schedule.item.north-quay-inspection',
          'harbor.empty-state.no-arrivals',
        ]),
      );
    },
  );
}

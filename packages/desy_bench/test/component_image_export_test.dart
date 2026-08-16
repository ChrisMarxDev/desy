import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/component_image_export.dart';
import 'package:desy_bench/src/workbench/presentation/detail_screen.dart';
import 'package:desy_bench/src/workbench/presentation/preview_accessibility_overlay.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds a deterministic filesystem-safe PNG name', () {
    expect(
      desyPngFileName(
        entryId: 'Inputs/Primary Button',
        variantId: 'State · Hovered',
        themeId: 'Dark Theme',
      ),
      'inputs-primary-button-state-hovered-dark-theme@2x.png',
    );
    expect(
      desyPngFileName(
        entryId: '图标',
        variantId: '',
        themeId: '',
        pixelRatio: 2.5,
      ),
      'component-default-theme@2.5x.png',
    );
  });

  testWidgets(
    'exports the active real component boundary without Desy overlays',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final component = DesyComponent(
        id: 'marketing-card',
        name: 'Marketing card',
        knobs: (knobs) =>
            (label: knobs.string('label', name: 'Label', initial: 'Default')),
        build: (context, knobs) => Semantics(
          label: knobs.label.value,
          button: true,
          child: const SizedBox(
            width: 22,
            height: 14,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 6,
                height: 4,
                child: ColoredBox(color: Colors.red),
              ),
            ),
          ),
        ),
        instances: (knobs) => {
          'default': [knobs.label('Default')],
          'hero': [knobs.label('Hero')],
        },
      );
      final registry = DesyRegistry(
        name: 'Image export',
        themes: const [DesyTheme(id: 'dark', name: 'Dark', wrap: _wrap)],
        components: [component],
      );
      final entry = registry.resolve(component.id)!;
      final session = DesyWorkbenchSession(registry: registry)
        ..prepareEntry(entry);
      addTearDown(session.dispose);
      GlobalKey? exportedBoundaryKey;
      String? exportedFileName;

      await tester.pumpWidget(
        FTheme(
          data: FTheme.neutral.light.desktop,
          child: MaterialApp(
            home: Scaffold(
              body: DesyDetailScreen(
                session: session,
                entry: entry,
                imageExportAction:
                    ({required boundaryKey, required fileName}) async {
                      exportedBoundaryKey = boundaryKey;
                      exportedFileName = fileName;
                      return DesyImageSaveResult.saved;
                    },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('detail-instance-artboard-instance-hero')),
      );
      session.setPreviewAccessibility(
        session.previewAccessibility.value.copyWith(showSemantics: true),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const ValueKey('detail-controls-list')),
        const Offset(0, -1600),
      );
      await tester.pumpAndSettle();

      expect(find.text('IMAGE'), findsOneWidget);
      expect(find.text('Export image'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byKey(const ValueKey('detail-export-image')),
          matching: find.byKey(const ValueKey('detail-actions-sheet')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('detail-preview-toolbar')),
          matching: find.byKey(const ValueKey('detail-export-image')),
        ),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('detail-export-image')));
      await tester.pumpAndSettle();

      expect(exportedFileName, 'marketing-card-instance-hero-dark@2x.png');
      expect(exportedBoundaryKey, isNotNull);
      final boundary = exportedBoundaryKey!.currentContext!.findRenderObject();
      expect(boundary, isA<RenderRepaintBoundary>());
      expect((boundary! as RenderRepaintBoundary).size, const Size(22, 14));
      expect(
        find.ancestor(
          of: find.byKey(exportedBoundaryKey!),
          matching: find.byType(DesyPreviewAccessibilityOverlay),
        ),
        findsOneWidget,
      );
      expect(
        find.text('Saved marketing-card-instance-hero-dark@2x.png'),
        findsOneWidget,
      );
    },
  );

  testWidgets('does not offer component export on an atom detail', (
    tester,
  ) async {
    final registry = DesyRegistry(
      name: 'Atom detail',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      colors: [
        DesyColorEntry(id: 'accent', name: 'Accent', color: Colors.pink),
      ],
    );
    final entry = registry.resolve('accent')!;
    final session = DesyWorkbenchSession(registry: registry)
      ..prepareEntry(entry);
    addTearDown(session.dispose);

    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.desktop,
        child: MaterialApp(
          home: Scaffold(
            body: DesyDetailScreen(session: session, entry: entry),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('detail-export-image')), findsNothing);
  });
}

Widget _wrap(BuildContext context, Widget child) => child;

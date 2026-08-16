import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/presentation/detail_screen.dart';
import 'package:desy_bench/src/workbench/presentation/preview_accessibility_overlay.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('accessibility controls change only the consumer preview', (
    tester,
  ) async {
    MediaQueryData? previewMedia;
    TextDirection? previewDirection;
    final registry = DesyRegistry(
      name: 'Accessibility preview',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [
        DesyStaticComponent(
          id: 'example',
          name: 'Example',
          instances: {
            'default': (context) {
              previewMedia = MediaQuery.of(context);
              previewDirection = Directionality.of(context);
              return Semantics(
                button: true,
                label: 'Save preview',
                onTap: () {},
                child: const SizedBox(width: 48, height: 48),
              );
            },
          },
        ),
      ],
    );
    final entry = registry.resolve('example')!;
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

    expect(find.text('MEDIA QUERY'), findsOneWidget);
    expect(find.text('Preview frame'), findsOneWidget);
    expect(previewMedia!.textScaler.scale(10), 10);
    expect(previewDirection, TextDirection.ltr);

    await tester.tap(find.byKey(const ValueKey('preview-frame-select')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('preview-frame-iPhone15Pro')));
    await tester.pumpAndSettle();
    expect(session.previewDevice.value, DesyDevicePreset.iPhone15Pro);

    final scale = tester.widget<DesyNumericKnobRow>(
      find.byWidgetPredicate(
        (widget) =>
            widget is DesyNumericKnobRow && widget.label == 'Text scale',
      ),
    );
    scale.onChanged!(1.5);
    await tester.pumpAndSettle();

    expect(previewMedia!.textScaler.scale(10), 15);

    final directionButton = tester.widget<DesyButton>(
      find.ancestor(of: find.text('LTR'), matching: find.byType(DesyButton)),
    );
    directionButton.onPress!();
    await tester.pumpAndSettle();
    expect(previewDirection, TextDirection.rtl);

    final semantics = tester.widget<DesyBooleanKnobRow>(
      find.byWidgetPredicate(
        (widget) =>
            widget is DesyBooleanKnobRow && widget.label == 'Semantic labels',
      ),
    );
    semantics.onChanged!(true);
    await tester.pumpAndSettle();

    expect(find.byType(DesyPreviewAccessibilityOverlay), findsOneWidget);

    final hitTargets = tester.widget<DesyBooleanKnobRow>(
      find.byWidgetPredicate(
        (widget) =>
            widget is DesyBooleanKnobRow && widget.label == 'Hit targets',
      ),
    );
    hitTargets.onChanged!(true);
    await tester.pumpAndSettle();

    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(DesyPreviewAccessibilityOverlay),
        matching: find.byType(CustomPaint),
      ),
    );
    expect(paint.foregroundPainter, isNotNull);
  });
}

Widget _wrap(BuildContext context, Widget child) => child;

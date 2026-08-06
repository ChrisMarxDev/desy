import 'package:desy_bench/desy_bench.dart';
import 'package:desy_screenshot_builder/desy_screenshot_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

void main() {
  const extension = DesyScreenshotBuilderExtension();

  test('declares the screenshot-builder workspace boundary', () {
    expect(extension.id, 'screenshot-builder');
    expect(extension.name, 'Screenshot builder');
    expect(extension.description, 'Compose a repeatable capture recipe.');
    expect(extension.icon, isNotNull);
    expect(extension, isA<DesyWorkspaceExtension>());
  });

  testWidgets('derives its draft summary from the active registry context', (
    tester,
  ) async {
    final registry = DesyRegistry(
      name: 'Harbor',
      themes: const [DesyTheme(id: 'night', name: 'Night watch', wrap: _wrap)],
      folders: [
        DesyFolder(
          id: 'actions',
          name: 'Actions',
          components: [
            DesyComponent(
              id: 'action.publish',
              name: 'Publish',
              preview: _emptyPreview,
            ),
            DesyComponent(
              id: 'action.cancel',
              name: 'Cancel',
              preview: _emptyPreview,
            ),
          ],
        ),
      ],
    );
    final context = DesyWorkspaceExtensionContext(
      registry: registry,
      activeTheme: registry.themes.single,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FTheme(
          data: FTheme.neutral.light.desktop,
          child: Builder(
            builder: (buildContext) => extension.build(buildContext, context),
          ),
        ),
      ),
    );

    expect(find.text('EXPERIMENTAL'), findsOneWidget);
    expect(find.text('Recipe draft'), findsOneWidget);
    expect(find.text('Theme · Night watch'), findsOneWidget);
    expect(find.text('2 declared components'), findsOneWidget);
    expect(find.text('Capture coming soon'), findsOneWidget);
  });
}

Widget _wrap(BuildContext context, Widget child) => child;

Widget _emptyPreview(BuildContext context) => const SizedBox();

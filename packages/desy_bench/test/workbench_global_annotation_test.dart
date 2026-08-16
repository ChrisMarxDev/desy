import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('annotation controls select only scoped consumer content', (
    tester,
  ) async {
    await tester.pumpWidget(
      DesyBenchApp(
        registry: DesyRegistry(
          name: 'Annotation test',
          themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
          components: [
            DesyStaticComponent(
              id: 'annotation.button',
              name: 'Annotation button',
              path: '/actions',
              instances: {
                'default': (_) => const SizedBox(
                  width: 120,
                  height: 48,
                  child: Text('A real registry widget'),
                ),
              },
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final reportIssue = find.byKey(
      const ValueKey('registry-spine-report-issue'),
    );
    expect(reportIssue, findsOneWidget);
    expect(
      tester.widget<DesyButton>(reportIssue).semanticsLabel,
      'Report an issue',
    );
    final inspectionToggle = find.byKey(
      const ValueKey('registry-spine-toggle-inspection'),
    );
    expect(
      tester.getCenter(reportIssue).dx,
      lessThan(tester.getCenter(inspectionToggle).dx),
      reason: 'the report action sits beside the top-right annotation toggle',
    );

    await tester.tap(inspectionToggle);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('workbench-inspection-overlay')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('workbench-annotation-summary')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('workbench-annotation-summary')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Review your feedback'), findsOneWidget);
  });

  testWidgets('prototype canvas owns the annotation mode switch', (
    tester,
  ) async {
    const prototypeId = 'annotation.prototype.one';
    const sessionId = 'annotation.prototype.session';
    await tester.pumpWidget(
      DesyBenchApp(
        registry: DesyRegistry(
          name: 'Canvas annotation test',
          themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
          prototypes: [
            DesyPrototypeSession(
              id: sessionId,
              name: 'Canvas directions',
              prototypes: [
                DesyPrototype(
                  id: prototypeId,
                  name: 'Annotation direction',
                  builder: _prototypePreview,
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    tester
        .widget<DesySidebarItem>(
          find.byKey(const ValueKey('prototype-session-$sessionId')),
        )
        .onPress!
        .call();
    await tester.pumpAndSettle();

    const prefix = 'prototypes-canvas-$sessionId';
    expect(find.byKey(const ValueKey('$prefix-action-bar')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('registry-spine-toggle-inspection')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('$prefix-mode-annotate')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('workbench-inspection-overlay')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('$prefix-mode-select')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('workbench-inspection-overlay')),
      findsNothing,
    );
  });
}

Widget _wrap(BuildContext context, Widget child) => child;

Widget _prototypePreview(BuildContext context) => const Text('Prototype body');

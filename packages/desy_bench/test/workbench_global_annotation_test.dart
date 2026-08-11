import 'package:desy_bench/desy_bench.dart';
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

    await tester.tap(
      find.byKey(const ValueKey('registry-spine-toggle-inspection')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('workbench-inspection-overlay')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('workbench-annotation-dock')),
      findsNothing,
    );
  });
}

Widget _wrap(BuildContext context, Widget child) => child;

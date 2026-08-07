import 'package:desy_bench/desy_bench.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('detail folder breadcrumbs navigate back to the matching Atlas', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      DesyBenchApp(
        registry: DesyRegistry(
          name: 'Breadcrumb navigation',
          themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
          folders: [
            DesyFolder(
              id: 'components',
              name: 'Components',
              children: [
                DesyFolder(
                  id: 'components.actions',
                  name: 'Actions',
                  components: [
                    DesyComponent(
                      id: 'button.primary',
                      name: 'Primary button',
                      preview: _preview,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    tester.semantics.tap(find.semantics.byLabel('Open Primary button'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('detail-breadcrumb-folder-components')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('detail-breadcrumb-folder-components.actions')),
      findsOneWidget,
    );
    expect(find.semantics.byLabel('Open Actions folder'), findsOneWidget);

    tester.semantics.tap(find.semantics.byLabel('Open Actions folder'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('atlas-search')), findsOneWidget);
    expect(find.text('ACTIONS'), findsOneWidget);
    expect(find.text('Primary button'), findsWidgets);
    semantics.dispose();
  });
}

Widget _preview(BuildContext context) => const SizedBox();

Widget _wrap(BuildContext context, Widget child) => child;

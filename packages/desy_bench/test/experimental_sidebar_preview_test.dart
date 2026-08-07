import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/presentation/workbench_sidebar.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'experimental preview grid shows every entry and keeps tree navigation',
    (tester) async {
      String? destination;
      final registry = DesyRegistry(
        name: 'Visual sidebar',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
        tokens: [
          DesyToken(
            id: 'root.token',
            name: 'Root token',
            builder: (_) => const SizedBox(
              key: ValueKey('root-token-preview'),
              width: 32,
              height: 32,
            ),
          ),
        ],
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
                    id: 'deep.component',
                    name: 'Deep component',
                    preview: (_) =>
                        const SizedBox(key: ValueKey('deep-component-preview')),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      final session = DesyWorkbenchSession(registry: registry);
      addTearDown(session.dispose);

      await tester.pumpWidget(
        FTheme(
          data: FTheme.neutral.light.desktop,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: DesyWorkbenchSidebar(
              session: session,
              location: Uri.parse('/atlas'),
              onNavigate: (location) => destination = location,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('sidebar-folder-components')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('sidebar-catalogue-preview-grid')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('sidebar-catalogue-preview-toggle')),
      );
      await tester.pumpAndSettle();

      final grid = tester.widget<GridView>(
        find.byKey(const ValueKey('sidebar-catalogue-preview-grid')),
      );
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
      expect(delegate.mainAxisExtent, 128);
      expect(grid.semanticChildCount, registry.allEntries.length);
      expect(
        find.byKey(const ValueKey('sidebar-preview-widget-root.token')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('sidebar-preview-widget-deep.component')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('root-token-preview')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('deep-component-preview')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('sidebar-folder-components')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('sidebar-preview-root.token')),
      );
      await tester.pump();
      expect(destination, '/entries/root.token');

      await tester.tap(
        find.byKey(const ValueKey('sidebar-catalogue-preview-toggle')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('sidebar-folder-components')),
        findsOneWidget,
      );
    },
  );
}

Widget _wrap(BuildContext context, Widget child) => child;

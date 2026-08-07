import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/presentation/workbench_sidebar.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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
          for (var index = 0; index < 3; index++)
            DesyToken(
              id: 'extra.token.$index',
              name: 'Extra token $index',
              builder: (_) => const SizedBox(width: 32, height: 32),
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

      Widget buildSidebar(double width) => FTheme(
        data: FTheme.neutral.light.desktop,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: width,
              child: DesyWorkbenchSidebar(
                session: session,
                location: Uri.parse('/atlas'),
                onNavigate: (location) => destination = location,
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(buildSidebar(248));

      expect(
        find.byKey(const ValueKey('sidebar-folder-components')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('sidebar-catalogue-preview-grid')),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey('sidebar-section-catalogue-header-control'),
          ),
          matching: find.byKey(
            const ValueKey('sidebar-catalogue-preview-toggle'),
          ),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('sidebar-catalogue-preview-toggle')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('sidebar-catalogue-preview-grid')),
        findsOneWidget,
      );
      expect(
        (await SharedPreferences.getInstance()).getBool(
          'desy_bench.catalogue.preview_grid',
        ),
        isTrue,
      );
      for (final id in ['components', 'unfiled']) {
        final header = tester.widget<Semantics>(
          find.byKey(ValueKey('sidebar-preview-header-$id')),
        );
        expect(header.properties.header, isTrue);
      }
      expect(
        find.byKey(const ValueKey('sidebar-preview-divider-components')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('sidebar-preview-divider-unfiled')),
        findsOneWidget,
      );
      final componentGrid = tester.widget<GridView>(
        find.byKey(const ValueKey('sidebar-preview-grid-components')),
      );
      final componentDelegate =
          componentGrid.gridDelegate
              as SliverGridDelegateWithFixedCrossAxisCount;
      expect(componentDelegate.crossAxisCount, 1);
      expect(componentGrid.semanticChildCount, 1);
      final grid = tester.widget<GridView>(
        find.byKey(const ValueKey('sidebar-preview-grid-unfiled')),
      );
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
      expect(delegate.mainAxisExtent, 128);
      expect(grid.semanticChildCount, 4);
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

      await tester.pumpWidget(buildSidebar(400));
      await tester.pump();
      final widerDelegate =
          tester
                  .widget<GridView>(
                    find.byKey(const ValueKey('sidebar-preview-grid-unfiled')),
                  )
                  .gridDelegate
              as SliverGridDelegateWithFixedCrossAxisCount;
      expect(widerDelegate.crossAxisCount, 4);

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

  testWidgets('catalogue restores its saved grid view', (tester) async {
    SharedPreferences.setMockInitialValues({
      'desy_bench.catalogue.preview_grid': true,
    });
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'Saved sidebar',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
        tokens: [
          DesyToken(
            id: 'saved.token',
            name: 'Saved token',
            builder: (_) => const SizedBox(width: 32, height: 32),
          ),
        ],
      ),
    );
    addTearDown(session.dispose);

    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.desktop,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 248,
            child: DesyWorkbenchSidebar(
              session: session,
              location: Uri.parse('/atlas'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('sidebar-catalogue-preview-grid')),
      findsOneWidget,
    );
  });

  testWidgets('desktop sidebar resizes by drag', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final registry = DesyRegistry(
      name: 'Resizable sidebar',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      tokens: [
        for (var index = 0; index < 6; index++)
          DesyToken(
            id: 'token.$index',
            name: 'Token $index',
            builder: (_) => const SizedBox(width: 32, height: 32),
          ),
      ],
    );

    await tester.pumpWidget(DesyBenchApp(registry: registry));
    await tester.pumpAndSettle();

    final sidebar = find.byKey(const ValueKey('workbench-sidebar'));
    final handle = find.byKey(const ValueKey('desktop-sidebar-resize-handle'));
    expect(tester.getSize(sidebar).width, 248);
    expect(handle, findsOneWidget);

    await tester.drag(handle, const Offset(144, 0));
    await tester.pumpAndSettle();
    expect(tester.getSize(sidebar).width, greaterThan(360));

    await tester.tap(
      find.byKey(const ValueKey('sidebar-catalogue-preview-toggle')),
    );
    await tester.pumpAndSettle();
    final delegate =
        tester
                .widget<GridView>(
                  find.byKey(const ValueKey('sidebar-preview-grid-unfiled')),
                )
                .gridDelegate
            as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, greaterThan(2));
  });
}

Widget _wrap(BuildContext context, Widget child) => child;

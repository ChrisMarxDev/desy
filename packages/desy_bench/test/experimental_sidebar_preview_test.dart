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
    'component preview grid excludes primitives and preserves the file tree',
    (tester) async {
      final semantics = tester.ensureSemantics();
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
        components: [
          DesyComponent(
            id: 'deep.component',
            name: 'Deep component',
            path: '/actions',
            preview: (_) =>
                const SizedBox(key: ValueKey('deep-component-preview')),
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
        find.byKey(const ValueKey('sidebar-folder-/actions')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('sidebar-components-preview-grid')),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('sidebar-section-components-control')),
          matching: find.byKey(
            const ValueKey('sidebar-components-view-toggle'),
          ),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('sidebar-components-view-toggle')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('sidebar-components-preview-grid')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('workspace-atlas-nav')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('workspace-components-nav')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('workspace-ai-prompts-nav')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('sidebar-section-showcases')),
        findsOneWidget,
      );
      expect(
        (await SharedPreferences.getInstance()).getBool(
          'desy_bench.components.preview_grid',
        ),
        isTrue,
      );
      final header = tester.widget<Semantics>(
        find.byKey(const ValueKey('sidebar-preview-header-/actions')),
      );
      expect(header.properties.header, isTrue);
      expect(header.properties.button, isTrue);
      expect(
        find.byKey(const ValueKey('sidebar-preview-divider-/actions')),
        findsNothing,
      );
      final componentGrid = tester.widget<GridView>(
        find.byKey(const ValueKey('sidebar-preview-grid-/actions')),
      );
      final componentDelegate =
          componentGrid.gridDelegate
              as SliverGridDelegateWithFixedCrossAxisCount;
      expect(componentDelegate.crossAxisCount, 1);
      expect(componentGrid.semanticChildCount, 1);
      expect(
        find.byKey(const ValueKey('sidebar-preview-widget-root.token')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('sidebar-preview-widget-deep.component')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('root-token-preview')), findsNothing);
      expect(
        find.byKey(const ValueKey('deep-component-preview')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('sidebar-folder-/actions')),
        findsNothing,
      );

      tester
          .widget<DesyButton>(
            find.descendant(
              of: find.byKey(const ValueKey('sidebar-preview-header-/actions')),
              matching: find.byType(DesyButton),
            ),
          )
          .onPress!();
      await tester.pump();
      expect(destination, '/atlas?folder=%2Factions');

      await tester.pumpWidget(buildSidebar(400));
      await tester.pump();
      expect(
        tester
            .widget<GridView>(
              find.byKey(const ValueKey('sidebar-preview-grid-/actions')),
            )
            .semanticChildCount,
        1,
      );

      await tester.tap(
        find.byKey(const ValueKey('sidebar-preview-deep.component')),
      );
      await tester.pump();
      expect(destination, '/entries/deep.component');

      await tester.tap(
        find.byKey(const ValueKey('sidebar-components-view-toggle')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('sidebar-folder-/actions')),
        findsOneWidget,
      );
      semantics.dispose();
    },
  );

  testWidgets('atom-only catalogues stay on typed lane navigation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'desy_bench.components.preview_grid': true,
    });
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'Saved sidebar',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
        colors: [
          DesyColorEntry(
            id: 'saved.color',
            name: 'Saved color',
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
      find.byKey(const ValueKey('sidebar-components-preview-grid')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey('sidebar-folder-${DesyAtomKind.colors.id}')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('sidebar-entry-saved.color')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('sidebar-components-view-toggle')),
      findsNothing,
    );
  });

  testWidgets('desktop sidebar resizes by drag', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final registry = DesyRegistry(
      name: 'Resizable sidebar',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [
        for (var index = 0; index < 6; index++)
          DesyComponent(
            id: 'component.$index',
            name: 'Component $index',
            path: '/components',
            preview: (_) => const SizedBox(width: 32, height: 32),
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
      find.byKey(const ValueKey('sidebar-components-view-toggle')),
    );
    await tester.pumpAndSettle();
    final delegate =
        tester
                .widget<GridView>(
                  find.byKey(
                    const ValueKey('sidebar-preview-grid-/components'),
                  ),
                )
                .gridDelegate
            as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, greaterThan(2));
  });
}

Widget _wrap(BuildContext context, Widget child) => child;

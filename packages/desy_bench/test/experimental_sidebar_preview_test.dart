import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/presentation/workbench_sidebar.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('components always use the registry-derived file list', (
    tester,
  ) async {
    String? destination;
    final registry = DesyRegistry(
      name: 'List sidebar',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      tokens: [
        DesyToken(
          id: 'root.token',
          name: 'Root token',
          builder: (_) => const SizedBox(),
        ),
      ],
      components: [
        DesyStaticComponent(
          id: 'deep.component',
          name: 'Deep component',
          path: '/actions',
          instances: {
            'default': (_) =>
                const SizedBox(key: ValueKey('deep-component-preview')),
          },
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
              location: Uri.parse('/entries/deep.component'),
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
      find.byKey(const ValueKey('sidebar-entry-deep.component')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('registry-home-nav')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('sidebar-components-view-toggle')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('sidebar-components-preview-grid')),
      findsNothing,
    );

    tester
        .widget<DesySidebarItem>(
          find.byKey(const ValueKey('sidebar-folder-/actions')),
        )
        .onPress!();
    await tester.pump();
    expect(destination, '/atlas?folder=%2Factions');

    await tester.pumpWidget(buildSidebar(400));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('sidebar-folder-/actions')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('sidebar-entry-deep.component')),
      findsOneWidget,
    );
  });

  testWidgets('atom-only catalogues stay on typed lane navigation', (
    tester,
  ) async {
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'Saved sidebar',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
        colors: [
          DesyColorEntry(
            id: 'saved.color',
            name: 'Saved color',
            color: const Color(0xff0055aa),
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
    var closeCount = 0;
    var minimizeCount = 0;
    var maximizeCount = 0;
    final registry = DesyRegistry(
      name: 'Resizable sidebar',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [
        for (var index = 0; index < 6; index++)
          DesyStaticComponent(
            id: 'component.$index',
            name: 'Component $index',
            path: '/components',
            instances: {
              'default': (_) => const SizedBox(width: 32, height: 32),
            },
          ),
      ],
    );

    await tester.pumpWidget(
      DesyBenchApp(
        registry: registry,
        windowControls: DesyWindowControls(
          onClose: () => closeCount++,
          onMinimize: () => minimizeCount++,
          onToggleMaximize: () => maximizeCount++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final id in ['close', 'minimize', 'maximize']) {
      final indicator = tester.widget<DecoratedBox>(
        find.byKey(ValueKey('window-control-$id-indicator')),
      );
      final decoration = indicator.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.border, isNull);
    }
    await tester.tap(find.byKey(const ValueKey('window-control-close')));
    await tester.tap(find.byKey(const ValueKey('window-control-minimize')));
    await tester.tap(find.byKey(const ValueKey('window-control-maximize')));
    expect((closeCount, minimizeCount, maximizeCount), (1, 1, 1));

    final sidebar = find.byKey(const ValueKey('workbench-sidebar'));
    final sidebarRegion = find.byKey(
      const ValueKey('workbench-sidebar-region'),
    );
    final contentRegion = find.byKey(
      const ValueKey('workbench-content-region'),
    );
    final contentTopDivider = find.byKey(
      const ValueKey('workbench-content-top-divider'),
    );
    final handle = find.byKey(const ValueKey('desktop-sidebar-resize-handle'));
    expect(tester.getSize(sidebar).width, 248);
    expect(tester.getSize(sidebarRegion).width, 248);
    expect(handle, findsOneWidget);
    expect(tester.getSize(handle).width, 8);
    expect(tester.getCenter(handle).dx, 248);
    final dividerLine = find.descendant(
      of: handle,
      matching: find.byType(ColoredBox),
    );
    expect(dividerLine, findsOneWidget);
    expect(tester.getSize(dividerLine).width, 1);
    expect(tester.getTopLeft(contentRegion).dx, 248);
    expect(tester.getTopLeft(contentTopDivider), const Offset(248, 48));
    final themePicker = find.byKey(const ValueKey('top-bar-theme-select'));
    expect(tester.getTopLeft(themePicker).dx, 272);
    expect(tester.getSize(themePicker).width, lessThan(220));
    expect(
      find.descendant(
        of: themePicker,
        matching: find.byIcon(DesyIcons.palette),
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.byType(DesyScaffold)).dx,
      248,
      reason: 'the resize divider overlays the row boundary without a gap',
    );
    await tester.drag(handle, const Offset(144, 0));
    await tester.pumpAndSettle();
    expect(tester.getSize(sidebar).width, greaterThan(360));
    expect(
      tester.getCenter(handle).dx,
      tester.getTopRight(sidebarRegion).dx,
      reason: 'the single resize divider tracks the resizable sidebar edge',
    );
    expect(
      tester.getTopLeft(contentRegion).dx,
      tester.getTopRight(sidebarRegion).dx,
      reason: 'content starts immediately after the sidebar',
    );
    expect(
      tester.getTopLeft(contentTopDivider).dx,
      tester.getTopLeft(contentRegion).dx,
      reason: 'the content column owns its horizontal top divider',
    );
    expect(
      find.byKey(const ValueKey('registry-spine-top-bar-left-segment')),
      findsNothing,
      reason: 'the floating top controls do not paint a second panel edge',
    );

    final toggle = find.byKey(const ValueKey('registry-spine-toggle-sidebar'));
    expect(
      tester.getTopLeft(toggle).dx,
      136,
      reason: 'the Flutter window controls precede the panel control',
    );
    expect(
      tester.getCenter(toggle).dy,
      24,
      reason: 'the panel control shares the native traffic-light centerline',
    );
    expect(
      tester.widget<DesyButton>(toggle).semanticsLabel,
      'Hide registry sidebar',
    );
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(toggle, findsOneWidget);
    expect(
      tester.widget<DesyButton>(toggle).semanticsLabel,
      'Show registry sidebar',
    );
    expect(tester.getSize(sidebarRegion).width, 0);
    expect(handle, findsNothing);
    expect(tester.getTopLeft(contentRegion).dx, 0);
    expect(
      tester.getTopLeft(themePicker).dx,
      greaterThanOrEqualTo(tester.getTopRight(toggle).dx + 16),
      reason: 'the collapsed theme selector clears the leading controls',
    );
    expect(
      find.byKey(const ValueKey('desktop-sidebar-restore')),
      findsNothing,
      reason: 'the persistent top-frame control restores the sidebar',
    );

    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('sidebar-folder-/components')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('sidebar-components-view-toggle')),
      findsNothing,
    );
  });

  testWidgets('desktop top frame has no agent sidebar controls', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final registry = DesyRegistry(
      name: 'Registry frame',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
    );

    await tester.pumpWidget(DesyBenchApp(registry: registry));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('registry-spine-toggle-agent-sidebar')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('registry-spine-agent-rail')),
      findsNothing,
    );
  });
}

Widget _wrap(BuildContext context, Widget child) => child;

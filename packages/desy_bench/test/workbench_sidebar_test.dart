import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/presentation/workbench_sidebar.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desy_design_system/desy_design_system.dart';

void main() {
  testWidgets('a deep-linked entry expands every sidebar ancestor', (
    tester,
  ) async {
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'Deep link',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
        folders: [
          DesyFolder(
            id: 'one',
            name: 'One',
            children: [
              DesyFolder(
                id: 'one.two',
                name: 'Two',
                children: [
                  DesyFolder(
                    id: 'one.two.three',
                    name: 'Three',
                    components: [_component('deep.component')],
                  ),
                ],
              ),
            ],
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
          child: DesyWorkbenchSidebar(
            session: session,
            location: Uri.parse('/entries/deep.component'),
          ),
        ),
      ),
    );

    for (final id in ['one', 'one.two', 'one.two.three']) {
      expect(
        tester
            .widget<FSidebarItem>(find.byKey(ValueKey('sidebar-folder-$id')))
            .initiallyExpanded,
        isTrue,
      );
    }
  });

  testWidgets('component leaves use overrides and a component fallback icon', (
    tester,
  ) async {
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'Component icons',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
        folders: [
          DesyFolder(
            id: 'components',
            name: 'Components',
            components: [
              _component('default.component'),
              _component('override.component', icon: FLucideIcons.anchor),
            ],
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
          child: DesyWorkbenchSidebar(
            session: session,
            location: Uri.parse('/entries/override.component'),
          ),
        ),
      ),
    );

    Icon iconFor(String id) {
      final item = tester.widget<FSidebarItem>(
        find.byKey(ValueKey('sidebar-entry-$id')),
      );
      return item.icon! as Icon;
    }

    expect(iconFor('default.component').icon, FLucideIcons.component);
    expect(iconFor('override.component').icon, FLucideIcons.anchor);
  });

  testWidgets('catalogue uses one hierarchy and shows only useful leaves', (
    tester,
  ) async {
    String? destination;
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'Folder boundaries',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
        folders: [
          DesyFolder(
            id: 'atoms',
            name: 'Atoms',
            children: [
              DesyFolder(
                id: 'atoms.colors',
                name: 'Colors',
                tokens: [
                  DesyToken(
                    id: 'atoms.color.primary',
                    name: 'Primary color',
                    builder: (_) => const SizedBox(),
                  ),
                ],
              ),
              DesyFolder(id: 'atoms.empty', name: 'Empty'),
            ],
          ),
          DesyFolder(
            id: 'components',
            name: 'Components',
            components: [_component('components.button')],
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
          child: DesyWorkbenchSidebar(
            session: session,
            location: Uri.parse('/atlas'),
            onNavigate: (location) => destination = location,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('sidebar-folder-atoms')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('sidebar-folder-atoms.colors')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('sidebar-folder-atoms.empty')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('sidebar-entry-atoms.color.primary')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('sidebar-folder-components')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('sidebar-entry-components.button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('sidebar-folder-header-atoms')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('sidebar-folder-header-components')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('sidebar-folder-divider-atoms')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('sidebar-folder-divider-components')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('sidebar-tool-ai')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('sidebar-tool-showcases')),
      findsOneWidget,
    );

    final atomsLabel = tester.widget<Text>(find.text('Atoms'));
    final componentsLabel = tester.widget<Text>(find.text('Components'));
    expect(atomsLabel.style?.fontWeight, isNot(FontWeight.w700));
    expect(componentsLabel.style?.fontWeight, isNot(FontWeight.w700));

    tester
        .widget<DesySidebarItem>(
          find.byKey(const ValueKey('sidebar-folder-atoms.colors')),
        )
        .onPress!
        .call();
    await tester.pump();
    expect(destination, '/atlas?folder=atoms.colors');
  });
}

DesyComponent _component(String id, {IconData? icon}) => DesyComponent(
  id: id,
  name: id,
  icon: icon,
  preview: (_) => const SizedBox(),
);

Widget _wrap(BuildContext context, Widget child) => child;

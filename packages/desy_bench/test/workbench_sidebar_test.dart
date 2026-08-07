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

  testWidgets('normal catalogue separates root folders with semantic headers', (
    tester,
  ) async {
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'Folder boundaries',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
        folders: [
          DesyFolder(
            id: 'atoms',
            name: 'Atoms',
            components: [_component('atoms.color')],
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
          ),
        ),
      ),
    );

    for (final id in ['atoms', 'components']) {
      final header = tester.widget<Semantics>(
        find.byKey(ValueKey('sidebar-folder-header-$id')),
      );
      expect(header.properties.header, isTrue);
    }
    expect(
      find.byKey(const ValueKey('sidebar-folder-divider-atoms')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('sidebar-folder-divider-components')),
      findsOneWidget,
    );
  });
}

DesyComponent _component(String id, {IconData? icon}) => DesyComponent(
  id: id,
  name: id,
  icon: icon,
  preview: (_) => const SizedBox(),
);

Widget _wrap(BuildContext context, Widget child) => child;

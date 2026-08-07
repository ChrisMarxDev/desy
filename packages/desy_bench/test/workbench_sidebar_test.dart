import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/presentation/workbench_sidebar.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desy_design_system/desy_design_system.dart';

void main() {
  testWidgets('a deep-linked entry expands its component file-tree ancestors', (
    tester,
  ) async {
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'Deep link',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
        components: [_component('deep.component', path: 'one/two/three')],
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

    for (final path in ['/one', '/one/two', '/one/two/three']) {
      expect(
        tester
            .widget<DesySidebarItem>(
              find.byKey(ValueKey('sidebar-folder-$path')),
            )
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
        components: [
          _component('default.component'),
          _component('override.component', icon: FLucideIcons.anchor),
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
      final item = tester.widget<DesySidebarItem>(
        find.byKey(ValueKey('sidebar-entry-$id')),
      );
      return item.icon! as Icon;
    }

    expect(iconFor('default.component').icon, FLucideIcons.component);
    expect(iconFor('override.component').icon, FLucideIcons.anchor);
  });

  testWidgets('sidebar uses flat sections and a component file tree', (
    tester,
  ) async {
    String? destination;
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'Folder boundaries',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
        colors: [
          DesyColorEntry(
            id: 'atoms.color.primary',
            name: 'Primary color',
            builder: (_) => const SizedBox(),
          ),
        ],
        components: [_component('components.button', path: '/buttons')],
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

    expect(
      find.byKey(const ValueKey('sidebar-section-workspace')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('sidebar-section-atoms')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('sidebar-section-components')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('sidebar-section-showcases')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('sidebar-folder-${DesyAtomKind.colors.id}')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('sidebar-entry-atoms.color.primary')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('sidebar-folder-/buttons')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('sidebar-entry-components.button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('workspace-ai-prompts-nav')),
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
    expect(find.text('Workspace'), findsOneWidget);
    expect(find.text('Atoms'), findsOneWidget);
    expect(find.text('Components'), findsOneWidget);
    expect(find.text('Showcases'), findsOneWidget);

    expect(
      tester
          .widget<DesySidebarItem>(
            find.byKey(const ValueKey('workspace-atlas-nav')),
          )
          .opensScreen,
      isTrue,
    );
    expect(
      tester
          .widget<DesySidebarItem>(
            find.byKey(ValueKey('sidebar-folder-${DesyAtomKind.colors.id}')),
          )
          .opensScreen,
      isFalse,
    );

    tester
        .widget<DesySidebarItem>(
          find.byKey(ValueKey('sidebar-folder-${DesyAtomKind.colors.id}')),
        )
        .onPress!
        .call();
    await tester.pump();
    expect(destination, '/atlas?folder=${DesyAtomKind.colors.id}');
  });

  testWidgets('Components section label opens the Atlas root', (tester) async {
    final semantics = tester.ensureSemantics();
    String? destination;
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'Components destination',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
        components: [_component('components.button', path: '/actions')],
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
            location: Uri.parse('/entries/components.button'),
            onNavigate: (location) => destination = location,
          ),
        ),
      ),
    );

    final label = find.byKey(
      const ValueKey('sidebar-section-label-Components'),
    );
    expect(label, findsOneWidget);
    final labelSemantics = tester.getSemantics(label);
    expect(labelSemantics.label, 'Components');
    expect(labelSemantics.flagsCollection.isButton, isTrue);

    await tester.tap(label);
    await tester.pump();

    expect(destination, '/atlas');
    semantics.dispose();
  });

  testWidgets('sidebar omits Atoms when every typed lane is empty', (
    tester,
  ) async {
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'No atoms',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
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

    expect(find.byKey(const ValueKey('sidebar-section-atoms')), findsNothing);
  });
}

DesyRegistryComponent _component(String id, {IconData? icon, String path = '/'}) =>
    DesyStaticComponent(
      id: id,
      name: id,
      icon: icon,
      path: path,
      instances: {'default': (_) => const SizedBox()},
    );

Widget _wrap(BuildContext context, Widget child) => child;

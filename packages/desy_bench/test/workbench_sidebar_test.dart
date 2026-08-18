import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/presentation/workbench_sidebar.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desy_design_system/desy_design_system.dart';

void main() {
  testWidgets('sidebar search filters registry entries and can be cleared', (
    tester,
  ) async {
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'Searchable registry',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
        components: [
          _component('action.primary', path: '/actions'),
          _component('input.checkbox', path: '/inputs'),
        ],
      ),
    );
    addTearDown(session.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: FTheme(
          data: FTheme.neutral.light.desktop,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: DesyWorkbenchSidebar(
              session: session,
              location: Uri.parse('/atlas'),
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const ValueKey('sidebar-search')),
              matching: find.byType(TextField),
            ),
          )
          .textAlign,
      TextAlign.center,
    );
    expect(
      tester.getCenter(find.text('Search registry')).dx,
      closeTo(
        tester.getCenter(find.byKey(const ValueKey('sidebar-search'))).dx,
        2,
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('sidebar-search')),
      'checkbox',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('sidebar-section-search-results')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('sidebar-entry-input.checkbox')),
      findsOne,
    );
    expect(
      find.byKey(const ValueKey('sidebar-entry-action.primary')),
      findsNothing,
    );

    await tester.tap(find.bySemanticsLabel('Clear registry search'));
    await tester.pumpAndSettle();

    expect(session.sidebarQuery.value, isEmpty);
    expect(
      find.byKey(const ValueKey('sidebar-section-search-results')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('sidebar-entry-action.primary')),
      findsOne,
    );
  });

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
      MaterialApp(
        home: FTheme(
          data: FTheme.neutral.light.desktop,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: DesyWorkbenchSidebar(
              session: session,
              location: Uri.parse('/entries/deep.component'),
            ),
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
      MaterialApp(
        home: FTheme(
          data: FTheme.neutral.light.desktop,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: DesyWorkbenchSidebar(
              session: session,
              location: Uri.parse('/entries/override.component'),
            ),
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

  testWidgets('sidebar groups apps above the catalogue sections', (
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
            color: const Color(0xff0055aa),
          ),
        ],
        components: [_component('components.button', path: '/buttons')],
        prototypes: [
          DesyPrototypeSession(
            id: 'prototype.homepage',
            name: 'Homepage exploration',
            prototypes: const [
              DesyPrototype(
                id: 'prototype.homepage.dense',
                name: 'Dense',
                builder: _prototype,
              ),
            ],
          ),
        ],
      ),
      extensions: [
        DesyWorkspaceExtension.builder(
          id: 'extension.screenshot-builder',
          name: 'Screenshot builder',
          builder: (_, _) => const SizedBox(),
        ),
      ],
    );
    addTearDown(session.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: FTheme(
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
      ),
    );

    expect(
      find.byKey(const ValueKey('sidebar-section-registry')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('sidebar-section-apps')), findsOneWidget);
    expect(find.byKey(const ValueKey('registry-home-nav')), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('workspace-extension-extension.screenshot-builder'),
      ),
      findsOneWidget,
    );
    for (final key in [
      'registry-home-nav',
      'workspace-extension-extension.screenshot-builder',
    ]) {
      expect(
        find.ancestor(
          of: find.byKey(ValueKey(key)),
          matching: find.byKey(const ValueKey('sidebar-section-apps')),
        ),
        findsOneWidget,
      );
    }
    expect(find.byKey(const ValueKey('registry-canvas-nav')), findsNothing);
    expect(find.byKey(const ValueKey('sidebar-section-atoms')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('sidebar-section-components')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('sidebar-section-prototypes')),
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
    expect(find.byKey(const ValueKey('sidebar-section-tools')), findsNothing);
    expect(
      find.byKey(const ValueKey('sidebar-folder-divider-atoms')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('sidebar-folder-divider-components')),
      findsNothing,
    );
    expect(find.text('Registry'), findsNothing);
    expect(find.text('Apps'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Tools'), findsNothing);
    expect(find.text('Screenshot builder'), findsOneWidget);
    expect(find.text('Prototypes'), findsOneWidget);
    expect(find.text('Atoms'), findsOneWidget);
    expect(find.text('Components'), findsOneWidget);
    expect(find.text('Showcases'), findsNothing);

    for (final label in ['Prototypes', 'Atoms', 'Components']) {
      expect(
        find.byKey(ValueKey('sidebar-section-toggle-$label')),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(const ValueKey('sidebar-section-toggle-Registry')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('sidebar-section-toggle-Tools')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('sidebar-section-toggle-Apps')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('sidebar-section-toggle-Atoms')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('sidebar-folder-${DesyAtomKind.colors.id}')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('sidebar-folder-/buttons')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('sidebar-section-toggle-Components')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sidebar-folder-/buttons')), findsNothing);
    expect(
      find.byKey(const ValueKey('sidebar-components-view-toggle')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('sidebar-components-preview-grid')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('sidebar-section-toggle-Atoms')),
    );
    await tester.tap(
      find.byKey(const ValueKey('sidebar-section-toggle-Components')),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<DesySidebarItem>(
            find.byKey(const ValueKey('registry-home-nav')),
          )
          .opensScreen,
      isFalse,
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

    tester
        .widget<DesySidebarItem>(
          find.byKey(const ValueKey('prototype-session-prototype.homepage')),
        )
        .onPress!
        .call();
    await tester.pump();
    expect(destination, '/prototypes/prototype.homepage');

    tester
        .widget<DesySidebarItem>(
          find.byKey(
            const ValueKey('workspace-extension-extension.screenshot-builder'),
          ),
        )
        .onPress!
        .call();
    await tester.pump();
    expect(destination, '/workspace/extension.screenshot-builder');
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
      MaterialApp(
        home: FTheme(
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
      MaterialApp(
        home: FTheme(
          data: FTheme.neutral.light.desktop,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: DesyWorkbenchSidebar(
              session: session,
              location: Uri.parse('/atlas'),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('sidebar-section-atoms')), findsNothing);
  });
}

DesyRegistryComponent _component(
  String id, {
  IconData? icon,
  String path = '/',
}) => DesyStaticComponent(
  id: id,
  name: id,
  icon: icon,
  path: path,
  instances: {'default': (_) => const SizedBox()},
);

Widget _wrap(BuildContext context, Widget child) => child;

Widget _prototype(BuildContext context) => const SizedBox();

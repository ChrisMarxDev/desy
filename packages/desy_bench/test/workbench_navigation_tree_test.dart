import 'package:desy_bench/desy_bench.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:desy_bench/src/workbench/workbench_navigation_tree.dart';
import 'package:desy_bench/src/workbench/workbench_routes.dart';

void main() {
  test('component destinations use canonical paths', () {
    final registry = DesyRegistry(
      name: 'Repeated labels',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [
        _component('alpha.component', path: 'library-alpha/shared'),
        _component('beta.component', path: '/library-beta/shared/'),
      ],
    );

    final tree = DesyWorkbenchNavigationTree.fromRegistry(
      registry,
      extensions: const [],
    );
    final locations = _destinations(tree.roots);
    final apps = tree.roots.firstWhere((node) => node.id == 'apps');
    final home = apps.children.firstWhere((node) => node.id == 'home');
    expect(apps.label, 'Apps');
    expect(apps.location, isNull);
    expect(home.label, 'Home');
    expect(home.location, DesyWorkbenchRoutes.homePath);
    expect(home.children, isEmpty);

    expect(
      locations,
      containsAll([
        DesyWorkbenchRoutes.atlas(folderId: '/library-alpha/shared'),
        DesyWorkbenchRoutes.atlas(folderId: '/library-beta/shared'),
      ]),
    );
    expect(locations.toSet(), hasLength(locations.length));
  });

  test('deep entry navigation retains ID ancestry independently of labels', () {
    final registry = DesyRegistry(
      name: 'Deep',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [_component('deep.component', path: '/one/two/three')],
    );

    final entry = registry.resolve('deep.component')!;
    final tree = DesyWorkbenchNavigationTree.fromRegistry(
      registry,
      extensions: const [],
    );

    expect(entry.folderIds, ['/one', '/one/two', '/one/two/three']);
    expect(
      tree.parent(Uri.parse(DesyWorkbenchRoutes.entry(entry.id))),
      DesyWorkbenchRoutes.atlas(folderId: '/one/two/three'),
    );
  });

  test('typed atoms are browsed through built-in lane destinations', () {
    final registry = DesyRegistry(
      name: 'Primitive navigation',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      colors: [
        DesyColorEntry(
          id: 'color.primary',
          name: 'Primary',
          color: const Color(0xff0055aa),
        ),
      ],
      components: [_component('button.primary', path: '/buttons')],
    );

    final tree = DesyWorkbenchNavigationTree.fromRegistry(
      registry,
      extensions: const [],
    );
    final locations = _destinations(tree.roots);

    expect(
      locations,
      contains(DesyWorkbenchRoutes.atlas(folderId: DesyAtomKind.colors.id)),
    );
    expect(
      locations,
      isNot(contains(DesyWorkbenchRoutes.entry('color.primary'))),
    );
    expect(tree.roots.any((node) => node.id == DesyAtomKind.rootId), isTrue);
    expect(locations, contains(DesyWorkbenchRoutes.entry('button.primary')));
  });

  test('custom atoms use the single built-in Custom lane', () {
    final registry = DesyRegistry(
      name: 'Custom atoms',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      customAtoms: [
        DesyCustomAtom(
          id: 'brand.ribbon',
          name: 'Brand ribbon',
          instances: {'default': (_) => const SizedBox()},
        ),
      ],
    );

    final tree = DesyWorkbenchNavigationTree.fromRegistry(
      registry,
      extensions: const [],
    );

    expect(
      _destinations(tree.roots),
      contains(DesyWorkbenchRoutes.atlas(folderId: DesyAtomKind.custom.id)),
    );
  });

  test('prototype sessions have their own registry-derived destinations', () {
    final registry = DesyRegistry(
      name: 'Prototype navigation',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
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
    );

    final tree = DesyWorkbenchNavigationTree.fromRegistry(
      registry,
      extensions: const [],
    );

    expect(
      _destinations(tree.roots),
      contains(DesyWorkbenchRoutes.prototype('prototype.homepage')),
    );
  });

  test('workspace extensions are grouped with Home under Apps', () {
    final registry = DesyRegistry(
      name: 'Extensions',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
    );
    final extension = DesyWorkspaceExtension.builder(
      id: 'screenshots',
      name: 'Screenshot builder',
      builder: (_, _) => const SizedBox(),
    );

    final tree = DesyWorkbenchNavigationTree.fromRegistry(
      registry,
      extensions: [extension],
    );
    final apps = tree.roots.firstWhere((node) => node.id == 'apps');
    final extensionNode = apps.children.firstWhere(
      (node) => node.id == 'extension.screenshots',
    );

    expect(apps.children.firstWhere((node) => node.id == 'home').label, 'Home');
    expect(extensionNode.label, 'Screenshot builder');
    expect(
      extensionNode.location,
      DesyWorkbenchRoutes.workspaceExtension('screenshots'),
    );
    expect(extensionNode.children, isEmpty);
    expect(tree.roots.any((node) => node.id == 'tools'), isFalse);
  });
}

DesyRegistryComponent _component(String id, {String path = '/'}) =>
    DesyStaticComponent(
      id: id,
      name: id,
      path: path,
      instances: {'default': (_) => const SizedBox()},
    );

List<String> _destinations(Iterable<DesyWorkbenchNavigationNode> nodes) {
  final destinations = <String>[];
  void visit(Iterable<DesyWorkbenchNavigationNode> current) {
    for (final node in current) {
      final location = node.location;
      if (location != null) destinations.add(location);
      visit(node.children);
    }
  }

  visit(nodes);
  return destinations;
}

Widget _wrap(BuildContext context, Widget child) => child;

Widget _prototype(BuildContext context) => const SizedBox();

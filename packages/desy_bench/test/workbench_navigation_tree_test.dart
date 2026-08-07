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
    final workspace = tree.roots.firstWhere((node) => node.id == 'workspace');
    expect(
      workspace.children.firstWhere((node) => node.id == 'components').label,
      'Sketch',
    );

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
          builder: (_) => const SizedBox(),
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
}

DesyComponent _component(String id, {String path = '/'}) => DesyComponent(
  id: id,
  name: id,
  path: path,
  preview: (_) => const SizedBox(),
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

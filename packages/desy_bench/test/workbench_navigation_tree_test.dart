import 'package:desy_bench/desy_bench.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:desy_bench/src/workbench/workbench_navigation_tree.dart';
import 'package:desy_bench/src/workbench/workbench_routes.dart';

void main() {
  test('folder destinations use stable IDs when labels repeat', () {
    final registry = DesyRegistry(
      name: 'Repeated labels',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      folders: [
        DesyFolder(
          id: 'library.alpha',
          name: 'Library',
          children: [
            DesyFolder(
              id: 'library.alpha.shared',
              name: 'Shared',
              components: [_component('alpha.component')],
            ),
          ],
        ),
        DesyFolder(
          id: 'library.beta',
          name: 'Library',
          children: [
            DesyFolder(
              id: 'library.beta.shared',
              name: 'Shared',
              components: [_component('beta.component')],
            ),
          ],
        ),
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
        DesyWorkbenchRoutes.atlas(folderId: 'library.alpha.shared'),
        DesyWorkbenchRoutes.atlas(folderId: 'library.beta.shared'),
      ]),
    );
    expect(locations.toSet(), hasLength(locations.length));
  });

  test('deep entry navigation retains ID ancestry independently of labels', () {
    final registry = DesyRegistry(
      name: 'Deep',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      folders: [
        DesyFolder(
          id: 'one',
          name: 'Repeated',
          children: [
            DesyFolder(
              id: 'one.two',
              name: 'Repeated',
              children: [
                DesyFolder(
                  id: 'one.two.three',
                  name: 'Repeated',
                  components: [_component('deep.component')],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    final entry = registry.resolve('deep.component')!;
    final tree = DesyWorkbenchNavigationTree.fromRegistry(
      registry,
      extensions: const [],
    );

    expect(entry.folderIds, ['one', 'one.two', 'one.two.three']);
    expect(
      tree.parent(Uri.parse(DesyWorkbenchRoutes.entry(entry.id))),
      DesyWorkbenchRoutes.atlas(folderId: 'one.two.three'),
    );
  });
}

DesyComponent _component(String id) =>
    DesyComponent(id: id, name: id, preview: (_) => const SizedBox());

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

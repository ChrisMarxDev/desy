// Internal workbench navigation infrastructure.
// ignore_for_file: public_member_api_docs

import '../workspace_extension.dart';
import '../registry.dart';
import 'workbench_routes.dart';

/// A navigable branch in Desy's registry-derived workbench tree.
class DesyWorkbenchNavigationNode {
  const DesyWorkbenchNavigationNode({
    required this.id,
    required this.label,
    this.location,
    this.children = const [],
  });

  final String id;
  final String label;
  final String? location;
  final List<DesyWorkbenchNavigationNode> children;
}

/// One derived navigation tree shared by keyboard traversal and future command
/// palette work. It never creates a second registry or navigation source.
class DesyWorkbenchNavigationTree {
  const DesyWorkbenchNavigationTree(this.roots);

  final List<DesyWorkbenchNavigationNode> roots;

  factory DesyWorkbenchNavigationTree.fromRegistry(
    DesyRegistry registry, {
    required List<DesyWorkspaceExtension> extensions,
  }) {
    final rootFolders = registry.folders;

    return DesyWorkbenchNavigationTree([
      DesyWorkbenchNavigationNode(
        id: 'workspace',
        label: 'Workspace',
        children: [
          const DesyWorkbenchNavigationNode(
            id: 'atlas',
            label: 'Atlas',
            location: DesyWorkbenchRoutes.atlasPath,
          ),
          const DesyWorkbenchNavigationNode(
            id: 'components',
            label: 'Sketch',
            location: DesyWorkbenchRoutes.componentsPath,
          ),
          const DesyWorkbenchNavigationNode(
            id: 'showcases',
            label: 'Showcases',
            location: DesyWorkbenchRoutes.showcasesPath,
          ),
          for (final extension in extensions)
            DesyWorkbenchNavigationNode(
              id: 'workspace.${extension.id}',
              label: extension.name,
              location: DesyWorkbenchRoutes.workspaceExtension(extension.id),
            ),
        ],
      ),
      for (final folder in rootFolders) _folder(registry, folder),
    ]);
  }

  /// The next or previous destination in the visible, depth-first tree.
  String? adjacent(Uri current, {required bool forward}) {
    final destinations = _destinations;
    if (destinations.isEmpty) return null;
    final index = destinations.indexWhere((node) => _matches(node, current));
    if (index < 0) return destinations.first.location;
    final next = index + (forward ? 1 : -1);
    if (next < 0 || next >= destinations.length) return null;
    return destinations[next].location;
  }

  /// The first destination nested beneath the current destination.
  String? firstChild(Uri current) {
    final node = _find(current, roots);
    return node == null ? null : _firstDestination(node.children);
  }

  /// The nearest ancestor that has a concrete destination.
  String? parent(Uri current) {
    final path = _pathTo(current, roots);
    if (path == null) return null;
    for (final node in path.reversed.skip(1)) {
      if (node.location case final location?) return location;
    }
    return null;
  }

  List<DesyWorkbenchNavigationNode> get _destinations => [
    for (final root in roots) ..._flatten(root),
  ].where((node) => node.location != null).toList(growable: false);

  static DesyWorkbenchNavigationNode _folder(
    DesyRegistry registry,
    DesyFolder folder,
  ) => DesyWorkbenchNavigationNode(
    id: 'folder.${folder.id}',
    label: folder.name,
    location: DesyWorkbenchRoutes.atlas(folderId: folder.id),
    children: [
      for (final child in folder.children) _folder(registry, child),
      for (final entry in _directEntries(registry, folder))
        DesyWorkbenchNavigationNode(
          id: 'entry.${entry.id}',
          label: entry.name,
          location: DesyWorkbenchRoutes.entry(entry.id),
        ),
    ],
  );

  static Iterable<DesyRegistryEntry> _directEntries(
    DesyRegistry registry,
    DesyFolder folder,
  ) sync* {
    yield* registry.allEntries.where(
      (entry) =>
          entry.folderIds.isNotEmpty && entry.folderIds.last == folder.id,
    );
  }

  static Iterable<DesyWorkbenchNavigationNode> _flatten(
    DesyWorkbenchNavigationNode node,
  ) sync* {
    yield node;
    for (final child in node.children) {
      yield* _flatten(child);
    }
  }

  static String? _firstDestination(
    Iterable<DesyWorkbenchNavigationNode> nodes,
  ) {
    for (final node in nodes) {
      if (node.location case final location?) return location;
      final nested = _firstDestination(node.children);
      if (nested != null) return nested;
    }
    return null;
  }

  static bool _matches(DesyWorkbenchNavigationNode node, Uri current) =>
      node.location == current.toString();

  static DesyWorkbenchNavigationNode? _find(
    Uri current,
    Iterable<DesyWorkbenchNavigationNode> nodes,
  ) {
    for (final node in nodes) {
      if (_matches(node, current)) return node;
      final nested = _find(current, node.children);
      if (nested != null) return nested;
    }
    return null;
  }

  static List<DesyWorkbenchNavigationNode>? _pathTo(
    Uri current,
    Iterable<DesyWorkbenchNavigationNode> nodes,
  ) {
    for (final node in nodes) {
      if (_matches(node, current)) return [node];
      final nested = _pathTo(current, node.children);
      if (nested != null) return [node, ...nested];
    }
    return null;
  }
}

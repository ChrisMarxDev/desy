// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';

import '../../registry.dart';
import '../widget_preview.dart';
import '../workbench_annotation.dart';

/// Preview cards grouped by the folder paths of a supplied component list.
///
/// The component list remains the only inventory. Folder headings are derived
/// directly from each component's validated path.
class DesyComponentOverview extends StatelessWidget {
  const DesyComponentOverview({
    super.key,
    required this.components,
    required this.registry,
    required this.theme,
    required this.onOpen,
    this.pathPrefix = '/',
    this.leadingSlivers = const [],
    this.emptyMessage = 'No components registered.',
  });

  final List<DesyRegistryComponent> components;
  final DesyRegistry registry;
  final DesyTheme theme;
  final ValueChanged<DesyRegistryComponent> onOpen;
  final String pathPrefix;
  final List<Widget> leadingSlivers;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final root = _ComponentOverviewFolder.root(pathPrefix);
    final prefix = _pathSegments(pathPrefix);
    for (final component in components) {
      var folder = root;
      final segments = component.componentPath.segments.skip(prefix.length);
      for (final segment in segments) {
        folder = folder.childFor(segment);
      }
      folder.components.add(component);
    }

    final sections = <_ComponentOverviewFolder>[];
    for (final child in root.children.values) {
      _appendSections(child, sections);
    }

    return CustomScrollView(
      key: const ValueKey('component-overview-scroll'),
      slivers: [
        ...leadingSlivers,
        if (components.isEmpty)
          SliverToBoxAdapter(
            child: Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        if (root.components.isNotEmpty)
          _ComponentCardsSliver(
            components: root.components,
            registry: registry,
            theme: theme,
            onOpen: onOpen,
            bottomPadding: 18,
          ),
        for (final (index, section) in sections.indexed) ...[
          SliverToBoxAdapter(
            child: _ComponentFolderHeading(
              folder: section,
              first: root.components.isEmpty && index == 0,
            ),
          ),
          if (section.components.isNotEmpty)
            _ComponentCardsSliver(
              components: section.components,
              registry: registry,
              theme: theme,
              onOpen: onOpen,
              bottomPadding: 6,
            ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }

  static void _appendSections(
    _ComponentOverviewFolder folder,
    List<_ComponentOverviewFolder> sections,
  ) {
    sections.add(folder);
    for (final child in folder.children.values) {
      _appendSections(child, sections);
    }
  }

  static List<String> _pathSegments(String path) => path
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);
}

class _ComponentOverviewFolder {
  _ComponentOverviewFolder({
    required this.path,
    required this.label,
    required this.depth,
  });

  factory _ComponentOverviewFolder.root(String pathPrefix) =>
      _ComponentOverviewFolder(
        path: _normalizedPrefix(pathPrefix),
        label: '',
        depth: -1,
      );

  final String path;
  final String label;
  final int depth;
  final components = <DesyRegistryComponent>[];
  final children = <String, _ComponentOverviewFolder>{};

  _ComponentOverviewFolder childFor(String segment) => children.putIfAbsent(
    segment,
    () => _ComponentOverviewFolder(
      path: path == '/' ? '/$segment' : '$path/$segment',
      label: _labelFor(segment),
      depth: depth + 1,
    ),
  );

  static String _normalizedPrefix(String path) {
    final segments = DesyComponentOverview._pathSegments(path);
    return segments.isEmpty ? '/' : '/${segments.join('/')}';
  }

  static String _labelFor(String segment) {
    final label = segment.replaceAll('-', ' ').replaceAll('_', ' ');
    return '${label[0].toUpperCase()}${label.substring(1)}';
  }
}

class _ComponentFolderHeading extends StatelessWidget {
  const _ComponentFolderHeading({required this.folder, required this.first});

  final _ComponentOverviewFolder folder;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = switch (folder.depth) {
      0 => textTheme.headlineSmall,
      1 => textTheme.titleLarge,
      2 => textTheme.titleMedium,
      _ => textTheme.titleSmall,
    };
    final topSpacing = first
        ? 2.0
        : switch (folder.depth) {
            0 => 28.0,
            1 => 20.0,
            2 => 16.0,
            _ => 14.0,
          };
    return Padding(
      padding: EdgeInsets.only(top: topSpacing, bottom: 10),
      child: Semantics(
        header: true,
        child: Text(
          folder.label,
          key: ValueKey('atlas-folder-heading-${folder.path}'),
          style: style,
        ),
      ),
    );
  }
}

class _ComponentCardsSliver extends StatelessWidget {
  const _ComponentCardsSliver({
    required this.components,
    required this.registry,
    required this.theme,
    required this.onOpen,
    required this.bottomPadding,
  });

  final List<DesyRegistryComponent> components;
  final DesyRegistry registry;
  final DesyTheme theme;
  final ValueChanged<DesyRegistryComponent> onOpen;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: EdgeInsets.only(bottom: bottomPadding),
    sliver: SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        mainAxisExtent: 236,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final component = components[index];
        final entry = registry.resolve(component.id)!;
        return _ComponentPreviewCard(
          entry: entry,
          theme: theme,
          onOpen: () => onOpen(component),
        );
      }, childCount: components.length),
    ),
  );
}

class _ComponentPreviewCard extends StatelessWidget {
  const _ComponentPreviewCard({
    required this.entry,
    required this.theme,
    required this.onOpen,
  });

  final DesyRegistryEntry entry;
  final DesyTheme theme;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    button: true,
    label: 'Open ${entry.name}',
    onTap: onOpen,
    child: GestureDetector(
      key: ValueKey('atlas-card-${entry.id}'),
      excludeFromSemantics: true,
      onTap: onOpen,
      child: DesyCatalogueCard(
        identifier: entry.id,
        preview: ClipRect(
          child: DesyWidgetPreview(
            theme: theme,
            builder: (previewContext) => ColoredBox(
              color:
                  theme.previewBackgroundColor ??
                  Theme.of(previewContext).scaffoldBackgroundColor,
              child: Center(
                child: DesyFittedPreview(
                  child: DesyWorkbenchInspectionScope(
                    context: DesyWorkbenchInspectionContext(
                      artifactId: entry.id,
                      kind: 'Registry entry',
                      label: entry.name,
                    ),
                    child: Builder(builder: entry.builder),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

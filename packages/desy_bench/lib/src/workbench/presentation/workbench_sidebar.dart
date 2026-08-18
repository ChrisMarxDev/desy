// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../registry.dart';
import '../workbench_routes.dart';
import '../workbench_session.dart';

/// Persistent catalogue navigation. It deliberately lives outside route bodies
/// so selecting a detail never removes the way back through the system.
class DesyWorkbenchSidebar extends StatelessWidget {
  const DesyWorkbenchSidebar({
    super.key,
    required this.session,
    this.location,
    this.onNavigate,
    this.onOpenAnnotations,
  });

  final DesyWorkbenchSession session;
  final Uri? location;
  final ValueChanged<String>? onNavigate;
  final VoidCallback? onOpenAnnotations;

  @override
  Widget build(BuildContext context) {
    final currentLocation = location ?? GoRouterState.of(context).uri;
    final query = session.sidebarQuery.watch(context).trim();
    final componentRoots = session.registry.componentGroups;
    final componentTree = _componentTreeChildren(
      context,
      componentRoots,
      currentLocation,
    );
    final componentCount = session.registry.allComponents.length;
    final extensions = session.extensions;
    final searchResults = _searchEntries(query);

    return DesySidebar(
      constraints: const BoxConstraints(minWidth: double.infinity),
      headerPadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      footerPadding: EdgeInsets.zero,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: _searchField(context, query),
      ),
      footer: onOpenAnnotations == null
          ? null
          : _SidebarAnnotationSummary(
              session: session,
              onOpen: onOpenAnnotations!,
            ),
      children: [
        if (query.isNotEmpty)
          DesySidebarSection(
            key: const ValueKey('sidebar-section-search-results'),
            label: 'Search results',
            count: searchResults.length,
            children: [
              if (searchResults.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                  child: Text(
                    'No registry entries match “$query”.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                )
              else
                for (final entry in searchResults)
                  _componentEntryItem(context, entry),
            ],
          )
        else ...[
          DesySidebarSection(
            key: const ValueKey('sidebar-section-apps'),
            label: 'Apps',
            children: [
              DesySidebarItem(
                key: const ValueKey('registry-home-nav'),
                icon: const Icon(DesyIcons.layoutGrid, size: 18),
                label: const Text('Home'),
                selected: currentLocation.path == DesyWorkbenchRoutes.homePath,
                onPress: () => _go(context, DesyWorkbenchRoutes.homePath),
              ),
              for (final extension in extensions)
                DesySidebarItem(
                  key: ValueKey('workspace-extension-${extension.id}'),
                  icon: Icon(extension.icon ?? DesyIcons.boxes, size: 18),
                  label: Text(extension.name),
                  selected:
                      currentLocation.path ==
                      DesyWorkbenchRoutes.workspaceExtension(extension.id),
                  onPress: () => _go(
                    context,
                    DesyWorkbenchRoutes.workspaceExtension(extension.id),
                  ),
                ),
            ],
          ),
          if (session.registry.allPrototypes.isNotEmpty)
            DesySidebarSection(
              key: const ValueKey('sidebar-section-prototypes'),
              label: 'Prototypes',
              count: session.registry.allPrototypes.length,
              collapsible: true,
              children: [
                for (final prototypeSession in session.registry.allPrototypes)
                  DesySidebarItem(
                    key: ValueKey('prototype-session-${prototypeSession.id}'),
                    icon: const Icon(DesyIcons.sparkles, size: 18),
                    label: Text(prototypeSession.name),
                    selected:
                        currentLocation.path ==
                        DesyWorkbenchRoutes.prototype(prototypeSession.id),
                    onPress: () => _go(
                      context,
                      DesyWorkbenchRoutes.prototype(prototypeSession.id),
                    ),
                  ),
              ],
            ),
          if (session.registry.hasAtoms)
            DesySidebarSection(
              key: const ValueKey('sidebar-section-atoms'),
              label: 'Atoms',
              collapsible: true,
              children: _atomItems(context, currentLocation),
            ),
          if (componentCount > 0)
            DesySidebarSection(
              key: const ValueKey('sidebar-section-components'),
              label: 'Components',
              count: componentCount,
              collapsible: true,
              onLabelPress: () => _go(context, DesyWorkbenchRoutes.atlasPath),
              children: componentTree,
            ),
        ],
      ],
    );
  }

  List<DesyRegistryEntry> _searchEntries(String query) {
    final normalized = query.toLowerCase();
    if (normalized.isEmpty) return const [];
    return session.registry.allEntries
        .where((entry) {
          final haystack = [
            entry.name,
            entry.id,
            entry.description,
            entry.path,
            ...entry.folderIds,
          ].whereType<String>().join(' ').toLowerCase();
          return haystack.contains(normalized);
        })
        .toList(growable: false);
  }

  Widget _searchField(BuildContext context, String query) {
    final field = DesyTextField(
      key: const ValueKey('sidebar-search'),
      label: 'Search registry',
      value: session.sidebarQuery.value,
      hintText: 'Search registry',
      textAlign: TextAlign.center,
      suffixIcon: query.isEmpty
          ? null
          : DesyButton.icon(
              size: DesyButtonSize.xs,
              variant: DesyButtonVariant.ghost,
              semanticsLabel: 'Clear registry search',
              onPress: () => session.sidebarQuery.value = '',
              child: const Icon(DesyIcons.x, size: 14),
            ),
      onChanged: (value) => session.sidebarQuery.value = value,
    );
    final localizedField =
        Localizations.of<MaterialLocalizations>(
              context,
              MaterialLocalizations,
            ) !=
            null
        ? field
        : Localizations(
            locale: const Locale('en'),
            delegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            child: field,
          );
    return Stack(
      children: [
        localizedField,
        Positioned.directional(
          textDirection: Directionality.of(context),
          start: 14,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: Icon(
                DesyIcons.search,
                size: 16,
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _atomItems(BuildContext context, Uri location) => [
    for (final kind in session.registry.atomKinds)
      DesySidebarItem(
        key: ValueKey('sidebar-folder-${kind.id}'),
        icon: Icon(_folderIcon(kind.label), size: 18),
        label: Text(kind.label),
        selected:
            location.path == DesyWorkbenchRoutes.atlasPath &&
            location.queryParameters['folder'] == kind.id,
        onPress: () =>
            _go(context, DesyWorkbenchRoutes.atlas(folderId: kind.id)),
      ),
  ];

  List<Widget> _componentTreeChildren(
    BuildContext context,
    List<DesyComponentGroup> roots,
    Uri location,
  ) => [
    for (final root in roots) _componentFolderItem(context, root, location),
    for (final component in session.registry.components)
      if (component.componentPath.segments.isEmpty)
        _componentEntryItem(context, session.registry.resolve(component.id)!),
  ];

  DesySidebarItem _componentFolderItem(
    BuildContext context,
    DesyComponentGroup folder,
    Uri location,
  ) {
    final entries = _directEntries(folder);
    return DesySidebarItem(
      key: ValueKey('sidebar-folder-${folder.path}'),
      icon: const Icon(DesyIcons.folder, size: 16),
      label: Text(folder.name),
      selected:
          location.path == DesyWorkbenchRoutes.atlasPath &&
          location.queryParameters['folder'] == folder.path,
      initiallyExpanded: _containsActiveDestination(folder, location),
      onPress: () =>
          _go(context, DesyWorkbenchRoutes.atlas(folderId: folder.path)),
      children: [
        for (final child in folder.children)
          _componentFolderItem(context, child, location),
        for (final entry in entries) _componentEntryItem(context, entry),
      ],
    );
  }

  DesySidebarItem _componentEntryItem(
    BuildContext context,
    DesyRegistryEntry entry,
  ) => DesySidebarItem(
    key: ValueKey('sidebar-entry-${entry.id}'),
    icon: Icon(_entryIcon(entry), size: 16),
    label: Text(entry.name),
    onPress: () {
      session.prepareEntry(entry);
      _go(context, DesyWorkbenchRoutes.entry(entry.id));
    },
  );

  List<DesyRegistryEntry> _directEntries(DesyComponentGroup folder) => [
    for (final component in folder.components)
      session.registry.resolve(component.id)!,
  ];

  bool _containsActiveDestination(DesyComponentGroup folder, Uri location) {
    final folderId = location.queryParameters['folder'];
    if (folderId != null) return _containsFolder(folder, folderId);
    if (location.pathSegments.isNotEmpty &&
        location.pathSegments.first ==
            DesyWorkbenchRoutes.entriesPath.substring(1)) {
      final entryId = location.pathSegments.last;
      return _containsEntry(folder, entryId);
    }
    return false;
  }

  bool _containsFolder(DesyComponentGroup folder, String id) =>
      folder.path == id ||
      folder.children.any((child) => _containsFolder(child, id));

  bool _containsEntry(DesyComponentGroup folder, String id) =>
      session.registry.allEntries.any(
        (entry) => entry.id == id && entry.folderIds.contains(folder.path),
      ) ||
      folder.children.any((child) => _containsEntry(child, id));

  IconData _entryIcon(DesyRegistryEntry entry) =>
      entry.component?.icon ??
      (entry.component == null ? _folderIcon(entry.path) : DesyIcons.component);

  IconData _folderIcon(String name) => switch (name) {
    'Colors' => DesyIcons.palette,
    'Fonts' => DesyIcons.type,
    'Icons' => DesyIcons.shapes,
    'Spacing' || 'Sizing' || 'Shape' => DesyIcons.ruler,
    'Motion' => DesyIcons.sparkles,
    'Effects' => DesyIcons.layers,
    'Assets' => DesyIcons.image,
    _ => DesyIcons.folder,
  };

  void _go(BuildContext context, String location) {
    if (onNavigate case final navigate?) {
      navigate(location);
      return;
    }
    context.go(location);
  }
}

class _SidebarAnnotationSummary extends StatelessWidget {
  const _SidebarAnnotationSummary({
    required this.session,
    required this.onOpen,
  });

  final DesyWorkbenchSession session;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final annotations = session.workbenchAnnotations.watch(context);
    final latest = annotations.isEmpty ? null : annotations.last;
    final colors = context.theme.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Semantics(
        button: true,
        label: 'Open ${annotations.length} annotations',
        child: GestureDetector(
          key: const ValueKey('workbench-annotation-summary'),
          behavior: HitTestBehavior.opaque,
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.desy.signalSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    DesyIcons.messageSquare,
                    size: 14,
                    color: colors.desy.signal,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: latest == null
                      ? Text(
                          'Annotations',
                          style: context.theme.typography.body.sm.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${annotations.length} annotations',
                              style: context.theme.typography.body.sm.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${latest.target.displayLabel}: ${latest.comment}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.theme.typography.body.xs.copyWith(
                                color: colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                ),
                Container(
                  constraints: const BoxConstraints(
                    minWidth: 22,
                    minHeight: 22,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.desy.signal,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${annotations.length}',
                    style: context.theme.typography.body.xs.copyWith(
                      color: colors.desy.onSignal,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

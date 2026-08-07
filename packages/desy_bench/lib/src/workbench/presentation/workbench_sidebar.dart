// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../registry.dart';
import '../widget_preview.dart';
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
    this.onCollapse,
  });

  final DesyWorkbenchSession session;
  final Uri? location;
  final ValueChanged<String>? onNavigate;
  final VoidCallback? onCollapse;

  @override
  Widget build(BuildContext context) {
    final currentLocation = location ?? GoRouterState.of(context).uri;
    final theme = session.activeThemeIndex.watch(context);
    final componentRoots = session.registry.componentGroups;
    final componentTree = _componentTreeChildren(
      context,
      componentRoots,
      currentLocation,
    );
    final componentSections = _componentPreviewSections(componentRoots);
    final componentCount = session.registry.allComponents.length;

    return DesySidebar(
      style: const DesySidebarStyleDelta.delta(
        constraints: BoxConstraints(minWidth: double.infinity),
        headerPadding: EdgeInsetsGeometryDelta.value(EdgeInsets.zero),
        contentPadding: EdgeInsetsGeometryDelta.value(
          EdgeInsets.symmetric(horizontal: 8),
        ),
        footerPadding: EdgeInsetsGeometryDelta.value(EdgeInsets.zero),
      ),
      header: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('DESY BENCH')),
                if (onCollapse case final collapse?)
                  Semantics(
                    container: true,
                    button: true,
                    label: 'Collapse sidebar',
                    child: DesyButton(
                      key: const ValueKey('desktop-sidebar-collapse'),
                      variant: DesyButtonVariant.outline,
                      size: DesyButtonSize.sm,
                      onPress: collapse,
                      child: const Icon(DesyIcons.panelLeftClose, size: 16),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            DesySelect<int>.rich(
              key: const ValueKey('sidebar-theme-select'),
              control: DesySelectControl.lifted(
                value: theme,
                onChange: (index) {
                  if (index != null) session.selectTheme(index);
                },
              ),
              format: (index) => session.registry.themes[index].name,
              children: [
                for (final (index, option) in session.registry.themes.indexed)
                  DesySelectItem.item(
                    key: ValueKey('sidebar-theme-${option.id}'),
                    value: index,
                    title: Text(option.name),
                    subtitle: Text(option.description ?? 'Preview context'),
                  ),
              ],
            ),
          ],
        ),
      ),
      children: [
        DesySidebarSection(
          key: const ValueKey('sidebar-section-workspace'),
          label: 'Workspace',
          children: [
            DesySidebarItem.screen(
              key: const ValueKey('workspace-atlas-nav'),
              icon: const Icon(DesyIcons.layoutGrid, size: 18),
              label: const Text('Atlas'),
              selected:
                  currentLocation.path == DesyWorkbenchRoutes.atlasPath &&
                  currentLocation.queryParameters['folder'] == null,
              onPress: () => _go(context, DesyWorkbenchRoutes.atlasPath),
            ),
            DesySidebarItem.screen(
              key: const ValueKey('workspace-components-nav'),
              icon: const Icon(DesyIcons.boxes, size: 18),
              label: const Text('Sketch'),
              selected:
                  currentLocation.path == DesyWorkbenchRoutes.componentsPath,
              onPress: () => _go(context, DesyWorkbenchRoutes.componentsPath),
            ),
            const DesySidebarItem.screen(
              key: ValueKey('workspace-ai-prompts-nav'),
              icon: Icon(DesyIcons.sparkles, size: 18),
              label: Text('AI prompts'),
            ),
            for (final extension in session.extensions)
              DesySidebarItem.screen(
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
        if (session.registry.hasAtoms)
          DesySidebarSection(
            key: const ValueKey('sidebar-section-atoms'),
            label: 'Atoms',
            children: _atomItems(context, currentLocation),
          ),
        if (componentCount > 0)
          _ComponentsSidebarSection(
            entryCount: componentCount,
            sections: componentSections,
            theme: session.registry.themes[theme],
            selectedEntryId: _selectedEntryId(currentLocation),
            onOpenSection: (section) => _go(
              context,
              DesyWorkbenchRoutes.atlas(folderId: section.folderId),
            ),
            onOpen: (entry) {
              session.prepareEntry(entry);
              _go(context, DesyWorkbenchRoutes.entry(entry.id));
            },
            treeChildren: componentTree,
          ),
        DesySidebarSection(
          key: const ValueKey('sidebar-section-showcases'),
          label: 'Showcases',
          count: session.registry.allShowcases.length,
          children: [
            DesySidebarItem(
              key: const ValueKey('showcases-nav'),
              icon: const Icon(DesyIcons.layers, size: 18),
              label: const Text('Overview'),
              selected:
                  currentLocation.path == DesyWorkbenchRoutes.showcasesPath,
              onPress: () => _go(context, DesyWorkbenchRoutes.showcasesPath),
            ),
          ],
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

  List<_SidebarPreviewSection> _componentPreviewSections(
    List<DesyComponentGroup> roots,
  ) {
    final entries = session.registry.allEntries
        .where((entry) => entry.component != null)
        .toList(growable: false);
    final sections = <_SidebarPreviewSection>[];
    for (final folder in roots) {
      final folderEntries = entries
          .where((entry) => entry.folderIds.contains(folder.path))
          .toList(growable: false);
      if (folderEntries.isNotEmpty) {
        sections.add(
          _SidebarPreviewSection(
            id: folder.path,
            label: folder.name,
            folderId: folder.path,
            entries: folderEntries,
          ),
        );
      }
    }

    final unfiledEntries = entries
        .where((entry) => entry.folderIds.isEmpty)
        .toList(growable: false);
    if (unfiledEntries.isNotEmpty) {
      sections.add(
        _SidebarPreviewSection(
          id: 'unfiled',
          label: 'Unfiled',
          folderId: null,
          entries: unfiledEntries,
        ),
      );
    }
    return List.unmodifiable(sections);
  }

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

String? _selectedEntryId(Uri location) {
  if (location.pathSegments.length != 2 ||
      location.pathSegments.first !=
          DesyWorkbenchRoutes.entriesPath.substring(1)) {
    return null;
  }
  return Uri.decodeComponent(location.pathSegments.last);
}

/// The Components section and its local file-tree/preview-grid preference.
///
/// Both modes resolve previews and destinations from the same active registry.
/// The preference changes presentation only; the file tree remains the default.
class _ComponentsSidebarSection extends StatefulWidget {
  const _ComponentsSidebarSection({
    required this.entryCount,
    required this.sections,
    required this.theme,
    required this.selectedEntryId,
    required this.onOpenSection,
    required this.onOpen,
    required this.treeChildren,
  });

  final int entryCount;
  final List<_SidebarPreviewSection> sections;
  final DesyTheme theme;
  final String? selectedEntryId;
  final ValueChanged<_SidebarPreviewSection> onOpenSection;
  final ValueChanged<DesyRegistryEntry> onOpen;
  final List<Widget> treeChildren;

  @override
  State<_ComponentsSidebarSection> createState() =>
      _ComponentsSidebarSectionState();
}

class _ComponentsSidebarSectionState extends State<_ComponentsSidebarSection> {
  static const _previewGridPreferenceKey = 'desy_bench.components.preview_grid';

  var _showPreviewGrid = false;
  var _modeChosenInThisSession = false;
  SharedPreferences? _preferences;

  @override
  void initState() {
    super.initState();
    unawaited(_restoreMode());
  }

  Future<void> _restoreMode() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _preferences = preferences;
      final savedMode = preferences.getBool(_previewGridPreferenceKey);
      if (!mounted ||
          _modeChosenInThisSession ||
          savedMode == null ||
          widget.sections.isEmpty) {
        return;
      }
      setState(() => _showPreviewGrid = savedMode);
    } on MissingPluginException {
      // Some custom embedders intentionally omit optional preference plugins.
    }
  }

  Future<void> _persistMode(bool showPreviewGrid) async {
    try {
      final preferences = _preferences ?? await SharedPreferences.getInstance();
      _preferences = preferences;
      await preferences.setBool(_previewGridPreferenceKey, showPreviewGrid);
    } on MissingPluginException {
      // The immediate in-memory toggle still works without persistence.
    }
  }

  void _toggleMode() {
    final showPreviewGrid = !_showPreviewGrid;
    _modeChosenInThisSession = true;
    setState(() => _showPreviewGrid = showPreviewGrid);
    unawaited(_persistMode(showPreviewGrid));
  }

  @override
  Widget build(BuildContext context) => DesySidebarSection(
    key: const ValueKey('sidebar-section-components'),
    label: 'Components',
    count: widget.entryCount,
    action: widget.sections.isEmpty
        ? null
        : KeyedSubtree(
            key: const ValueKey('sidebar-section-components-control'),
            child: Icon(
              _showPreviewGrid ? DesyIcons.folderTree : DesyIcons.layoutGrid,
              key: const ValueKey('sidebar-components-view-toggle'),
              size: 15,
            ),
          ),
    actionSemanticsLabel: _showPreviewGrid
        ? 'Use component file tree'
        : 'Use component preview grid',
    onActionPress: widget.sections.isEmpty ? null : _toggleMode,
    children: [
      if (_showPreviewGrid && widget.sections.isNotEmpty)
        _SidebarPreviewGrid(
          sections: widget.sections,
          theme: widget.theme,
          selectedEntryId: widget.selectedEntryId,
          onOpenSection: widget.onOpenSection,
          onOpen: widget.onOpen,
        )
      else
        ...widget.treeChildren,
    ],
  );
}

class _SidebarPreviewGrid extends StatelessWidget {
  const _SidebarPreviewGrid({
    required this.sections,
    required this.theme,
    required this.selectedEntryId,
    required this.onOpenSection,
    required this.onOpen,
  });

  final List<_SidebarPreviewSection> sections;
  final DesyTheme theme;
  final String? selectedEntryId;
  final ValueChanged<_SidebarPreviewSection> onOpenSection;
  final ValueChanged<DesyRegistryEntry> onOpen;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('sidebar-components-preview-grid'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (index, section) in sections.indexed)
        _SidebarPreviewSectionView(
          section: section,
          showDivider: index > 0,
          theme: theme,
          selectedEntryId: selectedEntryId,
          onOpenSection: onOpenSection,
          onOpen: onOpen,
        ),
    ],
  );
}

class _SidebarPreviewSection {
  const _SidebarPreviewSection({
    required this.id,
    required this.label,
    required this.folderId,
    required this.entries,
  });

  final String id;
  final String label;
  final String? folderId;
  final List<DesyRegistryEntry> entries;
}

class _SidebarPreviewSectionView extends StatelessWidget {
  static const _minimumTileWidth = 88.0;
  static const _tileSpacing = 8.0;

  const _SidebarPreviewSectionView({
    required this.section,
    required this.showDivider,
    required this.theme,
    required this.selectedEntryId,
    required this.onOpenSection,
    required this.onOpen,
  });

  final _SidebarPreviewSection section;
  final bool showDivider;
  final DesyTheme theme;
  final String? selectedEntryId;
  final ValueChanged<_SidebarPreviewSection> onOpenSection;
  final ValueChanged<DesyRegistryEntry> onOpen;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (showDivider)
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 9),
          child: Divider(
            key: ValueKey('sidebar-preview-divider-${section.id}'),
            height: 1,
            thickness: 1,
            color: context.theme.colors.border,
          ),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
        child: Semantics(
          key: ValueKey('sidebar-preview-header-${section.id}'),
          header: true,
          button: true,
          label: 'Open ${section.label} catalogue section',
          excludeSemantics: true,
          onTap: () => onOpenSection(section),
          child: DesyButton(
            variant: DesyButtonVariant.ghost,
            size: DesyButtonSize.xs,
            mainAxisAlignment: MainAxisAlignment.start,
            onPress: () => onOpenSection(section),
            child: Text(
              section.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
      LayoutBuilder(
        builder: (context, constraints) {
          final columnCount =
              ((constraints.maxWidth + _tileSpacing) /
                      (_minimumTileWidth + _tileSpacing))
                  .floor()
                  .clamp(1, section.entries.length)
                  .toInt();
          return GridView.builder(
            key: ValueKey('sidebar-preview-grid-${section.id}'),
            shrinkWrap: true,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
              mainAxisExtent: 128,
              crossAxisSpacing: _tileSpacing,
              mainAxisSpacing: _tileSpacing,
            ),
            itemCount: section.entries.length,
            itemBuilder: (context, index) {
              final entry = section.entries[index];
              return DesyButton(
                key: ValueKey('sidebar-preview-${entry.id}'),
                semanticsLabel: 'Open ${entry.name}',
                semanticsTooltip: 'Open catalogue entry',
                selected: entry.id == selectedEntryId,
                variant: DesyButtonVariant.outline,
                size: DesyButtonSize.xs,
                onPress: () => onOpen(entry),
                child: SizedBox(
                  width: 64,
                  height: 104,
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRect(
                          child: IgnorePointer(
                            child: DesyFittedPreview(
                              key: ValueKey(
                                'sidebar-preview-widget-${entry.id}',
                              ),
                              child: DesyWidgetPreview(
                                theme: theme,
                                builder: entry.builder,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    ],
  );
}

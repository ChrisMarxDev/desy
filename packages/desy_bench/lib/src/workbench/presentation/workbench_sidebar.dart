// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
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
    final folders = session.registry.folders;

    return FSidebar(
      style: const FSidebarStyleDelta.delta(
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
                    child: FButton(
                      key: const ValueKey('desktop-sidebar-collapse'),
                      variant: FButtonVariant.outline,
                      size: FButtonSizeVariant.sm,
                      onPress: collapse,
                      child: const Icon(FLucideIcons.panelLeftClose, size: 16),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            FSelect<int>.rich(
              key: const ValueKey('sidebar-theme-select'),
              control: FSelectControl.lifted(
                value: theme,
                onChange: (index) {
                  if (index != null) session.selectTheme(index);
                },
              ),
              format: (index) => session.registry.themes[index].name,
              children: [
                for (final (index, option) in session.registry.themes.indexed)
                  FSelectItem.item(
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
      footer: Padding(
        padding: const EdgeInsets.all(12),
        child: FBadge(
          child: Text('${session.registry.allEntries.length} entries'),
        ),
      ),
      children: [
        _CollapsibleSidebarGroup(
          id: 'workspace',
          label: const Text('Workspace'),
          children: [
            FSidebarItem(
              icon: const Icon(FLucideIcons.layoutGrid),
              label: const Text('Atlas'),
              selected:
                  currentLocation.path == DesyWorkbenchRoutes.atlasPath &&
                  currentLocation.queryParameters['folder'] == null,
              onPress: () => _go(context, DesyWorkbenchRoutes.atlasPath),
            ),
            FSidebarItem(
              key: const ValueKey('workspace-components-nav'),
              icon: const Icon(FLucideIcons.boxes),
              label: const Text('Components'),
              selected:
                  currentLocation.path == DesyWorkbenchRoutes.componentsPath,
              onPress: () => _go(context, DesyWorkbenchRoutes.componentsPath),
            ),
            for (final extension in session.extensions)
              FSidebarItem(
                key: ValueKey('workspace-extension-${extension.id}'),
                icon: Icon(extension.icon ?? FLucideIcons.boxes),
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
        if (session.registry.allEntries.isNotEmpty)
          _CatalogueSidebarGroup(
            entries: session.registry.allEntries,
            theme: session.registry.themes[theme],
            selectedEntryId: _selectedEntryId(currentLocation),
            onOpen: (entry) {
              session.prepareEntry(entry);
              _go(context, DesyWorkbenchRoutes.entry(entry.id));
            },
            treeChildren: [
              for (final folder in folders)
                _folderItem(context, folder, currentLocation),
            ],
          ),
        _CollapsibleSidebarGroup(
          id: 'ai',
          label: const Text('AI'),
          children: const [
            FSidebarItem(
              icon: Icon(FLucideIcons.sparkles),
              label: Text('Prompt library'),
              children: [FSidebarItem(label: Text('No prompts yet'))],
            ),
          ],
        ),
        _CollapsibleSidebarGroup(
          id: 'showcases',
          label: const Text('Showcases'),
          children: [
            FSidebarItem(
              key: const ValueKey('showcases-nav'),
              icon: const Icon(FLucideIcons.layers),
              label: const Text('Overview · experimental'),
              selected:
                  currentLocation.path == DesyWorkbenchRoutes.showcasesPath,
              onPress: () => _go(context, DesyWorkbenchRoutes.showcasesPath),
            ),
          ],
        ),
      ],
    );
  }

  FSidebarItem _folderItem(
    BuildContext context,
    DesyFolder folder,
    Uri location,
  ) {
    final entries = _directEntries(folder);
    return FSidebarItem(
      key: ValueKey('sidebar-folder-${folder.id}'),
      icon: Icon(_folderIcon(folder.name)),
      label: Text(folder.name),
      selected:
          location.path == DesyWorkbenchRoutes.atlasPath &&
          location.queryParameters['folder'] == folder.id,
      initiallyExpanded: _containsActiveDestination(folder, location),
      onPress: () =>
          _go(context, DesyWorkbenchRoutes.atlas(folderId: folder.id)),
      children: [
        for (final child in folder.children)
          _folderItem(context, child, location),
        for (final entry in entries)
          FSidebarItem(
            icon: Icon(_folderIcon(entry.path), size: 16),
            label: Text(entry.name),
            onPress: () {
              session.prepareEntry(entry);
              _go(context, DesyWorkbenchRoutes.entry(entry.id));
            },
          ),
      ],
    );
  }

  List<DesyRegistryEntry> _directEntries(DesyFolder folder) {
    return session.registry.allEntries
        .where(
          (entry) =>
              entry.folderIds.isNotEmpty && entry.folderIds.last == folder.id,
        )
        .toList(growable: false);
  }

  bool _containsActiveDestination(DesyFolder folder, Uri location) {
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

  bool _containsFolder(DesyFolder folder, String id) =>
      folder.id == id ||
      folder.children.any((child) => _containsFolder(child, id));

  bool _containsEntry(DesyFolder folder, String id) =>
      _directEntries(folder).any((entry) => entry.id == id) ||
      folder.children.any((child) => _containsEntry(child, id));

  IconData _folderIcon(String name) => switch (name) {
    'Colors' => FLucideIcons.palette,
    'Fonts' => FLucideIcons.type,
    'Spacing' || 'Sizing' || 'Shape' => FLucideIcons.ruler,
    'Motion' => FLucideIcons.sparkles,
    'Effects' => FLucideIcons.layers,
    'Assets' => FLucideIcons.image,
    _ => FLucideIcons.folder,
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

/// An opt-in visual catalogue that experiments with recognition over recall.
///
/// The folder tree remains the stable default. This mode owns presentation
/// state only and resolves every preview and destination from the same active
/// registry used by the rest of the workbench.
class _CatalogueSidebarGroup extends StatefulWidget {
  const _CatalogueSidebarGroup({
    required this.entries,
    required this.theme,
    required this.selectedEntryId,
    required this.onOpen,
    required this.treeChildren,
  });

  final List<DesyRegistryEntry> entries;
  final DesyTheme theme;
  final String? selectedEntryId;
  final ValueChanged<DesyRegistryEntry> onOpen;
  final List<Widget> treeChildren;

  @override
  State<_CatalogueSidebarGroup> createState() => _CatalogueSidebarGroupState();
}

class _CatalogueSidebarGroupState extends State<_CatalogueSidebarGroup> {
  var _showPreviewGrid = false;

  void _toggleMode() => setState(() => _showPreviewGrid = !_showPreviewGrid);

  @override
  Widget build(BuildContext context) => _CollapsibleSidebarGroup(
    id: 'catalogue',
    label: const Text('Catalogue'),
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: DesyButton(
          key: const ValueKey('sidebar-catalogue-preview-toggle'),
          semanticsLabel: _showPreviewGrid
              ? 'Use catalogue folder tree'
              : 'Try experimental catalogue preview grid',
          semanticsTooltip: _showPreviewGrid
              ? 'Show folder tree'
              : 'Preview grid · experimental',
          variant: DesyButtonVariant.outline,
          size: DesyButtonSize.xs,
          onPress: _toggleMode,
          child: Icon(
            _showPreviewGrid ? DesyIcons.folder : DesyIcons.layoutGrid,
            size: 14,
          ),
        ),
      ),
      if (_showPreviewGrid)
        _SidebarPreviewGrid(
          entries: widget.entries,
          theme: widget.theme,
          selectedEntryId: widget.selectedEntryId,
          onOpen: widget.onOpen,
        )
      else
        ...widget.treeChildren,
    ],
  );
}

class _SidebarPreviewGrid extends StatelessWidget {
  static const _minimumTileWidth = 88.0;
  static const _tileSpacing = 8.0;

  const _SidebarPreviewGrid({
    required this.entries,
    required this.theme,
    required this.selectedEntryId,
    required this.onOpen,
  });

  final List<DesyRegistryEntry> entries;
  final DesyTheme theme;
  final String? selectedEntryId;
  final ValueChanged<DesyRegistryEntry> onOpen;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columnCount =
          ((constraints.maxWidth + _tileSpacing) /
                  (_minimumTileWidth + _tileSpacing))
              .floor()
              .clamp(1, entries.length)
              .toInt();
      return GridView.builder(
        key: const ValueKey('sidebar-catalogue-preview-grid'),
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
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
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
                          key: ValueKey('sidebar-preview-widget-${entry.id}'),
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
  );
}

/// A compact, independent disclosure for a top-level navigation section.
///
/// Section state belongs to the sidebar presentation only; neither routes nor
/// the consumer registry have to know whether a person has folded a group.
class _CollapsibleSidebarGroup extends StatefulWidget {
  const _CollapsibleSidebarGroup({
    required this.id,
    required this.label,
    required this.children,
  });

  final String id;
  final Widget label;
  final List<Widget> children;

  @override
  State<_CollapsibleSidebarGroup> createState() =>
      _CollapsibleSidebarGroupState();
}

class _CollapsibleSidebarGroupState extends State<_CollapsibleSidebarGroup> {
  var _expanded = true;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) => FSidebarGroup(
    key: ValueKey('sidebar-section-${widget.id}'),
    style: const FSidebarGroupStyleDelta.delta(
      padding: EdgeInsetsDelta.value(EdgeInsets.symmetric(vertical: 3)),
      headerPadding: EdgeInsetsGeometryDelta.value(
        EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
      childrenSpacing: 6,
      childrenPadding: EdgeInsetsGeometryDelta.value(EdgeInsets.zero),
      itemStyle: FSidebarItemStyleDelta.delta(
        iconSpacing: 6,
        collapsibleIconSpacing: 6,
        childrenSpacing: 6,
        childrenPadding: EdgeInsetsGeometryDelta.value(
          EdgeInsets.only(left: 12),
        ),
        padding: EdgeInsetsGeometryDelta.value(
          EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
      ),
    ),
    label: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: ValueKey('sidebar-section-${widget.id}-header'),
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: Semantics(
          button: true,
          toggled: _expanded,
          label: '${widget.id} section, ${_expanded ? 'collapse' : 'expand'}',
          child: widget.label,
        ),
      ),
    ),
    action: KeyedSubtree(
      key: ValueKey('sidebar-section-${widget.id}-toggle'),
      child: Semantics(
        button: true,
        label: '${widget.id} section, ${_expanded ? 'collapse' : 'expand'}',
        child: Icon(
          _expanded ? FLucideIcons.chevronUp : FLucideIcons.chevronDown,
          size: 15,
        ),
      ),
    ),
    onActionPress: _toggle,
    children: _expanded ? widget.children : const [],
  );
}

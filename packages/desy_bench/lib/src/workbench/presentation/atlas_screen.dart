// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:state_beacon/state_beacon.dart';

import 'component_overview.dart';
import 'workbench_breadcrumbs.dart';
import '../../registry.dart';
import '../widget_preview.dart';
import '../workbench_annotation.dart';
import '../workbench_session.dart';

/// The compact, browse-first view of a consumer registry.
class DesyAtlasScreen extends StatefulWidget {
  const DesyAtlasScreen({
    super.key,
    required this.session,
    required this.folderId,
    required this.onOpen,
    required this.onOpenCatalogue,
    required this.onOpenFolder,
  });

  final DesyWorkbenchSession session;
  final String? folderId;
  final ValueChanged<DesyRegistryEntry> onOpen;
  final VoidCallback onOpenCatalogue;
  final ValueChanged<String> onOpenFolder;

  @override
  State<DesyAtlasScreen> createState() => _DesyAtlasScreenState();
}

class _DesyAtlasScreenState extends State<DesyAtlasScreen> {
  DesyWorkbenchSession get session => widget.session;
  String? get folderId => widget.folderId;

  @override
  Widget build(BuildContext context) {
    final query = session.atlasQuery.watch(context);
    final theme = session.activeTheme;
    final fontSampleText = session.fontSampleText.watch(context);
    final widgets = session.registry.widgetBuilder;
    final folder = _folderFor(folderId);
    final atomKind = folderId == null
        ? null
        : session.registry.atomKindForId(folderId!);
    final atomRoot = folderId == DesyAtomKind.rootId;
    if (atomKind == null && !atomRoot) {
      final components = folder?.allComponents ?? session.registry.components;
      return _ComponentsAtlas(
        title: folder?.name ?? 'Components',
        pathPrefix: folder?.path ?? '/',
        components: components,
        registry: session.registry,
        theme: theme,
        query: query,
        onQueryChanged: (value) => session.atlasQuery.value = value,
        breadcrumbs: _componentBreadcrumbs(folder),
        onOpenFolder: widget.onOpenFolder,
        onOpen: (component) =>
            widget.onOpen(session.registry.resolve(component.id)!),
      );
    }

    final entries = _entriesFor(folder, atomKind, atomRoot, query);

    if (entries.isNotEmpty &&
        entries.every((entry) => entry.typography != null)) {
      return _FontsAtlas(
        entries: [for (final entry in entries) entry.typography!],
        theme: theme,
        sampleText: fontSampleText,
        onSampleTextChanged: (value) => session.fontSampleText.value = value,
        breadcrumbs: _atomBreadcrumbs(atomKind),
      );
    }

    return Padding(
      key: const ValueKey('atlas-content-padding'),
      padding: const EdgeInsets.fromLTRB(
        desyWorkbenchCanvasInset,
        desyWorkbenchCanvasInset,
        desyWorkbenchCanvasInset,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DesyWorkbenchBreadcrumbs(
            key: const ValueKey('atlas-breadcrumbs'),
            textKey: const ValueKey('atlas-breadcrumb-text'),
            segments: _atomBreadcrumbs(atomKind),
          ),
          const SizedBox(height: 10),
          Text.rich(
            key: const ValueKey('atlas-headline'),
            TextSpan(
              children: [
                TextSpan(
                  text: _title(folder, atomKind, atomRoot),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      '${entries.length} entries',
                      key: const ValueKey('atlas-entry-count'),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (entries.any((entry) => entry.source is DesyColorEntry)) ...[
            const SizedBox(height: 4),
            Text(
              'Color in context.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 20),
          DesyTextField(
            key: const ValueKey('atlas-search'),
            value: query,
            onChanged: (value) => session.atlasQuery.value = value,
            hintText: 'Search',
          ),
          Expanded(
            child: _AtlasEntryGrid(
              entries: entries,
              theme: theme,
              widgets: widgets,
              onOpen: widget.onOpen,
            ),
          ),
        ],
      ),
    );
  }

  List<DesyRegistryEntry> _entriesFor(
    DesyComponentGroup? folder,
    DesyAtomKind? atomKind,
    bool atomRoot,
    String query,
  ) {
    final normalized = query.trim().toLowerCase();
    final candidates = atomKind != null
        ? session.registry.entriesForAtom(atomKind)
        : atomRoot
        ? session.registry.atomKinds.expand(session.registry.entriesForAtom)
        : folder == null
        ? session.registry.allEntries.where(
            (entry) => entry.component != null || entry.folderIds.isEmpty,
          )
        : _directEntriesInFolder(folder);
    return candidates.where((entry) {
      return (normalized.isEmpty ||
          entry.name.toLowerCase().contains(normalized) ||
          entry.id.toLowerCase().contains(normalized));
    }).toList();
  }

  DesyComponentGroup? _folderFor(String? id) {
    if (id == null) return null;
    for (final root in session.registry.componentGroups) {
      final match = _findFolder(root, id);
      if (match != null) return match;
    }
    return null;
  }

  DesyComponentGroup? _findFolder(DesyComponentGroup folder, String id) {
    if (folder.path == id) return folder;
    for (final child in folder.children) {
      final match = _findFolder(child, id);
      if (match != null) return match;
    }
    return null;
  }

  List<DesyRegistryEntry> _directEntriesInFolder(DesyComponentGroup folder) => [
    for (final component in folder.components)
      session.registry.resolve(component.id)!,
  ];

  String _title(
    DesyComponentGroup? folder,
    DesyAtomKind? atomKind,
    bool atomRoot,
  ) => atomKind?.label ?? (atomRoot ? 'Atoms' : folder?.name ?? 'Components');

  List<DesyWorkbenchBreadcrumb> _componentBreadcrumbs(
    DesyComponentGroup? folder,
  ) => [
    DesyWorkbenchBreadcrumb(
      label: 'all/',
      onOpen: folder == null ? null : widget.onOpenCatalogue,
    ),
    if (folder != null)
      for (final group in _groupsForPath(folder.path))
        DesyWorkbenchBreadcrumb(
          label: group.name,
          onOpen: group.path == folder.path
              ? null
              : () => widget.onOpenFolder(group.path),
        ),
  ];

  List<DesyWorkbenchBreadcrumb> _atomBreadcrumbs(DesyAtomKind? atomKind) => [
    DesyWorkbenchBreadcrumb(label: 'all/', onOpen: widget.onOpenCatalogue),
    DesyWorkbenchBreadcrumb(
      label: 'Atoms',
      onOpen: atomKind == null
          ? null
          : () => widget.onOpenFolder(DesyAtomKind.rootId),
    ),
    if (atomKind != null) DesyWorkbenchBreadcrumb(label: atomKind.label),
  ];

  List<DesyComponentGroup> _groupsForPath(String path) {
    final groups = <DesyComponentGroup>[];
    var children = session.registry.componentGroups;
    for (final segment
        in path.split('/').where((segment) => segment.isNotEmpty)) {
      final currentPath = groups.isEmpty
          ? '/$segment'
          : '${groups.last.path}/$segment';
      final group = children.firstWhere(
        (candidate) => candidate.path == currentPath,
      );
      groups.add(group);
      children = group.children;
    }
    return groups;
  }
}

class _ComponentsAtlas extends StatelessWidget {
  const _ComponentsAtlas({
    required this.title,
    required this.pathPrefix,
    required this.components,
    required this.registry,
    required this.theme,
    required this.query,
    required this.onQueryChanged,
    required this.breadcrumbs,
    required this.onOpenFolder,
    required this.onOpen,
  });

  final String title;
  final String pathPrefix;
  final List<DesyRegistryComponent> components;
  final DesyRegistry registry;
  final DesyTheme theme;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final List<DesyWorkbenchBreadcrumb> breadcrumbs;
  final ValueChanged<String> onOpenFolder;
  final ValueChanged<DesyRegistryComponent> onOpen;

  @override
  Widget build(BuildContext context) {
    final normalized = query.trim().toLowerCase();
    final visibleComponents = components
        .where((component) {
          return normalized.isEmpty ||
              component.name.toLowerCase().contains(normalized) ||
              component.id.toLowerCase().contains(normalized);
        })
        .toList(growable: false);

    return Padding(
      key: const ValueKey('atlas-content-padding'),
      padding: const EdgeInsets.fromLTRB(
        desyWorkbenchCanvasInset,
        desyWorkbenchCanvasInset,
        desyWorkbenchCanvasInset,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DesyWorkbenchBreadcrumbs(
            key: const ValueKey('atlas-breadcrumbs'),
            textKey: const ValueKey('atlas-breadcrumb-text'),
            segments: breadcrumbs,
          ),
          const SizedBox(height: 10),
          Text.rich(
            key: const ValueKey('atlas-headline'),
            TextSpan(
              children: [
                TextSpan(
                  text: title,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      '${visibleComponents.length} entries',
                      key: const ValueKey('atlas-entry-count'),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          DesyTextField(
            key: const ValueKey('atlas-search'),
            value: query,
            onChanged: onQueryChanged,
            hintText: 'Search',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: DesyComponentOverview(
                components: visibleComponents,
                registry: registry,
                theme: theme,
                pathPrefix: pathPrefix,
                onOpen: onOpen,
                onOpenFolder: onOpenFolder,
                emptyMessage: 'No components match this search.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AtlasEntryGrid extends StatelessWidget {
  const _AtlasEntryGrid({
    required this.entries,
    required this.theme,
    required this.widgets,
    required this.onOpen,
  });

  final List<DesyRegistryEntry> entries;
  final DesyTheme theme;
  final DesyWidgetResolver widgets;
  final ValueChanged<DesyRegistryEntry> onOpen;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    key: const ValueKey('atlas-entry-grid'),
    slivers: [
      const SliverToBoxAdapter(
        child: SizedBox(key: ValueKey('atlas-scroll-top-padding'), height: 20),
      ),
      _AtlasEntriesSliver(
        entries: entries,
        theme: theme,
        widgets: widgets,
        onOpen: onOpen,
        bottomPadding: 0,
      ),
    ],
  );
}

class _AtlasEntriesSliver extends StatelessWidget {
  const _AtlasEntriesSliver({
    required this.entries,
    required this.theme,
    required this.widgets,
    required this.onOpen,
    required this.bottomPadding,
  });

  final List<DesyRegistryEntry> entries;
  final DesyTheme theme;
  final DesyWidgetResolver widgets;
  final ValueChanged<DesyRegistryEntry> onOpen;
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
      delegate: SliverChildBuilderDelegate(
        (context, index) => _AtlasCard(
          entry: entries[index],
          theme: theme,
          widgets: widgets,
          onOpen: () => onOpen(entries[index]),
        ),
        childCount: entries.length,
      ),
    ),
  );
}

class _AtlasCard extends StatelessWidget {
  const _AtlasCard({
    required this.entry,
    required this.theme,
    required this.widgets,
    required this.onOpen,
  });

  final DesyRegistryEntry entry;
  final DesyTheme theme;
  final DesyWidgetResolver widgets;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      button: true,
      label: 'Open ${entry.name}',
      onTap: onOpen,
      child: GestureDetector(
        key: ValueKey('atlas-card-${entry.id}'),
        // The selectable identifier owns pointer gestures over its text. Taps
        // on the remaining card surface keep the established open-entry
        // behaviour.
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
                    // Measure only the consumer widget at its true natural
                    // size. The full-card theme background must stay outside
                    // this fitted subtree or its empty canvas scales compact
                    // components down with it.
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
}

class _FontsAtlas extends StatelessWidget {
  const _FontsAtlas({
    required this.entries,
    required this.theme,
    required this.sampleText,
    required this.onSampleTextChanged,
    required this.breadcrumbs,
  });

  final List<DesyTypographyEntry> entries;
  final DesyTheme theme;
  final String sampleText;
  final ValueChanged<String> onSampleTextChanged;
  final List<DesyWorkbenchBreadcrumb> breadcrumbs;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(desyWorkbenchCanvasInset),
    children: [
      _FontsAtlasHeader(
        sampleText: sampleText,
        onSampleTextChanged: onSampleTextChanged,
        breadcrumbs: breadcrumbs,
      ),
      const SizedBox(height: 32),
      _FontLedger(entries: entries, theme: theme, sampleText: sampleText),
    ],
  );
}

/// Keeps the editable source copy visually separate from the typography
/// specimens it controls.
class _FontsAtlasHeader extends StatelessWidget {
  const _FontsAtlasHeader({
    required this.sampleText,
    required this.onSampleTextChanged,
    required this.breadcrumbs,
  });

  final String sampleText;
  final ValueChanged<String> onSampleTextChanged;
  final List<DesyWorkbenchBreadcrumb> breadcrumbs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesyWorkbenchBreadcrumbs(
          key: const ValueKey('atlas-breadcrumbs'),
          textKey: const ValueKey('atlas-breadcrumb-text'),
          segments: breadcrumbs,
        ),
        const SizedBox(height: 10),
        Text('Type styles', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 20),
        _FontSampleEditor(
          sampleText: sampleText,
          onSampleTextChanged: onSampleTextChanged,
        ),
      ],
    );
  }
}

class _FontSampleEditor extends StatelessWidget {
  const _FontSampleEditor({
    required this.sampleText,
    required this.onSampleTextChanged,
  });

  final String sampleText;
  final ValueChanged<String> onSampleTextChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.desy.panelSubtle,
        border: Border(left: BorderSide(color: colors.desy.signal, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final editor = DesyTextField(
              key: const ValueKey('font-preview-text'),
              label: 'Specimen copy',
              hintText: 'Write a specimen',
              value: sampleText,
              onChanged: onSampleTextChanged,
            );
            final explanation = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SPECIMEN COPY',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.mutedForeground,
                    letterSpacing: .6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Edit once to proof every declared type style.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            );
            if (constraints.maxWidth < 720) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [explanation, const SizedBox(height: 12), editor],
              );
            }
            return Row(
              children: [
                Expanded(child: explanation),
                const SizedBox(width: 24),
                SizedBox(width: 360, child: editor),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A divider-based type inventory: each row gives metadata a stable left
/// column and lets the consumer's real specimen occupy the reading space.
class _FontLedger extends StatelessWidget {
  const _FontLedger({
    required this.entries,
    required this.theme,
    required this.sampleText,
  });

  final List<DesyTypographyEntry> entries;
  final DesyTheme theme;
  final String sampleText;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const ValueKey('font-ledger'),
    decoration: BoxDecoration(
      border: Border.symmetric(
        horizontal: BorderSide(color: context.theme.colors.desy.divider),
      ),
    ),
    child: Column(
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          _FontLedgerRow(
            entry: entries[index],
            theme: theme,
            sampleText: sampleText,
          ),
          if (index < entries.length - 1)
            Divider(height: 1, color: context.theme.colors.desy.divider),
        ],
      ],
    ),
  );
}

class _FontLedgerRow extends StatelessWidget {
  const _FontLedgerRow({
    required this.entry,
    required this.theme,
    required this.sampleText,
  });

  final DesyTypographyEntry entry;
  final DesyTheme theme;
  final String sampleText;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final metadata = _FontMetadata(entry: entry);
        final specimen = _FontSpecimen(
          entry: entry,
          theme: theme,
          sampleText: sampleText,
        );
        if (constraints.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [metadata, const SizedBox(height: 20), specimen],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 1, child: metadata),
            Container(
              width: 1,
              height: 68,
              color: context.theme.colors.desy.divider,
            ),
            const SizedBox(width: 28),
            Expanded(flex: 2, child: specimen),
          ],
        );
      },
    ),
  );
}

class _FontMetadata extends StatelessWidget {
  const _FontMetadata({required this.entry});

  final DesyTypographyEntry entry;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(entry.name, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4),
      Text(
        entry.value ?? entry.id,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: context.theme.colors.mutedForeground,
        ),
      ),
      if (entry.description case final description?) ...[
        const SizedBox(height: 12),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
      ],
    ],
  );
}

class _FontSpecimen extends StatelessWidget {
  const _FontSpecimen({
    required this.entry,
    required this.theme,
    required this.sampleText,
  });

  final DesyTypographyEntry entry;
  final DesyTheme theme;
  final String sampleText;

  @override
  Widget build(BuildContext context) => DesyWidgetPreview(
    theme: theme,
    builder: (context) => entry.builder(context, sampleText),
  );
}

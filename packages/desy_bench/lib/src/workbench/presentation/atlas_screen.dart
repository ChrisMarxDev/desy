// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:state_beacon/state_beacon.dart';

import 'motion_playback_controls.dart';
import '../../motion_playback.dart';
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
  });

  final DesyWorkbenchSession session;
  final String? folderId;
  final ValueChanged<DesyRegistryEntry> onOpen;

  @override
  State<DesyAtlasScreen> createState() => _DesyAtlasScreenState();
}

class _DesyAtlasScreenState extends State<DesyAtlasScreen>
    with TickerProviderStateMixin {
  DesyMotionPlaybackController? _motionPlayback;
  Duration? _globalMotionDuration;

  DesyWorkbenchSession get session => widget.session;
  String? get folderId => widget.folderId;

  @override
  void initState() {
    super.initState();
    _configureMotionPlayback();
  }

  @override
  void didUpdateWidget(covariant DesyAtlasScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.folderId != widget.folderId ||
        oldWidget.session != widget.session) {
      _configureMotionPlayback();
    }
  }

  void _configureMotionPlayback() {
    _motionPlayback?.dispose();
    _motionPlayback = null;
    _globalMotionDuration = null;
    final entries = _entriesForDestination(folderId);
    if (entries.isEmpty ||
        !entries.every((entry) => entry.source is DesyMotionEntry)) {
      return;
    }
    var longestDeclaredDuration = Duration.zero;
    for (final entry in entries) {
      final motion = entry.source as DesyMotionEntry;
      final duration = motion.duration;
      if (duration != null && duration > longestDeclaredDuration) {
        longestDeclaredDuration = duration;
      }
    }
    final globalDuration = longestDeclaredDuration == Duration.zero
        ? DesyMotionPlaybackController.defaultDuration
        : longestDeclaredDuration;
    _globalMotionDuration = globalDuration;
    _motionPlayback = DesyMotionPlaybackController(
      vsync: this,
      duration: globalDuration,
      loopMode: DesyMotionLoopMode.once,
      autoplay: false,
    );
  }

  void _setGlobalMotionDuration(Duration duration) {
    final playback = _motionPlayback;
    if (playback == null || duration <= Duration.zero) return;
    setState(() {
      _globalMotionDuration = duration;
      playback.setDuration(duration);
    });
  }

  @override
  void dispose() {
    _motionPlayback?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = session.atlasQuery.watch(context);
    final theme = session.activeTheme;
    final fontSampleText = session.fontSampleText.watch(context);
    final folder = _folderFor(folderId);
    final atomKind = folderId == null
        ? null
        : session.registry.atomKindForId(folderId!);
    final atomRoot = folderId == DesyAtomKind.rootId;
    final entries = _entriesFor(folder, atomKind, atomRoot, query);

    if (entries.isNotEmpty &&
        entries.every((entry) => entry.typography != null)) {
      return _FontsAtlas(
        entries: [for (final entry in entries) entry.typography!],
        theme: theme,
        sampleText: fontSampleText,
        onSampleTextChanged: (value) => session.fontSampleText.value = value,
      );
    }

    return Padding(
      key: const ValueKey('atlas-content-padding'),
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _eyebrow(folder, atomKind, atomRoot),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
          Text(
            _title(folder, atomKind, atomRoot),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          if ((_motionPlayback, _globalMotionDuration) case (
            final playback?,
            final globalDuration?,
          )) ...[
            const SizedBox(height: 14),
            DesyMotionPlaybackControls(
              controller: playback,
              compact: true,
              globalDuration: globalDuration,
              onGlobalDurationChanged: _setGlobalMotionDuration,
            ),
          ],
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
          const SizedBox(height: 18),
          Text(
            '${entries.length} entries',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 280,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                mainAxisExtent: 236,
              ),
              itemCount: entries.length,
              itemBuilder: (context, index) => _AtlasCard(
                entry: entries[index],
                theme: theme,
                motionPlayback: _motionPlayback,
                onOpen: () => widget.onOpen(entries[index]),
              ),
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
        : _entriesInFolderTree(folder);
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

  List<DesyRegistryEntry> _entriesInFolderTree(DesyComponentGroup folder) {
    return session.registry.allEntries
        .where((entry) => entry.folderIds.contains(folder.path))
        .toList(growable: false);
  }

  List<DesyRegistryEntry> _entriesForDestination(String? id) {
    if (id == null) return const [];
    if (id == DesyAtomKind.rootId) {
      return [
        for (final kind in session.registry.atomKinds)
          ...session.registry.entriesForAtom(kind),
      ];
    }
    final atomKind = session.registry.atomKindForId(id);
    if (atomKind != null) return session.registry.entriesForAtom(atomKind);
    final folder = _folderFor(id);
    return folder == null ? const [] : _entriesInFolderTree(folder);
  }

  String _eyebrow(
    DesyComponentGroup? folder,
    DesyAtomKind? atomKind,
    bool atomRoot,
  ) => atomKind != null
      ? 'ATOMS / ${atomKind.label.toUpperCase()}'
      : atomRoot
      ? 'ATOMS'
      : folder == null
      ? 'CATALOGUE'
      : folder.name.toUpperCase();

  String _title(
    DesyComponentGroup? folder,
    DesyAtomKind? atomKind,
    bool atomRoot,
  ) => atomKind?.label ?? (atomRoot ? 'Atoms' : folder?.name ?? 'Components');
}

class _AtlasCard extends StatelessWidget {
  const _AtlasCard({
    required this.entry,
    required this.theme,
    required this.motionPlayback,
    required this.onOpen,
  });

  final DesyRegistryEntry entry;
  final DesyTheme theme;
  final DesyMotionPlaybackController? motionPlayback;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final previewBuilder = _previewBuilder();
    return Semantics(
      container: true,
      explicitChildNodes: true,
      button: true,
      label: 'Open ${entry.name}',
      onTap: onOpen,
      child: GestureDetector(
        key: ValueKey('atlas-card-${entry.id}'),
        // The card owns the semantic tap action above. Keep this gesture for
        // pointer input without adding a second, competing accessibility action.
        excludeFromSemantics: true,
        onTap: onOpen,
        child: DesyCatalogueCard(
          path: entry.path,
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
                      child: Builder(builder: previewBuilder),
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

  WidgetBuilder _previewBuilder() {
    final playback = motionPlayback;
    final source = entry.source;
    if (playback == null || source is! DesyMotionEntry) return entry.builder;
    return (context) => DesyMotionPlaybackScope(
      progress: playback.timeline,
      child: Builder(
        builder: (context) =>
            source.build(context, source.defaultChild.build(context)),
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
  });

  final List<DesyTypographyEntry> entries;
  final DesyTheme theme;
  final String sampleText;
  final ValueChanged<String> onSampleTextChanged;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(28),
    children: [
      _FontsAtlasHeader(
        sampleText: sampleText,
        onSampleTextChanged: onSampleTextChanged,
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
  });

  final String sampleText;
  final ValueChanged<String> onSampleTextChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ATOMS / FONTS', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
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

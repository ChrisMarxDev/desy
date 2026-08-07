// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:state_beacon/state_beacon.dart';

import 'motion_playback_controls.dart';
import '../../motion_playback.dart';
import '../../registry.dart';
import '../widget_preview.dart';
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
      duration: _cycleDuration(entries, globalDuration),
    );
  }

  Duration _cycleDuration(
    List<DesyRegistryEntry> entries,
    Duration globalDuration,
  ) {
    var duration = globalDuration;
    for (final entry in entries) {
      final declared = (entry.source as DesyMotionEntry).duration;
      if (declared != null && declared > duration) duration = declared;
    }
    return duration;
  }

  void _setGlobalMotionDuration(Duration duration) {
    final playback = _motionPlayback;
    if (playback == null || duration <= Duration.zero) return;
    final entries = _entriesForDestination(folderId);
    setState(() {
      _globalMotionDuration = duration;
      playback.setDuration(_cycleDuration(entries, duration));
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
      padding: const EdgeInsets.all(28),
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
                globalMotionDuration: _globalMotionDuration,
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
    required this.globalMotionDuration,
    required this.onOpen,
  });

  final DesyRegistryEntry entry;
  final DesyTheme theme;
  final DesyMotionPlaybackController? motionPlayback;
  final Duration? globalMotionDuration;
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
        // The card owns the semantic tap action above. Keep this gesture for
        // pointer input without adding a second, competing accessibility action.
        excludeFromSemantics: true,
        onTap: onOpen,
        child: DesyCard(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.path.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRect(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        // The consumer widget lays itself out at its intended
                        // logical size; the completed preview then scales down
                        // for this atlas card. Do not impose a compact artboard
                        // on consumer widgets here.
                        child: DesyWidgetPreview(
                          theme: theme,
                          builder: previewBuilder,
                          withThemeBackground: true,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(entry.name, style: Theme.of(context).textTheme.titleSmall),
                // DesyWorkbenchShell supplies SelectionArea for the workbench.
                // A regular Text keeps this identifier on one polished line while
                // retaining selection through that shared surface.
                Text(
                  entry.id,
                  style: Theme.of(context).textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
    final duration =
        source.duration ??
        globalMotionDuration ??
        DesyMotionPlaybackController.defaultDuration;
    final durationRatio =
        (duration.inMicroseconds / playback.duration.inMicroseconds).clamp(
          0.0,
          1.0,
        );
    final progress = playback.timeline.drive(
      CurveTween(curve: Interval(0, durationRatio, curve: source.curve)),
    );
    return (context) => DesyMotionPlaybackScope(
      progress: progress,
      child: Builder(builder: source.builder),
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
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(28),
      itemCount: entries.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ATOMS / FONTS',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Type styles',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 16),
              DesyTextField(
                key: const ValueKey('font-preview-text'),
                label: 'Preview text',
                value: sampleText,
                onChanged: onSampleTextChanged,
              ),
            ],
          );
        }
        final entry = entries[index - 1];
        return DesyCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 16),
                DesyWidgetPreview(
                  theme: theme,
                  builder: (context) => entry.builder(context, sampleText),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

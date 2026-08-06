// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../desy_text_field.dart';
import '../../registry.dart';
import '../widget_preview.dart';
import '../workbench_session.dart';

/// The compact, browse-first view of a consumer registry.
class DesyAtlasScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final query = session.atlasQuery.watch(context);
    final theme = session.activeTheme;
    final fontSampleText = session.fontSampleText.watch(context);
    final folder = _folderFor(folderId);
    final entries = _entriesFor(folder, query);

    if (entries.any((entry) => entry.typography != null)) {
      return _FontsAtlas(
        entries: entries,
        theme: theme,
        sampleText: fontSampleText,
        onSampleTextChanged: (value) => session.fontSampleText.value = value,
        onOpen: onOpen,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_eyebrow(folder), style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(_title(folder), style: Theme.of(context).textTheme.displaySmall),
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
                onOpen: () => onOpen(entries[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DesyRegistryEntry> _entriesFor(DesyFolder? folder, String query) {
    final normalized = query.trim().toLowerCase();
    final candidates = folder == null
        ? session.registry.allEntries.where(
            (entry) => entry.component != null || entry.folderIds.isEmpty,
          )
        : _directEntries(folder);
    return candidates.where((entry) {
      return (normalized.isEmpty ||
          entry.name.toLowerCase().contains(normalized) ||
          entry.id.toLowerCase().contains(normalized));
    }).toList();
  }

  DesyFolder? _folderFor(String? id) {
    if (id == null) return null;
    for (final root in session.registry.folders) {
      final match = _findFolder(root, id);
      if (match != null) return match;
    }
    return null;
  }

  DesyFolder? _findFolder(DesyFolder folder, String id) {
    if (folder.id == id) return folder;
    for (final child in folder.children) {
      final match = _findFolder(child, id);
      if (match != null) return match;
    }
    return null;
  }

  List<DesyRegistryEntry> _directEntries(DesyFolder folder) {
    return session.registry.allEntries
        .where(
          (entry) =>
              entry.folderIds.isNotEmpty && entry.folderIds.last == folder.id,
        )
        .toList(growable: false);
  }

  String _eyebrow(DesyFolder? folder) =>
      folder == null ? 'CATALOGUE' : folder.name.toUpperCase();

  String _title(DesyFolder? folder) => folder?.name ?? 'Components';
}

class _AtlasCard extends StatelessWidget {
  const _AtlasCard({
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
      // The card owns the semantic tap action above. Keep this gesture for
      // pointer input without adding a second, competing accessibility action.
      excludeFromSemantics: true,
      onTap: onOpen,
      child: FCard(
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
                        builder: entry.builder,
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

class _FontsAtlas extends StatelessWidget {
  const _FontsAtlas({
    required this.entries,
    required this.theme,
    required this.sampleText,
    required this.onSampleTextChanged,
    required this.onOpen,
  });

  final List<DesyRegistryEntry> entries;
  final DesyTheme theme;
  final String sampleText;
  final ValueChanged<String> onSampleTextChanged;
  final ValueChanged<DesyRegistryEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    final typography = entries
        .where((entry) => entry.typography != null)
        .toList(growable: false);
    final siblings = entries
        .where((entry) => entry.typography == null)
        .toList(growable: false);
    final cards = [...typography, ...siblings];
    return ListView.separated(
      padding: const EdgeInsets.all(28),
      itemCount: cards.length + 1,
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
        final entry = cards[index - 1];
        if (entry.typography == null) {
          return SizedBox(
            height: 236,
            child: _AtlasCard(
              entry: entry,
              theme: theme,
              onOpen: () => onOpen(entry),
            ),
          );
        }
        return FCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 16),
                DesyWidgetPreview(
                  theme: theme,
                  builder: (context) =>
                      Text(sampleText, style: entry.typography!.style(context)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

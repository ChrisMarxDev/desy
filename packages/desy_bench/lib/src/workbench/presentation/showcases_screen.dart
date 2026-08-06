// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../registry.dart';
import '../widget_preview.dart';
import '../workbench_session.dart';

/// Browseable proof-of-concept area for consumer-defined full compositions.
class DesyShowcasesScreen extends StatelessWidget {
  const DesyShowcasesScreen({super.key, required this.session});

  final DesyWorkbenchSession session;

  @override
  Widget build(BuildContext context) {
    final theme = session.activeThemeIndex.watch(context);
    final showcases = session.registry.allShowcases;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FBadge(child: const Text('EXPERIMENTAL')),
              const SizedBox(width: 10),
              Text(
                'COMPOSITIONS',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Showcases', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 6),
          Text(
            'Consumer-defined examples made from the real system.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: showcases.isEmpty
                ? const _EmptyShowcases()
                : ListView.separated(
                    itemCount: showcases.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) => _ShowcaseCard(
                      showcase: showcases[index],
                      theme: session.registry.themes[theme],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ShowcaseCard extends StatelessWidget {
  const _ShowcaseCard({required this.showcase, required this.theme});

  final DesyShowcase showcase;
  final DesyTheme theme;

  @override
  Widget build(BuildContext context) => FCard(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                showcase.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (showcase.description case final description?) ...[
                const SizedBox(height: 4),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        Container(
          height: 360,
          width: double.infinity,
          color: theme.previewBackgroundColor,
          alignment: Alignment.topCenter,
          child: ClipRect(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: DesyWidgetPreview(theme: theme, builder: showcase.builder),
            ),
          ),
        ),
      ],
    ),
  );
}

class _EmptyShowcases extends StatelessWidget {
  const _EmptyShowcases();

  @override
  Widget build(BuildContext context) => Center(
    child: FCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'No consumer-defined showcases yet.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ),
  );
}

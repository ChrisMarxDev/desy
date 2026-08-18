// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';

import '../../registry.dart';
import '../workbench_session.dart';
import 'component_overview.dart';

/// The all-registry component and atom overview presented as Home.
class DesyHomeScreen extends StatelessWidget {
  const DesyHomeScreen({
    super.key,
    required this.session,
    required this.onOpen,
  });

  final DesyWorkbenchSession session;
  final ValueChanged<DesyRegistryEntry> onOpen;

  @override
  Widget build(BuildContext context) => Padding(
    key: const ValueKey('home-overview'),
    padding: const EdgeInsets.fromLTRB(28, 28, 28, 48),
    child: DesyComponentOverview(
      components: session.registry.components,
      registry: session.registry,
      theme: session.activeTheme,
      onOpen: (component) => onOpen(session.registry.resolve(component.id)!),
      leadingSlivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HOME', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 4),
              Text('All', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 28),
              Text('COMPONENTS', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
      trailingSlivers: [
        if (session.registry.atomKinds.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('ATOMS', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 8),
                  for (final kind in session.registry.atomKinds) ...[
                    _AtomOverview(
                      label: kind.label,
                      entries: session.registry.entriesForAtom(kind),
                      onOpen: onOpen,
                    ),
                    if (kind != session.registry.atomKinds.last)
                      const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 1)),
      ],
    ),
  );
}

class _AtomOverview extends StatelessWidget {
  const _AtomOverview({
    required this.label,
    required this.entries,
    required this.onOpen,
  });

  final String label;
  final List<DesyRegistryEntry> entries;
  final ValueChanged<DesyRegistryEntry> onOpen;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: 4),
      for (final entry in entries)
        DesyButton(
          key: ValueKey('home-atom-entry-${entry.id}'),
          onPress: () => onOpen(entry),
          variant: DesyButtonVariant.ghost,
          size: DesyButtonSize.sm,
          mainAxisAlignment: MainAxisAlignment.start,
          suffix: const Icon(DesyIcons.chevronRight, size: 14),
          child: Text(entry.name),
        ),
    ],
  );
}

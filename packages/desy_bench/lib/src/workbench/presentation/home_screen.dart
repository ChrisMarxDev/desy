// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import '../../registry.dart';
import '../workbench_session.dart';
import 'component_overview.dart';

/// The all-registry component preview overview presented as Home.
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
    ),
  );
}

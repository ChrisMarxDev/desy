import 'package:desy_design_system/desy_design_system.dart';
import 'package:desy_widget_workshop/desy_widget_workshop.dart';
import 'package:flutter/material.dart';

/// The ordinary Dart file edited by Desy's dogfood hot-reload workshop.
List<DesyWorkshopCandidate> buildDesyWorkshopCandidates() => const [
  DesyWorkshopCandidate(
    id: 'desy.homepage.focused',
    title: 'Focused workspace',
    description:
        'A restrained system overview that leads with the next useful action.',
    builder: _buildFocusedWorkspace,
  ),
  DesyWorkshopCandidate(
    id: 'desy.homepage.atlas-first',
    title: 'Atlas first',
    description:
        'A browse-led home that keeps real registry families visually dominant.',
    builder: _buildAtlasFirst,
  ),
  DesyWorkshopCandidate(
    id: 'desy.homepage.journey',
    title: 'Workshop journey',
    description:
        'A continuation-led home centered on recent design explorations.',
    builder: _buildWorkshopJourney,
  ),
];

Widget _buildFocusedWorkspace(BuildContext context) => const _PreviewFrame(
  eyebrow: 'DESY WORKSPACE',
  title: 'Build from what already exists.',
  description:
      'Browse the registry or begin a focused exploration with the real system attached.',
  primaryLabel: 'Start a workshop',
  children: [
    _SummaryTile(label: 'Components', value: '16', icon: DesyIcons.boxes),
    _SummaryTile(label: 'Atoms', value: '31', icon: DesyIcons.sparkles),
    _SummaryTile(label: 'Themes', value: '2', icon: DesyIcons.palette),
  ],
);

Widget _buildAtlasFirst(BuildContext context) => const _PreviewFrame(
  eyebrow: 'ATLAS',
  title: 'Your design system, visible.',
  description:
      'Every card below is a real registered widget rendered under the active theme.',
  primaryLabel: 'Browse all components',
  children: [
    _RegistryTile(label: 'Actions', detail: 'Button · 3 instances'),
    _RegistryTile(label: 'Inputs', detail: 'Text field · Switch · Select'),
    _RegistryTile(label: 'Surfaces', detail: 'Card · Dialog · Catalogue card'),
  ],
);

Widget _buildWorkshopJourney(BuildContext context) => const _PreviewFrame(
  eyebrow: 'CONTINUE WORKING',
  title: 'The exploration is the artifact.',
  description:
      'Return to selected directions, comments, and visible iterations without losing the thread.',
  primaryLabel: 'New exploration',
  children: [
    _JourneyTile(
      title: 'Homepage exploration',
      detail: '4 iterations · 2 selected',
      status: 'Today',
    ),
    _JourneyTile(
      title: 'Activity chat',
      detail: '3 implementations · 1 selected',
      status: 'Yesterday',
    ),
    _JourneyTile(
      title: 'Compact navigation',
      detail: '2 iterations · feedback added',
      status: 'Mon',
    ),
  ],
);

class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.primaryLabel,
    required this.children,
  });

  final String eyebrow;
  final String title;
  final String description;
  final String primaryLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return SizedBox(
      width: 560,
      height: 390,
      child: FCard(
        child: Padding(
          padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: typography.body.xs.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: DesyDesignSystemTokens.spaceSm),
              Text(title, style: typography.display.xl2),
              const SizedBox(height: DesyDesignSystemTokens.spaceSm),
              Text(
                description,
                style: typography.body.sm.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
              const SizedBox(height: DesyDesignSystemTokens.spaceLg),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (index, child) in children.indexed) ...[
                      if (index > 0)
                        const SizedBox(
                          width: DesyDesignSystemTokens.spaceSm,
                        ),
                      Expanded(child: child),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: DesyDesignSystemTokens.spaceMd),
              FButton(
                mainAxisSize: MainAxisSize.min,
                onPress: () {},
                child: Text(primaryLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => _TileShell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const Spacer(),
        Text(value, style: context.theme.typography.display.xl3),
        Text(label, style: context.theme.typography.body.xs),
      ],
    ),
  );
}

class _RegistryTile extends StatelessWidget {
  const _RegistryTile({required this.label, required this.detail});

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) => _TileShell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(DesyIcons.folder, size: 18),
        const Spacer(),
        Text(label, style: context.theme.typography.body.sm),
        const SizedBox(height: 4),
        Text(
          detail,
          style: context.theme.typography.body.xs.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
      ],
    ),
  );
}

class _JourneyTile extends StatelessWidget {
  const _JourneyTile({
    required this.title,
    required this.detail,
    required this.status,
  });

  final String title;
  final String detail;
  final String status;

  @override
  Widget build(BuildContext context) => _TileShell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(status, style: context.theme.typography.body.xs),
        const Spacer(),
        Text(title, style: context.theme.typography.body.sm),
        const SizedBox(height: 4),
        Text(
          detail,
          style: context.theme.typography.body.xs.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
      ],
    ),
  );
}

class _TileShell extends StatelessWidget {
  const _TileShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.theme.colors.secondary,
      border: Border.all(color: context.theme.colors.border),
      borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusMd),
    ),
    child: Padding(
      padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
      child: child,
    ),
  );
}

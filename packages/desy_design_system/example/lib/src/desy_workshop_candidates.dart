import 'package:desy_design_system/desy_design_system.dart';
import 'package:desy_widget_workshop/desy_widget_workshop.dart';
import 'package:flutter/material.dart';

/// The ordinary Dart file edited by Desy's dogfood hot-reload workshop.
List<DesyWorkshopCandidate> buildDesyWorkshopCandidates() => [
  DesyWorkshopCandidate(
    id: 'desy.annotations.review-cards',
    title: 'Activity cards',
    description:
        'Compact cards turn Codex tool calls, edits, and checks into readable activity updates.',
    builder: _buildActivityCards,
  ),
  DesyWorkshopCandidate(
    id: 'desy.activity.progress-trail',
    title: 'Progress trail',
    description:
        'A quiet connected step list keeps completed work and the current task easy to scan.',
    builder: _buildProgressTrail,
  ),
  DesyWorkshopCandidate(
    id: 'desy.activity.grouped-run',
    title: 'Grouped run',
    description:
        'Related activity is folded into compact phases with useful counts and outcomes.',
    builder: _buildGroupedRun,
  ),
  DesyWorkshopCandidate(
    id: 'desy.activity.terminal-digest',
    title: 'Terminal digest',
    description:
        'Command output becomes a concise result summary while preserving the command itself.',
    builder: _buildTerminalDigest,
  ),
];

const _activities = [
  _Activity(
    kind: _ActivityKind.reasoning,
    title: 'Mapped the workshop surface',
    detail:
        'Found the candidate entry point and kept the public builder intact.',
    meta: '12s',
  ),
  _Activity(
    kind: _ActivityKind.command,
    title: 'Inspected the current candidates',
    detail: 'Read the isolated workshop file and its existing card patterns.',
    meta: 'dart · 1 file',
    code: 'sed -n 1,760p desy_workshop_candidates.dart',
  ),
  _Activity(
    kind: _ActivityKind.edit,
    title: 'Built compact activity widgets',
    detail:
        'Replaced raw output with structured events, state, and concise metadata.',
    meta: '+286  −412',
    file: 'desy_workshop_candidates.dart',
  ),
  _Activity(
    kind: _ActivityKind.check,
    title: 'Formatted the candidate file',
    detail: 'The workshop is ready for hot reload.',
    meta: 'Passed · 0.4s',
  ),
];

const _progressActivities = [
  _Activity(
    kind: _ActivityKind.reasoning,
    title: 'Mapped the workshop surface',
    detail: 'Located the live candidate builder and preserved its public API.',
    meta: '12s',
  ),
  _Activity(
    kind: _ActivityKind.command,
    title: 'Reviewed selected directions',
    detail: 'Compared the activity cards and connected progress trail.',
    meta: '4s',
    code: 'rg "desy.activity" desy_workshop_candidates.dart',
  ),
  _Activity(
    kind: _ActivityKind.edit,
    title: 'Simplified the activity trail',
    detail: 'Kept only connected steps and essential task context.',
    meta: '1 file',
    file: 'desy_workshop_candidates.dart',
  ),
  _Activity(
    kind: _ActivityKind.check,
    title: 'Formatting candidate source',
    detail: 'Applying the final Dart formatting pass before hot reload.',
    meta: 'Running',
    code: 'dart format desy_workshop_candidates.dart',
  ),
];

Widget _buildActivityCards(BuildContext context) => const _ActivityFrame(
  eyebrow: 'CODEX ACTIVITY',
  title: 'Building a clearer activity stream',
  status: 'Complete',
  child: _ActivityCardList(activities: _activities),
);

Widget _buildProgressTrail(BuildContext context) =>
    const _ProgressTrailFrame(activities: _progressActivities);

Widget _buildGroupedRun(BuildContext context) => const _ActivityFrame(
  eyebrow: 'CODEX ACTIVITY',
  title: 'Workshop update',
  status: '18s',
  child: _GroupedRun(),
);

Widget _buildTerminalDigest(BuildContext context) => const _ActivityFrame(
  eyebrow: 'COMMAND RESULT',
  title: 'Format workshop candidate',
  status: 'Passed',
  child: _TerminalDigest(),
);

enum _ActivityKind { reasoning, command, edit, check }

class _Activity {
  const _Activity({
    required this.kind,
    required this.title,
    required this.detail,
    required this.meta,
    this.code,
    this.file,
  });

  final _ActivityKind kind;
  final String title;
  final String detail;
  final String meta;
  final String? code;
  final String? file;
}

class _ActivityFrame extends StatelessWidget {
  const _ActivityFrame({
    required this.eyebrow,
    required this.title,
    required this.status,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String status;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return SizedBox(
      width: 620,
      height: 420,
      child: ColoredBox(
        color: colors.background,
        child: Padding(
          padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eyebrow,
                          style: typography.body.xs.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: DesyDesignSystemTokens.spaceXs),
                        Text(title, style: typography.display.sm),
                      ],
                    ),
                  ),
                  _StatusPill(label: status),
                ],
              ),
              const SizedBox(height: DesyDesignSystemTokens.spaceMd),
              Divider(height: 1, color: colors.border),
              const SizedBox(height: DesyDesignSystemTokens.spaceMd),
              Expanded(child: SingleChildScrollView(child: child)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCardList extends StatelessWidget {
  const _ActivityCardList({required this.activities});

  final List<_Activity> activities;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final (index, activity) in activities.indexed) ...[
        if (index > 0) const SizedBox(height: DesyDesignSystemTokens.spaceSm),
        _ActivityCard(activity: activity, active: index == 2),
      ],
    ],
  );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity, required this.active});

  final _Activity activity;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return Semantics(
      label: '${_kindLabel(activity.kind)}: ${activity.title}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active
              ? colors.primary.withValues(alpha: .06)
              : colors.secondary.withValues(alpha: .52),
          border: Border.all(
            color: active
                ? colors.primary.withValues(alpha: .56)
                : colors.border,
          ),
          borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusMd),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesyDesignSystemTokens.spaceMd,
            vertical: DesyDesignSystemTokens.spaceSm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ActivityGlyph(kind: activity.kind, active: active),
              const SizedBox(width: DesyDesignSystemTokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            activity.title,
                            style: typography.body.sm.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          activity.meta,
                          style: typography.body.xs.copyWith(
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesyDesignSystemTokens.spaceXs),
                    Text(
                      activity.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.body.xs.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                    if (activity.file case final file?) ...[
                      const SizedBox(height: DesyDesignSystemTokens.spaceSm),
                      _FileChip(label: file),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressTrailFrame extends StatelessWidget {
  const _ProgressTrailFrame({required this.activities});

  final List<_Activity> activities;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 620,
    height: 420,
    child: ColoredBox(
      color: context.theme.colors.background,
      child: Padding(
        padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceLg),
        child: SingleChildScrollView(
          child: DesyProgressTrail(
            items: [
              for (final (index, activity) in activities.indexed)
                DesyProgressTrailItem(
                  title: activity.title,
                  detail: activity.detail,
                  metadata: index == activities.length - 1
                      ? 'Running'
                      : activity.meta,
                  state: index == activities.length - 1
                      ? DesyProgressTrailItemState.current
                      : DesyProgressTrailItemState.complete,
                  icon: _kindIcon(activity.kind),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _GroupedRun extends StatelessWidget {
  const _GroupedRun();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      _RunGroup(
        icon: Icons.search_rounded,
        title: 'Understand',
        summary: 'Read workshop candidate file',
        count: '2 actions',
        detail: 'Builder signature preserved · 4 existing candidates found',
      ),
      SizedBox(height: DesyDesignSystemTokens.spaceSm),
      _RunGroup(
        icon: Icons.edit_rounded,
        title: 'Implement',
        summary: 'Created four compact stream directions',
        count: '1 file',
        detail: 'Activity cards · progress trail · grouped run · digest',
        emphasized: true,
      ),
      SizedBox(height: DesyDesignSystemTokens.spaceSm),
      _RunGroup(
        icon: Icons.check_rounded,
        title: 'Verify',
        summary: 'Formatted Dart source',
        count: 'Passed',
        detail: 'No other workspace files changed',
      ),
    ],
  );
}

class _RunGroup extends StatelessWidget {
  const _RunGroup({
    required this.icon,
    required this.title,
    required this.summary,
    required this.count,
    required this.detail,
    this.emphasized = false,
  });

  final IconData icon;
  final String title;
  final String summary;
  final String count;
  final String detail;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: emphasized
            ? colors.primary.withValues(alpha: .06)
            : colors.background,
        border: Border.all(
          color: emphasized
              ? colors.primary.withValues(alpha: .5)
              : colors.border,
        ),
        borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: emphasized
                    ? colors.primary
                    : colors.secondary.withValues(alpha: .8),
                borderRadius: BorderRadius.circular(
                  DesyDesignSystemTokens.radiusSm,
                ),
              ),
              child: Icon(
                icon,
                size: 17,
                color: emphasized
                    ? colors.primaryForeground
                    : colors.foreground,
              ),
            ),
            const SizedBox(width: DesyDesignSystemTokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: typography.body.xs.copyWith(
                          color: colors.mutedForeground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(count, style: typography.body.xs),
                    ],
                  ),
                  const SizedBox(height: DesyDesignSystemTokens.spaceXs),
                  Text(
                    summary,
                    style: typography.body.sm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: DesyDesignSystemTokens.spaceXs),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TerminalDigest extends StatelessWidget {
  const _TerminalDigest();

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CodeLine(code: 'dart format …/desy_workshop_candidates.dart'),
        const SizedBox(height: DesyDesignSystemTokens.spaceMd),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.secondary.withValues(alpha: .56),
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(
              DesyDesignSystemTokens.radiusMd,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
            child: Column(
              children: [
                Row(
                  children: [
                    const _ActivityGlyph(
                      kind: _ActivityKind.check,
                      active: true,
                    ),
                    const SizedBox(width: DesyDesignSystemTokens.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Formatted successfully',
                            style: typography.body.sm.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(
                            height: DesyDesignSystemTokens.spaceXs,
                          ),
                          Text(
                            '1 file · 0 changes required',
                            style: typography.body.xs.copyWith(
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '0.4s',
                      style: typography.body.xs.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesyDesignSystemTokens.spaceMd),
                Divider(height: 1, color: colors.border),
                const SizedBox(height: DesyDesignSystemTokens.spaceMd),
                const Row(
                  children: [
                    Expanded(
                      child: _DigestMetric(value: '0', label: 'errors'),
                    ),
                    Expanded(
                      child: _DigestMetric(value: '0', label: 'warnings'),
                    ),
                    Expanded(
                      child: _DigestMetric(value: '1', label: 'file checked'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DigestMetric extends StatelessWidget {
  const _DigestMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return Column(
      children: [
        Text(
          value,
          style: typography.display.sm.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: DesyDesignSystemTokens.spaceXs),
        Text(
          label,
          style: typography.body.xs.copyWith(color: colors.mutedForeground),
        ),
      ],
    );
  }
}

class _ActivityGlyph extends StatelessWidget {
  const _ActivityGlyph({required this.kind, required this.active});

  final _ActivityKind kind;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? colors.primary : colors.secondary,
        shape: BoxShape.circle,
        border: Border.all(color: active ? colors.primary : colors.border),
      ),
      child: Icon(
        _kindIcon(kind),
        size: 14,
        color: active ? colors.primaryForeground : colors.mutedForeground,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: .08),
        border: Border.all(color: colors.primary.withValues(alpha: .36)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: context.theme.typography.body.xs.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeLine extends StatelessWidget {
  const _CodeLine({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.foreground.withValues(alpha: .05),
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesyDesignSystemTokens.spaceSm,
          vertical: 7,
        ),
        child: Row(
          children: [
            Icon(Icons.chevron_right_rounded, size: 15, color: colors.primary),
            const SizedBox(width: DesyDesignSystemTokens.spaceXs),
            Expanded(
              child: Text(
                code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.theme.typography.body.xs.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileChip extends StatelessWidget {
  const _FileChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.description_outlined, size: 13, color: colors.primary),
        const SizedBox(width: DesyDesignSystemTokens.spaceXs),
        Text(
          label,
          style: context.theme.typography.body.xs.copyWith(
            color: colors.primary,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

IconData _kindIcon(_ActivityKind kind) => switch (kind) {
  _ActivityKind.reasoning => Icons.route_rounded,
  _ActivityKind.command => Icons.terminal_rounded,
  _ActivityKind.edit => Icons.edit_rounded,
  _ActivityKind.check => Icons.check_rounded,
};

String _kindLabel(_ActivityKind kind) => switch (kind) {
  _ActivityKind.reasoning => 'Reasoning',
  _ActivityKind.command => 'Command',
  _ActivityKind.edit => 'Edit',
  _ActivityKind.check => 'Check',
};

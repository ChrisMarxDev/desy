// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';

import 'orbit_theme.dart';

/// Composable content blocks that an agent may place in a generated response.
///
/// These are production consumer widgets, not catalogue-only preview stand-ins.
class OrbitStack extends StatelessWidget {
  const OrbitStack({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var index = 0; index < children.length; index++) ...[
        if (index > 0) const SizedBox(height: OrbitTokens.spaceMd),
        children[index],
      ],
    ],
  );
}

class OrbitInsightCard extends StatelessWidget {
  const OrbitInsightCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.detail,
    required this.metric,
    required this.change,
    this.tone = OrbitBadgeTone.info,
  });

  final String eyebrow;
  final String title;
  final String detail;
  final String metric;
  final String change;
  final OrbitBadgeTone tone;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '$eyebrow. $title. $metric, $change.',
    child: OrbitSurface(
      tone: OrbitSurfaceTone.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OrbitBadge(label: eyebrow, tone: tone, glyph: OrbitGlyphs.sparkle),
          const SizedBox(height: OrbitTokens.spaceXl),
          Text(title, style: OrbitType.heading(context)),
          const SizedBox(height: OrbitTokens.spaceXs),
          Text(
            detail,
            style: OrbitType.body(
              context,
            ).copyWith(color: OrbitTheme.of(context).colors.mutedForeground),
          ),
          const SizedBox(height: OrbitTokens.spaceXl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text(metric, style: OrbitType.display(context))),
              Text(
                change,
                style: OrbitType.label(context).copyWith(
                  color: _badgeColor(OrbitTheme.of(context).colors, tone),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class OrbitTaskList extends StatelessWidget {
  const OrbitTaskList({super.key, required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => OrbitSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: OrbitType.heading(context))),
            OrbitBadge(
              label: '${rows.length} active',
              tone: OrbitBadgeTone.info,
              glyph: OrbitGlyphs.activity,
            ),
          ],
        ),
        const SizedBox(height: OrbitTokens.spaceSm),
        for (var index = 0; index < rows.length; index++) ...[
          if (index > 0) const OrbitDivider(indent: 22),
          rows[index],
        ],
      ],
    ),
  );
}

enum OrbitTaskState { queued, working, done, blocked }

class OrbitTaskRow extends StatelessWidget {
  const OrbitTaskRow({
    super.key,
    required this.title,
    required this.detail,
    required this.state,
  });

  final String title;
  final String detail;
  final OrbitTaskState state;

  @override
  Widget build(BuildContext context) {
    final (label, tone, glyph) = switch (state) {
      OrbitTaskState.queued => (
        'Queued',
        OrbitBadgeTone.warning,
        OrbitGlyphs.pause,
      ),
      OrbitTaskState.working => (
        'In progress',
        OrbitBadgeTone.info,
        OrbitGlyphs.activity,
      ),
      OrbitTaskState.done => (
        'Done',
        OrbitBadgeTone.success,
        OrbitGlyphs.check,
      ),
      OrbitTaskState.blocked => (
        'Blocked',
        OrbitBadgeTone.danger,
        OrbitGlyphs.close,
      ),
    };
    return Semantics(
      label: '$title. $detail. $label.',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: OrbitTokens.spaceMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: OrbitGlyph(
                state == OrbitTaskState.done
                    ? OrbitGlyphs.check
                    : OrbitGlyphs.dot,
                size: 15,
                color: _badgeColor(OrbitTheme.of(context).colors, tone),
              ),
            ),
            const SizedBox(width: OrbitTokens.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: OrbitType.title(context)),
                  const SizedBox(height: 2),
                  Text(detail, style: OrbitType.small(context)),
                ],
              ),
            ),
            const SizedBox(width: OrbitTokens.spaceSm),
            OrbitBadge(label: label, tone: tone, glyph: glyph),
          ],
        ),
      ),
    );
  }
}

class OrbitRecommendationCard extends StatelessWidget {
  const OrbitRecommendationCard({
    super.key,
    required this.title,
    required this.detail,
    required this.confidence,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String detail;
  final double confidence;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final percentage = (confidence.clamp(0, 1) * 100).round();
    return OrbitSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OrbitBadge(
            label: 'AGENT RECOMMENDATION',
            tone: OrbitBadgeTone.success,
            glyph: OrbitGlyphs.sparkle,
          ),
          const SizedBox(height: OrbitTokens.spaceLg),
          Text(title, style: OrbitType.heading(context)),
          const SizedBox(height: OrbitTokens.spaceXs),
          Text(
            detail,
            style: OrbitType.body(
              context,
            ).copyWith(color: OrbitTheme.of(context).colors.mutedForeground),
          ),
          const SizedBox(height: OrbitTokens.spaceLg),
          Row(
            children: [
              Expanded(
                child: OrbitProgress(
                  value: confidence,
                  color: OrbitTheme.of(context).colors.success,
                ),
              ),
              const SizedBox(width: OrbitTokens.spaceSm),
              Text('$percentage%', style: OrbitType.label(context)),
            ],
          ),
          const SizedBox(height: OrbitTokens.spaceLg),
          OrbitButton(
            label: actionLabel,
            onPressed: onAction,
            trailing: const OrbitGlyph(OrbitGlyphs.arrowRight, size: 15),
          ),
        ],
      ),
    );
  }
}

class OrbitApprovalCard extends StatelessWidget {
  const OrbitApprovalCard({
    super.key,
    required this.title,
    required this.detail,
    required this.approveLabel,
    required this.rejectLabel,
    this.onApprove,
    this.onReject,
  });

  final String title;
  final String detail;
  final String approveLabel;
  final String rejectLabel;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) => OrbitSurface(
    tone: OrbitSurfaceTone.raised,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OrbitBadge(
          label: 'APPROVAL NEEDED',
          tone: OrbitBadgeTone.warning,
          glyph: OrbitGlyphs.document,
        ),
        const SizedBox(height: OrbitTokens.spaceLg),
        Text(title, style: OrbitType.heading(context)),
        const SizedBox(height: OrbitTokens.spaceXs),
        Text(
          detail,
          style: OrbitType.body(
            context,
          ).copyWith(color: OrbitTheme.of(context).colors.mutedForeground),
        ),
        const SizedBox(height: OrbitTokens.spaceLg),
        Wrap(
          spacing: OrbitTokens.spaceSm,
          runSpacing: OrbitTokens.spaceSm,
          children: [
            OrbitButton(
              label: approveLabel,
              onPressed: onApprove,
              leading: const OrbitGlyph(OrbitGlyphs.check, size: 14),
            ),
            OrbitButton(
              label: rejectLabel,
              onPressed: onReject,
              variant: OrbitButtonVariant.secondary,
              leading: const OrbitGlyph(OrbitGlyphs.close, size: 16),
            ),
          ],
        ),
      ],
    ),
  );
}

class OrbitToolActivity extends StatelessWidget {
  const OrbitToolActivity({
    super.key,
    required this.tool,
    required this.detail,
    required this.state,
    this.progress,
  });

  final String tool;
  final String detail;
  final OrbitTaskState state;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final (stateLabel, tone) = switch (state) {
      OrbitTaskState.queued => ('Queued', OrbitBadgeTone.warning),
      OrbitTaskState.working => ('Running', OrbitBadgeTone.info),
      OrbitTaskState.done => ('Complete', OrbitBadgeTone.success),
      OrbitTaskState.blocked => ('Blocked', OrbitBadgeTone.danger),
    };
    return OrbitSurface(
      padding: const EdgeInsets.all(OrbitTokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OrbitGlyph(
                OrbitGlyphs.activity,
                color: _badgeColor(OrbitTheme.of(context).colors, tone),
              ),
              const SizedBox(width: OrbitTokens.spaceSm),
              Expanded(child: Text(tool, style: OrbitType.title(context))),
              OrbitBadge(label: stateLabel, tone: tone),
            ],
          ),
          const SizedBox(height: OrbitTokens.spaceXs),
          Text(detail, style: OrbitType.small(context)),
          if (progress case final value?) ...[
            const SizedBox(height: OrbitTokens.spaceMd),
            OrbitProgress(
              value: value,
              color: _badgeColor(OrbitTheme.of(context).colors, tone),
            ),
          ],
        ],
      ),
    );
  }
}

class OrbitMetricGrid extends StatelessWidget {
  const OrbitMetricGrid({super.key, required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: OrbitTokens.spaceSm,
    runSpacing: OrbitTokens.spaceSm,
    children: [for (final tile in tiles) SizedBox(width: 172, child: tile)],
  );
}

class OrbitMetricTile extends StatelessWidget {
  const OrbitMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.change,
    this.tone = OrbitBadgeTone.neutral,
  });

  final String label;
  final String value;
  final String change;
  final OrbitBadgeTone tone;

  @override
  Widget build(BuildContext context) => OrbitSurface(
    padding: const EdgeInsets.all(OrbitTokens.spaceMd),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: OrbitType.overline(context)),
        const SizedBox(height: OrbitTokens.spaceMd),
        Text(value, style: OrbitType.heading(context)),
        const SizedBox(height: OrbitTokens.spaceXs),
        Text(
          change,
          style: OrbitType.small(
            context,
          ).copyWith(color: _badgeColor(OrbitTheme.of(context).colors, tone)),
        ),
      ],
    ),
  );
}

class OrbitSourceCard extends StatelessWidget {
  const OrbitSourceCard({
    super.key,
    required this.title,
    required this.detail,
    required this.meta,
  });

  final String title;
  final String detail;
  final String meta;

  @override
  Widget build(BuildContext context) => OrbitSurface(
    padding: const EdgeInsets.all(OrbitTokens.spaceMd),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OrbitGlyph(
          OrbitGlyphs.document,
          color: OrbitTheme.of(context).colors.info,
          size: 18,
        ),
        const SizedBox(width: OrbitTokens.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: OrbitType.title(context)),
              const SizedBox(height: 2),
              Text(detail, style: OrbitType.small(context)),
              const SizedBox(height: OrbitTokens.spaceXs),
              Text(meta, style: OrbitType.overline(context)),
            ],
          ),
        ),
      ],
    ),
  );
}

Color _badgeColor(OrbitColors colors, OrbitBadgeTone tone) => switch (tone) {
  OrbitBadgeTone.neutral => colors.mutedForeground,
  OrbitBadgeTone.info => colors.info,
  OrbitBadgeTone.success => colors.success,
  OrbitBadgeTone.warning => colors.warning,
  OrbitBadgeTone.danger => colors.destructive,
};

// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart' as md;
import 'package:flutter_mermaid/flutter_mermaid.dart' as mermaid;

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

/// A small, app-owned ticket record rendered by the generated ticket list.
class OrbitTicket {
  const OrbitTicket({
    required this.key,
    required this.summary,
    required this.status,
  });

  final String key;
  final String summary;
  final String status;

  factory OrbitTicket.fromJson(Map<Object?, Object?> json) {
    final key = json['key'];
    final summary = json['summary'];
    final status = json['status'];
    if (key is! String || summary is! String || status is! String) {
      throw const FormatException(
        'Tickets need string key, summary, and status fields.',
      );
    }
    return OrbitTicket(key: key, summary: summary, status: status);
  }
}

/// A data-driven issue list. Its ticket collection is deliberately a raw JSON
/// knob so external providers can hand it off without Dart domain types.
class OrbitTicketList extends StatelessWidget {
  const OrbitTicketList({
    super.key,
    required this.title,
    required this.tickets,
  });

  final String title;
  final List<OrbitTicket> tickets;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '$title. ${tickets.length} tickets.',
    child: OrbitSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: OrbitType.heading(context))),
              OrbitBadge(
                label: '${tickets.length} loaded',
                tone: OrbitBadgeTone.info,
                glyph: OrbitGlyphs.activity,
              ),
            ],
          ),
          const SizedBox(height: OrbitTokens.spaceSm),
          if (tickets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: OrbitTokens.spaceMd,
              ),
              child: Text(
                'No tickets loaded yet.',
                style: OrbitType.small(context),
              ),
            )
          else
            for (var index = 0; index < tickets.length; index++) ...[
              if (index > 0) const OrbitDivider(),
              _OrbitTicketRow(ticket: tickets[index]),
            ],
        ],
      ),
    ),
  );
}

class _OrbitTicketRow extends StatelessWidget {
  const _OrbitTicketRow({required this.ticket});

  final OrbitTicket ticket;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: OrbitTokens.spaceMd),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OrbitBadge(
          label: ticket.key,
          tone: OrbitBadgeTone.neutral,
          glyph: OrbitGlyphs.document,
        ),
        const SizedBox(width: OrbitTokens.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ticket.summary, style: OrbitType.title(context)),
              const SizedBox(height: 2),
              Text(ticket.status, style: OrbitType.small(context)),
            ],
          ),
        ),
      ],
    ),
  );
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

/// Rich text supplied as Markdown, rendered locally by Flutter rather than
/// replaced by a prose approximation from the agent.
class OrbitMarkdownCard extends StatelessWidget {
  const OrbitMarkdownCard({
    super.key,
    required this.title,
    required this.markdown,
  });

  final String title;
  final String markdown;

  @override
  Widget build(BuildContext context) {
    final colors = OrbitTheme.of(context).colors;
    final body = OrbitType.body(context).copyWith(color: colors.cardForeground);
    return Semantics(
      container: true,
      label: '$title. Rich text content.',
      child: OrbitSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                OrbitGlyph(OrbitGlyphs.document, color: colors.info, size: 18),
                const SizedBox(width: OrbitTokens.spaceSm),
                Expanded(child: Text(title, style: OrbitType.heading(context))),
              ],
            ),
            const SizedBox(height: OrbitTokens.spaceMd),
            md.MarkdownBody(
              data: markdown,
              selectable: true,
              styleSheet: md.MarkdownStyleSheet(
                p: body,
                pPadding: EdgeInsets.zero,
                h1: OrbitType.display(context),
                h1Padding: EdgeInsets.zero,
                h2: OrbitType.heading(context),
                h2Padding: EdgeInsets.zero,
                h3: OrbitType.title(context),
                h3Padding: EdgeInsets.zero,
                h4: OrbitType.title(context),
                h4Padding: EdgeInsets.zero,
                h5: OrbitType.label(context),
                h5Padding: EdgeInsets.zero,
                h6: OrbitType.label(context),
                h6Padding: EdgeInsets.zero,
                strong: body.copyWith(fontWeight: FontWeight.w700),
                em: body.copyWith(fontStyle: FontStyle.italic),
                code: body.copyWith(
                  fontFamily: 'monospace',
                  color: colors.cardForeground,
                  backgroundColor: colors.muted,
                ),
                blockSpacing: OrbitTokens.spaceSm,
                listIndent: OrbitTokens.spaceXl,
                listBullet: body,
                tableHead: OrbitType.label(context),
                tableBody: body,
                tableBorder: TableBorder.all(color: colors.border),
                tableCellsPadding: const EdgeInsets.all(OrbitTokens.spaceSm),
                codeblockPadding: const EdgeInsets.all(OrbitTokens.spaceSm),
                codeblockDecoration: BoxDecoration(
                  color: colors.background,
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(OrbitTokens.radiusSm),
                ),
                blockquote: body,
                blockquotePadding: const EdgeInsets.symmetric(
                  horizontal: OrbitTokens.spaceMd,
                  vertical: OrbitTokens.spaceXs,
                ),
                blockquoteDecoration: BoxDecoration(
                  color: colors.muted,
                  border: Border(
                    left: BorderSide(color: colors.info, width: 3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A pure-Dart Mermaid diagram. The agent supplies the portable Mermaid
/// source; Orbit owns parsing, visual styling, and failure presentation.
class OrbitMermaidDiagramCard extends StatelessWidget {
  const OrbitMermaidDiagramCard({
    super.key,
    required this.title,
    required this.code,
  });

  final String title;
  final String code;

  @override
  Widget build(BuildContext context) {
    final colors = OrbitTheme.of(context).colors;
    return Semantics(
      container: true,
      label: '$title. Mermaid diagram.',
      child: OrbitSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                OrbitGlyph(OrbitGlyphs.activity, color: colors.info, size: 18),
                const SizedBox(width: OrbitTokens.spaceSm),
                Expanded(child: Text(title, style: OrbitType.heading(context))),
              ],
            ),
            const SizedBox(height: OrbitTokens.spaceMd),
            ExcludeSemantics(
              child: mermaid.MermaidDiagram(
                code: code,
                height: 280,
                style: mermaid.MermaidStyle(
                  backgroundColor: colors.card.toARGB32(),
                  defaultNodeStyle: mermaid.NodeStyle(
                    fillColor: colors.muted.toARGB32(),
                    strokeColor: colors.info.toARGB32(),
                    textColor: colors.cardForeground.toARGB32(),
                  ),
                  defaultEdgeStyle: mermaid.EdgeStyle(
                    strokeColor: colors.mutedForeground.toARGB32(),
                  ),
                  padding: OrbitTokens.spaceLg,
                  nodeSpacingX: 40,
                  nodeSpacingY: 36,
                  themeMode: OrbitTheme.of(context).isDark
                      ? mermaid.MermaidThemeMode.dark
                      : mermaid.MermaidThemeMode.light,
                ),
                loadingBuilder: (_) => const SizedBox(height: 280),
                errorBuilder: (_, error) => _OrbitDiagramError(detail: error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbitDiagramError extends StatelessWidget {
  const _OrbitDiagramError({required this.detail});

  final String detail;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 280,
    child: Center(
      child: Text(
        'Could not render this Mermaid diagram: $detail',
        style: OrbitType.small(context),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

/// One portable chart datum assembled from separate label and number knobs.
///
/// Agent-facing contracts stay JSON-shaped (`labels` and `values`), while the
/// consumer owns this small view model and the `fl_chart` dependency.
class OrbitChartDatum {
  const OrbitChartDatum({required this.label, required this.value});

  final String label;
  final double value;

  static List<OrbitChartDatum> zip({
    required List<String> labels,
    required List<double> values,
  }) {
    if (labels.length != values.length) {
      throw ArgumentError.value(
        values,
        'values',
        'Chart labels and values must have the same length.',
      );
    }
    return List.unmodifiable([
      for (var index = 0; index < labels.length; index++)
        OrbitChartDatum(label: labels[index], value: values[index]),
    ]);
  }
}

class OrbitBarChartCard extends StatelessWidget {
  const OrbitBarChartCard({super.key, required this.title, required this.data});

  final String title;
  final List<OrbitChartDatum> data;

  @override
  Widget build(BuildContext context) {
    final colors = OrbitTheme.of(context).colors;
    final maximum = data.fold<double>(0, (maxValue, datum) {
      return math.max(maxValue, datum.value);
    });
    return Semantics(
      container: true,
      label: '$title. ${_chartSummary(data)}.',
      child: OrbitSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: OrbitType.heading(context)),
            const SizedBox(height: OrbitTokens.spaceLg),
            SizedBox(
              height: 220,
              child: data.isEmpty
                  ? const _OrbitEmptyChart()
                  : ExcludeSemantics(
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maximum <= 0 ? 1 : maximum * 1.16,
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) =>
                                FlLine(color: colors.border, strokeWidth: 1),
                          ),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(),
                            rightTitles: const AxisTitles(),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 34,
                                getTitlesWidget: (value, meta) => Text(
                                  value.toStringAsFixed(0),
                                  style: OrbitType.overline(context),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 || index >= data.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      data[index].label,
                                      overflow: TextOverflow.ellipsis,
                                      style: OrbitType.overline(context),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: [
                            for (var index = 0; index < data.length; index++)
                              BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: data[index].value,
                                    width: 20,
                                    color: colors.info,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(
                                        OrbitTokens.radiusSm,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        // Live data refreshes should settle immediately. An
                        // agent or provider can change several values at once;
                        // replaying a default chart tween for each refresh
                        // reads as flicker rather than meaningful motion.
                        duration: Duration.zero,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrbitPieChartCard extends StatelessWidget {
  const OrbitPieChartCard({super.key, required this.title, required this.data});

  final String title;
  final List<OrbitChartDatum> data;

  @override
  Widget build(BuildContext context) {
    final colors = OrbitTheme.of(context).colors;
    final palette = [
      colors.info,
      colors.success,
      colors.warning,
      colors.destructive,
      colors.ring,
    ];
    final total = data.fold<double>(0, (sum, datum) => sum + datum.value);
    return Semantics(
      container: true,
      label: '$title. ${_chartSummary(data)}.',
      child: OrbitSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: OrbitType.heading(context)),
            const SizedBox(height: OrbitTokens.spaceLg),
            SizedBox(
              height: 190,
              child: data.isEmpty
                  ? const _OrbitEmptyChart()
                  : ExcludeSemantics(
                      child: PieChart(
                        PieChartData(
                          centerSpaceRadius: 34,
                          sectionsSpace: 3,
                          sections: [
                            for (var index = 0; index < data.length; index++)
                              PieChartSectionData(
                                color: palette[index % palette.length],
                                value: data[index].value,
                                radius: 58,
                                title: total <= 0
                                    ? ''
                                    : '${(data[index].value / total * 100).round()}%',
                                titleStyle: OrbitType.overline(
                                  context,
                                ).copyWith(color: colors.cardForeground),
                              ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: OrbitTokens.spaceSm),
            Wrap(
              spacing: OrbitTokens.spaceMd,
              runSpacing: OrbitTokens.spaceXs,
              children: [
                for (var index = 0; index < data.length; index++)
                  _OrbitChartLegend(
                    color: palette[index % palette.length],
                    label: '${data[index].label} ${data[index].value}',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbitEmptyChart extends StatelessWidget {
  const _OrbitEmptyChart();

  @override
  Widget build(BuildContext context) => Center(
    child: Text('No values to chart', style: OrbitType.small(context)),
  );
}

class _OrbitChartLegend extends StatelessWidget {
  const _OrbitChartLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const SizedBox(width: 8, height: 8),
      ),
      const SizedBox(width: OrbitTokens.spaceXs),
      Text(label, style: OrbitType.small(context)),
    ],
  );
}

String _chartSummary(List<OrbitChartDatum> data) =>
    data.map((datum) => '${datum.label}: ${datum.value}').join(', ');

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

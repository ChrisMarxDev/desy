// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../registry.dart';
import '../widget_preview.dart';
import '../workbench_session.dart';

/// A dedicated comparison board for spacing and other numeric primitives.
///
/// Measurements are not reduced to a token table: each value is rendered as a
/// direct geometry specimen and, when declared, beside the consumer's real
/// widget specimen.
class DesyMeasuresScreen extends StatelessWidget {
  const DesyMeasuresScreen({
    super.key,
    required this.session,
    required this.folder,
  });

  final DesyWorkbenchSession session;
  final DesyFolder folder;

  @override
  Widget build(BuildContext context) {
    final theme = session.activeThemeIndex.watch(context);
    final measures = folder.numbers;
    final groups = <DesyNumericKind, List<DesyNumericEntry>>{};
    for (final measure in measures) {
      (groups[measure.kind] ??= []).add(measure);
    }

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Text(
          folder.name.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 4),
        Text(folder.name, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 6),
        Text(
          'Compare the geometry that gives components their rhythm.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        for (final group in DesyNumericKind.values)
          if (groups[group] case final entries? when entries.isNotEmpty) ...[
            Text(
              group.label.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final entry in entries)
                    SizedBox(
                      width: constraints.maxWidth >= 940
                          ? (constraints.maxWidth - 28) / 3
                          : constraints.maxWidth >= 620
                          ? (constraints.maxWidth - 14) / 2
                          : constraints.maxWidth,
                      child: _MeasureCard(
                        entry: entry,
                        theme: session.registry.themes[theme],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
      ],
    );
  }
}

class _MeasureCard extends StatelessWidget {
  const _MeasureCard({required this.entry, required this.theme});

  final DesyNumericEntry entry;
  final DesyTheme theme;

  @override
  Widget build(BuildContext context) => FCard(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              FBadge(child: Text(entry.kind.label)),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            entry.id,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 18),
          _MeasureDiagram(entry: entry),
          if (entry.builder != null) ...[
            const SizedBox(height: 14),
            Text(
              'CONSUMER SPECIMEN',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 72,
              child: ClipRect(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: DesyWidgetPreview(
                      theme: theme,
                      builder: entry.build,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            entry.displayValue,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (entry.description case final description?) ...[
            const SizedBox(height: 4),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    ),
  );
}

class _MeasureDiagram extends StatelessWidget {
  const _MeasureDiagram({required this.entry});

  final DesyNumericEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final extent = entry.value.clamp(4.0, 128.0).toDouble();
    final color = scheme.primary;

    return SizedBox(
      height: 92,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: switch (entry.kind) {
            DesyNumericKind.spacing => _SpacingDiagram(
              extent: extent,
              axis: entry.axis,
              color: color,
            ),
            DesyNumericKind.radius => _RadiusDiagram(
              radius: extent,
              color: color,
            ),
            DesyNumericKind.breakpoint => _BreakpointDiagram(
              value: entry.value,
              color: color,
            ),
            DesyNumericKind.stroke => _StrokeDiagram(
              width: entry.value.clamp(1.0, 16.0).toDouble(),
              color: color,
            ),
            DesyNumericKind.opacity => _OpacityDiagram(
              opacity: entry.value.clamp(0.0, 1.0).toDouble(),
              color: color,
            ),
            DesyNumericKind.elevation => _ElevationDiagram(
              elevation: entry.value.clamp(0.0, 24.0).toDouble(),
              color: color,
            ),
            DesyNumericKind.size => _SizeDiagram(extent: extent, color: color),
          },
        ),
      ),
    );
  }
}

class _SpacingDiagram extends StatelessWidget {
  const _SpacingDiagram({
    required this.extent,
    required this.axis,
    required this.color,
  });

  final double extent;
  final DesyNumericAxis axis;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final vertical = axis == DesyNumericAxis.vertical;
    final blocks = [
      DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const SizedBox(width: 28, height: 28),
      ),
      SizedBox(width: vertical ? 28 : extent, height: vertical ? extent : 28),
      DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const SizedBox(width: 28, height: 28),
      ),
    ];
    return vertical
        ? Column(mainAxisSize: MainAxisSize.min, children: blocks)
        : Row(mainAxisSize: MainAxisSize.min, children: blocks);
  }
}

class _RadiusDiagram extends StatelessWidget {
  const _RadiusDiagram({required this.radius, required this.color});
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 116,
    height: 54,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .22),
      border: Border.all(color: color, width: 2),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class _BreakpointDiagram extends StatelessWidget {
  const _BreakpointDiagram({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = (value / 1440).clamp(.08, 1.0);
    return SizedBox(
      width: 180,
      child: Stack(
        children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          FractionallySizedBox(
            widthFactor: fraction,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Transform.translate(
              offset: const Offset(0, 16),
              child: Text('0', style: Theme.of(context).textTheme.labelSmall),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Transform.translate(
              offset: const Offset(0, 16),
              child: Text(
                '1440',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StrokeDiagram extends StatelessWidget {
  const _StrokeDiagram({required this.width, required this.color});
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 150,
    height: width,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(width),
    ),
  );
}

class _OpacityDiagram extends StatelessWidget {
  const _OpacityDiagram({required this.opacity, required this.color});
  final double opacity;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 112,
    height: 50,
    color: color.withValues(alpha: opacity),
  );
}

class _ElevationDiagram extends StatelessWidget {
  const _ElevationDiagram({required this.elevation, required this.color});
  final double elevation;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 112,
    height: 50,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: .24),
          blurRadius: elevation,
          offset: Offset(0, elevation / 2),
        ),
      ],
    ),
  );
}

class _SizeDiagram extends StatelessWidget {
  const _SizeDiagram({required this.extent, required this.color});
  final double extent;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: extent.clamp(16, 80),
    height: extent.clamp(16, 80),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

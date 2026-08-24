// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../registry.dart';
import '../widget_preview.dart';
import '../workbench_session.dart';

/// A comparison board for the system's typed numeric foundations.
///
/// Measurements are shown as their actual visual role: a spacing rhythm, a
/// radius surface, a responsive threshold, and so on. This keeps a token's
/// number secondary to the decision that number makes in the interface.
class DesyMeasuresScreen extends StatelessWidget {
  const DesyMeasuresScreen({
    super.key,
    required this.session,
    required this.measurements,
  });

  final DesyWorkbenchSession session;
  final List<DesyNumericEntry> measurements;

  @override
  Widget build(BuildContext context) {
    final themeIndex = session.activeThemeIndex.watch(context);
    final groups = <DesyNumericKind, List<DesyNumericEntry>>{};
    for (final measurement in measurements) {
      (groups[measurement.kind] ??= []).add(measurement);
    }

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Text(
          'ATOMS / MEASUREMENTS',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 4),
        Text('Measurements', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 620),
          child: Text(
            'Scales, shapes, and thresholds that make the system consistent.',
          ),
        ),
        const SizedBox(height: 28),
        for (final kind in DesyNumericKind.values)
          if (groups[kind] case final entries? when entries.isNotEmpty) ...[
            _MeasurementSection(
              key: ValueKey('measurements-kind-${kind.name}'),
              kind: kind,
              entries: entries,
              theme: session.registry.themes[themeIndex],
            ),
            const SizedBox(height: 24),
          ],
      ],
    );
  }
}

class _MeasurementSection extends StatelessWidget {
  const _MeasurementSection({
    super.key,
    required this.kind,
    required this.entries,
    required this.theme,
  });

  final DesyNumericKind kind;
  final List<DesyNumericEntry> entries;
  final DesyTheme theme;

  @override
  Widget build(BuildContext context) => DesyCard(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kind.label.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(
            _description(kind),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 20),
          switch (kind) {
            DesyNumericKind.spacing => _SpacingScale(
              entries: entries,
              theme: theme,
            ),
            DesyNumericKind.size => _SizeScale(entries: entries, theme: theme),
            DesyNumericKind.radius => _RadiusScale(
              entries: entries,
              theme: theme,
            ),
            DesyNumericKind.stroke => _StrokeScale(
              entries: entries,
              theme: theme,
            ),
            DesyNumericKind.breakpoint => _BreakpointScale(
              entries: entries,
              theme: theme,
            ),
            DesyNumericKind.opacity => _OpacityScale(
              entries: entries,
              theme: theme,
            ),
            DesyNumericKind.elevation => _ElevationScale(
              entries: entries,
              theme: theme,
            ),
          },
        ],
      ),
    ),
  );

  String _description(DesyNumericKind kind) => switch (kind) {
    DesyNumericKind.spacing =>
      'Compare the gaps and insets that establish layout rhythm.',
    DesyNumericKind.size =>
      'Compare fixed dimensions at their intended visual weight.',
    DesyNumericKind.radius =>
      'Compare the corner treatment applied to contained surfaces.',
    DesyNumericKind.stroke =>
      'Compare visible line weights before applying them to surfaces.',
    DesyNumericKind.breakpoint =>
      'Compare responsive thresholds across a shared viewport range.',
    DesyNumericKind.opacity =>
      'Compare blend levels against a transparent background.',
    DesyNumericKind.elevation =>
      'Compare surface depth and its resulting shadow.',
  };
}

class _MeasurementDetails extends StatelessWidget {
  const _MeasurementDetails({required this.entry, required this.theme});

  final DesyNumericEntry entry;
  final DesyTheme theme;

  @override
  Widget build(BuildContext context) => Column(
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
          Text(
            entry.displayValue,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
      const SizedBox(height: 2),
      SelectableText(entry.id, style: Theme.of(context).textTheme.labelSmall),
      if (entry.description case final description?) ...[
        const SizedBox(height: 5),
        Text(description, style: Theme.of(context).textTheme.bodySmall),
      ],
      if (entry.builder != null) ...[
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: DesyWidgetPreview(theme: theme, builder: entry.build),
            ),
          ),
        ),
      ],
    ],
  );
}

class _SpacingScale extends StatelessWidget {
  const _SpacingScale({required this.entries, required this.theme});

  final List<DesyNumericEntry> entries;
  final DesyTheme theme;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        for (final entry in entries)
          SizedBox(
            key: ValueKey('measurement-${entry.id}'),
            width: constraints.maxWidth >= 760
                ? (constraints.maxWidth - 20) / 2
                : constraints.maxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SpacingSpecimen(entry: entry),
                const SizedBox(height: 12),
                _MeasurementDetails(entry: entry, theme: theme),
              ],
            ),
          ),
      ],
    ),
  );
}

class _SpacingSpecimen extends StatelessWidget {
  const _SpacingSpecimen({required this.entry});

  final DesyNumericEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = context.theme.colors.primary;
    final extent = entry.value.clamp(4.0, 72.0).toDouble();
    final block = DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const SizedBox(width: 30, height: 30),
    );
    return Semantics(
      label: '${entry.name}, ${entry.displayValue} ${entry.axis.name} spacing',
      child: SizedBox(
        height: 94,
        child: DecoratedBox(
          decoration: _quietSurface(context),
          child: Center(
            child: switch (entry.axis) {
              DesyNumericAxis.vertical => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  block,
                  SizedBox(height: extent),
                  block,
                ],
              ),
              DesyNumericAxis.horizontal => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  block,
                  SizedBox(width: extent),
                  block,
                ],
              ),
              DesyNumericAxis.both => Container(
                padding: EdgeInsets.all(extent),
                decoration: BoxDecoration(
                  border: Border.all(color: color.withValues(alpha: .45)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: block,
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _SizeScale extends StatelessWidget {
  const _SizeScale({required this.entries, required this.theme});

  final List<DesyNumericEntry> entries;
  final DesyTheme theme;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 20,
    runSpacing: 20,
    children: [
      for (final entry in entries)
        _VisualTile(
          key: ValueKey('measurement-${entry.id}'),
          entry: entry,
          theme: theme,
          child: Container(
            width: entry.value.clamp(18.0, 84.0).toDouble(),
            height: entry.value.clamp(18.0, 84.0).toDouble(),
            decoration: BoxDecoration(
              color: context.theme.colors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
    ],
  );
}

class _RadiusScale extends StatelessWidget {
  const _RadiusScale({required this.entries, required this.theme});

  final List<DesyNumericEntry> entries;
  final DesyTheme theme;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 20,
    runSpacing: 20,
    children: [
      for (final entry in entries)
        _VisualTile(
          key: ValueKey('measurement-${entry.id}'),
          entry: entry,
          theme: theme,
          child: Container(
            width: 132,
            height: 64,
            decoration: BoxDecoration(
              color: context.theme.colors.primary.withValues(alpha: .16),
              border: Border.all(color: context.theme.colors.primary, width: 2),
              borderRadius: BorderRadius.circular(entry.value.clamp(0.0, 32.0)),
            ),
          ),
        ),
    ],
  );
}

class _VisualTile extends StatelessWidget {
  const _VisualTile({
    super.key,
    required this.entry,
    required this.theme,
    required this.child,
  });

  final DesyNumericEntry entry;
  final DesyTheme theme;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 116,
          child: DecoratedBox(
            decoration: _quietSurface(context),
            child: Center(child: child),
          ),
        ),
        const SizedBox(height: 12),
        _MeasurementDetails(entry: entry, theme: theme),
      ],
    ),
  );
}

class _StrokeScale extends StatelessWidget {
  const _StrokeScale({required this.entries, required this.theme});

  final List<DesyNumericEntry> entries;
  final DesyTheme theme;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final entry in entries)
        Container(
          key: ValueKey('measurement-${entry.id}'),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: context.theme.colors.border),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: entry.value.clamp(1.0, 18.0).toDouble(),
                  decoration: BoxDecoration(
                    color: context.theme.colors.primary,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 250,
                child: _MeasurementDetails(entry: entry, theme: theme),
              ),
            ],
          ),
        ),
    ],
  );
}

class _BreakpointScale extends StatelessWidget {
  const _BreakpointScale({required this.entries, required this.theme});

  final List<DesyNumericEntry> entries;
  final DesyTheme theme;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        height: 94,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 28,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.theme.colors.primary.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              for (final entry in entries)
                Positioned(
                  left: _breakpointOffset(entry.value, constraints.maxWidth),
                  top: 17,
                  child: Column(
                    children: [
                      Container(
                        width: 4,
                        height: 26,
                        color: context.theme.colors.primary,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        entry.displayValue,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  '320 dp',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  '1440 dp',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 4),
      Wrap(
        spacing: 20,
        runSpacing: 16,
        children: [
          for (final entry in entries)
            SizedBox(
              key: ValueKey('measurement-${entry.id}'),
              width: 260,
              child: _MeasurementDetails(entry: entry, theme: theme),
            ),
        ],
      ),
    ],
  );

  double _breakpointOffset(double value, double width) =>
      ((value - 320) / 1120).clamp(0.0, 1.0) * (width - 4);
}

class _OpacityScale extends StatelessWidget {
  const _OpacityScale({required this.entries, required this.theme});

  final List<DesyNumericEntry> entries;
  final DesyTheme theme;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 20,
    runSpacing: 20,
    children: [
      for (final entry in entries)
        _VisualTile(
          key: ValueKey('measurement-${entry.id}'),
          entry: entry,
          theme: theme,
          child: Container(
            width: 128,
            height: 64,
            decoration: _checkerboard(context),
            child: ColoredBox(
              color: context.theme.colors.primary.withValues(
                alpha: entry.value.clamp(0.0, 1.0),
              ),
            ),
          ),
        ),
    ],
  );
}

class _ElevationScale extends StatelessWidget {
  const _ElevationScale({required this.entries, required this.theme});

  final List<DesyNumericEntry> entries;
  final DesyTheme theme;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 20,
    runSpacing: 20,
    children: [
      for (final entry in entries)
        _VisualTile(
          key: ValueKey('measurement-${entry.id}'),
          entry: entry,
          theme: theme,
          child: Container(
            width: 128,
            height: 64,
            decoration: BoxDecoration(
              color: context.theme.colors.background,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .22),
                  blurRadius: entry.value.clamp(0.0, 24.0),
                  offset: Offset(0, entry.value.clamp(0.0, 24.0) / 2),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

BoxDecoration _quietSurface(BuildContext context) => BoxDecoration(
  color: context.theme.colors.muted.withValues(alpha: .3),
  borderRadius: BorderRadius.circular(12),
);

BoxDecoration _checkerboard(BuildContext context) => BoxDecoration(
  color: context.theme.colors.background,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: context.theme.colors.border),
);

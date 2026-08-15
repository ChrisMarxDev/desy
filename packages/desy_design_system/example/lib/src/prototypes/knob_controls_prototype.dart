// PROTOTYPE — component-details control layout directions.
//
// This consumer-owned session asks: which grouping makes the same Button
// controls easiest to scan in the component details workflow?
// It is intentionally not production workbench code.

import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';

/// Three interactive component-details control layout directions.
DesyPrototypeSession
buildKnobControlsPrototypeSession() => DesyPrototypeSession(
  id: 'desy.prototype-session.knob-controls',
  name: 'Component control layouts',
  description:
      'Which grouping makes Button controls clearest in the component details view?',
  prototypes: const [
    DesyPrototype(
      id: 'desy.prototype.knob-controls.context-sheet',
      name: 'Group cards',
      description:
          'A Properties card establishes scope; Content and Appearance each get their own card.',
      canvasPlacement: DesyCanvasPlacement(
        offset: Offset(72, 96),
        size: Size(420, 700),
      ),
      builder: _groupCards,
    ),
    DesyPrototype(
      id: 'desy.prototype.knob-controls.property-sheet',
      name: 'Section wells',
      description:
          'One sheet uses contained section wells to distinguish groups without a stack of cards.',
      canvasPlacement: DesyCanvasPlacement(
        offset: Offset(556, 96),
        size: Size(420, 700),
      ),
      builder: _sectionWells,
    ),
    DesyPrototype(
      id: 'desy.prototype.knob-controls.section-sheet',
      name: 'Divider bands',
      description:
          'One sheet uses stronger labelled bands and generous gaps to create a reading rhythm.',
      canvasPlacement: DesyCanvasPlacement(
        offset: Offset(1040, 96),
        size: Size(420, 700),
      ),
      builder: _dividerBands,
    ),
  ],
);

Widget _groupCards(BuildContext context) =>
    const _ComponentControlsDemo(layout: _ComponentControlsLayout.cards);

Widget _sectionWells(BuildContext context) =>
    const _ComponentControlsDemo(layout: _ComponentControlsLayout.wells);

Widget _dividerBands(BuildContext context) =>
    const _ComponentControlsDemo(layout: _ComponentControlsLayout.bands);

enum _ComponentControlsLayout { cards, wells, bands }

class _ComponentControlsDemo extends StatefulWidget {
  const _ComponentControlsDemo({required this.layout});

  final _ComponentControlsLayout layout;

  @override
  State<_ComponentControlsDemo> createState() => _ComponentControlsDemoState();
}

class _ComponentControlsDemoState extends State<_ComponentControlsDemo> {
  var _label = 'Continue';
  var _radius = 12.0;
  var _enabled = true;

  @override
  Widget build(BuildContext context) => switch (widget.layout) {
    _ComponentControlsLayout.cards => _GroupCardLayout(
      labelRow: _labelRow(),
      appearanceRows: [_radiusRow(), _enabledRow()],
    ),
    _ComponentControlsLayout.wells => _SectionWellSheet(
      labelRow: _labelRow(),
      appearanceRows: [_radiusRow(), _enabledRow()],
    ),
    _ComponentControlsLayout.bands => _DividerBandSheet(
      labelRow: _labelRow(),
      appearanceRows: [_radiusRow(), _enabledRow()],
    ),
  };

  DesyTextKnobRow _labelRow() => DesyTextKnobRow(
    label: 'Label',
    description: 'Words people see before they take the action.',
    value: _label,
    onChanged: (value) => setState(() => _label = value),
  );

  DesyNumericKnobRow _radiusRow() => DesyNumericKnobRow(
    label: 'Corner radius',
    description: 'Rounds the button’s outer corners.',
    value: _radius,
    unit: 'px',
    step: 2,
    minimum: 0,
    maximum: 24,
    onChanged: (value) => setState(() => _radius = value),
  );

  DesyBooleanKnobRow _enabledRow() => DesyBooleanKnobRow(
    label: 'Enabled',
    description: 'Keeps the primary action available.',
    value: _enabled,
    onChanged: (value) => setState(() => _enabled = value),
  );
}

class _GroupCardLayout extends StatelessWidget {
  const _GroupCardLayout({
    required this.labelRow,
    required this.appearanceRows,
  });

  final Widget labelRow;
  final List<Widget> appearanceRows;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _DetailsHeadingCard(),
      const SizedBox(height: DesyDesignSystemTokens.spaceMd),
      _ControlGroupCard(
        label: 'CONTENT',
        description: 'The words people read.',
        children: [labelRow],
      ),
      const SizedBox(height: DesyDesignSystemTokens.spaceMd),
      _ControlGroupCard(
        label: 'APPEARANCE',
        description: 'Shape and availability.',
        children: appearanceRows,
      ),
    ],
  );
}

class _SectionWellSheet extends StatelessWidget {
  const _SectionWellSheet({
    required this.labelRow,
    required this.appearanceRows,
  });

  final Widget labelRow;
  final List<Widget> appearanceRows;

  @override
  Widget build(BuildContext context) => _DetailsSheet(
    children: [
      _SectionWell(
        label: 'CONTENT',
        description: 'The words people read.',
        children: [labelRow],
      ),
      const SizedBox(height: DesyDesignSystemTokens.spaceMd),
      _SectionWell(
        label: 'APPEARANCE',
        description: 'Shape and availability.',
        children: appearanceRows,
      ),
    ],
  );
}

class _DividerBandSheet extends StatelessWidget {
  const _DividerBandSheet({
    required this.labelRow,
    required this.appearanceRows,
  });

  final Widget labelRow;
  final List<Widget> appearanceRows;

  @override
  Widget build(BuildContext context) => _DetailsSheet(
    children: [
      _DividerBand(
        label: 'CONTENT',
        detail: 'Visible copy',
        children: [labelRow],
      ),
      const SizedBox(height: DesyDesignSystemTokens.spaceXl),
      _DividerBand(
        label: 'APPEARANCE',
        detail: 'Shape and state',
        children: appearanceRows,
      ),
    ],
  );
}

class _DetailsHeadingCard extends StatelessWidget {
  const _DetailsHeadingCard();

  @override
  Widget build(BuildContext context) => DesyCard(
    child: const Padding(
      padding: EdgeInsets.all(DesyDesignSystemTokens.spaceLg),
      child: _DetailsHeading(),
    ),
  );
}

class _DetailsSheet extends StatelessWidget {
  const _DetailsSheet({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DesyCard(
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DetailsHeading(),
          const SizedBox(height: DesyDesignSystemTokens.spaceLg),
          ...children,
        ],
      ),
    ),
  );
}

class _DetailsHeading extends StatelessWidget {
  const _DetailsHeading();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        header: true,
        child: Text('Properties', style: context.theme.typography.display.sm),
      ),
      const SizedBox(height: DesyDesignSystemTokens.spaceSm),
      Text(
        'Button component',
        style: context.theme.typography.body.md.copyWith(
          color: context.theme.colors.mutedForeground,
          height: 1.4,
        ),
      ),
    ],
  );
}

class _ControlGroupCard extends StatelessWidget {
  const _ControlGroupCard({
    required this.label,
    required this.description,
    required this.children,
  });

  final String label;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DesyCard(
    child: Padding(
      padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
      child: _SectionContents(
        label: label,
        description: description,
        children: children,
      ),
    ),
  );
}

class _SectionWell extends StatelessWidget {
  const _SectionWell({
    required this.label,
    required this.description,
    required this.children,
  });

  final String label;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.theme.colors.secondary,
      border: Border.all(color: context.theme.colors.border),
      borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusMd),
    ),
    child: Padding(
      padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
      child: _SectionContents(
        label: label,
        description: description,
        children: children,
      ),
    ),
  );
}

class _SectionContents extends StatelessWidget {
  const _SectionContents({
    required this.label,
    required this.description,
    required this.children,
  });

  final String label;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: context.theme.typography.body.xs.copyWith(
          color: context.theme.colors.mutedForeground,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
      const SizedBox(height: DesyDesignSystemTokens.spaceXs),
      Text(
        description,
        style: context.theme.typography.body.sm.copyWith(
          color: context.theme.colors.mutedForeground,
        ),
      ),
      const SizedBox(height: DesyDesignSystemTokens.spaceSm),
      ...children,
    ],
  );
}

class _DividerBand extends StatelessWidget {
  const _DividerBand({
    required this.label,
    required this.detail,
    required this.children,
  });

  final String label;
  final String detail;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Text(
            label,
            style: context.theme.typography.body.xs.copyWith(
              color: context.theme.colors.mutedForeground,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(width: DesyDesignSystemTokens.spaceSm),
          Expanded(
            child: SizedBox(
              height: DesyDesignSystemTokens.hairline,
              child: ColoredBox(color: context.theme.colors.border),
            ),
          ),
        ],
      ),
      const SizedBox(height: DesyDesignSystemTokens.spaceXs),
      Text(
        detail,
        style: context.theme.typography.body.sm.copyWith(
          color: context.theme.colors.mutedForeground,
        ),
      ),
      const SizedBox(height: DesyDesignSystemTokens.spaceSm),
      ...children,
    ],
  );
}

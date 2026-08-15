// PROTOTYPE — framed knob-sheet information hierarchy directions.
//
// This consumer-owned session asks: which framed-sheet hierarchy makes the
// same Button controls easiest to scan in a 173–175 px inspector rail?
// It is intentionally not production workbench code.

import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';

/// Three interactive framed-sheet directions for component controls.
DesyPrototypeSession
buildKnobControlsPrototypeSession() => DesyPrototypeSession(
  id: 'desy.prototype-session.knob-controls',
  name: 'Framed knob sheets',
  description:
      'Which framed hierarchy makes the same Button controls clearest in a 173–175 px rail?',
  prototypes: const [
    DesyPrototype(
      id: 'desy.prototype.knob-controls.context-sheet',
      name: 'Context first',
      description:
          'A component-level heading gives every control shared context before the groups begin.',
      canvasPlacement: DesyCanvasPlacement(
        offset: Offset(72, 96),
        size: Size(320, 480),
      ),
      builder: _contextFirstSheet,
    ),
    DesyPrototype(
      id: 'desy.prototype.knob-controls.property-sheet',
      name: 'Property first',
      description:
          'The most visible decision leads; supporting adjustments follow as a second step.',
      canvasPlacement: DesyCanvasPlacement(
        offset: Offset(72, 672),
        size: Size(320, 480),
      ),
      builder: _propertyFirstSheet,
    ),
    DesyPrototype(
      id: 'desy.prototype.knob-controls.section-sheet',
      name: 'Section first',
      description:
          'Three explicit groups make content, shape, and state easy to find at a glance.',
      canvasPlacement: DesyCanvasPlacement(
        offset: Offset(72, 1248),
        size: Size(320, 480),
      ),
      builder: _sectionFirstSheet,
    ),
  ],
);

Widget _contextFirstSheet(BuildContext context) =>
    const _FramedSheetDirection(hierarchy: _FramedSheetHierarchy.context);

Widget _propertyFirstSheet(BuildContext context) =>
    const _FramedSheetDirection(hierarchy: _FramedSheetHierarchy.property);

Widget _sectionFirstSheet(BuildContext context) =>
    const _FramedSheetDirection(hierarchy: _FramedSheetHierarchy.section);

enum _FramedSheetHierarchy { context, property, section }

class _FramedSheetDirection extends StatefulWidget {
  const _FramedSheetDirection({required this.hierarchy});

  final _FramedSheetHierarchy hierarchy;

  @override
  State<_FramedSheetDirection> createState() => _FramedSheetDirectionState();
}

class _FramedSheetDirectionState extends State<_FramedSheetDirection> {
  var _label = 'Continue';
  var _radius = 12.0;
  var _enabled = true;

  @override
  Widget build(BuildContext context) => DesyKnobSheet(
    title: switch (widget.hierarchy) {
      _FramedSheetHierarchy.context ||
      _FramedSheetHierarchy.section => 'Button',
      _FramedSheetHierarchy.property => 'Button label',
    },
    subtitle: switch (widget.hierarchy) {
      _FramedSheetHierarchy.context => 'Adjust this component.',
      _FramedSheetHierarchy.property => 'Start with its visible action copy.',
      _FramedSheetHierarchy.section => 'Content, appearance, and availability.',
    },
    sections: switch (widget.hierarchy) {
      _FramedSheetHierarchy.context => [
        DesyKnobSection(label: 'CONTENT', children: [_labelRow()]),
        DesyKnobSection(
          label: 'APPEARANCE',
          children: [_radiusRow(), _enabledRow()],
        ),
      ],
      _FramedSheetHierarchy.property => [
        DesyKnobSection(
          label: 'PRIMARY DECISION',
          children: [_labelRow(description: 'The action people read first.')],
        ),
        DesyKnobSection(
          label: 'REFINE',
          children: [
            _radiusRow(description: 'The button’s outer shape.'),
            _enabledRow(description: 'Whether the action is available.'),
          ],
        ),
      ],
      _FramedSheetHierarchy.section => [
        DesyKnobSection(label: 'CONTENT', children: [_labelRow()]),
        DesyKnobSection(label: 'SHAPE', children: [_radiusRow()]),
        DesyKnobSection(label: 'STATE', children: [_enabledRow()]),
      ],
    },
  );

  DesyTextKnobRow _labelRow({String? description}) => DesyTextKnobRow(
    label: 'Label',
    description: description ?? 'Visible action copy used by the button.',
    value: _label,
    onChanged: (value) => setState(() => _label = value),
  );

  DesyNumericKnobRow _radiusRow({String? description}) => DesyNumericKnobRow(
    label: 'Corner radius',
    description: description ?? 'Rounds the button’s outer corners.',
    value: _radius,
    unit: 'px',
    step: 2,
    minimum: 0,
    maximum: 24,
    onChanged: (value) => setState(() => _radius = value),
  );

  DesyBooleanKnobRow _enabledRow({String? description}) => DesyBooleanKnobRow(
    label: 'Enabled',
    description: description ?? 'Keeps the primary action available.',
    value: _enabled,
    onChanged: (value) => setState(() => _enabled = value),
  );
}

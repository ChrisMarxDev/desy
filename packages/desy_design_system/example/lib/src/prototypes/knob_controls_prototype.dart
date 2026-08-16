// PROTOTYPE — selected component-details sheet direction.
//
// This consumer-owned session exercises the component-detail sheet structure
// before it becomes the stable workbench control surface.

import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';

/// The selected component-details sheet direction.
DesyPrototypeSession
buildKnobControlsPrototypeSession() => DesyPrototypeSession(
  id: 'desy.prototype-session.knob-controls',
  name: 'Component control sheet',
  description:
      'A single framed sheet uses labelled segments to keep component controls and preview settings readable.',
  prototypes: const [
    DesyPrototype(
      id: 'desy.prototype.knob-controls.divider-bands',
      name: 'Divider bands',
      description:
          'One sheet with quiet segment descriptions, clear topic boundaries, and room for each control.',
      canvasPlacement: DesyCanvasPlacement(
        offset: Offset(72, 96),
        size: Size(420, 1320),
      ),
      builder: _componentDetailsSheet,
    ),
  ],
);

Widget _componentDetailsSheet(BuildContext context) =>
    const _ComponentDetailsDemo();

class _ComponentDetailsDemo extends StatefulWidget {
  const _ComponentDetailsDemo();

  @override
  State<_ComponentDetailsDemo> createState() => _ComponentDetailsDemoState();
}

class _ComponentDetailsDemoState extends State<_ComponentDetailsDemo> {
  var _label = 'Inspect component';
  var _outline = false;
  var _enabled = true;
  var _frame = _PreviewFrame.responsive;
  var _textScale = 1.0;
  var _textDirection = TextDirection.ltr;
  var _boldText = false;
  var _highContrast = false;
  var _reduceMotion = false;
  var _semanticLabels = false;
  var _hitTargets = false;

  @override
  Widget build(BuildContext context) => DesyKnobSheet(
    segments: [
      DesyKnobSegment(
        title: 'COMPONENT',
        description: 'The selected component and its declared controls.',
        children: _componentRows(),
      ),
      DesyKnobSegment(title: 'CANVAS', children: _canvasRows()),
      DesyKnobSegment(title: 'ACCESSIBILITY', children: _mediaQueryRows()),
    ],
  );

  List<Widget> _componentRows() => [
    const DesyTextValueKnobRow(label: 'ID', value: 'desy.component.button'),
    DesyTextKnobRow(
      label: 'Label',
      value: _label,
      onChanged: (value) => setState(() => _label = value),
    ),
    DesyBooleanKnobRow(
      label: 'Outline',
      value: _outline,
      onChanged: (value) => setState(() => _outline = value),
    ),
    DesyBooleanKnobRow(
      label: 'Enabled',
      value: _enabled,
      onChanged: (value) => setState(() => _enabled = value),
    ),
    const DesyKnobRow(
      label: 'Press event',
      description: 'Action emitted when the enabled button is activated.',
      control: DesyBadge(
        variant: DesyBadgeVariant.secondary,
        child: Text('Event'),
      ),
    ),
  ];

  List<Widget> _canvasRows() => [
    DesyKnobRow(
      label: 'Preview frame',
      expandControl: true,
      control: DesySelect<_PreviewFrame>.rich(
        size: DesySelectSize.sm,
        control: DesySelectControl.lifted(
          value: _frame,
          onChange: (value) {
            if (value != null) setState(() => _frame = value);
          },
        ),
        format: (frame) => frame.label,
        children: [
          for (final frame in _PreviewFrame.values)
            DesySelectItem.item(value: frame, title: Text(frame.label)),
        ],
      ),
    ),
  ];

  List<Widget> _mediaQueryRows() => [
    DesyNumericKnobRow(
      label: 'Text scale',
      value: _textScale,
      unit: '×',
      step: .1,
      minimum: .8,
      maximum: 2,
      onChanged: (value) => setState(() => _textScale = value),
    ),
    DesyKnobRow(
      label: 'Text direction',
      control: DesyButton(
        size: DesyButtonSize.xs,
        variant: DesyButtonVariant.outline,
        semanticsLabel:
            'Use ${_textDirection == TextDirection.ltr ? 'right-to-left' : 'left-to-right'} text direction',
        onPress: () => setState(
          () => _textDirection = _textDirection == TextDirection.ltr
              ? TextDirection.rtl
              : TextDirection.ltr,
        ),
        child: Text(_textDirection == TextDirection.ltr ? 'LTR' : 'RTL'),
      ),
    ),
    DesyBooleanKnobRow(
      label: 'Bold text',
      value: _boldText,
      onChanged: (value) => setState(() => _boldText = value),
    ),
    DesyBooleanKnobRow(
      label: 'High contrast',
      value: _highContrast,
      onChanged: (value) => setState(() => _highContrast = value),
    ),
    DesyBooleanKnobRow(
      label: 'Reduce motion',
      value: _reduceMotion,
      onChanged: (value) => setState(() => _reduceMotion = value),
    ),
    DesyBooleanKnobRow(
      label: 'Semantic labels',
      value: _semanticLabels,
      onChanged: (value) => setState(() => _semanticLabels = value),
    ),
    DesyBooleanKnobRow(
      label: 'Hit targets',
      value: _hitTargets,
      onChanged: (value) => setState(() => _hitTargets = value),
    ),
  ];
}

enum _PreviewFrame {
  responsive('Responsive'),
  iPhone15Pro('iPhone 15 Pro'),
  iPadPro11('iPad Pro 11');

  const _PreviewFrame(this.label);

  final String label;
}

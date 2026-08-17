// Shared internal workbench controls for real component instances.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:desy_design_system/desy_design_system.dart';

import '../../registry.dart';

/// One canonical knob UI used wherever Desy renders a component instance.
///
/// Detail inspection and sketching share this exact control surface. The
/// callers own state, while this panel only translates declared knob types to
/// Desy-owned knob rows and returns typed values through [onChanged].
class DesyComponentKnobPanel extends StatelessWidget {
  const DesyComponentKnobPanel({
    super.key,
    required this.registry,
    required this.knobs,
    required this.values,
    required this.onChanged,
    this.componentId,
    this.additionalSegments = const [],
  });

  final DesyRegistry registry;
  final List<KnobDefinition<Object>> knobs;
  final Map<String, Object> values;
  final void Function(KnobDefinition<Object> knob, Object value) onChanged;
  final String? componentId;
  final List<DesyKnobSegment> additionalSegments;

  /// Produces the reusable ordered knob-sheet segments for one component.
  ///
  /// Detail screens can compose these with their preview-environment, motion,
  /// and export segments without nesting multiple independently padded sheets.
  static List<DesyKnobSegment> segments({
    required DesyRegistry registry,
    required List<KnobDefinition<Object>> knobs,
    required Map<String, Object> values,
    required void Function(KnobDefinition<Object> knob, Object value) onChanged,
    String? componentId,
    List<DesyKnobSegment> additionalSegments = const [],
  }) => [
    DesyKnobSegment(
      title: 'COMPONENT',
      children: [
        if (componentId case final componentId?)
          DesyTextValueKnobRow(label: 'ID', value: componentId),
        for (final knob in knobs)
          switch (knob.kind) {
            DesyKnobKind.boolean => DesyBooleanKnobRow(
              label: knob.name,
              description: knob.description,
              value: values[knob.id] as bool? ?? knob.initial as bool,
              onChanged: (value) => onChanged(knob, value),
            ),
            DesyKnobKind.string => DesyTextKnobRow(
              label: knob.name,
              description: knob.description,
              value: values[knob.id] as String? ?? knob.initial as String,
              onChanged: (value) => onChanged(knob, value),
            ),
            DesyKnobKind.choice => DesyChoiceKnobRow(
              label: knob.name,
              description: knob.description,
              value: values[knob.id] as String? ?? knob.initial as String,
              options: knob.options,
              controlKey: ValueKey('choice-knob-select-${knob.id}'),
              onChanged: (value) => onChanged(knob, value),
            ),
            DesyKnobKind.number => DesyNumericKnobRow(
              label: knob.name,
              description: knob.description,
              value: values[knob.id] as double? ?? knob.initial as double,
              unit: knob.unit!,
              step: knob.step!,
              minimum: knob.minimum!,
              maximum: knob.maximum!,
              onChanged: (value) => onChanged(knob, value),
            ),
            DesyKnobKind.dateTime => DesyDateTimeKnobRow(
              label: knob.name,
              description: knob.description,
              value: values[knob.id] as DateTime? ?? knob.initial as DateTime,
              onChanged: (value) => onChanged(knob, value),
            ),
            DesyKnobKind.color => _ColorKnob(
              registry: registry,
              definition: knob,
              value: values[knob.id] as Color? ?? knob.initial as Color,
              onChanged: (value) => onChanged(knob, value),
            ),
            DesyKnobKind.widgetInstance => _ComponentInstanceKnob(
              registry: registry,
              definition: knob,
              selected:
                  (values[knob.id] as String?) ??
                  (knob.initial as DesyInstanceId).value,
              onChanged: (value) => onChanged(knob, value),
            ),
            DesyKnobKind.widgetInstances => _ComponentInstancesKnob(
              registry: registry,
              definition: knob,
              selected: switch (values[knob.id]) {
                Iterable<Object?> items => items.whereType<String>().toList(),
                _ => [
                  for (final id in (knob.initial as DesyInstanceIds).values)
                    id.value,
                ],
              },
              onChanged: (value) => onChanged(knob, value),
            ),
            DesyKnobKind.event => DesyKnobRow(
              label: knob.name,
              description: knob.description,
              control: const DesyBadge(
                variant: DesyBadgeVariant.secondary,
                child: Text('Event'),
              ),
            ),
          },
      ],
    ),
    ...additionalSegments,
  ];

  @override
  Widget build(BuildContext context) => DesyKnobSheet(
    segments: segments(
      registry: registry,
      knobs: knobs,
      values: values,
      onChanged: onChanged,
      componentId: componentId,
      additionalSegments: additionalSegments,
    ),
  );
}

class _ColorKnob extends StatelessWidget {
  const _ColorKnob({
    required this.registry,
    required this.definition,
    required this.value,
    required this.onChanged,
  });

  final DesyRegistry registry;
  final KnobDefinition<Object> definition;
  final Color value;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) => DesyColorKnobRow(
    label: definition.name,
    description: definition.description,
    value: value,
    onChanged: onChanged,
    onPick: () => _openPicker(context),
  );

  Future<void> _openPicker(BuildContext context) async {
    final result = await showDesyDialog<Color>(
      context: context,
      builder: (context, animation) => DesyDialog(
        animation: animation,
        semanticsLabel: 'Pick ${definition.name}',
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        builder: (context, _) => _ColorPicker(
          registry: registry,
          definition: definition,
          initial: value,
        ),
      ),
    );
    if (result != null) onChanged(result);
  }
}

class _ColorPicker extends StatefulWidget {
  const _ColorPicker({
    required this.registry,
    required this.definition,
    required this.initial,
  });

  final DesyRegistry registry;
  final KnobDefinition<Object> definition;
  final Color initial;

  @override
  State<_ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<_ColorPicker> {
  late HSVColor _color = HSVColor.fromColor(widget.initial);

  Color get color => _color.toColor();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: SizedBox(
      width: 460,
      height: 640,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pick ${widget.definition.name}',
            style: context.theme.typography.display.sm,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.registry.allColors.isNotEmpty) ...[
                    Text(
                      'REGISTERED COLORS',
                      style: context.theme.typography.body.xs.copyWith(
                        color: context.theme.colors.mutedForeground,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final entry in widget.registry.allColors)
                          DesyButton(
                            key: ValueKey(
                              'color-knob-option-${widget.definition.id}-${entry.id}',
                            ),
                            size: DesyButtonSize.sm,
                            variant: DesyButtonVariant.outline,
                            semanticsLabel:
                                'Use registered color ${entry.name}',
                            prefix: _ColorSwatch(color: entry.color),
                            onPress: () =>
                                Navigator.of(context).pop(entry.color),
                            child: Text(entry.name),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    'CUSTOM COLOR',
                    style: context.theme.typography.body.xs.copyWith(
                      color: context.theme.colors.mutedForeground,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _ColorSwatch(color: color, size: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DesyTextField(
                          key: ValueKey(
                            'color-knob-picker-field-${widget.definition.id}',
                          ),
                          label: '${widget.definition.name} ARGB',
                          value: _colorHex(color),
                          hintText: '#AARRGGBB',
                          onChanged: (input) {
                            final next = _parseColor(input);
                            if (next != null) {
                              setState(() => _color = HSVColor.fromColor(next));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ColorSlider(
                    label: 'Hue',
                    value: _color.hue / 360,
                    displayValue: '${_color.hue.round()}°',
                    onChanged: (value) =>
                        setState(() => _color = _color.withHue(value * 360)),
                  ),
                  _ColorSlider(
                    label: 'Saturation',
                    value: _color.saturation,
                    displayValue: '${(_color.saturation * 100).round()}%',
                    onChanged: (value) =>
                        setState(() => _color = _color.withSaturation(value)),
                  ),
                  _ColorSlider(
                    label: 'Brightness',
                    value: _color.value,
                    displayValue: '${(_color.value * 100).round()}%',
                    onChanged: (value) =>
                        setState(() => _color = _color.withValue(value)),
                  ),
                  _ColorSlider(
                    label: 'Alpha',
                    value: _color.alpha,
                    displayValue: '${(_color.alpha * 100).round()}%',
                    onChanged: (value) =>
                        setState(() => _color = _color.withAlpha(value)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          DesyButton(
            key: ValueKey('color-knob-use-custom-${widget.definition.id}'),
            onPress: () => Navigator.of(context).pop(color),
            child: const Text('Use custom color'),
          ),
        ],
      ),
    ),
  );
}

class _ColorSlider extends StatelessWidget {
  const _ColorSlider({
    required this.label,
    required this.value,
    required this.displayValue,
    required this.onChanged,
  });

  final String label;
  final double value;
  final String displayValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        SizedBox(width: 80, child: Text(label)),
        Expanded(
          child: DesySlider(
            control: DesySliderControl.liftedContinuous(
              value: DesySliderValue(max: value),
              onChange: (value) => onChanged(value.max),
            ),
            semanticValueFormatterCallback: (_) => displayValue,
            tooltipBuilder: (_, _) => Text(displayValue),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(displayValue, textAlign: TextAlign.end),
        ),
      ],
    ),
  );
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.color, this.size = 20});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: context.theme.colors.border),
      borderRadius: BorderRadius.circular(4),
    ),
  );
}

String _colorHex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

Color? _parseColor(String input) {
  final hex = input.trim().replaceFirst('#', '');
  if (hex.length != 6 && hex.length != 8) return null;
  final value = int.tryParse(hex, radix: 16);
  if (value == null) return null;
  return Color(hex.length == 6 ? 0xff000000 | value : value);
}

class _ComponentInstanceKnob extends StatelessWidget {
  const _ComponentInstanceKnob({
    required this.registry,
    required this.definition,
    required this.selected,
    required this.onChanged,
  });

  final DesyRegistry registry;
  final KnobDefinition<Object> definition;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final instance = registry.resolveComponentInstance(selected);
    return DesyInstanceKnobRow(
      label: definition.name,
      description: definition.description,
      instanceName: instance?.name ?? selected,
      controlKey: ValueKey('instance-swap-current-${definition.id}'),
      prefix: Icon(instance?.component.icon ?? DesyIcons.component),
      onPress: () => _openPicker(context),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final result = await showDesyDialog<String>(
      context: context,
      builder: (context, animation) => DesyDialog(
        animation: animation,
        semanticsLabel: 'Swap ${definition.name}',
        builder: (context, _) =>
            _InstancePicker(registry: registry, definition: definition),
      ),
    );
    if (result != null) onChanged(result);
  }
}

class _ComponentInstancesKnob extends StatelessWidget {
  const _ComponentInstancesKnob({
    required this.registry,
    required this.definition,
    required this.selected,
    required this.onChanged,
  });

  final DesyRegistry registry;
  final KnobDefinition<Object> definition;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) => DesyInstanceKnobRow(
    label: definition.name,
    description: definition.description,
    instanceName: '${selected.length} selected',
    controlKey: ValueKey('instance-multi-current-${definition.id}'),
    prefix: const Icon(DesyIcons.component),
    onPress: () => _openPicker(context),
  );

  Future<void> _openPicker(BuildContext context) async {
    final result = await showDesyDialog<List<String>>(
      context: context,
      builder: (context, animation) => DesyDialog(
        animation: animation,
        semanticsLabel: 'Select ${definition.name}',
        builder: (context, _) => _InstancesPicker(
          registry: registry,
          definition: definition,
          selected: selected,
        ),
      ),
    );
    if (result != null) onChanged(result);
  }
}

class _InstancesPicker extends StatefulWidget {
  const _InstancesPicker({
    required this.registry,
    required this.definition,
    required this.selected,
  });

  final DesyRegistry registry;
  final KnobDefinition<Object> definition;
  final List<String> selected;

  @override
  State<_InstancesPicker> createState() => _InstancesPickerState();
}

class _InstancesPickerState extends State<_InstancesPicker> {
  String _query = '';
  late final List<String> _selected = [...widget.selected];

  @override
  Widget build(BuildContext context) {
    Iterable<DesyRegisteredComponentInstance> all =
        widget.registry.allComponentInstances;
    if (widget.definition.options.isNotEmpty) {
      all = all.where(
        (option) => widget.definition.options.contains(option.id),
      );
    }
    final query = _query.toLowerCase();
    final options = all.where(
      (option) =>
          option.name.toLowerCase().contains(query) ||
          option.id.toLowerCase().contains(query),
    );
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select instances',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DesyTextField(
              autofocus: true,
              hintText: 'Search instances',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final option in options) ...[
                      DesyTile(
                        key: ValueKey('instance-multi-option-${option.id}'),
                        prefix: Icon(
                          option.component.icon ?? DesyIcons.component,
                        ),
                        title: Text(
                          option.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                        suffix: Icon(
                          _selected.contains(option.id)
                              ? DesyIcons.check
                              : DesyIcons.plus,
                          size: 14,
                        ),
                        onPress: () => setState(() {
                          if (_selected.contains(option.id)) {
                            _selected.remove(option.id);
                          } else {
                            _selected.add(option.id);
                          }
                        }),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            DesyButton(
              onPress: () => Navigator.of(
                context,
              ).pop(List<String>.unmodifiable(_selected)),
              child: Text('Use ${_selected.length} instances'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstancePicker extends StatefulWidget {
  const _InstancePicker({required this.registry, required this.definition});

  final DesyRegistry registry;
  final KnobDefinition<Object> definition;

  @override
  State<_InstancePicker> createState() => _InstancePickerState();
}

class _InstancePickerState extends State<_InstancePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    Iterable<DesyRegisteredComponentInstance> all =
        widget.registry.allComponentInstances;
    if (widget.definition.options.isNotEmpty) {
      all = all.where(
        (option) => widget.definition.options.contains(option.id),
      );
    }
    final options = all.where((option) {
      final query = _query.toLowerCase();
      return (option.name.toLowerCase().contains(query) ||
          option.id.toLowerCase().contains(query));
    }).toList();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Swap instance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DesyTextField(
              autofocus: true,
              hintText: 'Search instances',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final option in options) ...[
                      DesyTile(
                        key: ValueKey('instance-swap-option-${option.id}'),
                        prefix: Icon(
                          option.component.icon ?? DesyIcons.component,
                        ),
                        title: Text(
                          option.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPress: () => Navigator.of(context).pop(option.id),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

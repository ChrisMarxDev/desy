// Shared internal workbench controls for real component instances.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:desy_design_system/desy_design_system.dart';

import '../../registry.dart';

/// One canonical knob UI used wherever Desy renders a component instance.
///
/// Detail inspection and sketching share this exact control surface. The
/// callers own state, while this panel only translates declared knob types to
/// Forui controls and returns typed values through [onChanged].
class DesyComponentKnobPanel extends StatelessWidget {
  const DesyComponentKnobPanel({
    super.key,
    required this.registry,
    required this.knobs,
    required this.values,
    required this.onChanged,
  });

  final DesyRegistry registry;
  final List<KnobDefinition<Object>> knobs;
  final Map<String, Object> values;
  final void Function(KnobDefinition<Object> knob, Object value) onChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final knob in knobs)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: switch (knob.kind) {
            DesyKnobKind.boolean => DesySwitch(
              label: Text(knob.name),
              value: values[knob.id] as bool? ?? knob.initial as bool,
              onChange: (value) => onChanged(knob, value),
            ),
            DesyKnobKind.string => DesyTextField(
              label: knob.name,
              value: values[knob.id] as String? ?? knob.initial as String,
              onChanged: (value) => onChanged(knob, value),
            ),
            DesyKnobKind.widgetInstance => _ComponentInstanceKnob(
              registry: registry,
              definition: knob,
              selected: (values[knob.id] as String?) ??
                  (knob.initial as DesyInstanceId).value,
              onChanged: (value) => onChanged(knob, value),
            ),
          },
        ),
    ],
  );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(definition.name, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        DesyTile(
          key: ValueKey('instance-swap-current-${definition.id}'),
          prefix: Icon(instance?.component.icon ?? DesyIcons.component),
          title: Text(
            'Swap · ${instance?.name ?? selected}',
            overflow: TextOverflow.ellipsis,
          ),
          suffix: const Icon(DesyIcons.chevronsUpDown),
          onPress: () => _openPicker(context),
        ),
      ],
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final result = await showDesyDialog<String>(
      context: context,
      builder: (context, _, animation) => DesyDialog(
        animation: animation,
        semanticsLabel: 'Swap ${definition.name}',
        builder: (context, _) =>
            _InstancePicker(registry: registry, definition: definition),
      ),
    );
    if (result != null) onChanged(result);
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
    Iterable<DesyRegisteredComponentInstance> all = widget.registry
        .allComponentInstances;
    if (widget.definition.options.isNotEmpty) {
      all = all.where((option) => widget.definition.options.contains(option.id));
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
                        prefix: Icon(option.component.icon ?? DesyIcons.component),
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

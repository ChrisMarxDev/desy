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
  final List<DesyKnob<Object>> knobs;
  final Map<String, Object> values;
  final void Function(DesyKnob<Object> knob, Object value) onChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final knob in knobs)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: switch (knob) {
            DesyBooleanKnob() => DesySwitch(
              label: Text(knob.name),
              value: values[knob.id] as bool? ?? knob.initial,
              onChange: (value) => onChanged(knob, value),
            ),
            DesyStringKnob() => DesyTextField(
              label: knob.name,
              value: values[knob.id] as String? ?? knob.initial,
              onChanged: (value) => onChanged(knob, value),
            ),
            DesyComponentKnob() => _ComponentInstanceKnob(
              registry: registry,
              knob: knob,
              selected: values[knob.id] as String? ?? knob.initial,
              onChanged: (value) => onChanged(knob, value),
            ),
            _ => const SizedBox.shrink(),
          },
        ),
    ],
  );
}

class _ComponentInstanceKnob extends StatelessWidget {
  const _ComponentInstanceKnob({
    required this.registry,
    required this.knob,
    required this.selected,
    required this.onChanged,
  });

  final DesyRegistry registry;
  final DesyComponentKnob knob;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final instance = registry.resolveComponentInstance(selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(knob.name, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        DesyTile(
          key: ValueKey('instance-swap-current-${knob.id}'),
          prefix: Icon(instance?.instance.icon ?? DesyIcons.component),
          title: Text(
            'Swap · ${instance?.instance.name ?? selected}',
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
        semanticsLabel: 'Swap ${knob.name}',
        builder: (context, _) =>
            _InstancePicker(registry: registry, options: knob.options),
      ),
    );
    if (result != null) onChanged(result);
  }
}

class _InstancePicker extends StatefulWidget {
  const _InstancePicker({required this.registry, required this.options});

  final DesyRegistry registry;
  final List<String> options;

  @override
  State<_InstancePicker> createState() => _InstancePickerState();
}

class _InstancePickerState extends State<_InstancePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final options = widget.options.where((optionId) {
      final option = widget.registry.resolveComponentInstance(optionId);
      final query = _query.toLowerCase();
      return (option?.instance.name.toLowerCase().contains(query) ?? false) ||
          optionId.toLowerCase().contains(query);
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
              child: ListView.separated(
                itemCount: options.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final optionId = options[index];
                  final option = widget.registry.resolveComponentInstance(
                    optionId,
                  );
                  return DesyTile(
                    key: ValueKey('instance-swap-option-$optionId'),
                    prefix: Icon(option?.instance.icon ?? DesyIcons.component),
                    title: Text(
                      option?.instance.name ?? optionId,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPress: () => Navigator.of(context).pop(optionId),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

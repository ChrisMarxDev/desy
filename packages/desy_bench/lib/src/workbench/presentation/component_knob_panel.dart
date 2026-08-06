// Shared internal workbench controls for real component instances.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../desy_text_field.dart';
import '../../registry.dart';

/// One canonical knob UI used wherever Desy renders a component instance.
///
/// Detail inspection and sketching share this exact control surface. The
/// callers own state, while this panel only translates declared knob types to
/// Forui controls and returns typed values through [onChanged].
class DesyComponentKnobPanel extends StatelessWidget {
  const DesyComponentKnobPanel({
    super.key,
    required this.knobs,
    required this.values,
    required this.onChanged,
  });

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
            DesyBooleanKnob() => FSwitch(
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
              knob: knob,
              selected:
                  values[knob.id] as DesyComponentInstance? ?? knob.initial,
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
    required this.knob,
    required this.selected,
    required this.onChanged,
  });

  final DesyComponentKnob knob;
  final DesyComponentInstance selected;
  final ValueChanged<DesyComponentInstance> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(knob.name, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      FTile(
        title: Text('Swap · ${selected.name}', overflow: TextOverflow.ellipsis),
        suffix: const Icon(FLucideIcons.chevronsUpDown),
        onPress: () => _openPicker(context),
      ),
    ],
  );

  Future<void> _openPicker(BuildContext context) async {
    final result = await showFDialog<DesyComponentInstance>(
      context: context,
      builder: (context, _, animation) => FDialog(
        animation: animation,
        semanticsLabel: 'Swap ${knob.name}',
        builder: (context, _) => _InstancePicker(options: knob.options),
      ),
    );
    if (result != null) onChanged(result);
  }
}

class _InstancePicker extends StatefulWidget {
  const _InstancePicker({required this.options});

  final List<DesyComponentInstance> options;

  @override
  State<_InstancePicker> createState() => _InstancePickerState();
}

class _InstancePickerState extends State<_InstancePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final options = widget.options.where((option) {
      final query = _query.toLowerCase();
      return option.name.toLowerCase().contains(query) ||
          option.id.toLowerCase().contains(query);
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
                  final option = options[index];
                  return FTile(
                    title: Text(option.name, overflow: TextOverflow.ellipsis),
                    onPress: () => Navigator.of(context).pop(option),
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

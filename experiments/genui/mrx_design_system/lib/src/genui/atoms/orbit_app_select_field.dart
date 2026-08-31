// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppSelectField extends StatelessWidget {
  const OrbitAppSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });
  final String label;
  final List<OrbitChoiceOption> options;
  final String? value;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  @override
  Widget build(BuildContext context) => OrbitAppStack(
    gap: OrbitTokens.spaceXs,
    children: [
      OrbitAppText(label, role: OrbitTextRole.label),
      OrbitAppChoiceControl(
        options: options,
        values: value == null ? {} : {value!},
        onChanged: onChanged == null
            ? null
            : (next) {
                if (next.isNotEmpty) onChanged!(next.first);
              },
        enabled: enabled,
      ),
    ],
  );
}

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Desy's labelled boolean choice control.
///
/// This owns the current Forui implementation so workbench extensions never
/// need to expose or depend on Forui's checkbox contract directly.
class DesyCheckbox extends StatelessWidget {
  /// Creates a labelled Desy checkbox.
  const DesyCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.description,
  });

  /// Current selected state.
  final bool value;

  /// Receives a user-selected state, or disables interaction when null.
  final ValueChanged<bool>? onChanged;

  /// Main checkbox label.
  final Widget label;

  /// Optional supporting explanation.
  final Widget? description;

  @override
  Widget build(BuildContext context) => FCheckbox(
    value: value,
    onChange: onChanged,
    label: label,
    description: description,
  );
}

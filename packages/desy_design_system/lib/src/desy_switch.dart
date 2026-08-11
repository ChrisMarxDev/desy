import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import 'desy_visual_tokens.dart';

/// Desy's labelled boolean switch.
class DesySwitch extends StatelessWidget {
  /// Creates a labelled boolean control.
  const DesySwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChange,
  });

  /// Switch label.
  final Widget label;

  /// Current state.
  final bool value;

  /// Receives a new state, or disables the control when null.
  final ValueChanged<bool>? onChange;

  @override
  Widget build(BuildContext context) {
    final colors = FTheme.of(context).colors;
    return FSwitch(
      leadingLabel: true,
      label: label,
      value: value,
      onChange: onChange,
      style: FSwitchStyleDelta.delta(
        trackColor: FVariants(
          colors.secondary,
          variants: {
            [FSwitchVariant.disabled]: colors.disable(colors.secondary),
            [FSwitchVariant.selected]: colors.desy.signal,
            [FSwitchVariant.selected.and(FSwitchVariant.disabled)]: colors
                .disable(colors.desy.signal),
          },
        ),
      ),
    );
  }
}

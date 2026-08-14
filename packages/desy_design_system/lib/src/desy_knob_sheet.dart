import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'desy_button.dart';
import 'desy_card.dart';
import 'desy_design_system_scope.dart';
import 'desy_icons.dart';
import 'desy_switch.dart';
import 'desy_text_field.dart';
import 'desy_tile.dart';

/// A clear sheet containing related workbench property controls.
class DesyKnobSheet extends StatelessWidget {
  /// Creates a grouped knob sheet.
  const DesyKnobSheet({
    super.key,
    this.title = 'Knobs',
    this.subtitle,
    required this.sections,
  });

  /// The sheet heading.
  final String title;

  /// Optional context that explains the scope of the controls below.
  final String? subtitle;

  /// Typed groups of property controls shown in the sheet.
  final List<DesyKnobSection> sections;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 280;
      return DesyCard(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow
                ? DesyDesignSystemTokens.spaceMd
                : DesyDesignSystemTokens.spaceLg,
            vertical: DesyDesignSystemTokens.spaceLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: context.theme.typography.display.sm),
              ),
              if (subtitle case final subtitle?) ...[
                const SizedBox(height: DesyDesignSystemTokens.spaceSm),
                Text(
                  subtitle,
                  style: context.theme.typography.body.md.copyWith(
                    color: context.theme.colors.mutedForeground,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: DesyDesignSystemTokens.spaceBase),
              SizedBox(
                height: DesyDesignSystemTokens.hairline,
                child: ColoredBox(color: context.theme.colors.border),
              ),
              const SizedBox(height: DesyDesignSystemTokens.spaceSm),
              for (final section in sections) section,
            ],
          ),
        ),
      );
    },
  );
}

/// A labelled group inside a [DesyKnobSheet].
class DesyKnobSection extends StatelessWidget {
  /// Creates a knob group.
  const DesyKnobSection({
    super.key,
    required this.label,
    required this.children,
  });

  /// The compact section label.
  final String label;

  /// The property controls belonging to the group.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.only(
          top: DesyDesignSystemTokens.spaceXs,
          bottom: DesyDesignSystemTokens.spaceXs,
        ),
        child: Text(
          label,
          style: context.theme.typography.body.xs.copyWith(
            color: context.theme.colors.mutedForeground,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ),
      ...children,
      const SizedBox(height: DesyDesignSystemTokens.spaceBase),
    ],
  );
}

/// The shared aligned row used by Desy's knob controls.
class DesyKnobRow extends StatelessWidget {
  /// Creates an aligned label and control row.
  const DesyKnobRow({
    super.key,
    required this.label,
    required this.control,
    this.description,
    this.expandControl = false,
  });

  /// The property name shown at the leading edge.
  final String label;

  /// Optional usage guidance shown below the property name.
  final String? description;

  /// Lets complex controls take advantage of a resized property panel.
  final bool expandControl;

  /// The interactive control aligned to the trailing edge.
  final Widget control;

  @override
  Widget build(BuildContext context) {
    Widget buildLabel({required bool isNarrow}) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              (isNarrow
                      ? context.theme.typography.body.lg
                      : context.theme.typography.body.md)
                  .copyWith(fontWeight: FontWeight.w600),
        ),
        if (description case final description?) ...[
          const SizedBox(height: DesyDesignSystemTokens.spaceXs),
          Text(
            description,
            style: context.theme.typography.body.sm.copyWith(
              color: context.theme.colors.mutedForeground,
              height: 1.35,
            ),
          ),
        ],
      ],
    );

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.theme.colors.border,
            width: DesyDesignSystemTokens.hairline,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 280) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: DesyDesignSystemTokens.spaceMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildLabel(isNarrow: true),
                  const SizedBox(height: DesyDesignSystemTokens.spaceSm),
                  expandControl
                      ? SizedBox(width: double.infinity, child: control)
                      : Align(alignment: Alignment.centerRight, child: control),
                ],
              ),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: expandControl ? 2 : 1,
                child: buildLabel(isNarrow: false),
              ),
              const SizedBox(width: DesyDesignSystemTokens.spaceMd),
              if (expandControl) Expanded(flex: 3, child: control) else control,
            ],
          );
        },
      ),
    );
  }
}

/// A compact numeric property with accessible discrete step actions.
class DesyNumericKnobRow extends StatelessWidget {
  /// Creates a numeric knob row.
  const DesyNumericKnobRow({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.step,
    required this.onChanged,
    this.minimum = 0,
    this.maximum = 999,
    this.description,
  }) : assert(minimum <= maximum),
       assert(step > 0);

  /// The property name.
  final String label;

  /// Optional usage guidance.
  final String? description;

  /// The current numeric value.
  final double value;

  /// The short unit suffix, such as `px` or `%`.
  final String unit;

  /// The amount applied by each step action.
  final double step;

  /// The inclusive lower bound.
  final double minimum;

  /// The inclusive upper bound.
  final double maximum;

  /// Receives stepped values, or disables both actions when null.
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) => DesyKnobRow(
    label: label,
    description: description,
    control: DecoratedBox(
      decoration: BoxDecoration(
        color: context.theme.colors.secondary,
        border: Border.all(color: context.theme.colors.border),
        borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            label: 'Decrease $label',
            icon: DesyIcons.minus,
            onPress: onChanged == null
                ? null
                : () => onChanged!(
                    (value - step).clamp(minimum, maximum).toDouble(),
                  ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              '${_formatNumber(value)} $unit',
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              textAlign: TextAlign.center,
              style: context.theme.typography.body.xs.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          _StepButton(
            label: 'Increase $label',
            icon: DesyIcons.plus,
            onPress: onChanged == null
                ? null
                : () => onChanged!(
                    (value + step).clamp(minimum, maximum).toDouble(),
                  ),
          ),
        ],
      ),
    ),
  );
}

/// A boolean property row that composes Desy's existing switch component.
class DesyBooleanKnobRow extends StatelessWidget {
  /// Creates a boolean knob row.
  const DesyBooleanKnobRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
  });

  /// The property name.
  final String label;

  /// Optional usage guidance.
  final String? description;

  /// The current boolean state.
  final bool value;

  /// Receives state changes, or disables the switch when null.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => DesyKnobRow(
    label: label,
    description: description,
    control: SizedBox(
      width: 104,
      child: DesySwitch(
        label: Text(value ? 'On' : 'Off'),
        value: value,
        onChange: onChanged,
      ),
    ),
  );
}

/// A string property row backed by Desy's native editable text field.
class DesyTextKnobRow extends StatelessWidget {
  /// Creates a text knob row.
  const DesyTextKnobRow({
    super.key,
    required this.label,
    required this.value,
    this.hintText,
    this.onChanged,
    this.enabled = true,
    this.description,
  });

  /// The property name.
  final String label;

  /// Optional usage guidance.
  final String? description;

  /// The current text value.
  final String value;

  /// Optional empty-value guidance.
  final String? hintText;

  /// Receives text changes.
  final ValueChanged<String>? onChanged;

  /// Whether the field accepts editing.
  final bool enabled;

  @override
  Widget build(BuildContext context) => DesyKnobRow(
    label: label,
    description: description,
    expandControl: true,
    control: SizedBox(
      child: DesyTextField(
        label: label,
        value: value,
        hintText: hintText,
        enabled: enabled,
        onChanged: onChanged,
      ),
    ),
  );
}

/// A literal color property with an editable ARGB value.
///
/// The field accepts `#RRGGBB` for opaque colors and `#AARRGGBB` when an
/// explicit alpha channel is needed. Invalid intermediate text remains in the
/// field without changing the declared color.
class DesyColorKnobRow extends StatelessWidget {
  /// Creates a color knob row.
  const DesyColorKnobRow({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.description,
  });

  /// The property name.
  final String label;

  /// Optional usage guidance.
  final String? description;

  /// The current literal Flutter color.
  final Color value;

  /// Receives a complete, valid ARGB color edit.
  final ValueChanged<Color>? onChanged;

  @override
  Widget build(BuildContext context) => DesyKnobRow(
    label: label,
    description: description,
    control: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: '$label color preview',
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: value,
              border: Border.all(color: context.theme.colors.border),
              borderRadius: BorderRadius.circular(
                DesyDesignSystemTokens.radiusSm,
              ),
            ),
          ),
        ),
        const SizedBox(width: DesyDesignSystemTokens.spaceSm),
        SizedBox(
          width: 112,
          child: DesyTextField(
            key: ValueKey('color-knob-field-$label'),
            label: label,
            value: _colorHex(value),
            hintText: '#RRGGBB',
            onChanged: onChanged == null
                ? null
                : (input) {
                    final color = _parseColor(input);
                    if (color != null) onChanged!(color);
                  },
          ),
        ),
      ],
    ),
  );
}

/// A component-instance property row that opens a consumer-owned picker.
class DesyInstanceKnobRow extends StatelessWidget {
  /// Creates an instance-selection knob row.
  const DesyInstanceKnobRow({
    super.key,
    required this.label,
    required this.instanceName,
    required this.onPress,
    this.prefix,
    this.controlKey,
    this.description,
  });

  /// The slot or property name.
  final String label;

  /// Optional usage guidance.
  final String? description;

  /// The currently selected registered instance name.
  final String instanceName;

  /// Optional leading component glyph.
  final Widget? prefix;

  /// Optional stable key for the interactive selection control.
  final Key? controlKey;

  /// Opens the owning workflow's picker, or disables selection when null.
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) => DesyKnobRow(
    label: label,
    description: description,
    expandControl: true,
    control: Tooltip(
      message: instanceName,
      child: DesyTile(
        key: controlKey,
        prefix: prefix,
        title: Text(instanceName, maxLines: 1, overflow: TextOverflow.ellipsis),
        suffix: const Icon(DesyIcons.chevronsUpDown, size: 14),
        onPress: onPress,
      ),
    ),
  );
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.label,
    required this.icon,
    required this.onPress,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) => DesyButton.icon(
    size: DesyButtonSize.xs,
    variant: DesyButtonVariant.ghost,
    semanticsLabel: label,
    onPress: onPress,
    child: Icon(icon, size: 13),
  );
}

String _formatNumber(double value) =>
    value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);

String _colorHex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

Color? _parseColor(String input) {
  final hex = input.trim().replaceFirst('#', '');
  if (hex.length != 6 && hex.length != 8) return null;
  final value = int.tryParse(hex, radix: 16);
  if (value == null) return null;
  return Color(hex.length == 6 ? 0xff000000 | value : value);
}

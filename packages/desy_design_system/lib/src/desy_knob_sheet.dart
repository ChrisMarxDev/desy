import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'desy_button.dart';
import 'desy_design_system_scope.dart';
import 'desy_icons.dart';
import 'desy_select.dart';
import 'desy_switch.dart';
import 'desy_text_field.dart';
import 'desy_tile.dart';

/// A sheet containing ordered, labelled property-control segments.
class DesyKnobSheet extends StatelessWidget {
  /// Creates a knob sheet.
  const DesyKnobSheet({super.key, required this.segments});

  /// The ordered segments displayed in this sheet.
  final List<DesyKnobSegment> segments;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 280;
      return Padding(
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
            for (var index = 0; index < segments.length; index++) ...[
              if (index > 0)
                const SizedBox(height: DesyDesignSystemTokens.space2xl),
              _DesyKnobSegmentContents(segment: segments[index]),
            ],
          ],
        ),
      );
    },
  );
}

/// One labelled, ordered segment in a [DesyKnobSheet].
class DesyKnobSegment {
  /// Creates a knob segment.
  const DesyKnobSegment({
    required this.title,
    this.description,
    required this.children,
  });

  /// The compact heading that names this group of controls.
  final String title;

  /// Optional quiet context below [title].
  final String? description;

  /// The ordered content of this segment.
  ///
  /// Prefer Desy's standard knob rows: [DesyTextValueKnobRow],
  /// [DesyTextKnobRow], [DesyBooleanKnobRow], [DesyNumericKnobRow],
  /// [DesyChoiceKnobRow], [DesyDateTimeKnobRow], [DesyColorKnobRow],
  /// [DesyInstanceKnobRow], or [DesyKnobRow]. A detail
  /// extension may also supply one of its own self-contained widgets here;
  /// keep it visually aligned with the surrounding knob rows.
  final List<Widget> children;
}

class _DesyKnobSegmentContents extends StatelessWidget {
  const _DesyKnobSegmentContents({required this.segment});

  final DesyKnobSegment segment;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Semantics(
            header: true,
            child: Text(
              segment.title,
              style: context.theme.typography.body.xs.copyWith(
                color: context.theme.colors.mutedForeground,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(width: DesyDesignSystemTokens.spaceSm),
          Expanded(
            child: SizedBox(
              height: DesyDesignSystemTokens.hairline,
              child: ColoredBox(color: context.theme.colors.border),
            ),
          ),
        ],
      ),
      if (segment.description case final description?) ...[
        const SizedBox(height: DesyDesignSystemTokens.spaceXs),
        Text(
          description,
          style: context.theme.typography.body.sm.copyWith(
            color: context.theme.colors.mutedForeground,
            height: 1.35,
          ),
        ),
      ],
      const SizedBox(height: DesyDesignSystemTokens.spaceLg),
      ...segment.children,
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
    Widget buildLabel() => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.theme.typography.body.sm.copyWith(
            fontWeight: FontWeight.w600,
          ),
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

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 280) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: DesyDesignSystemTokens.spaceMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildLabel(),
                  const SizedBox(height: DesyDesignSystemTokens.spaceSm),
                  expandControl
                      ? SizedBox(width: double.infinity, child: control)
                      : control,
                ],
              ),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: expandControl ? 2 : 1, child: buildLabel()),
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

/// A read-only text value shown alongside a component property label.
///
/// Use this for stable metadata such as a component identifier. For editable
/// content, use [DesyTextKnobRow] instead.
class DesyTextValueKnobRow extends StatelessWidget {
  /// Creates a read-only text property row.
  const DesyTextValueKnobRow({
    super.key,
    required this.label,
    required this.value,
    this.description,
  });

  /// The metadata property name.
  final String label;

  /// Optional usage guidance.
  final String? description;

  /// The text value shown for the property.
  final String value;

  @override
  Widget build(BuildContext context) => DesyKnobRow(
    label: label,
    description: description,
    expandControl: true,
    control: Semantics(
      label: '$label: $value',
      child: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: context.theme.typography.body.sm.copyWith(
          color: context.theme.colors.mutedForeground,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

/// A finite string property rendered through Desy's dropdown control.
class DesyChoiceKnobRow extends StatelessWidget {
  /// Creates a string-choice knob row.
  const DesyChoiceKnobRow({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    this.onChanged,
    this.description,
    this.controlKey,
  }) : assert(options.length > 0);

  /// The property name.
  final String label;

  /// Optional usage guidance.
  final String? description;

  /// The currently selected option.
  final String value;

  /// Legal values and visible labels, in dropdown order.
  final List<String> options;

  /// Receives a selected legal value, or disables the dropdown when null.
  final ValueChanged<String>? onChanged;

  /// Optional stable key for the dropdown control.
  final Key? controlKey;

  @override
  Widget build(BuildContext context) => DesyKnobRow(
    label: label,
    description: description,
    expandControl: true,
    control: DesySelect<String>.rich(
      key: controlKey,
      size: DesySelectSize.sm,
      enabled: onChanged != null,
      control: DesySelectControl.lifted(
        value: value,
        onChange: (next) {
          if (next != null) onChanged?.call(next);
        },
      ),
      format: (current) => current,
      children: [
        for (final option in options)
          DesySelectItem.item(
            key: ValueKey('choice-knob-option-$label-$option'),
            value: option,
            title: Text(option),
          ),
      ],
    ),
  );
}

/// A typed date-and-time property edited without encoding it as one text knob.
///
/// Date and time fields accept `YYYY-MM-DD` and `HH:MM[:SS]`. Invalid
/// intermediate edits remain in the native field without changing [value].
class DesyDateTimeKnobRow extends StatelessWidget {
  /// Creates a date-and-time knob row.
  const DesyDateTimeKnobRow({
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

  /// The current literal Flutter date and time.
  final DateTime value;

  /// Receives complete, valid date or time edits.
  final ValueChanged<DateTime>? onChanged;

  @override
  Widget build(BuildContext context) => DesyKnobRow(
    label: label,
    description: description,
    expandControl: true,
    control: Wrap(
      spacing: DesyDesignSystemTokens.spaceSm,
      runSpacing: DesyDesignSystemTokens.spaceSm,
      children: [
        SizedBox(
          width: 128,
          child: DesyTextField(
            key: ValueKey('date-time-knob-date-$label'),
            label: '$label date',
            value: _formatDate(value),
            hintText: 'YYYY-MM-DD',
            onChanged: onChanged == null
                ? null
                : (input) {
                    final next = _replaceDate(value, input);
                    if (next != null) onChanged!(next);
                  },
          ),
        ),
        SizedBox(
          width: 112,
          child: DesyTextField(
            key: ValueKey('date-time-knob-time-$label'),
            label: '$label time',
            value: _formatTime(value),
            hintText: 'HH:MM:SS',
            onChanged: onChanged == null
                ? null
                : (input) {
                    final next = _replaceTime(value, input);
                    if (next != null) onChanged!(next);
                  },
          ),
        ),
      ],
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
    this.onPick,
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

  /// Opens a richer owning color workflow, such as registry swatches + picker.
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) => DesyKnobRow(
    label: label,
    description: description,
    control: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DesyButton.icon(
          key: ValueKey('color-knob-picker-$label'),
          size: DesyButtonSize.sm,
          variant: DesyButtonVariant.outline,
          semanticsLabel: 'Pick $label color',
          onPress: onPick,
          child: Container(
            width: 20,
            height: 20,
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

String _formatDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

String _formatTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}:'
    '${value.second.toString().padLeft(2, '0')}';

DateTime? _replaceDate(DateTime value, String input) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(input.trim());
  if (match == null) return null;
  final year = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final day = int.parse(match[3]!);
  final next = value.isUtc
      ? DateTime.utc(
          year,
          month,
          day,
          value.hour,
          value.minute,
          value.second,
          value.millisecond,
          value.microsecond,
        )
      : DateTime(
          year,
          month,
          day,
          value.hour,
          value.minute,
          value.second,
          value.millisecond,
          value.microsecond,
        );
  return next.year == year && next.month == month && next.day == day
      ? next
      : null;
}

DateTime? _replaceTime(DateTime value, String input) {
  final match = RegExp(
    r'^(\d{2}):(\d{2})(?::(\d{2}))?$',
  ).firstMatch(input.trim());
  if (match == null) return null;
  final hour = int.parse(match[1]!);
  final minute = int.parse(match[2]!);
  final second = int.parse(match[3] ?? '0');
  if (hour > 23 || minute > 59 || second > 59) return null;
  return value.isUtc
      ? DateTime.utc(
          value.year,
          value.month,
          value.day,
          hour,
          minute,
          second,
          value.millisecond,
          value.microsecond,
        )
      : DateTime(
          value.year,
          value.month,
          value.day,
          hour,
          minute,
          second,
          value.millisecond,
          value.microsecond,
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

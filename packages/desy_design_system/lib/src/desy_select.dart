import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Visual density for a [DesySelect] field.
enum DesySelectSize {
  /// Small, toolbar-friendly field height.
  sm,

  /// Standard form-control field height.
  md,

  /// Large field height for spacious forms.
  lg,
}

/// Desy's typed single-selection control.
///
/// The public API deliberately covers the controlled rich select used by the
/// workbench. More specialised search and popover behaviour remains an
/// implementation concern until Desy has a product-level reason to expose it.
class DesySelect<T> extends StatelessWidget {
  /// Creates a select whose options are provided as rich Desy items.
  const DesySelect.rich({
    super.key,
    required this.control,
    required this.format,
    required this.children,
    this.label,
    this.description,
    this.enabled = true,
    this.size = DesySelectSize.md,
  });

  /// State ownership for this select.
  final DesySelectControl<T> control;

  /// Formats the selected value for the closed field.
  final String Function(T value) format;

  /// Selectable options in display order.
  final List<DesySelectItem<T>> children;

  /// Optional field label.
  final Widget? label;

  /// Optional supporting text below the label.
  final Widget? description;

  /// Whether the control accepts interaction.
  final bool enabled;

  /// The field's visual density.
  final DesySelectSize size;

  @override
  Widget build(BuildContext context) => FSelect<T>.rich(
    control: control._toForui(),
    format: format,
    label: label,
    description: description,
    enabled: enabled,
    size: switch (size) {
      DesySelectSize.sm => FTextFieldSizeVariant.sm,
      DesySelectSize.md => FTextFieldSizeVariant.md,
      DesySelectSize.lg => FTextFieldSizeVariant.lg,
    },
    children: [for (final item in children) item._toForui()],
  );
}

/// State ownership for a [DesySelect].
class DesySelectControl<T> {
  const DesySelectControl._(this._value, this._onChange);

  /// Creates a select controlled by lifted application state.
  const DesySelectControl.lifted({
    required T? value,
    required ValueChanged<T?> onChange,
  }) : this._(value, onChange);

  final T? _value;
  final ValueChanged<T?> _onChange;

  FSelectControl<T> _toForui() =>
      FSelectControl<T>.lifted(value: _value, onChange: _onChange);
}

/// One option in a [DesySelect].
class DesySelectItem<T> {
  /// Creates a conventional option with a title and optional supporting UI.
  const DesySelectItem.item({
    this.key,
    required this.value,
    required this.title,
    this.subtitle,
    this.prefix,
    this.enabled,
  });

  /// Stable identity for the option widget.
  final Key? key;

  /// The value committed when this option is selected.
  final T value;

  /// Main option label.
  final Widget title;

  /// Optional supporting text.
  final Widget? subtitle;

  /// Optional leading visual.
  final Widget? prefix;

  /// Whether this option can be selected.
  final bool? enabled;

  FSelectItem<T> _toForui() => FSelectItem<T>.item(
    key: key,
    value: value,
    title: title,
    subtitle: subtitle,
    prefix: prefix,
    enabled: enabled,
  );
}

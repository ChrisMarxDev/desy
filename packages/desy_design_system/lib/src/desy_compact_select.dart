import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import 'desy_button.dart';
import 'desy_icons.dart';

/// A compact, borderless selector for toolbar-level choices.
///
/// The trigger deliberately reads as a labelled action instead of a form
/// field. Options remain in a Forui-managed popover so keyboard focus and
/// dismissal behaviour stay consistent with the rest of Desy's chrome.
class DesyCompactSelect<T> extends StatefulWidget {
  /// Creates a compact selector for a small set of toolbar choices.
  const DesyCompactSelect({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.format,
    required this.semanticsLabel,
    this.icon = DesyIcons.palette,
    this.size = DesyButtonSize.sm,
  });

  /// The currently selected value.
  final T value;

  /// Available values in display order.
  final List<DesyCompactSelectItem<T>> items;

  /// Called after the user picks an item.
  final ValueChanged<T> onChanged;

  /// Produces the concise label in the trigger and option list.
  final String Function(T value) format;

  /// Accessible name for the trigger.
  final String semanticsLabel;

  /// Leading icon that identifies the kind of selection.
  final IconData icon;

  /// The density of the toolbar trigger.
  final DesyButtonSize size;

  @override
  State<DesyCompactSelect<T>> createState() => _DesyCompactSelectState<T>();
}

class _DesyCompactSelectState<T> extends State<DesyCompactSelect<T>>
    with SingleTickerProviderStateMixin {
  late final FPopoverController _popover = FPopoverController(vsync: this);

  @override
  void dispose() {
    _popover.dispose();
    super.dispose();
  }

  Future<void> _select(T value) async {
    widget.onChanged(value);
    await _popover.hide();
  }

  @override
  Widget build(BuildContext context) => FPopover(
    control: FPopoverControl.managed(controller: _popover),
    popoverAnchor: Alignment.topLeft,
    childAnchor: Alignment.bottomLeft,
    semanticsLabel: widget.semanticsLabel,
    popoverBuilder: (context, _) => SizedBox(
      width: 188,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item in widget.items)
              DesyButton(
                key: item.key,
                variant: item.value == widget.value
                    ? DesyButtonVariant.secondary
                    : DesyButtonVariant.ghost,
                size: widget.size,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                onPress: () => _select(item.value),
                prefix: item.value == widget.value
                    ? const Icon(DesyIcons.check, size: 14)
                    : const SizedBox(width: 14),
                child: Text(widget.format(item.value)),
              ),
          ],
        ),
      ),
    ),
    builder: (context, controller, _) => DesyButton(
      variant: DesyButtonVariant.ghost,
      size: widget.size,
      mainAxisSize: MainAxisSize.min,
      onPress: controller.toggle,
      semanticsLabel: widget.semanticsLabel,
      semanticsTooltip: widget.semanticsLabel,
      prefix: Icon(widget.icon, size: 15),
      suffix: const Icon(DesyIcons.chevronDown, size: 14),
      child: Text(widget.format(widget.value)),
    ),
  );
}

/// One selectable value in [DesyCompactSelect].
class DesyCompactSelectItem<T> {
  /// Creates one compact-selector option.
  const DesyCompactSelectItem({required this.value, this.key});

  /// Value committed when this option is selected.
  final T value;

  /// Stable identity for the option's button.
  final Key? key;
}

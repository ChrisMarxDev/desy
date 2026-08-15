import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import 'desy_button.dart';

/// A compact icon trigger that reveals Desy-owned popover content.
///
/// The menu stays deliberately content-agnostic so workbench panels can group
/// a small number of related controls without leaking Forui popover types.
class DesyIconMenu extends StatefulWidget {
  /// Creates an icon-only popover menu.
  const DesyIconMenu({
    super.key,
    required this.icon,
    required this.semanticsLabel,
    required this.menuBuilder,
    this.size = DesyButtonSize.sm,
    this.variant = DesyButtonVariant.ghost,
  });

  /// Icon shown in the compact trigger.
  final IconData icon;

  /// Accessible name and tooltip for the trigger.
  final String semanticsLabel;

  /// Builds the popover's Desy-owned content.
  final WidgetBuilder menuBuilder;

  /// Trigger density.
  final DesyButtonSize size;

  /// Trigger emphasis.
  final DesyButtonVariant variant;

  @override
  State<DesyIconMenu> createState() => _DesyIconMenuState();
}

class _DesyIconMenuState extends State<DesyIconMenu>
    with SingleTickerProviderStateMixin {
  late final FPopoverController _popover = FPopoverController(vsync: this);

  @override
  void dispose() {
    _popover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FPopover(
    control: FPopoverControl.managed(controller: _popover),
    popoverAnchor: Alignment.topRight,
    childAnchor: Alignment.bottomRight,
    semanticsLabel: widget.semanticsLabel,
    popoverBuilder: (context, _) => widget.menuBuilder(context),
    builder: (context, controller, _) => DesyButton.icon(
      onPress: controller.toggle,
      variant: widget.variant,
      size: widget.size,
      semanticsLabel: widget.semanticsLabel,
      semanticsTooltip: widget.semanticsLabel,
      child: Icon(widget.icon, size: 16),
    ),
  );
}

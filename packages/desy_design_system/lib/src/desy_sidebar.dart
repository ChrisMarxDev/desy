import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import 'desy_icons.dart';

/// A named, non-interactive group of related sidebar items.
///
/// A section may expose one small section-level action, such as switching a
/// component browser between its file tree and preview grid. The section name
/// itself never navigates or expands.
class DesySidebarSection extends StatelessWidget {
  /// Creates a sidebar section.
  const DesySidebarSection({
    super.key,
    required this.label,
    required this.children,
    this.count,
    this.action,
    this.actionSemanticsLabel,
    this.onActionPress,
  });

  /// The concise section name shown above its items.
  final String label;

  /// Optional inventory count shown with lower emphasis after [label].
  final int? count;

  /// A small icon describing the section-level setting.
  final Widget? action;

  /// The accessible name of [action].
  final String? actionSemanticsLabel;

  /// Changes the section-level setting without making the label interactive.
  final VoidCallback? onActionPress;

  /// The items belonging to this section.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => FSidebarGroup(
    style: const FSidebarGroupStyleDelta.delta(
      padding: EdgeInsetsDelta.value(EdgeInsets.symmetric(vertical: 6)),
      headerPadding: EdgeInsetsGeometryDelta.value(
        EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      childrenSpacing: 2,
      childrenPadding: EdgeInsetsGeometryDelta.value(EdgeInsets.zero),
      itemStyle: FSidebarItemStyleDelta.delta(
        iconSpacing: 8,
        collapsibleIconSpacing: 8,
        childrenSpacing: 2,
        childrenPadding: EdgeInsetsGeometryDelta.value(
          EdgeInsets.only(left: 14),
        ),
        padding: EdgeInsetsGeometryDelta.value(
          EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
      ),
    ),
    label: Semantics(
      header: true,
      child: Row(
        children: [
          Text(label),
          if (count case final value?) ...[
            const SizedBox(width: 7),
            Text(
              '$value',
              style: TextStyle(color: context.theme.colors.mutedForeground),
            ),
          ],
        ],
      ),
    ),
    action: action == null
        ? null
        : Semantics(
            button: true,
            label: actionSemanticsLabel,
            excludeSemantics: actionSemanticsLabel != null,
            child: action!,
          ),
    onActionPress: onActionPress,
    children: children,
  );
}

/// A compact icon-and-label row inside a [DesySidebarSection].
///
/// Use [DesySidebarItem.screen] for a workspace destination that replaces the
/// current workbench screen. Its trailing arrow communicates that stronger
/// navigation. Ordinary items have no trailing affordance. [children] is
/// reserved for file-browser hierarchies such as the Components section.
class DesySidebarItem extends StatelessWidget {
  /// Creates an ordinary item or a node in a file-browser hierarchy.
  const DesySidebarItem({
    super.key,
    this.style = const FSidebarItemStyleDelta.context(),
    this.icon,
    this.label,
    this.selected = false,
    this.initiallyExpanded = false,
    this.autofocus = false,
    this.focusNode,
    this.onPress,
    this.onLongPress,
    this.children = const [],
  }) : opensScreen = false;

  /// Creates a workspace item that navigates to a separate screen.
  const DesySidebarItem.screen({
    super.key,
    this.style = const FSidebarItemStyleDelta.context(),
    this.icon,
    this.label,
    this.selected = false,
    this.autofocus = false,
    this.focusNode,
    this.onPress,
    this.onLongPress,
  }) : opensScreen = true,
       initiallyExpanded = false,
       children = const [];

  /// Scoped style changes for the underlying Forui item.
  final FSidebarItemStyleDelta style;

  /// The leading icon.
  final Widget? icon;

  /// The item label.
  final Widget? label;

  /// Whether this item represents the active destination.
  final bool selected;

  /// Whether a file-browser node starts expanded.
  final bool initiallyExpanded;

  /// Whether this item receives focus when first mounted.
  final bool autofocus;

  /// An optional externally managed focus node.
  final FocusNode? focusNode;

  /// Called when the row is pressed.
  final VoidCallback? onPress;

  /// Called when the row is long pressed.
  final VoidCallback? onLongPress;

  /// Nested file-browser items.
  final List<Widget> children;

  /// Whether the row carries the trailing new-screen arrow.
  final bool opensScreen;

  @override
  Widget build(BuildContext context) => FSidebarItem(
    style: style,
    icon: icon,
    label: opensScreen && label != null
        ? Row(
            children: [
              Expanded(child: label!),
              const SizedBox(width: 8),
              const ExcludeSemantics(
                child: Icon(DesyIcons.chevronRight, size: 14),
              ),
            ],
          )
        : label,
    selected: selected,
    initiallyExpanded: initiallyExpanded,
    autofocus: autofocus,
    focusNode: focusNode,
    onPress: onPress,
    onLongPress: onLongPress,
    children: children,
  );
}

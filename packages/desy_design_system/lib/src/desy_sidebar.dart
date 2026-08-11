import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import 'desy_icons.dart';
import 'desy_visual_tokens.dart';

/// Desy's persistent registry navigation surface.
///
/// Callers configure layout with Flutter primitives only. Forui remains the
/// internal focus and scrolling implementation, so Desy's public workbench
/// surface does not expose an `F*` style contract.
class DesySidebar extends StatelessWidget {
  /// Creates a registry navigation surface with optional sticky regions.
  const DesySidebar({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.constraints,
    this.headerPadding,
    this.contentPadding,
    this.footerPadding,
    this.autofocus = false,
    this.focusNode,
    this.traversalEdgeBehavior,
  });

  /// The optional sticky header above the registry tree.
  final Widget? header;

  /// The scrollable registry content.
  final List<Widget> children;

  /// The optional sticky footer, typically live sessions.
  final Widget? footer;

  /// Optional surface dimensions supplied by the surrounding shell.
  final BoxConstraints? constraints;

  /// Padding around [header].
  final EdgeInsetsGeometry? headerPadding;

  /// Padding around [children].
  final EdgeInsetsGeometry? contentPadding;

  /// Padding around [footer].
  final EdgeInsetsGeometry? footerPadding;

  /// Whether this sidebar receives focus when mounted.
  final bool autofocus;

  /// Optional focus ownership for keyboard traversal.
  final FocusScopeNode? focusNode;

  /// Controls keyboard traversal at the first and final registry items.
  final TraversalEdgeBehavior? traversalEdgeBehavior;

  @override
  Widget build(BuildContext context) => FSidebar(
    header: header,
    footer: footer,
    autofocus: autofocus,
    focusNode: focusNode,
    traversalEdgeBehavior: traversalEdgeBehavior,
    style: FSidebarStyleDelta.delta(
      constraints: constraints,
      headerPadding: headerPadding == null
          ? null
          : EdgeInsetsGeometryDelta.value(headerPadding!),
      contentPadding: contentPadding == null
          ? null
          : EdgeInsetsGeometryDelta.value(contentPadding!),
      footerPadding: footerPadding == null
          ? null
          : EdgeInsetsGeometryDelta.value(footerPadding!),
    ),
    children: children,
  );
}

/// A named group of related sidebar items.
///
/// A section may expose one small section-level action, such as switching a
/// component browser between its file tree and preview grid. Labels are
/// non-interactive by default; [onLabelPress] is reserved for a label that is
/// also a meaningful root destination, such as opening the component Atlas.
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
    this.onLabelPress,
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

  /// Opens the root destination represented by [label].
  ///
  /// Leave this null for ordinary organizational section labels.
  final VoidCallback? onLabelPress;

  /// The items belonging to this section.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const styleDelta = FSidebarGroupStyleDelta.delta(
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
    );
    final baseStyle =
        FSidebarData.maybeOf(context)?.style.groupStyle ??
        context.theme.sidebarStyle.groupStyle;
    final style = styleDelta(baseStyle);
    final labelContent = Row(
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
    );

    return FSidebarGroup(
      style: styleDelta,
      label: Semantics(
        key: onLabelPress == null
            ? null
            : ValueKey('sidebar-section-label-$label'),
        container: onLabelPress != null,
        header: true,
        button: onLabelPress != null,
        label: onLabelPress == null ? null : label,
        excludeSemantics: onLabelPress != null,
        onTap: onLabelPress,
        child: onLabelPress == null
            ? labelContent
            : FTappable(
                style: style.tappableStyle,
                focusedOutlineStyle: style.focusedOutlineStyle,
                onPress: onLabelPress,
                child: labelContent,
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
  Widget build(BuildContext context) => Stack(
    children: [
      FSidebarItem(
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
      ),
      if (selected)
        Positioned.directional(
          textDirection: Directionality.of(context),
          start: 0,
          top: 4,
          bottom: 4,
          child: ExcludeSemantics(
            child: DecoratedBox(
              key: const ValueKey('desy-sidebar-selection-indicator'),
              decoration: BoxDecoration(
                color: context.theme.colors.desy.signal,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const SizedBox(width: 2),
            ),
          ),
        ),
    ],
  );
}

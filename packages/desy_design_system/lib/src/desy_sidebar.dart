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
/// A section may expose one small section-level action. Labels are
/// non-interactive by default; [onLabelPress] is reserved for a label that is
/// also a meaningful root destination, such as opening the component Atlas.
/// A collapsible section gives disclosure its own trailing control so those
/// existing label and action behaviors remain independent.
class DesySidebarSection extends StatefulWidget {
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
    this.collapsible = false,
    this.initiallyExpanded = true,
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

  /// Whether the section exposes a leading expand/collapse control.
  final bool collapsible;

  /// Whether a collapsible section starts expanded.
  final bool initiallyExpanded;

  /// The items belonging to this section.
  final List<Widget> children;

  @override
  State<DesySidebarSection> createState() => _DesySidebarSectionState();
}

class _DesySidebarSectionState extends State<DesySidebarSection> {
  late bool _expanded = widget.initiallyExpanded;

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

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
        Text(widget.label),
        if (widget.count case final value?) ...[
          const SizedBox(width: 7),
          Text(
            '$value',
            style: TextStyle(color: context.theme.colors.mutedForeground),
          ),
        ],
      ],
    );
    final label = Semantics(
      key: ValueKey('sidebar-section-label-${widget.label}'),
      container: widget.onLabelPress != null,
      header: true,
      button: widget.onLabelPress != null,
      label: widget.onLabelPress == null ? null : widget.label,
      excludeSemantics: widget.onLabelPress != null,
      onTap: widget.onLabelPress,
      child: widget.onLabelPress == null
          ? labelContent
          : MouseRegion(
              cursor: SystemMouseCursors.click,
              child: FTappable(
                style: style.tappableStyle,
                focusedOutlineStyle: style.focusedOutlineStyle,
                onPress: widget.onLabelPress,
                child: labelContent,
              ),
            ),
    );
    final disclosure = Semantics(
      key: ValueKey('sidebar-section-toggle-${widget.label}'),
      container: true,
      button: true,
      expanded: _expanded,
      label: '${_expanded ? 'Collapse' : 'Expand'} ${widget.label}',
      excludeSemantics: true,
      onTap: _toggleExpanded,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: FTappable(
          style: style.tappableStyle,
          focusedOutlineStyle: style.focusedOutlineStyle,
          onPress: _toggleExpanded,
          builder: (_, variants, child) => IconTheme(
            data: style.actionStyle.resolve(variants),
            child: child!,
          ),
          child: SizedBox.square(
            dimension: 20,
            child: Icon(
              _expanded ? DesyIcons.chevronDown : DesyIcons.chevronRight,
              size: 14,
            ),
          ),
        ),
      ),
    );
    final sectionLabel = widget.collapsible
        ? Row(
            children: [
              Expanded(child: label),
              const SizedBox(width: 4),
              disclosure,
            ],
          )
        : label;
    final sectionChildren = widget.collapsible
        ? [
            Offstage(
              key: ValueKey('sidebar-section-body-${widget.label}'),
              offstage: !_expanded,
              child: Column(
                spacing: style.childrenSpacing,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.children,
              ),
            ),
          ]
        : widget.children;

    return FSidebarGroup(
      style: styleDelta,
      label: sectionLabel,
      action: widget.action == null
          ? null
          : Semantics(
              button: true,
              label: widget.actionSemanticsLabel,
              excludeSemantics: widget.actionSemanticsLabel != null,
              child: widget.action!,
            ),
      onActionPress: widget.onActionPress,
      children: sectionChildren,
    );
  }
}

/// A compact icon-and-label row inside a [DesySidebarSection].
///
/// Use [DesySidebarItem.screen] for a workspace destination that replaces the
/// current workbench screen. Its trailing arrow communicates that stronger
/// navigation. Use [DesySidebarItem.folder] for a file-browser node: its row
/// opens the folder destination while its separate trailing disclosure controls
/// expansion. Ordinary items have no trailing affordance.
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
    this.disclosureLabel,
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
       children = const [],
       disclosureLabel = null;

  /// Creates a file-browser folder with separate navigation and disclosure
  /// controls.
  const DesySidebarItem.folder({
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
    this.disclosureLabel,
    required this.children,
  }) : opensScreen = false;

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

  /// Name used by the separate folder disclosure control.
  final String? disclosureLabel;

  /// Whether the row carries the trailing new-screen arrow.
  final bool opensScreen;

  @override
  Widget build(BuildContext context) => children.isEmpty
      ? _DesySidebarLeafItem(
          style: style,
          icon: icon,
          label: label,
          selected: selected,
          autofocus: autofocus,
          focusNode: focusNode,
          onPress: onPress,
          onLongPress: onLongPress,
          opensScreen: opensScreen,
        )
      : _DesySidebarFolderItem(
          style: style,
          icon: icon,
          label: label,
          selected: selected,
          initiallyExpanded: initiallyExpanded,
          autofocus: autofocus,
          focusNode: focusNode,
          onPress: onPress,
          onLongPress: onLongPress,
          disclosureLabel: disclosureLabel,
          children: children,
        );
}

class _DesySidebarLeafItem extends StatelessWidget {
  const _DesySidebarLeafItem({
    required this.style,
    required this.icon,
    required this.label,
    required this.selected,
    required this.autofocus,
    required this.focusNode,
    required this.onPress,
    required this.onLongPress,
    required this.opensScreen,
  });

  final FSidebarItemStyleDelta style;
  final Widget? icon;
  final Widget? label;
  final bool selected;
  final bool autofocus;
  final FocusNode? focusNode;
  final VoidCallback? onPress;
  final VoidCallback? onLongPress;
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
        autofocus: autofocus,
        focusNode: focusNode,
        onPress: onPress,
        onLongPress: onLongPress,
      ),
      if (selected) const _DesySidebarSelectionIndicator(),
    ],
  );
}

class _DesySidebarFolderItem extends StatefulWidget {
  const _DesySidebarFolderItem({
    required this.style,
    required this.icon,
    required this.label,
    required this.selected,
    required this.initiallyExpanded,
    required this.autofocus,
    required this.focusNode,
    required this.onPress,
    required this.onLongPress,
    required this.disclosureLabel,
    required this.children,
  });

  final FSidebarItemStyleDelta style;
  final Widget? icon;
  final Widget? label;
  final bool selected;
  final bool initiallyExpanded;
  final bool autofocus;
  final FocusNode? focusNode;
  final VoidCallback? onPress;
  final VoidCallback? onLongPress;
  final String? disclosureLabel;
  final List<Widget> children;

  @override
  State<_DesySidebarFolderItem> createState() => _DesySidebarFolderItemState();
}

class _DesySidebarFolderItemState extends State<_DesySidebarFolderItem>
    with TickerProviderStateMixin {
  FSidebarItemStyle? _style;
  CurvedAnimation? _reveal;
  CurvedAnimation? _fade;
  CurvedAnimation? _iconReveal;
  Animation<double>? _iconRotation;
  AnimationController? _controller;
  AnimationController? _fadeController;
  late bool _expanded = widget.initiallyExpanded;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateStyle();
  }

  @override
  void didUpdateWidget(covariant _DesySidebarFolderItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateStyle();
  }

  void _updateStyle() {
    final style = widget.style(
      FSidebarGroupData.maybeOf(context)?.style.itemStyle ??
          FSidebarData.maybeOf(context)?.style.groupStyle.itemStyle ??
          context.theme.sidebarStyle.groupStyle.itemStyle,
    );
    if (_style == style) return;
    _style = style;
    _reveal?.dispose();
    _fade?.dispose();
    _iconReveal?.dispose();
    _controller?.dispose();
    _fadeController?.dispose();
    final motion = context.accessibility.motion;
    final reduceMotion = motion != FAccessibilityMotion.all;
    final disableMotion = motion == FAccessibilityMotion.disabled;
    _controller = AnimationController(
      vsync: this,
      value: _expanded ? 1 : 0,
      duration: reduceMotion ? Duration.zero : style.motion.expandDuration,
      reverseDuration: reduceMotion
          ? Duration.zero
          : style.motion.collapseDuration,
    );
    _fadeController = AnimationController(
      vsync: this,
      value: _expanded ? 1 : 0,
      duration: disableMotion ? Duration.zero : style.motion.expandDuration,
      reverseDuration: disableMotion
          ? Duration.zero
          : style.motion.collapseDuration,
    );
    _reveal = CurvedAnimation(
      parent: _controller!,
      curve: style.motion.expandCurve,
      reverseCurve: style.motion.collapseCurve,
    );
    _fade = CurvedAnimation(
      parent: _fadeController!,
      curve: Curves.easeIn,
      reverseCurve: Curves.easeOut,
    );
    _iconReveal = CurvedAnimation(
      parent: _controller!,
      curve: style.motion.iconExpandCurve,
      reverseCurve: style.motion.iconCollapseCurve,
    );
    _iconRotation = style.motion.iconTween.animate(_iconReveal!);
  }

  void _toggleExpanded() {
    _setExpanded(!_expanded);
  }

  void _activateFolder() {
    if (!_expanded) _setExpanded(true);
    widget.onPress?.call();
  }

  void _setExpanded(bool expanded) {
    if (_expanded == expanded) return;
    if (expanded) {
      _controller!.forward();
      _fadeController!.forward();
    } else {
      _controller!.reverse();
      _fadeController!.reverse();
    }
    setState(() => _expanded = expanded);
  }

  @override
  void dispose() {
    _reveal?.dispose();
    _fade?.dispose();
    _iconReveal?.dispose();
    _controller?.dispose();
    _fadeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _style!;
    final name = widget.disclosureLabel ?? 'folder';
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FTappable(
              style: style.tappableStyle,
              focusedOutlineStyle: style.focusedOutlineStyle,
              selected: widget.selected,
              autofocus: widget.autofocus,
              focusNode: widget.focusNode,
              onPress: _activateFolder,
              onLongPress: widget.onLongPress,
              builder: (context, variants, _) => Container(
                key: ValueKey('desy-sidebar-folder-row-$name'),
                padding: style.padding,
                decoration: ShapeDecoration(
                  shape: RoundedSuperellipseBorder(
                    borderRadius: style.borderRadius,
                  ),
                  color: style.backgroundColor.resolve(variants),
                ),
                child: Row(
                  spacing: style.collapsibleIconSpacing,
                  children: [
                    Expanded(
                      child: Row(
                        spacing: style.iconSpacing,
                        children: [
                          if (widget.icon != null)
                            IconTheme(
                              data: style.iconStyle.resolve(variants),
                              child: widget.icon!,
                            ),
                          if (widget.label != null)
                            Expanded(
                              child: DefaultTextStyle.merge(
                                style: style.textStyle.resolve(variants),
                                child: widget.label!,
                              ),
                            ),
                        ],
                      ),
                    ),
                    FTappable(
                      key: ValueKey('desy-sidebar-folder-toggle-$name'),
                      style: style.tappableStyle,
                      focusedOutlineStyle: style.focusedOutlineStyle,
                      semanticsLabel:
                          '${_expanded ? 'Collapse' : 'Expand'} $name',
                      semanticsButton: true,
                      semanticsExpanded: _expanded,
                      excludeSemantics: true,
                      onPress: _toggleExpanded,
                      builder: (_, variants, child) => IconTheme(
                        data: style.collapsibleIconStyle.resolve(variants),
                        child: child!,
                      ),
                      child: SizedBox.square(
                        dimension: 20,
                        child: RotationTransition(
                          turns: _iconRotation!,
                          child: style.collapsibleIcon(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              child: const SizedBox.shrink(),
            ),
            AnimatedBuilder(
              animation: _reveal!,
              builder: (_, _) => FCollapsible(
                key: ValueKey('desy-sidebar-folder-children-$name'),
                value: _reveal!.value,
                child: Padding(
                  padding: style.childrenPadding,
                  child: FadeTransition(
                    opacity: _fade!,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: style.childrenSpacing,
                      children: widget.children,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (widget.selected) const _DesySidebarSelectionIndicator(),
      ],
    );
  }
}

class _DesySidebarSelectionIndicator extends StatelessWidget {
  const _DesySidebarSelectionIndicator();

  @override
  Widget build(BuildContext context) => Positioned.directional(
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
  );
}

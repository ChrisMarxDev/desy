import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// The semantic emphasis of a Desy action.
///
/// This is deliberately owned by Desy. Forui's variant model remains an
/// implementation detail and can change without affecting workbench callers.
enum DesyButtonVariant {
  /// The single strongest action in the current region.
  primary,

  /// A lower-emphasis filled action.
  secondary,

  /// An irreversible or dangerous action.
  destructive,

  /// A bordered action on a structural surface.
  outline,

  /// A quiet action that becomes visible through interaction.
  ghost,
}

/// Desy's compact desktop control sizes.
enum DesyButtonSize {
  /// A dense inline action.
  xs,

  /// A compact toolbar action.
  sm,

  /// The default form and panel action.
  md,

  /// A prominent call to action.
  lg,
}

/// Desy's keyboard-operable action control.
///
/// The public contract contains only Flutter and Desy types. Forui currently
/// supplies the focus, hover, semantics, and press implementation underneath.
class DesyButton extends StatelessWidget {
  /// Creates a labelled action with optional leading and trailing content.
  const DesyButton({
    super.key,
    required this.onPress,
    required this.child,
    this.variant = DesyButtonVariant.primary,
    this.size = DesyButtonSize.md,
    this.onDisabledPress,
    this.onLongPress,
    this.onDoubleTap,
    this.onSecondaryPress,
    this.onSecondaryLongPress,
    this.semanticsLabel,
    this.semanticsTooltip,
    this.autofocus = false,
    this.focusNode,
    this.onFocusChange,
    this.onHoverChange,
    this.selected = false,
    this.shortcuts,
    this.actions,
    this.mainAxisSize = MainAxisSize.max,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textBaseline,
    this.prefix,
    this.suffix,
  }) : _iconOnly = false;

  /// Creates a square action containing only an icon.
  const DesyButton.icon({
    super.key,
    required this.onPress,
    required this.child,
    this.variant = DesyButtonVariant.outline,
    this.size = DesyButtonSize.md,
    this.onDisabledPress,
    this.onLongPress,
    this.onDoubleTap,
    this.onSecondaryPress,
    this.onSecondaryLongPress,
    this.semanticsLabel,
    this.semanticsTooltip,
    this.autofocus = false,
    this.focusNode,
    this.onFocusChange,
    this.onHoverChange,
    this.selected = false,
    this.shortcuts,
    this.actions,
  }) : _iconOnly = true,
       mainAxisSize = MainAxisSize.min,
       mainAxisAlignment = MainAxisAlignment.center,
       crossAxisAlignment = CrossAxisAlignment.center,
       textBaseline = null,
       prefix = null,
       suffix = null;

  /// Called when the enabled action is activated.
  final VoidCallback? onPress;

  /// Called when a disabled action is activated.
  final VoidCallback? onDisabledPress;

  /// Called after a primary long press.
  final VoidCallback? onLongPress;

  /// Called after a primary double tap.
  final VoidCallback? onDoubleTap;

  /// Called after a secondary press.
  final VoidCallback? onSecondaryPress;

  /// Called after a secondary long press.
  final VoidCallback? onSecondaryLongPress;

  /// An explicit accessible name for the action.
  final String? semanticsLabel;

  /// An accessible tooltip associated with the action.
  final String? semanticsTooltip;

  /// Whether the action requests focus when mounted.
  final bool autofocus;

  /// Optional externally owned keyboard focus.
  final FocusNode? focusNode;

  /// Reports keyboard-focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Reports pointer-hover changes.
  final ValueChanged<bool>? onHoverChange;

  /// Whether the action represents the active choice.
  final bool selected;

  /// Keyboard shortcuts scoped to this action.
  final Map<ShortcutActivator, Intent>? shortcuts;

  /// Actions invoked by [shortcuts].
  final Map<Type, Action<Intent>>? actions;

  /// The action's semantic emphasis.
  final DesyButtonVariant variant;

  /// The action's density.
  final DesyButtonSize size;

  /// The main action content.
  final Widget child;

  /// Optional content before [child].
  final Widget? prefix;

  /// Optional content after [child].
  final Widget? suffix;

  /// How much horizontal space labelled content occupies.
  final MainAxisSize mainAxisSize;

  /// How labelled content is aligned horizontally.
  final MainAxisAlignment mainAxisAlignment;

  /// How labelled content is aligned vertically.
  final CrossAxisAlignment crossAxisAlignment;

  /// The baseline used when [crossAxisAlignment] requests one.
  final TextBaseline? textBaseline;

  final bool _iconOnly;

  @override
  Widget build(BuildContext context) {
    final foruiVariant = switch (variant) {
      DesyButtonVariant.primary => FButtonVariant.primary,
      DesyButtonVariant.secondary => FButtonVariant.secondary,
      DesyButtonVariant.destructive => FButtonVariant.destructive,
      DesyButtonVariant.outline => FButtonVariant.outline,
      DesyButtonVariant.ghost => FButtonVariant.ghost,
    };
    final foruiSize = switch (size) {
      DesyButtonSize.xs => FButtonSizeVariant.xs,
      DesyButtonSize.sm => FButtonSizeVariant.sm,
      DesyButtonSize.md => FButtonSizeVariant.md,
      DesyButtonSize.lg => FButtonSizeVariant.lg,
    };

    if (_iconOnly) {
      return FButton.icon(
        onPress: onPress,
        variant: foruiVariant,
        size: foruiSize,
        onDisabledPress: onDisabledPress,
        onLongPress: onLongPress,
        onDoubleTap: onDoubleTap,
        onSecondaryPress: onSecondaryPress,
        onSecondaryLongPress: onSecondaryLongPress,
        semanticsLabel: semanticsLabel,
        semanticsTooltip: semanticsTooltip,
        autofocus: autofocus,
        focusNode: focusNode,
        onFocusChange: onFocusChange,
        onHoverChange: onHoverChange,
        selected: selected,
        shortcuts: shortcuts,
        actions: actions,
        child: child,
      );
    }

    return FButton(
      onPress: onPress,
      variant: foruiVariant,
      size: foruiSize,
      onDisabledPress: onDisabledPress,
      onLongPress: onLongPress,
      onDoubleTap: onDoubleTap,
      onSecondaryPress: onSecondaryPress,
      onSecondaryLongPress: onSecondaryLongPress,
      semanticsLabel: semanticsLabel,
      semanticsTooltip: semanticsTooltip,
      autofocus: autofocus,
      focusNode: focusNode,
      onFocusChange: onFocusChange,
      onHoverChange: onHoverChange,
      selected: selected,
      shortcuts: shortcuts,
      actions: actions,
      mainAxisSize: mainAxisSize,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      textBaseline: textBaseline,
      prefix: prefix,
      suffix: suffix,
      child: child,
    );
  }
}

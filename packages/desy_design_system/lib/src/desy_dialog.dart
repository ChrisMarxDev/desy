import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Desy's modal content surface.
class DesyDialog extends StatelessWidget {
  /// Creates a dialog body controlled by a Desy-owned animation contract.
  const DesyDialog({
    super.key,
    required this.builder,
    this.animation,
    this.semanticsLabel,
    this.constraints,
  });

  /// Dialog transition exposed without leaking a Forui style object.
  final Animation<double>? animation;

  /// Builds the dialog content.
  final Widget Function(BuildContext context, DesyDialogContentStyle style)
  builder;

  /// Optional semantic label for the modal surface.
  final String? semanticsLabel;

  /// Optional modal size constraints.
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = DesyDialogContentStyle(
      titleTextStyle: textTheme.titleLarge ?? const TextStyle(fontSize: 20),
      bodyTextStyle: textTheme.bodyMedium ?? const TextStyle(fontSize: 14),
    );
    return FDialog(
      animation: animation ?? kAlwaysCompleteAnimation,
      semanticsLabel: semanticsLabel,
      constraints: constraints ?? const BoxConstraints(),
      builder: (context, _) => builder(context, style),
    );
  }
}

/// Typography supplied to a [DesyDialog] body.
class DesyDialogContentStyle {
  /// Creates Desy's dialog typography values.
  const DesyDialogContentStyle({
    required this.titleTextStyle,
    required this.bodyTextStyle,
  });

  /// Heading style for the modal's title.
  final TextStyle titleTextStyle;

  /// Supporting copy style for the modal body.
  final TextStyle bodyTextStyle;
}

/// Shows a Desy modal using the current app's dialog transition.
Future<T?> showDesyDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext context, Animation<double> animation)
  builder,
  bool useRootNavigator = false,
  bool barrierDismissible = true,
  String? barrierLabel,
}) => showFDialog<T>(
  context: context,
  builder: (context, _, animation) => builder(context, animation),
  useRootNavigator: useRootNavigator,
  barrierDismissible: barrierDismissible,
  barrierLabel: barrierLabel,
);

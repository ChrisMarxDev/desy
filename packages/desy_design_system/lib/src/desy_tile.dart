import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Desy's selectable row surface for inspector and navigation lists.
class DesyTile extends StatelessWidget {
  /// Creates one interactive Desy row.
  const DesyTile({
    super.key,
    required this.title,
    this.prefix,
    this.subtitle,
    this.suffix,
    this.onPress,
    this.selected = false,
  });

  /// Leading visual.
  final Widget? prefix;

  /// Primary row content.
  final Widget title;

  /// Optional supporting content.
  final Widget? subtitle;

  /// Optional trailing visual.
  final Widget? suffix;

  /// Row action, or null for an informational row.
  final VoidCallback? onPress;

  /// Whether the row represents the current selection.
  final bool selected;

  @override
  Widget build(BuildContext context) => FTile(
    prefix: prefix,
    title: title,
    subtitle: subtitle,
    suffix: suffix,
    onPress: onPress,
    selected: selected,
  );
}

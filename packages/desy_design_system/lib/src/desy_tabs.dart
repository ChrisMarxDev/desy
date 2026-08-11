import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Desy's tabbed content surface.
class DesyTabs extends StatelessWidget {
  /// Creates a set of labelled content pages.
  const DesyTabs({
    super.key,
    required this.children,
    this.scrollable = false,
    this.expands = false,
  });

  /// Ordered tab pages.
  final List<DesyTabEntry> children;

  /// Whether labels may scroll horizontally.
  final bool scrollable;

  /// Whether the selected page fills its available height.
  final bool expands;

  @override
  Widget build(BuildContext context) => FTabs(
    scrollable: scrollable,
    expands: expands,
    children: [for (final child in children) child._toForui()],
  );
}

/// One Desy tab page.
class DesyTabEntry {
  /// Creates one labelled page.
  const DesyTabEntry({required this.label, required this.child});

  /// Tab selector content.
  final Widget label;

  /// Page body.
  final Widget child;

  FTabEntry _toForui() => FTabEntry(label: label, child: child);
}

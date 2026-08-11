import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Desy's expandable disclosure group.
class DesyAccordion extends StatelessWidget {
  /// Creates a group of independently expandable Desy items.
  const DesyAccordion({super.key, required this.children});

  /// Ordered disclosure items.
  final List<DesyAccordionItem> children;

  @override
  Widget build(BuildContext context) =>
      FAccordion(children: [for (final item in children) item._toForui()]);
}

/// One Desy disclosure item.
class DesyAccordionItem extends StatelessWidget {
  /// Creates one expandable item.
  const DesyAccordionItem({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  /// Always-visible item summary.
  final Widget title;

  /// Content shown when the item is expanded.
  final Widget child;

  /// Whether this item opens on its first build.
  final bool initiallyExpanded;

  FAccordionItem _toForui() => FAccordionItem(
    key: key,
    initiallyExpanded: initiallyExpanded,
    title: title,
    child: child,
  );

  @override
  Widget build(BuildContext context) => _toForui();
}

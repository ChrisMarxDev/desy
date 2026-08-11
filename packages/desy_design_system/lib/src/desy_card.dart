import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// A contained Desy workbench surface.
///
/// Cards group one coherent piece of content. Structural workspace regions use
/// dividers instead of nesting cards around every panel.
class DesyCard extends StatelessWidget {
  /// Creates a Desy-owned contained surface.
  const DesyCard({super.key, this.clipBehavior = Clip.none, this.child});

  /// The clipping applied to content at the card boundary.
  final Clip clipBehavior;

  /// The content contained by the surface.
  final Widget? child;

  @override
  Widget build(BuildContext context) =>
      FCard(clipBehavior: clipBehavior, child: child);
}

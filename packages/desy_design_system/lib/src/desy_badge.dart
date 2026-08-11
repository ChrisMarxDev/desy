import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// The semantic treatment of a compact Desy label.
enum DesyBadgeVariant {
  /// A high-emphasis label.
  primary,

  /// A lower-emphasis filled label.
  secondary,

  /// A bordered label on a structural surface.
  outline,

  /// A destructive or failed status label.
  destructive,
}

/// A compact, non-interactive Desy label.
class DesyBadge extends StatelessWidget {
  /// Creates a semantic metadata or status label.
  const DesyBadge({
    super.key,
    required this.child,
    this.variant = DesyBadgeVariant.primary,
  });

  /// The badge contents.
  final Widget child;

  /// The badge's semantic treatment.
  final DesyBadgeVariant variant;

  @override
  Widget build(BuildContext context) => FBadge(
    variant: switch (variant) {
      DesyBadgeVariant.primary => FBadgeVariant.primary,
      DesyBadgeVariant.secondary => FBadgeVariant.secondary,
      DesyBadgeVariant.outline => FBadgeVariant.outline,
      DesyBadgeVariant.destructive => FBadgeVariant.destructive,
    },
    child: child,
  );
}

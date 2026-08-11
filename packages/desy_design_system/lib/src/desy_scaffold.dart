import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Desy's structural workbench surface.
///
/// This keeps page, header, sidebar, footer, focus, and keyboard-avoidance
/// behavior behind a Desy-owned Flutter contract. Forui currently implements
/// those mechanics internally.
class DesyScaffold extends StatelessWidget {
  /// Creates a structural surface for one Desy workbench region.
  const DesyScaffold({
    super.key,
    required this.child,
    this.header,
    this.sidebar,
    this.footer,
    this.childPad = true,
    this.resizeToAvoidBottomInset = true,
  });

  /// The primary region content.
  final Widget child;

  /// Optional structural header.
  final Widget? header;

  /// Optional structural sidebar.
  final Widget? sidebar;

  /// Optional structural footer.
  final Widget? footer;

  /// Whether the active Desy page padding surrounds [child].
  final bool childPad;

  /// Whether the content adapts to the software keyboard.
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) => FScaffold(
    header: header,
    sidebar: sidebar,
    footer: footer,
    childPad: childPad,
    resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    child: child,
  );
}

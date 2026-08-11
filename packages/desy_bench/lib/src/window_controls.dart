import 'package:flutter/widgets.dart';

/// Optional host-window actions rendered by Desy's Flutter top frame.
///
/// Desktop hosts can connect these callbacks to their window-management
/// package without making the reusable workbench depend on a platform plugin.
@immutable
class DesyWindowControls {
  /// Creates the three standard desktop window actions.
  const DesyWindowControls({
    required this.onClose,
    required this.onMinimize,
    required this.onToggleMaximize,
    this.onSetBackgroundColor,
  });

  /// Closes the host window.
  final VoidCallback onClose;

  /// Minimizes the host window.
  final VoidCallback onMinimize;

  /// Maximizes or restores the host window.
  final VoidCallback onToggleMaximize;

  /// Updates the native window background behind the Flutter surface.
  ///
  /// Hosts may omit this when they cannot control their window bezel.
  final ValueChanged<Color>? onSetBackgroundColor;
}

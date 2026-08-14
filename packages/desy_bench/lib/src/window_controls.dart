import 'package:flutter/widgets.dart';

/// Optional host-window actions rendered by Desy's Flutter top frame.
///
/// Standalone Bench catalogues receive the default platform controls. Embedder
/// apps can supply their own window-management callbacks when needed.
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

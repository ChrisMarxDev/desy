import 'package:flutter/foundation.dart';

import 'mrx_colors.dart';

/// Immutable configuration for the one MRX theme.
@immutable
class MrxThemeData {
  /// Creates the configuration inherited by all MRX widgets.
  const MrxThemeData({
    required this.id,
    required this.name,
    required this.colors,
  });

  /// Stable identifier used by previews and diagnostics.
  final String id;

  /// Human-readable theme name.
  final String name;

  /// Semantic colours inherited by widgets.
  final MrxColors colors;

  /// The single initial MRX theme.
  static const standard = MrxThemeData(
    id: 'mrx.midnight',
    name: 'MRX Midnight',
    colors: MrxPalettes.midnight,
  );
}

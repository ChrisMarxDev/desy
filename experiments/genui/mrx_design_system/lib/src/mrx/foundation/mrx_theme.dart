import 'package:flutter/widgets.dart';

import 'mrx_theme_data.dart';

/// Makes one [MrxThemeData] available to every MRX widget below it.
class MrxTheme extends InheritedWidget {
  /// Wraps [child] in the supplied MRX theme configuration.
  const MrxTheme({
    super.key,
    this.data = MrxThemeData.standard,
    required super.child,
  });

  /// The immutable theme configuration inherited by descendants.
  final MrxThemeData data;

  /// Reads the nearest MRX theme, falling back to the canonical theme in
  /// release builds when a standalone widget is previewed without a wrapper.
  static MrxThemeData of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<MrxTheme>();
    assert(theme != null, 'MRX widgets need an MrxTheme ancestor.');
    return theme?.data ?? MrxThemeData.standard;
  }

  @override
  bool updateShouldNotify(MrxTheme oldWidget) => data != oldWidget.data;
}

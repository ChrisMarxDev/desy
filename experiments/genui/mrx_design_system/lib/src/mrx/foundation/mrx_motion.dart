import 'package:flutter/widgets.dart';

/// Motion timings which honour the platform's reduced-motion preference.
abstract final class MrxMotion {
  /// A quick response for subtle feedback.
  static Duration quick(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 120);

  /// The default duration for component transitions.
  static Duration standard(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 180);
}

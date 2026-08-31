import 'package:flutter/widgets.dart';

/// Semantic colours consumed by MRX widgets.
@immutable
class MrxColors {
  /// Creates a semantic colour set for one MRX theme.
  const MrxColors({
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.text,
    required this.textMuted,
    required this.border,
    required this.accent,
    required this.accentText,
    required this.positive,
    required this.warning,
    required this.negative,
    required this.focusRing,
  });

  /// The page background.
  final Color canvas;

  /// The default component background.
  final Color surface;

  /// A surface layered above the default component background.
  final Color surfaceRaised;

  /// The primary text colour.
  final Color text;

  /// The secondary text colour.
  final Color textMuted;

  /// The low-contrast border used by cards and controls.
  final Color border;

  /// The primary interactive colour.
  final Color accent;

  /// Text and glyphs shown over [accent].
  final Color accentText;

  /// The success state colour.
  final Color positive;

  /// The warning state colour.
  final Color warning;

  /// The destructive state colour.
  final Color negative;

  /// The keyboard focus treatment colour.
  final Color focusRing;
}

/// The colour set for MRX's sole initial theme.
abstract final class MrxPalettes {
  /// A neutral dark colour set that keeps hierarchy in surfaces and borders.
  static const midnight = MrxColors(
    canvas: Color(0xff111111),
    surface: Color(0xff1a1a1a),
    surfaceRaised: Color(0xff242424),
    text: Color(0xfff5f5f5),
    textMuted: Color(0xffa3a3a3),
    border: Color(0x26ffffff),
    accent: Color(0xfff5f5f5),
    accentText: Color(0xff171717),
    positive: Color(0xff4ade80),
    warning: Color(0xfffacc15),
    negative: Color(0xfffb7185),
    focusRing: Color(0xffa3a3a3),
  );
}

import 'package:flutter/widgets.dart';

import 'mrx_theme.dart';

/// MRX's context-aware text styles.
abstract final class MrxTextStyles {
  static const _fontFallback = <String>[
    'Inter',
    'SF Pro Text',
    'Segoe UI',
    'Helvetica Neue',
    'Arial',
  ];

  /// A large screen heading.
  static TextStyle display(BuildContext context) => TextStyle(
    color: MrxTheme.of(context).colors.text,
    fontSize: 32,
    height: 1.1,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.8,
    fontFamilyFallback: _fontFallback,
  );

  /// A section heading.
  static TextStyle heading(BuildContext context) => TextStyle(
    color: MrxTheme.of(context).colors.text,
    fontSize: 18,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    fontFamilyFallback: _fontFallback,
  );

  /// The default readable body style.
  static TextStyle body(BuildContext context) => TextStyle(
    color: MrxTheme.of(context).colors.text,
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
    fontFamilyFallback: _fontFallback,
  );

  /// Supporting copy with lower visual emphasis.
  static TextStyle label(BuildContext context) => TextStyle(
    color: MrxTheme.of(context).colors.textMuted,
    fontSize: 12,
    height: 1.35,
    fontWeight: FontWeight.w500,
    fontFamilyFallback: _fontFallback,
  );
}

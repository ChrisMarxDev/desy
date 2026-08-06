import 'package:flutter/material.dart';

/// Color roles owned by the sample consumer, rather than by Desy Bench.
abstract final class SampleColors {
  /// Deep teal used for primary actions.
  static const Color lagoon = Color(0xff006b63);

  /// Brighter teal for high-contrast treatments.
  static const Color lagoonBright = Color(0xff0b8177);

  /// Near-black text and icon color.
  static const Color ink = Color(0xff17201f);

  /// Pale green-tinted neutral surface.
  static const Color mist = Color(0xffedf5f2);

  /// Violet used for informative content.
  static const Color iris = Color(0xff6750a4);

  /// Amber used for warnings.
  static const Color sun = Color(0xff8d5700);

  /// Red-orange used for destructive states.
  static const Color coral = Color(0xffb42318);

  /// Green reserved for confirmed non-primary states.
  static const Color moss = Color(0xff28734d);
}

/// The light theme used by the sample design system.
final ThemeData sampleLightTheme = _sampleTheme(Brightness.light);

/// The dark theme used by the sample design system.
final ThemeData sampleDarkTheme = _sampleTheme(Brightness.dark);

ThemeData _sampleTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: isDark ? const Color(0xff74d8cc) : SampleColors.lagoon,
    onPrimary: isDark ? SampleColors.ink : Colors.white,
    primaryContainer: isDark
        ? const Color(0xff005049)
        : const Color(0xffa8f1e5),
    onPrimaryContainer: isDark
        ? const Color(0xffa8f1e5)
        : const Color(0xff00201d),
    secondary: isDark ? const Color(0xffd0bcff) : SampleColors.iris,
    onSecondary: isDark ? const Color(0xff381e72) : Colors.white,
    secondaryContainer: isDark
        ? const Color(0xff4f378b)
        : const Color(0xffe9ddff),
    onSecondaryContainer: isDark
        ? const Color(0xffe9ddff)
        : const Color(0xff21005d),
    tertiary: isDark ? const Color(0xffffb95f) : SampleColors.sun,
    onTertiary: isDark ? const Color(0xff482900) : Colors.white,
    tertiaryContainer: isDark
        ? const Color(0xff6a4100)
        : const Color(0xffffddb2),
    onTertiaryContainer: isDark
        ? const Color(0xffffddb2)
        : const Color(0xff2d1600),
    error: isDark ? const Color(0xffffb4ab) : SampleColors.coral,
    onError: isDark ? const Color(0xff690005) : Colors.white,
    errorContainer: isDark ? const Color(0xff93000a) : const Color(0xffffdad6),
    onErrorContainer: isDark
        ? const Color(0xffffdad6)
        : const Color(0xff410002),
    surface: isDark ? const Color(0xff101918) : const Color(0xfff8fbf9),
    onSurface: isDark ? const Color(0xffdfe8e5) : SampleColors.ink,
    surfaceContainerHighest: isDark
        ? const Color(0xff303a38)
        : const Color(0xffdce5e2),
    onSurfaceVariant: isDark
        ? const Color(0xffbec9c5)
        : const Color(0xff3f4947),
    outline: isDark ? const Color(0xff89938f) : const Color(0xff6f7976),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: isDark ? const Color(0xffdfe8e5) : const Color(0xff2c3331),
    onInverseSurface: isDark
        ? const Color(0xff26302e)
        : const Color(0xffedf1ef),
    inversePrimary: isDark ? SampleColors.lagoon : const Color(0xff74d8cc),
  );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.surface,
  );
}

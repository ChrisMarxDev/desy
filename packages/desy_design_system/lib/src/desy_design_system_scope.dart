import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// The two Desy-owned workbench theme variants.
enum DesyDesignSystemTheme {
  /// High-clarity neutral workbench chrome.
  light,

  /// Low-glare neutral workbench chrome.
  dark,
}

/// Desy-owned foundation values shared by the package and its catalogue.
abstract final class DesyDesignSystemTokens {
  /// Primary typeface used throughout Desy-owned workbench surfaces.
  static const String fontFamily = 'packages/desy_design_system/Space Grotesk';

  /// Compact separation between related inline elements.
  static const double spaceXs = 4;

  /// Default compact-control separation.
  static const double spaceSm = 8;

  /// Default panel-internal separation.
  static const double spaceMd = 12;

  /// Default panel padding.
  static const double spaceLg = 20;

  /// Radius for compact controls and keycaps.
  static const double radiusSm = 4;

  /// Radius for cards and contained panels.
  static const double radiusMd = 8;

  /// Desy's standard navigation reveal duration.
  static const Duration navigationMotion = Duration(milliseconds: 180);

  /// Desy's standard emphasized feedback duration.
  static const Duration feedbackMotion = Duration(milliseconds: 220);

  /// The standard responsive threshold for compact workbench navigation.
  static const double compactBreakpoint = 640;
}

/// Theme and localization values used to mount Desy-owned surfaces.
abstract final class DesyDesignSystemFoundation {
  /// Resolves the Forui data for [theme].
  static FThemeData themeData(DesyDesignSystemTheme theme) {
    final foundation = switch (theme) {
      DesyDesignSystemTheme.light => FTheme.neutral.light.desktop,
      DesyDesignSystemTheme.dark => FTheme.neutral.dark.desktop,
    };
    final typeface = FTypeface.inherit(
      colors: foundation.colors,
      touch: false,
      fontFamily: DesyDesignSystemTokens.fontFamily,
      fontFamilyFallback: const [FTypeface.defaultFontFamily],
    );
    final data = FThemeData(
      colors: foundation.colors,
      touch: false,
      debugLabel: foundation.debugLabel,
      breakpoints: foundation.breakpoints,
      typography: FTypography(display: typeface, body: typeface),
      icons: foundation.icons,
      hapticFeedback: foundation.hapticFeedback,
    );
    return data.copyWith(
      dialogStyle: FDialogStyleDelta.delta(
        insetPadding: EdgeInsetsGeometryDelta.value(
          const EdgeInsets.all(DesyDesignSystemTokens.spaceLg),
        ),
      ),
    );
  }

  /// Builds the Flutter Material bridge needed by native platform primitives.
  static ThemeData materialTheme(DesyDesignSystemTheme theme) {
    final data = themeData(theme);
    return data.toApproximateMaterialTheme().copyWith(
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: data.colors.primary,
        selectionColor: data.colors.primary.withValues(alpha: .28),
        selectionHandleColor: data.colors.primary,
      ),
    );
  }

  /// The locales provided by the underlying scaffold foundation.
  static Iterable<Locale> get supportedLocales =>
      FLocalizations.supportedLocales;

  /// Localization delegates required by Desy controls.
  static Iterable<LocalizationsDelegate<dynamic>> get localizationsDelegates =>
      FLocalizations.localizationsDelegates;
}

/// Mounts only Desy's inherited visual theme around [child].
///
/// This is the appropriate boundary for component previews. It preserves the
/// child's own layout while still rendering it with the real Desy theme.
class DesyDesignSystemThemeScope extends StatelessWidget {
  /// Creates a visual theme scope around [child].
  const DesyDesignSystemThemeScope({
    super.key,
    required this.theme,
    required this.child,
  });

  /// The active Desy-owned chrome theme.
  final DesyDesignSystemTheme theme;

  /// The Desy-owned subtree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final data = DesyDesignSystemFoundation.themeData(theme);
    return Theme(
      data: DesyDesignSystemFoundation.materialTheme(theme),
      child: FTheme(data: data, child: child),
    );
  }
}

/// Mounts the Desy theme and app-wide interaction services around [child].
///
/// Use [DesyDesignSystemThemeScope] for isolated component previews. The
/// toaster's overlay intentionally occupies its available surface, so it
/// belongs at an application boundary rather than around a natural-size
/// specimen.
class DesyDesignSystemScope extends StatelessWidget {
  /// Creates a complete design-system host around [child].
  const DesyDesignSystemScope({
    super.key,
    required this.theme,
    required this.child,
  });

  /// The active Desy-owned chrome theme.
  final DesyDesignSystemTheme theme;

  /// The Desy-owned subtree.
  final Widget child;

  @override
  Widget build(BuildContext context) => DesyDesignSystemThemeScope(
    theme: theme,
    child: FToaster(child: FTooltipGroup(child: child)),
  );
}

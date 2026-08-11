import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'desy_visual_tokens.dart';

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
  static const String fontFamily = 'packages/desy_design_system/Roboto';

  /// Compact separation between related inline elements.
  static const double spaceXs = 4;

  /// Default compact-control separation.
  static const double spaceSm = 8;

  /// Default panel-internal separation.
  static const double spaceMd = 12;

  /// Default content and toolbar separation.
  static const double spaceBase = 16;

  /// Default panel padding.
  static const double spaceLg = 20;

  /// Separation between major regions inside a workspace.
  static const double spaceXl = 24;

  /// Large empty-state and page-section separation.
  static const double space2xl = 32;

  /// Radius for compact controls and keycaps.
  static const double radiusSm = 4;

  /// Radius for cards and contained panels.
  static const double radiusMd = 8;

  /// Radius for prominent overlays and floating docks.
  static const double radiusLg = 12;

  /// The structural divider used between persistent workspace regions.
  static const double hairline = 1;

  /// Pointer hit target centered around an interactive resize divider.
  static const double resizeDividerHitSize = 8;

  /// Compact desktop controls and icon buttons.
  static const double controlSm = 28;

  /// Default desktop controls.
  static const double controlMd = 36;

  /// The persistent Registry Spine width in the committed desktop shell.
  static const double registrySpineWidth = 280;

  /// The default agent conversation rail width.
  static const double agentRailWidth = 320;

  /// The stable global workbench toolbar height.
  static const double toolbarHeight = 32;

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
    final visualColors = switch (theme) {
      DesyDesignSystemTheme.light => DesyVisualColors.light,
      DesyDesignSystemTheme.dark => DesyVisualColors.dark,
    };
    final colors = foundation.colors.copyWith(
      background: visualColors.canvas,
      foreground: theme == DesyDesignSystemTheme.light
          ? const Color(0xFF171717)
          : const Color(0xFFFAFAFA),
      primary: theme == DesyDesignSystemTheme.light
          ? const Color(0xFF171717)
          : const Color(0xFFFAFAFA),
      primaryForeground: theme == DesyDesignSystemTheme.light
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF171717),
      secondary: visualColors.panelSubtle,
      muted: visualColors.panelSubtle,
      mutedForeground: theme == DesyDesignSystemTheme.light
          ? const Color(0xFF71717A)
          : const Color(0xFFA1A1AA),
      card: visualColors.panel,
      border: visualColors.divider,
      extensions: [visualColors],
    );
    final typeface = FTypeface.inherit(
      colors: colors,
      touch: false,
      fontFamily: DesyDesignSystemTokens.fontFamily,
      fontFamilyFallback: const [FTypeface.defaultFontFamily],
    );
    final typography = FTypography(display: typeface, body: typeface);
    final style =
        FStyle.inherit(
          colors: colors,
          typography: typography,
          touch: false,
        ).copyWith(
          borderRadius: const FBorderRadius(
            xs2: BorderRadius.all(Radius.circular(2)),
            xs: BorderRadius.all(Radius.circular(3)),
            sm: BorderRadius.all(Radius.circular(4)),
            md: BorderRadius.all(Radius.circular(6)),
            lg: BorderRadius.all(Radius.circular(8)),
            xl: BorderRadius.all(Radius.circular(10)),
            xl2: BorderRadius.all(Radius.circular(12)),
            xl3: BorderRadius.all(Radius.circular(14)),
          ),
          focusedOutlineStyle: FFocusedOutlineStyleDelta.delta(
            color: visualColors.signal,
            borderRadius: const BorderRadius.all(Radius.circular(6)),
            width: 1.5,
            spacing: 2,
          ),
          pagePadding: const EdgeInsetsDelta.value(
            EdgeInsets.symmetric(
              horizontal: DesyDesignSystemTokens.spaceBase,
              vertical: DesyDesignSystemTokens.spaceMd,
            ),
          ),
          shadow: const [
            BoxShadow(
              color: Color(0x12000000),
              offset: Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        );
    final data = FThemeData(
      colors: colors,
      touch: false,
      debugLabel: 'Desy Registry Spine ${theme.name}',
      breakpoints: foundation.breakpoints,
      typography: typography,
      style: style,
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
      scaffoldBackgroundColor: data.colors.desy.canvas,
      dividerColor: data.colors.desy.divider,
      cardColor: data.colors.desy.panel,
      focusColor: data.colors.desy.signalSurface,
      hoverColor: data.colors.desy.panelSubtle,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: data.colors.desy.signal,
        selectionColor: data.colors.desy.signal.withValues(alpha: .22),
        selectionHandleColor: data.colors.desy.signal,
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

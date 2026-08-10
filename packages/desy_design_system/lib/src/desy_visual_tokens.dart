import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Desy's semantic colors that do not belong to Forui's action hierarchy.
///
/// The workbench deliberately keeps primary actions black. Pink is a signal
/// color reserved for selection, inspection, annotation, and live design
/// feedback so those states remain unmistakable across every surface.
@immutable
class DesyVisualColors extends ThemeExtension<DesyVisualColors> {
  /// Creates Desy's additional semantic palette.
  const DesyVisualColors({
    required this.signal,
    required this.onSignal,
    required this.signalSurface,
    required this.signalBorder,
    required this.positive,
    required this.onPositive,
    required this.canvas,
    required this.panel,
    required this.panelSubtle,
    required this.divider,
  });

  /// The bright selection and annotation color.
  final Color signal;

  /// Content shown on a solid [signal] surface.
  final Color onSignal;

  /// A quiet surface tint for selected rows and annotation context.
  final Color signalSurface;

  /// A lower-emphasis signal border.
  final Color signalBorder;

  /// Positive runtime and hot-reload state.
  final Color positive;

  /// Content shown on [positive].
  final Color onPositive;

  /// The uninterrupted workspace canvas.
  final Color canvas;

  /// The default structural panel surface.
  final Color panel;

  /// The one permitted recessed or hover surface.
  final Color panelSubtle;

  /// The structural hairline used between app regions.
  final Color divider;

  /// Desy's light desktop palette from the committed Registry Spine design.
  static const light = DesyVisualColors(
    signal: Color(0xFFFF2D7A),
    onSignal: Color(0xFFFFFFFF),
    signalSurface: Color(0xFFFFF0F6),
    signalBorder: Color(0xFFFF9FC1),
    positive: Color(0xFF16A34A),
    onPositive: Color(0xFFFFFFFF),
    canvas: Color(0xFFFFFFFF),
    panel: Color(0xFFFFFFFF),
    panelSubtle: Color(0xFFF7F7F8),
    divider: Color(0xFFE4E4E7),
  );

  /// A low-glare counterpart that keeps the same signal semantics.
  static const dark = DesyVisualColors(
    signal: Color(0xFFFF4D91),
    onSignal: Color(0xFFFFFFFF),
    signalSurface: Color(0xFF331322),
    signalBorder: Color(0xFF8A2A51),
    positive: Color(0xFF4ADE80),
    onPositive: Color(0xFF052E16),
    canvas: Color(0xFF0F0F10),
    panel: Color(0xFF151516),
    panelSubtle: Color(0xFF202023),
    divider: Color(0xFF2B2B2F),
  );

  @override
  DesyVisualColors copyWith({
    Color? signal,
    Color? onSignal,
    Color? signalSurface,
    Color? signalBorder,
    Color? positive,
    Color? onPositive,
    Color? canvas,
    Color? panel,
    Color? panelSubtle,
    Color? divider,
  }) => DesyVisualColors(
    signal: signal ?? this.signal,
    onSignal: onSignal ?? this.onSignal,
    signalSurface: signalSurface ?? this.signalSurface,
    signalBorder: signalBorder ?? this.signalBorder,
    positive: positive ?? this.positive,
    onPositive: onPositive ?? this.onPositive,
    canvas: canvas ?? this.canvas,
    panel: panel ?? this.panel,
    panelSubtle: panelSubtle ?? this.panelSubtle,
    divider: divider ?? this.divider,
  );

  @override
  DesyVisualColors lerp(covariant DesyVisualColors? other, double t) {
    if (other == null) return this;
    return DesyVisualColors(
      signal: Color.lerp(signal, other.signal, t)!,
      onSignal: Color.lerp(onSignal, other.onSignal, t)!,
      signalSurface: Color.lerp(signalSurface, other.signalSurface, t)!,
      signalBorder: Color.lerp(signalBorder, other.signalBorder, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      onPositive: Color.lerp(onPositive, other.onPositive, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      panelSubtle: Color.lerp(panelSubtle, other.panelSubtle, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}

/// Accesses Desy's additional semantic colors from Forui's active palette.
extension DesyVisualColorsAccess on FColors {
  /// Desy's selection, feedback, and workspace surface colors.
  ///
  /// A brightness-matched fallback keeps reusable workbench widgets safe when
  /// they are rendered inside a consumer-owned or deliberately minimal Forui
  /// test theme that has not installed Desy's extension yet.
  DesyVisualColors get desy {
    for (final candidate in extensions) {
      if (candidate is DesyVisualColors) return candidate;
    }
    return brightness == Brightness.dark
        ? DesyVisualColors.dark
        : DesyVisualColors.light;
  }
}

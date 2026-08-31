// ignore_for_file: public_member_api_docs

/// Orbit's consumer-owned desktop design system.
///
/// The library intentionally uses Flutter's widget, focus, semantics, and
/// editable-text primitives rather than Material controls. Mix owns the core
/// surface treatment; the small wrappers below provide Orbit's semantic API.
library;

import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

abstract final class OrbitTokens {
  // Shadcn's 0.625rem base radius, expressed at Flutter's logical pixel scale.
  static const radiusSm = 6.0;
  static const radiusMd = 8.0;
  static const radiusLg = 10.0;
  static const radiusXl = 14.0;
  static const radiusPill = 999.0;

  static const space2xs = 4.0;
  static const spaceXs = 6.0;
  static const spaceSm = 8.0;
  static const spaceMd = 12.0;
  static const spaceLg = 16.0;
  static const spaceXl = 24.0;
  static const space2xl = 32.0;
  static const controlHeight = 36.0;
  static const touchTarget = 40.0;
}

/// Semantic colors, deliberately named by role rather than by a swatch.
@immutable
class OrbitColors {
  const OrbitColors({
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.popover,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.border,
    required this.input,
    required this.ring,
    required this.destructive,
    required this.success,
    required this.warning,
    required this.info,
    required this.selection,
  });

  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color popover;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color border;
  final Color input;
  final Color ring;
  final Color destructive;
  final Color success;
  final Color warning;
  final Color info;
  final Color selection;
}

abstract final class OrbitPalettes {
  /// Orbit's one neutral dark foundation.
  static const standard = OrbitColors(
    background: Color(0xff171717),
    foreground: Color(0xfffafafa),
    card: Color(0xff262626),
    cardForeground: Color(0xfffafafa),
    popover: Color(0xff262626),
    primary: Color(0xffeaeaea),
    primaryForeground: Color(0xff343434),
    secondary: Color(0xff454545),
    secondaryForeground: Color(0xfffafafa),
    muted: Color(0xff454545),
    mutedForeground: Color(0xffa3a3a3),
    accent: Color(0xff454545),
    accentForeground: Color(0xfffafafa),
    border: Color(0x1affffff),
    input: Color(0x26ffffff),
    ring: Color(0xff8a8a8a),
    destructive: Color(0xfffb7185),
    success: Color(0xff34d399),
    warning: Color(0xfffbbf24),
    info: Color(0xff60a5fa),
    selection: Color(0x667c3aed),
  );
}

@immutable
class OrbitThemeData {
  const OrbitThemeData({
    required this.id,
    required this.name,
    required this.isDark,
    required this.colors,
  });

  final String id;
  final String name;
  final bool isDark;
  final OrbitColors colors;

  static const standard = OrbitThemeData(
    id: 'orbit.theme',
    name: 'Orbit',
    isDark: true,
    colors: OrbitPalettes.standard,
  );
}

/// Gives all Orbit widgets one real, consumer-owned source for design tokens.
class OrbitTheme extends InheritedWidget {
  const OrbitTheme({super.key, required this.data, required super.child});

  final OrbitThemeData data;

  static OrbitThemeData of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<OrbitTheme>();
    assert(result != null, 'Orbit widgets need an OrbitTheme ancestor.');
    return result?.data ?? OrbitThemeData.standard;
  }

  @override
  bool updateShouldNotify(OrbitTheme oldWidget) => data != oldWidget.data;
}

abstract final class OrbitType {
  static const _fontFallback = <String>[
    'Inter',
    'SF Pro Text',
    'Segoe UI',
    'Helvetica Neue',
    'Arial',
  ];

  static TextStyle display(BuildContext context) => TextStyle(
    color: OrbitTheme.of(context).colors.foreground,
    fontSize: 32,
    height: 1.08,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.9,
    fontFamilyFallback: _fontFallback,
  );

  static TextStyle heading(BuildContext context) => TextStyle(
    color: OrbitTheme.of(context).colors.foreground,
    fontSize: 18,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.24,
    fontFamilyFallback: _fontFallback,
  );

  static TextStyle title(BuildContext context) => TextStyle(
    color: OrbitTheme.of(context).colors.foreground,
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w600,
    fontFamilyFallback: _fontFallback,
  );

  static TextStyle body(BuildContext context) => TextStyle(
    color: OrbitTheme.of(context).colors.foreground,
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
    fontFamilyFallback: _fontFallback,
  );

  static TextStyle small(BuildContext context) => TextStyle(
    color: OrbitTheme.of(context).colors.mutedForeground,
    fontSize: 12,
    height: 1.35,
    fontWeight: FontWeight.w400,
    fontFamilyFallback: _fontFallback,
  );

  static TextStyle label(BuildContext context) => TextStyle(
    color: OrbitTheme.of(context).colors.foreground,
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    fontFamilyFallback: _fontFallback,
  );

  static TextStyle overline(BuildContext context) => TextStyle(
    color: OrbitTheme.of(context).colors.mutedForeground,
    fontSize: 10,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    fontFamilyFallback: _fontFallback,
  );
}

abstract final class OrbitMotion {
  static Duration quick(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 120);

  static Duration standard(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 180);
}

abstract final class OrbitGlyphs {
  static const sparkle = '✦';
  static const send = '↑';
  static const add = '+';
  static const command = '⌘';
  static const search = '⌕';
  static const arrowRight = '→';
  static const check = '✓';
  static const pause = 'Ⅱ';
  static const dot = '•';
  static const more = '⋯';
  static const database = '▦';
  static const grid = '⊞';
  static const activity = '⌁';
  static const document = '▤';
  static const close = '×';
}

class OrbitGlyph extends StatelessWidget {
  const OrbitGlyph(
    this.glyph, {
    super.key,
    this.color,
    this.size = 16,
    this.label,
  });

  final String glyph;
  final Color? color;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    excluding: label == null,
    child: Semantics(
      label: label,
      child: Text(
        glyph,
        style: TextStyle(
          color: color ?? OrbitTheme.of(context).colors.foreground,
          fontSize: size,
          height: 1,
          fontWeight: FontWeight.w700,
          fontFamilyFallback: const ['Arial', 'Helvetica Neue'],
        ),
      ),
    ),
  );
}

/// Compact semantic keycaps matching Desy's shortcut-label treatment while
/// remaining bound to Orbit's consumer theme.
class OrbitShortcutLabel extends StatelessWidget {
  const OrbitShortcutLabel({super.key, required this.keys, this.semanticLabel});

  final List<String> keys;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = OrbitTheme.of(context).colors;
    return Semantics(
      label: semanticLabel ?? 'Keyboard shortcut: ${keys.join(' plus ')}',
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 3,
          runSpacing: 3,
          children: [
            for (final key in keys)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.card,
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(OrbitTokens.radiusSm),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  child: Text(
                    key,
                    style: OrbitType.label(
                      context,
                    ).copyWith(color: colors.mutedForeground, fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum OrbitSurfaceTone { card, raised, muted, transparent }

class OrbitSurface extends StatelessWidget {
  const OrbitSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(OrbitTokens.spaceLg),
    this.tone = OrbitSurfaceTone.card,
    this.radius = OrbitTokens.radiusLg,
    this.border = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final OrbitSurfaceTone tone;
  final double radius;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final colors = OrbitTheme.of(context).colors;
    final background = switch (tone) {
      OrbitSurfaceTone.card => colors.card,
      OrbitSurfaceTone.raised => colors.popover,
      OrbitSurfaceTone.muted => colors.muted,
      OrbitSurfaceTone.transparent => const Color(0x00000000),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: border
            ? Border.all(
                color: colors.border.withValues(alpha: colors.border.a * 0.82),
              )
            : null,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class OrbitDivider extends StatelessWidget {
  const OrbitDivider({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: indent),
    child: ColoredBox(
      color: OrbitTheme.of(context).colors.border,
      child: const SizedBox(height: 1, width: double.infinity),
    ),
  );
}

enum OrbitButtonVariant { primary, secondary, ghost, destructive }

class OrbitButton extends StatelessWidget {
  const OrbitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.trailing,
    this.variant = OrbitButtonVariant.primary,
    this.compact = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;
  final OrbitButtonVariant variant;
  final bool compact;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = OrbitTheme.of(context).colors;
    final enabled = onPressed != null;
    final (background, foreground, outline) = switch (variant) {
      OrbitButtonVariant.primary => (
        colors.primary,
        colors.primaryForeground,
        colors.primary,
      ),
      OrbitButtonVariant.secondary => (
        colors.secondary,
        colors.secondaryForeground,
        colors.border,
      ),
      OrbitButtonVariant.ghost => (
        const Color(0x00000000),
        colors.accentForeground,
        const Color(0x00000000),
      ),
      OrbitButtonVariant.destructive => (
        colors.destructive,
        const Color(0xffffffff),
        colors.destructive,
      ),
    };
    final hoverBackground = variant == OrbitButtonVariant.ghost
        ? colors.accent
        : Color.alphaBlend(foreground.withValues(alpha: 0.08), background);
    final pressedBackground = Color.alphaBlend(
      foreground.withValues(alpha: 0.16),
      background,
    );
    final horizontal = compact ? OrbitTokens.spaceSm : OrbitTokens.spaceMd;
    final animation = AnimationConfig.ease(OrbitMotion.quick(context));
    final buttonStyle = BoxStyler()
        .color(background)
        .borderRounded(OrbitTokens.radiusMd)
        .borderAll(color: outline)
        .constraints(BoxConstraintsMix.minHeight(OrbitTokens.controlHeight))
        .onHovered(BoxStyler().color(hoverBackground))
        .onPressed(BoxStyler().color(pressedBackground).scale(0.98))
        .onFocused(BoxStyler().borderAll(color: colors.ring, width: 1))
        .onDisabled(
          BoxStyler()
              .color(colors.muted)
              .borderAll(color: colors.input)
              .wrap(WidgetModifierConfig.opacity(0.72)),
        )
        .animate(animation);
    final labelStyle = TextStyler()
        .style(TextStyleMix.value(OrbitType.label(context)))
        .color(foreground)
        .maxLines(1)
        .overflow(TextOverflow.ellipsis)
        .onDisabled(TextStyler().color(colors.mutedForeground))
        .animate(animation);

    return Pressable(
      enabled: enabled,
      mouseCursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      semanticButtonLabel: label,
      onPress: onPressed,
      child: Box(
        style: buttonStyle,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 8),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading case final leading?) ...[
                leading,
                const SizedBox(width: OrbitTokens.spaceSm),
              ],
              Flexible(child: StyledText(label, style: labelStyle)),
              if (trailing case final trailing?) ...[
                const SizedBox(width: OrbitTokens.spaceSm),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class OrbitIconButton extends StatelessWidget {
  const OrbitIconButton({
    super.key,
    required this.label,
    required this.glyph,
    required this.onPressed,
    this.variant = OrbitButtonVariant.ghost,
  });

  final String label;
  final String glyph;
  final VoidCallback? onPressed;
  final OrbitButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = OrbitTheme.of(context).colors;
    final enabled = onPressed != null;
    final (background, outline) = switch (variant) {
      OrbitButtonVariant.primary => (colors.primary, colors.primary),
      OrbitButtonVariant.secondary => (colors.secondary, colors.border),
      OrbitButtonVariant.ghost => (
        const Color(0x00000000),
        const Color(0x00000000),
      ),
      OrbitButtonVariant.destructive => (
        colors.destructive,
        colors.destructive,
      ),
    };
    final foreground = switch (variant) {
      OrbitButtonVariant.primary => colors.primaryForeground,
      OrbitButtonVariant.secondary ||
      OrbitButtonVariant.ghost => colors.accentForeground,
      OrbitButtonVariant.destructive => const Color(0xffffffff),
    };
    final hoverBackground = variant == OrbitButtonVariant.ghost
        ? colors.accent
        : Color.alphaBlend(foreground.withValues(alpha: 0.08), background);
    final pressedBackground = Color.alphaBlend(
      foreground.withValues(alpha: 0.16),
      background,
    );

    return Pressable(
      enabled: enabled,
      mouseCursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      semanticButtonLabel: label,
      onPress: onPressed,
      child: Box(
        style: BoxStyler()
            .color(background)
            .borderRounded(OrbitTokens.radiusMd)
            .borderAll(color: outline)
            .constraints(BoxConstraintsMix.square(OrbitTokens.touchTarget))
            .onHovered(BoxStyler().color(hoverBackground))
            .onPressed(BoxStyler().color(pressedBackground).scale(0.98))
            .onFocused(BoxStyler().borderAll(color: colors.ring, width: 1))
            .onDisabled(
              BoxStyler()
                  .color(colors.muted)
                  .borderAll(color: colors.input)
                  .wrap(WidgetModifierConfig.opacity(0.72)),
            )
            .animate(AnimationConfig.ease(OrbitMotion.quick(context))),
        child: Center(child: OrbitGlyph(glyph, color: foreground, size: 14)),
      ),
    );
  }
}

enum OrbitBadgeTone { neutral, info, success, warning, danger }

class OrbitBadge extends StatelessWidget {
  const OrbitBadge({
    super.key,
    required this.label,
    this.tone = OrbitBadgeTone.neutral,
    this.glyph,
  });

  final String label;
  final OrbitBadgeTone tone;
  final String? glyph;

  @override
  Widget build(BuildContext context) {
    final colors = OrbitTheme.of(context).colors;
    final toneColor = switch (tone) {
      OrbitBadgeTone.neutral => colors.mutedForeground,
      OrbitBadgeTone.info => colors.info,
      OrbitBadgeTone.success => colors.success,
      OrbitBadgeTone.warning => colors.warning,
      OrbitBadgeTone.danger => colors.destructive,
    };
    return Box(
      style: BoxStyler()
          .color(toneColor.withValues(alpha: 0.14))
          .borderRounded(OrbitTokens.radiusPill),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OrbitTokens.spaceSm,
          vertical: OrbitTokens.spaceXs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (glyph case final glyph?) ...[
              OrbitGlyph(glyph, color: toneColor, size: 12),
              const SizedBox(width: OrbitTokens.space2xs),
            ],
            Text(
              label,
              style: OrbitType.overline(context).copyWith(color: toneColor),
            ),
          ],
        ),
      ),
    );
  }
}

class OrbitProgress extends StatelessWidget {
  const OrbitProgress({
    super.key,
    required this.value,
    this.color,
    this.height = 6,
  });

  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = OrbitTheme.of(context).colors;
    return Semantics(
      value: '${(value.clamp(0, 1) * 100).round()} percent',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(OrbitTokens.radiusPill),
        child: SizedBox(
          height: height,
          child: ColoredBox(
            color: colors.muted,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value.clamp(0, 1),
                child: ColoredBox(color: color ?? colors.primary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OrbitSpinner extends StatefulWidget {
  const OrbitSpinner({super.key, this.size = 18, this.color});

  final double size;
  final Color? color;

  @override
  State<OrbitSpinner> createState() => _OrbitSpinnerState();
}

class _OrbitSpinnerState extends State<OrbitSpinner>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spinner = CustomPaint(
      size: Size.square(widget.size),
      painter: _OrbitSpinnerPainter(
        color: widget.color ?? OrbitTheme.of(context).colors.foreground,
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return spinner;
    final controller = _controller ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat();
    return RotationTransition(turns: controller, child: spinner);
  }
}

class _OrbitSpinnerPainter extends CustomPainter {
  const _OrbitSpinnerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = math.max(1.5, size.width / 9)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final inset = paint.strokeWidth / 2;
    canvas.drawArc(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - inset * 2,
        size.height - inset * 2,
      ),
      -math.pi / 2,
      math.pi * 1.35,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_OrbitSpinnerPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// A native [EditableText] wrapped in Orbit's visual and focus contract.
/// It preserves platform text editing, selection, IME, and accessibility.
class OrbitTextArea extends StatefulWidget {
  const OrbitTextArea({
    super.key,
    required this.controller,
    required this.hint,
    this.focusNode,
    this.enabled = true,
    this.minLines = 1,
    this.maxLines = 5,
    this.onSubmitted,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final FocusNode? focusNode;
  final bool enabled;
  final int minLines;
  final int maxLines;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  State<OrbitTextArea> createState() => _OrbitTextAreaState();
}

class _OrbitTextAreaState extends State<OrbitTextArea> {
  late FocusNode _focusNode;
  late bool _ownsFocusNode;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode(debugLabel: 'orbit-text-area');
  }

  @override
  void didUpdateWidget(OrbitTextArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == widget.focusNode) return;
    if (_ownsFocusNode) _focusNode.dispose();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode(debugLabel: 'orbit-text-area');
  }

  @override
  void dispose() {
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = OrbitTheme.of(context).colors;
    return AnimatedBuilder(
      animation: Listenable.merge([_focusNode, widget.controller]),
      builder: (context, _) {
        final focused = _focusNode.hasFocus;
        final empty = widget.controller.text.isEmpty;
        final inputStyle = BoxStyler()
            .color(colors.card)
            .borderRounded(OrbitTokens.radiusLg)
            .borderAll(
              color: focused ? colors.ring : colors.input,
              // Keep the border's geometry constant. A focus indication
              // is a color transition, not a layout transition.
              width: 1,
            );
        final duration = OrbitMotion.quick(context);
        return Semantics(
          textField: true,
          enabled: widget.enabled,
          label: widget.hint,
          child: MouseRegion(
            cursor: widget.enabled
                ? SystemMouseCursors.text
                : SystemMouseCursors.forbidden,
            child: Box(
              style: duration == Duration.zero
                  ? inputStyle
                  : inputStyle.animate(AnimationConfig.ease(duration)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: OrbitTokens.spaceMd,
                  vertical: OrbitTokens.spaceSm,
                ),
                child: Stack(
                  children: [
                    if (empty)
                      IgnorePointer(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            widget.hint,
                            style: OrbitType.body(
                              context,
                            ).copyWith(color: colors.mutedForeground),
                          ),
                        ),
                      ),
                    EditableText(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      readOnly: !widget.enabled,
                      style: OrbitType.body(context),
                      cursorColor: colors.foreground,
                      backgroundCursorColor: colors.background,
                      selectionColor: colors.selection,
                      maxLines: widget.maxLines,
                      minLines: widget.minLines,
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                      onSubmitted: widget.onSubmitted,
                      onChanged: widget.onChanged,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

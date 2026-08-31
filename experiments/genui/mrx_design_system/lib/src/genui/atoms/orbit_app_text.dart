// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppText extends StatelessWidget {
  const OrbitAppText(
    this.content, {
    super.key,
    this.role = OrbitTextRole.body,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String content;
  final OrbitTextRole role;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => Text(
    content,
    maxLines: maxLines,
    overflow: overflow,
    textAlign: textAlign,
    style: _textStyle(context, role),
  );
}

TextStyle _textStyle(BuildContext context, OrbitTextRole role) {
  final colors = OrbitTheme.of(context).colors;
  return switch (role) {
    OrbitTextRole.display => OrbitType.display(context),
    OrbitTextRole.titleLarge => OrbitType.heading(
      context,
    ).copyWith(fontSize: 24),
    OrbitTextRole.title => OrbitType.title(context),
    OrbitTextRole.heading => OrbitType.heading(context),
    OrbitTextRole.body => OrbitType.body(context),
    OrbitTextRole.bodySecondary => OrbitType.body(
      context,
    ).copyWith(color: colors.mutedForeground),
    OrbitTextRole.label => OrbitType.label(context),
    OrbitTextRole.caption => OrbitType.small(context),
    OrbitTextRole.value => OrbitType.heading(context).copyWith(fontSize: 20),
    OrbitTextRole.code => OrbitType.body(context).copyWith(
      fontFamily: 'SF Mono',
      fontFamilyFallback: const ['SF Mono', 'Menlo', 'Consolas', 'monospace'],
    ),
  };
}

/// Small Markdown implementation with Orbit typography; it deliberately never
/// leaks an HTML/CSS rendering surface into GenUI.

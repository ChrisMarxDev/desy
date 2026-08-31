// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppIcon extends StatelessWidget {
  const OrbitAppIcon({
    super.key,
    required this.icon,
    this.tone = OrbitSemanticTone.neutral,
    this.label,
  });

  final String icon;
  final OrbitSemanticTone tone;
  final String? label;

  @override
  Widget build(BuildContext context) => OrbitGlyph(
    _glyphFor(icon),
    label: label,
    color: _toneColor(OrbitTheme.of(context).colors, tone),
  );
}

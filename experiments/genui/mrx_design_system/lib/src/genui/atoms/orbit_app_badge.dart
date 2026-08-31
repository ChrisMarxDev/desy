// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppBadge extends StatelessWidget {
  const OrbitAppBadge({
    super.key,
    required this.label,
    this.tone = OrbitSemanticTone.neutral,
    this.icon,
  });
  final String label;
  final OrbitSemanticTone tone;
  final String? icon;
  @override
  Widget build(BuildContext context) => OrbitBadge(
    label: label,
    tone: _badgeTone(tone),
    glyph: icon == null ? null : _glyphFor(icon!),
  );
}

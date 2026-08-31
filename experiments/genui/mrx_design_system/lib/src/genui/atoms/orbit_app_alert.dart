// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppAlert extends StatelessWidget {
  const OrbitAppAlert({
    super.key,
    required this.title,
    required this.detail,
    this.tone = OrbitSemanticTone.info,
  });
  final String title;
  final String detail;
  final OrbitSemanticTone tone;
  @override
  Widget build(BuildContext context) => OrbitSurface(
    tone: OrbitSurfaceTone.muted,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OrbitAppIcon(icon: _toneIcon(tone), tone: tone, label: tone.name),
        const SizedBox(width: OrbitTokens.spaceSm),
        Expanded(
          child: OrbitAppStack(
            gap: OrbitTokens.space2xs,
            children: [
              OrbitAppText(title, role: OrbitTextRole.title),
              OrbitAppText(detail, role: OrbitTextRole.bodySecondary),
            ],
          ),
        ),
      ],
    ),
  );
}

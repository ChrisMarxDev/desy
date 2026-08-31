// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppCode extends StatelessWidget {
  const OrbitAppCode({
    super.key,
    required this.code,
    this.language,
    this.onCopy,
  });

  final String code;
  final String? language;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) => OrbitSurface(
    tone: OrbitSurfaceTone.muted,
    padding: const EdgeInsets.all(OrbitTokens.spaceMd),
    child: OrbitAppStack(
      gap: OrbitTokens.spaceSm,
      children: [
        if (language != null || onCopy != null)
          Row(
            children: [
              Expanded(
                child: OrbitAppText(
                  language?.toUpperCase() ?? 'CODE',
                  role: OrbitTextRole.caption,
                ),
              ),
              if (onCopy != null)
                OrbitAppButton(
                  label: 'Copy',
                  intent: OrbitActionIntent.tertiary,
                  onPressed: onCopy,
                ),
            ],
          ),
        Text(code, style: _textStyle(context, OrbitTextRole.code)),
      ],
    ),
  );
}

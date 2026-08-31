// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppInline extends StatelessWidget {
  const OrbitAppInline({
    super.key,
    required this.children,
    this.gap = OrbitTokens.spaceSm,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });
  final List<Widget> children;
  final double gap;
  final CrossAxisAlignment crossAxisAlignment;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: crossAxisAlignment,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) SizedBox(width: gap),
        children[i],
      ],
    ],
  );
}

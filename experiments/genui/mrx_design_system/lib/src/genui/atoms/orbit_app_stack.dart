// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppStack extends StatelessWidget {
  const OrbitAppStack({
    super.key,
    required this.children,
    this.gap = OrbitTokens.spaceMd,
  });
  final List<Widget> children;
  final double gap;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) SizedBox(height: gap),
        children[i],
      ],
    ],
  );
}

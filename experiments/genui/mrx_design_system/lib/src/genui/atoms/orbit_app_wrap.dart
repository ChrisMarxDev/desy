// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppWrap extends StatelessWidget {
  const OrbitAppWrap({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: OrbitTokens.spaceSm,
    runSpacing: OrbitTokens.spaceSm,
    children: children,
  );
}

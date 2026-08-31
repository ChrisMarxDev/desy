// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppResponsiveGrid extends StatelessWidget {
  const OrbitAppResponsiveGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width < 560
        ? 1
        : width < 900
        ? 2
        : width < 1200
        ? 3
        : 4;
    final itemWidth = (width - ((columns - 1) * OrbitTokens.spaceMd)) / columns;
    return Wrap(
      spacing: OrbitTokens.spaceMd,
      runSpacing: OrbitTokens.spaceMd,
      children: [
        for (final child in children) SizedBox(width: itemWidth, child: child),
      ],
    );
  }
}

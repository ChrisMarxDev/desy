// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppSkeleton extends StatelessWidget {
  const OrbitAppSkeleton({super.key, this.lines = 3});
  final int lines;
  @override
  Widget build(BuildContext context) => OrbitAppStack(
    gap: OrbitTokens.spaceSm,
    children: [
      for (var index = 0; index < lines; index++)
        FractionallySizedBox(
          widthFactor: index == lines - 1 ? .62 : 1,
          child: Box(
            style: BoxStyler()
                .color(OrbitTheme.of(context).colors.muted)
                .borderRounded(OrbitTokens.radiusSm)
                .constraints(BoxConstraintsMix.minHeight(12)),
          ),
        ),
    ],
  );
}

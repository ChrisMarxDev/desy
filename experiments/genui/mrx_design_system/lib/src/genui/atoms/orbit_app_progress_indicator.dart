// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppProgressIndicator extends StatelessWidget {
  const OrbitAppProgressIndicator({super.key, this.value, this.label});
  final double? value;
  final String? label;
  @override
  Widget build(BuildContext context) => OrbitAppStack(
    gap: OrbitTokens.spaceXs,
    children: [
      if (label != null) OrbitAppText(label!, role: OrbitTextRole.label),
      if (value == null)
        const OrbitAppSpinner()
      else
        OrbitProgress(value: value!.clamp(0, 1)),
    ],
  );
}

// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppSurface extends StatelessWidget {
  const OrbitAppSurface({
    super.key,
    required this.child,
    this.muted = false,
    this.raised = false,
  });
  final Widget child;
  final bool muted;
  final bool raised;
  @override
  Widget build(BuildContext context) => OrbitSurface(
    tone: muted
        ? OrbitSurfaceTone.muted
        : raised
        ? OrbitSurfaceTone.raised
        : OrbitSurfaceTone.card,
    child: child,
  );
}

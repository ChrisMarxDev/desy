// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppCard extends StatelessWidget {
  const OrbitAppCard({super.key, required this.child, this.onOpen});
  final Widget child;
  final VoidCallback? onOpen;
  @override
  Widget build(BuildContext context) => Pressable(
    enabled: onOpen != null,
    semanticButtonLabel: onOpen == null ? null : 'Open card',
    onPress: onOpen,
    child: OrbitSurface(tone: OrbitSurfaceTone.raised, child: child),
  );
}

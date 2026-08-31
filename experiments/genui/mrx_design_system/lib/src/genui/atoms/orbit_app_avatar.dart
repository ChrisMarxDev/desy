// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppAvatar extends StatelessWidget {
  const OrbitAppAvatar({
    super.key,
    this.image,
    this.initials,
    this.icon,
    this.size = 36,
  });
  final String? image;
  final String? initials;
  final String? icon;
  final double size;
  @override
  Widget build(BuildContext context) => ClipOval(
    child: SizedBox(
      height: size,
      width: size,
      child: image != null
          ? Image.network(
              image!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback(context),
            )
          : _fallback(context),
    ),
  );
  Widget _fallback(BuildContext context) => ColoredBox(
    color: OrbitTheme.of(context).colors.muted,
    child: Center(
      child: OrbitAppText(
        initials ?? _glyphFor(icon ?? 'user'),
        role: OrbitTextRole.label,
      ),
    ),
  );
}

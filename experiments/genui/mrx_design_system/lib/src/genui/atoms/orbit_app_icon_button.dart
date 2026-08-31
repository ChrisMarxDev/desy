// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppIconButton extends StatelessWidget {
  const OrbitAppIconButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.intent = OrbitActionIntent.tertiary,
  });
  final String label;
  final String icon;
  final VoidCallback? onPressed;
  final OrbitActionIntent intent;
  @override
  Widget build(BuildContext context) => OrbitIconButton(
    label: label,
    glyph: _glyphFor(icon),
    onPressed: onPressed,
    variant: switch (intent) {
      OrbitActionIntent.primary => OrbitButtonVariant.primary,
      OrbitActionIntent.secondary => OrbitButtonVariant.secondary,
      OrbitActionIntent.tertiary => OrbitButtonVariant.ghost,
      OrbitActionIntent.destructive => OrbitButtonVariant.destructive,
    },
  );
}

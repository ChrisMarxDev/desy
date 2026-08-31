// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppButton extends StatelessWidget {
  const OrbitAppButton({
    super.key,
    required this.label,
    this.icon,
    this.intent = OrbitActionIntent.secondary,
    required this.onPressed,
    this.expand = false,
    this.loading = false,
  });
  final String label;
  final String? icon;
  final OrbitActionIntent intent;
  final VoidCallback? onPressed;
  final bool expand;
  final bool loading;
  @override
  Widget build(BuildContext context) => OrbitButton(
    label: label,
    variant: switch (intent) {
      OrbitActionIntent.primary => OrbitButtonVariant.primary,
      OrbitActionIntent.secondary => OrbitButtonVariant.secondary,
      OrbitActionIntent.tertiary => OrbitButtonVariant.ghost,
      OrbitActionIntent.destructive => OrbitButtonVariant.destructive,
    },
    onPressed: loading ? null : onPressed,
    expand: expand,
    leading: loading
        ? const OrbitAppSpinner(size: 14)
        : icon == null
        ? null
        : OrbitAppIcon(icon: icon!),
  );
}

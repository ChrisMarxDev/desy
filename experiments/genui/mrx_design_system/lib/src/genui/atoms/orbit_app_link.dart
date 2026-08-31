// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppLink extends StatelessWidget {
  const OrbitAppLink({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Pressable(
    enabled: onPressed != null,
    semanticButtonLabel: label,
    onPress: onPressed,
    child: StyledText(
      label,
      style: TextStyler()
          .style(TextStyleMix.value(OrbitType.body(context)))
          .color(OrbitTheme.of(context).colors.info)
          .decoration(TextDecoration.underline),
    ),
  );
}

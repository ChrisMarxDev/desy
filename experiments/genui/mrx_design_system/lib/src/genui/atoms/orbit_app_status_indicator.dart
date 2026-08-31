// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppStatusIndicator extends StatelessWidget {
  const OrbitAppStatusIndicator({super.key, required this.state, this.label});
  final OrbitSemanticTone state;
  final String? label;
  @override
  Widget build(BuildContext context) => OrbitAppBadge(
    label: label ?? state.name,
    tone: state,
    icon: _toneIcon(state),
  );
}

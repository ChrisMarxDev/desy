// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppToast extends StatelessWidget {
  const OrbitAppToast({
    super.key,
    required this.message,
    this.tone = OrbitSemanticTone.info,
  });
  final String message;
  final OrbitSemanticTone tone;
  @override
  Widget build(BuildContext context) => OrbitAppAlert(
    title: tone.name.toUpperCase(),
    detail: message,
    tone: tone,
  );
}

/// Private composition vocabulary. These stay out of the model catalog.

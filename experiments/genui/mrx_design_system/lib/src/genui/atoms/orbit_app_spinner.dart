// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppSpinner extends StatelessWidget {
  const OrbitAppSpinner({super.key, this.size = 18});
  final double size;
  @override
  Widget build(BuildContext context) => OrbitSpinner(size: size);
}

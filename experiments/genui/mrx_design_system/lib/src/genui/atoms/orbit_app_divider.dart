// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppDivider extends StatelessWidget {
  const OrbitAppDivider({super.key, this.indent = 0});
  final double indent;
  @override
  Widget build(BuildContext context) => OrbitDivider(indent: indent);
}

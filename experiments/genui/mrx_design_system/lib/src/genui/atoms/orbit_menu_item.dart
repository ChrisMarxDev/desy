// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitMenuItem {
  const OrbitMenuItem({
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool destructive;
}

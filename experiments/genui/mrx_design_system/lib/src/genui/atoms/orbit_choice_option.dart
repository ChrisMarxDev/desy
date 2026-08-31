// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitChoiceOption {
  const OrbitChoiceOption({
    required this.id,
    required this.label,
    this.description,
    this.shortcut,
  });
  final String id;
  final String label;
  final String? description;
  final String? shortcut;
}

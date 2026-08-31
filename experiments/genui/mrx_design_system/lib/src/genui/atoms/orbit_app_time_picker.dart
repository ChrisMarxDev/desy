// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppTimePicker extends OrbitAppTextField {
  const OrbitAppTimePicker({
    super.key,
    required super.label,
    required super.value,
    required super.onChanged,
    super.enabled = true,
  }) : super(type: OrbitInputType.text, placeholder: 'HH:MM');
}

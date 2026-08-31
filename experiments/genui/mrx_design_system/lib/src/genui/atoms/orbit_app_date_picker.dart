// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppDatePicker extends OrbitAppTextField {
  const OrbitAppDatePicker({
    super.key,
    required super.label,
    required super.value,
    required super.onChanged,
    super.enabled = true,
  }) : super(type: OrbitInputType.text, placeholder: 'YYYY-MM-DD');
}

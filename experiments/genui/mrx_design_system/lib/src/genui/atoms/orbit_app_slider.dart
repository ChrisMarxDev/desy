// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppSlider extends StatelessWidget {
  const OrbitAppSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.onChanged,
    this.enabled = true,
  });
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double>? onChanged;
  final bool enabled;
  @override
  Widget build(BuildContext context) => CupertinoSlider(
    value: value.clamp(min, max),
    min: min,
    max: max,
    divisions: ((max - min) / step).round().clamp(1, 1000),
    activeColor: OrbitTheme.of(context).colors.info,
    thumbColor: OrbitTheme.of(context).colors.primary,
    onChanged: enabled ? onChanged : null,
  );
}

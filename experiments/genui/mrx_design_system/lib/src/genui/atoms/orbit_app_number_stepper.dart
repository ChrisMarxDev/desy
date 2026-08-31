// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppNumberStepper extends StatelessWidget {
  const OrbitAppNumberStepper({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    this.unit,
  });
  final double value;
  final double min;
  final double max;
  final double step;
  final String? unit;
  final ValueChanged<double>? onChanged;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      OrbitAppIconButton(
        label: 'Decrease',
        icon: 'minus',
        onPressed: value <= min
            ? null
            : () => onChanged?.call((value - step).clamp(min, max)),
      ),
      Expanded(
        child: OrbitAppText(
          '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}${unit == null ? '' : ' $unit'}',
          role: OrbitTextRole.value,
          textAlign: TextAlign.center,
        ),
      ),
      OrbitAppIconButton(
        label: 'Increase',
        icon: 'add',
        onPressed: value >= max
            ? null
            : () => onChanged?.call((value + step).clamp(min, max)),
      ),
    ],
  );
}

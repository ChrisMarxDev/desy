// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/widgets.dart';

import '../../device_preview.dart';
import '../workbench_session.dart';

/// Builds the Canvas and Media query segments for a details sheet.
///
/// These are segments of the component-details sheet, not a separate
/// accessibility panel or component.
List<DesyKnobSegment> buildPreviewEnvironmentSegments({
  required DesyPreviewAccessibilitySettings settings,
  required ValueChanged<DesyPreviewAccessibilitySettings> onChanged,
  required DesyDevicePreset? selectedDevice,
  required ValueChanged<DesyDevicePreset?> onDeviceChanged,
}) => [
  DesyKnobSegment(
    title: 'CANVAS',
    children: [
      DesyKnobRow(
        label: 'Canvas size',
        expandControl: true,
        control: DesySelect<_PreviewFrame>.rich(
          key: const ValueKey('preview-frame-select'),
          size: DesySelectSize.sm,
          control: DesySelectControl.lifted(
            value: _PreviewFrame.fromDevice(selectedDevice),
            onChange: (frame) {
              if (frame != null) onDeviceChanged(frame.device);
            },
          ),
          format: (frame) => frame.label,
          children: [
            for (final frame in _PreviewFrame.values)
              DesySelectItem.item(
                key: ValueKey('preview-frame-${frame.name}'),
                value: frame,
                title: Text(frame.label),
              ),
          ],
        ),
      ),
    ],
  ),
  DesyKnobSegment(
    title: 'ACCESSIBILITY',
    children: [
      DesyNumericKnobRow(
        label: 'Text scale',
        value: settings.textScale,
        unit: '×',
        step: .1,
        minimum: .8,
        maximum: 2,
        onChanged: (value) => onChanged(settings.copyWith(textScale: value)),
      ),
      DesyKnobRow(
        label: 'Text direction',
        control: DesyButton(
          size: DesyButtonSize.xs,
          variant: DesyButtonVariant.outline,
          semanticsLabel:
              'Use ${settings.textDirection == TextDirection.ltr ? 'right-to-left' : 'left-to-right'} text direction',
          onPress: () => onChanged(
            settings.copyWith(
              textDirection: settings.textDirection == TextDirection.ltr
                  ? TextDirection.rtl
                  : TextDirection.ltr,
            ),
          ),
          child: Text(
            settings.textDirection == TextDirection.ltr ? 'LTR' : 'RTL',
          ),
        ),
      ),
      DesyBooleanKnobRow(
        label: 'Bold text',
        value: settings.boldText,
        onChanged: (value) => onChanged(settings.copyWith(boldText: value)),
      ),
      DesyBooleanKnobRow(
        label: 'High contrast',
        value: settings.highContrast,
        onChanged: (value) => onChanged(settings.copyWith(highContrast: value)),
      ),
      DesyBooleanKnobRow(
        label: 'Reduce motion',
        value: settings.disableAnimations,
        onChanged: (value) =>
            onChanged(settings.copyWith(disableAnimations: value)),
      ),
      DesyBooleanKnobRow(
        label: 'Semantic labels',
        value: settings.showSemantics,
        onChanged: (value) =>
            onChanged(settings.copyWith(showSemantics: value)),
      ),
      DesyBooleanKnobRow(
        label: 'Hit targets',
        value: settings.showHitTargets,
        onChanged: (value) =>
            onChanged(settings.copyWith(showHitTargets: value)),
      ),
    ],
  ),
];

enum _PreviewFrame {
  responsive('Responsive', null),
  iPhone15Pro('iPhone 15 Pro', DesyDevicePreset.iPhone15Pro),
  iPadPro11('iPad Pro 11', DesyDevicePreset.iPadPro11);

  const _PreviewFrame(this.label, this.device);

  final String label;
  final DesyDevicePreset? device;

  static _PreviewFrame fromDevice(DesyDevicePreset? device) => switch (device) {
    DesyDevicePreset.iPhone15Pro => _PreviewFrame.iPhone15Pro,
    DesyDevicePreset.iPadPro11 => _PreviewFrame.iPadPro11,
    null => _PreviewFrame.responsive,
  };
}

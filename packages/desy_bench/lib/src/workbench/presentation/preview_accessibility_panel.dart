// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/widgets.dart';

import '../../device_preview.dart';
import '../workbench_session.dart';

/// Compact preview-only environmental checks below the component controls.
class DesyPreviewAccessibilityPanel extends StatelessWidget {
  const DesyPreviewAccessibilityPanel({
    super.key,
    required this.settings,
    required this.onChanged,
    required this.selectedDevice,
    required this.onDeviceChanged,
  });

  final DesyPreviewAccessibilitySettings settings;
  final ValueChanged<DesyPreviewAccessibilitySettings> onChanged;
  final DesyDevicePreset? selectedDevice;
  final ValueChanged<DesyDevicePreset?> onDeviceChanged;

  @override
  Widget build(BuildContext context) => DesyKnobSheet(
    title: 'Accessibility',
    subtitle: 'Preview environment only',
    sections: [
      DesyKnobSection(
        label: 'CANVAS',
        children: [
          DesyKnobRow(
            label: 'Preview frame',
            description:
                'View the component responsively or inside a device bezel.',
            expandControl: true,
            control: Wrap(
              spacing: DesyDesignSystemTokens.spaceXs,
              runSpacing: DesyDesignSystemTokens.spaceXs,
              children: [
                _DeviceButton(
                  label: 'Responsive',
                  device: null,
                  selectedDevice: selectedDevice,
                  onChanged: onDeviceChanged,
                ),
                _DeviceButton(
                  label: 'iPhone 15 Pro',
                  device: DesyDevicePreset.iPhone15Pro,
                  selectedDevice: selectedDevice,
                  onChanged: onDeviceChanged,
                ),
                _DeviceButton(
                  label: 'iPad Pro 11',
                  device: DesyDevicePreset.iPadPro11,
                  selectedDevice: selectedDevice,
                  onChanged: onDeviceChanged,
                ),
              ],
            ),
          ),
        ],
      ),
      DesyKnobSection(
        label: 'MEDIA QUERY',
        children: [
          DesyNumericKnobRow(
            label: 'Text scale',
            description: 'Scale text in the consumer preview.',
            value: settings.textScale,
            unit: '×',
            step: .1,
            minimum: .8,
            maximum: 2,
            onChanged: (value) =>
                onChanged(settings.copyWith(textScale: value)),
          ),
          DesyKnobRow(
            label: 'Text direction',
            description: 'Check bidirectional layout.',
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
            onChanged: (value) =>
                onChanged(settings.copyWith(highContrast: value)),
          ),
          DesyBooleanKnobRow(
            label: 'Reduce motion',
            value: settings.disableAnimations,
            onChanged: (value) =>
                onChanged(settings.copyWith(disableAnimations: value)),
          ),
          DesyBooleanKnobRow(
            label: 'Semantic labels',
            description: 'Reveal Flutter semantic regions and labels.',
            value: settings.showSemantics,
            onChanged: (value) =>
                onChanged(settings.copyWith(showSemantics: value)),
          ),
          DesyBooleanKnobRow(
            label: 'Hit targets',
            description:
                'Green is at least 44 dp; red is smaller; pink has no label.',
            value: settings.showHitTargets,
            onChanged: (value) =>
                onChanged(settings.copyWith(showHitTargets: value)),
          ),
        ],
      ),
    ],
  );
}

class _DeviceButton extends StatelessWidget {
  const _DeviceButton({
    required this.label,
    required this.device,
    required this.selectedDevice,
    required this.onChanged,
  });

  final String label;
  final DesyDevicePreset? device;
  final DesyDevicePreset? selectedDevice;
  final ValueChanged<DesyDevicePreset?> onChanged;

  @override
  Widget build(BuildContext context) => DesyButton(
    size: DesyButtonSize.xs,
    mainAxisSize: MainAxisSize.min,
    variant: selectedDevice == device
        ? DesyButtonVariant.primary
        : DesyButtonVariant.outline,
    onPress: () => onChanged(device),
    child: Text(label),
  );
}

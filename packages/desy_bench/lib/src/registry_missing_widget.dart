import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';

/// Builds Desy's interactive diagnostic for an unresolved registry link.
///
/// This helper stays internal to `desy_bench`; consumers receive it only as
/// the result of `DesyRegistryWidgetBuilder.build` through the public registry
/// contract.
Widget buildDesyMissingRegistryWidget({
  required String registryName,
  required String instanceId,
}) => _DesyMissingRegistryWidget(
  registryName: registryName,
  instanceId: instanceId,
);

class _DesyMissingRegistryWidget extends StatelessWidget {
  const _DesyMissingRegistryWidget({
    required this.registryName,
    required this.instanceId,
  });

  final String registryName;
  final String instanceId;

  @override
  Widget build(BuildContext context) => DesyButton(
    key: ValueKey('missing-component-instance-$instanceId'),
    semanticsLabel: 'Missing component instance $instanceId',
    semanticsTooltip: 'Show missing instance details',
    variant: DesyButtonVariant.outline,
    size: DesyButtonSize.xs,
    mainAxisSize: MainAxisSize.min,
    onPress: () => _showDetails(context),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          DesyIcons.triangleAlert,
          size: 16,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: DesyDesignSystemTokens.spaceSm),
        Text(
          'Missing instance',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
    ),
  );

  Future<void> _showDetails(BuildContext context) => showDesyDialog<void>(
    context: context,
    barrierLabel: 'Dismiss missing component instance details',
    builder: (dialogContext, _, animation) => DesyDialog(
      animation: animation,
      semanticsLabel: 'Missing component instance details',
      constraints: const BoxConstraints(maxWidth: 480),
      builder: (context, style) => Padding(
        padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  DesyIcons.triangleAlert,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: DesyDesignSystemTokens.spaceSm),
                Expanded(
                  child: Text(
                    'Missing component instance',
                    style: style.titleTextStyle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesyDesignSystemTokens.spaceMd),
            Text(
              'Desy could not resolve a component instance referenced by a '
              'widget slot in the “$registryName” registry.',
              style: style.bodyTextStyle,
            ),
            const SizedBox(height: DesyDesignSystemTokens.spaceLg),
            Text(
              'Referenced ID',
              style: style.bodyTextStyle.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: DesyDesignSystemTokens.spaceXs),
            SelectionArea(
              child: Text(
                instanceId,
                key: const ValueKey('missing-component-instance-id'),
                style: style.bodyTextStyle,
              ),
            ),
            const SizedBox(height: DesyDesignSystemTokens.spaceLg),
            Text(
              'How to fix it',
              style: style.bodyTextStyle.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: DesyDesignSystemTokens.spaceXs),
            Text(
              'Check the DesyComponentKnob option and ensure a component '
              'declares an instance whose registry-scoped ID matches exactly. '
              'Registry validation reports the same broken link at startup.',
              style: style.bodyTextStyle,
            ),
            const SizedBox(height: DesyDesignSystemTokens.spaceLg),
            Align(
              alignment: Alignment.centerRight,
              child: DesyButton(
                onPress: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

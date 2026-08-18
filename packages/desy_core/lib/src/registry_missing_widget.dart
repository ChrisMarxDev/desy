import 'package:flutter/material.dart';

/// Builds a neutral interactive diagnostic for an unresolved registry link.
///
/// Registry resolution belongs to `desy_core`, so this fallback deliberately
/// uses only Flutter Material widgets. Workbench presentation never leaks into
/// the consumer registry contract.
Widget buildDesyMissingRegistryWidget({
  required String registryName,
  required String instanceId,
}) => Semantics(
  label: 'Missing component instance $instanceId',
  tooltip: 'Show missing instance details',
  button: true,
  child: Builder(
    builder: (context) => OutlinedButton.icon(
      key: ValueKey('missing-component-instance-$instanceId'),
      icon: Icon(
        Icons.warning_amber_rounded,
        size: 16,
        color: Theme.of(context).colorScheme.error,
      ),
      label: Text(
        'Missing instance',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      onPressed: () => showDialog<void>(
        context: context,
        barrierLabel: 'Dismiss missing component instance details',
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Missing component instance')),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Desy could not resolve a component instance referenced by a '
                  'widget slot in the “$registryName” registry.',
                ),
                const SizedBox(height: 20),
                const Text(
                  'Referenced ID',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                SelectionArea(
                  child: Text(
                    instanceId,
                    key: const ValueKey('missing-component-instance-id'),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'How to fix it',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Check the widget-instance knob value and ensure a component '
                  'declares an instance whose registry-scoped ID matches exactly. '
                  'Registry validation reports the same broken link at startup.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    ),
  ),
);

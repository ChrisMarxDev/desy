import 'package:desy_bench/desy_bench.dart';
import 'package:flutter/material.dart';
import 'package:desy_design_system/desy_design_system.dart';

/// A deliberately non-exporting first slice of a screenshot recipe builder.
///
/// It proves the extension boundary with registry-derived choices only. Image
/// capture and recipe persistence will be added after the workflow is shaped.
class DesyScreenshotBuilderExtension extends DesyWorkspaceExtension {
  /// Creates the experimental screenshot-builder extension.
  const DesyScreenshotBuilderExtension();

  @override
  String get id => 'screenshot-builder';

  @override
  String get name => 'Screenshot builder';

  @override
  IconData get icon => DesyIcons.camera;

  @override
  String get description => 'Compose a repeatable capture recipe.';

  @override
  Widget build(
    BuildContext context,
    DesyWorkspaceExtensionContext extension,
  ) => Padding(
    padding: const EdgeInsets.all(28),
    child: ListView(
      children: [
        DesyBadge(child: const Text('EXPERIMENTAL')),
        const SizedBox(height: 12),
        Text(
          'Screenshot builder',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Capture recipes will be derived from your declared components and active preview context.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        DesyCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recipe draft',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text('Theme · ${extension.activeTheme.name}'),
                Text(
                  '${extension.registry.allComponents.length} declared components',
                ),
                const SizedBox(height: 16),
                DesyButton(
                  size: DesyButtonSize.xs,
                  mainAxisSize: MainAxisSize.min,
                  variant: DesyButtonVariant.outline,
                  onPress: () {},
                  child: const Text('Capture coming soon'),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

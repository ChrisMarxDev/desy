import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import 'desy_button.dart';
import 'desy_design_system_scope.dart';
import 'desy_icons.dart';

/// Shared zoom control used by Desy-owned canvas surfaces.
class DesyZoomDock extends StatelessWidget {
  /// Creates a compact `- 100% +` zoom dock.
  const DesyZoomDock({
    super.key,
    required this.keyPrefix,
    required this.zoom,
    required this.onZoomOut,
    required this.onZoomIn,
  });

  /// Prefix used for stable child keys.
  final String keyPrefix;

  /// Current zoom as a scale value where `1` means 100%.
  final double zoom;

  /// Called when the user requests a smaller zoom.
  final VoidCallback onZoomOut;

  /// Called when the user requests a larger zoom.
  final VoidCallback onZoomIn;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.theme.colors.background.withValues(alpha: .92),
      border: Border.all(color: context.theme.colors.border),
      borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusMd),
    ),
    child: Padding(
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesyButton.icon(
            key: ValueKey('$keyPrefix-zoom-out'),
            variant: DesyButtonVariant.ghost,
            size: DesyButtonSize.xs,
            onPress: onZoomOut,
            semanticsLabel: 'Zoom out',
            child: const Icon(DesyIcons.minus, size: 14),
          ),
          Semantics(
            key: ValueKey('$keyPrefix-zoom-level'),
            label: 'Zoom ${(zoom * 100).round()} percent',
            child: SizedBox(
              width: 42,
              child: Text(
                '${(zoom * 100).round()}%',
                textAlign: TextAlign.center,
                style: context.theme.typography.body.xs.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          DesyButton.icon(
            key: ValueKey('$keyPrefix-zoom-in'),
            variant: DesyButtonVariant.ghost,
            size: DesyButtonSize.xs,
            onPress: onZoomIn,
            semanticsLabel: 'Zoom in',
            child: const Icon(DesyIcons.plus, size: 14),
          ),
        ],
      ),
    ),
  );
}

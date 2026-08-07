import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import 'desy_design_system_scope.dart';

/// A compact, semantic display of one keyboard shortcut.
class DesyKeyboardShortcutLabel extends StatelessWidget {
  /// Creates a shortcut label from the keys in one shortcut.
  const DesyKeyboardShortcutLabel({
    super.key,
    required this.keys,
    this.semanticLabel,
  });

  /// The visual keycaps that form the shortcut, in reading order.
  final List<String> keys;

  /// A descriptive label announced by assistive technology.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Semantics(
      label: semanticLabel ?? 'Keyboard shortcut: ${keys.join(' plus ')}',
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 3,
          runSpacing: 3,
          children: [
            for (final key in keys)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.card,
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(
                    DesyDesignSystemTokens.radiusSm,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  child: Text(
                    key,
                    style: TextStyle(
                      color: colors.mutedForeground,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

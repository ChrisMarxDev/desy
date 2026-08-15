import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import 'desy_design_system_scope.dart';

/// A catalogue surface that separates a real component preview from its
/// durable registry identity.
class DesyCatalogueCard extends StatelessWidget {
  /// Creates a catalogue card.
  const DesyCatalogueCard({
    super.key,
    required this.path,
    required this.identifier,
    required this.preview,
  });

  /// The concise registry path shown as low-emphasis orientation metadata.
  final String path;

  /// The stable registry identity shown below the preview region.
  final String identifier;

  /// The real consumer widget preview, already prepared for this surface.
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typeface = context.theme.typography.body;
    return FCard(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DesyDesignSystemTokens.spaceMd,
                DesyDesignSystemTokens.spaceMd,
                DesyDesignSystemTokens.spaceMd,
                DesyDesignSystemTokens.spaceSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    path,
                    key: const ValueKey('desy-catalogue-card-path'),
                    style: typeface.xs2.copyWith(
                      color: colors.mutedForeground,
                      letterSpacing: .4,
                    ),
                  ),
                  const SizedBox(height: DesyDesignSystemTokens.spaceSm),
                  Expanded(child: preview),
                ],
              ),
            ),
          ),
          ColoredBox(
            key: const ValueKey('desy-catalogue-card-divider'),
            color: colors.border,
            child: const SizedBox(height: 1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesyDesignSystemTokens.spaceMd,
              DesyDesignSystemTokens.spaceSm,
              DesyDesignSystemTokens.spaceMd,
              DesyDesignSystemTokens.spaceMd,
            ),
            child: SelectableText(
              identifier,
              key: const ValueKey('desy-catalogue-card-identifier'),
              style: typeface.xs.copyWith(color: colors.foreground),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';

/// The shared right-hand control surface for canvas hosts.
///
/// Hosts provide their own scrollable content. This surface deliberately owns
/// only the consistent full-height edge treatment, arrival motion, and optional
/// collapse affordance so Details and Prototypes do not drift apart.
class DesyWorkbenchControlSheet extends StatelessWidget {
  const DesyWorkbenchControlSheet({
    super.key,
    required this.visible,
    required this.child,
    this.header,
    this.onClose,
    this.closeKey,
  });

  final bool visible;
  final Widget child;
  final Widget? header;
  final VoidCallback? onClose;
  final Key? closeKey;

  @override
  Widget build(BuildContext context) {
    final shown = visible;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: shown ? Offset.zero : const Offset(1.1, 0),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: shown ? 1 : 0,
          duration: const Duration(milliseconds: 120),
          alwaysIncludeSemantics: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.theme.colors.background,
              border: Border(
                left: BorderSide(color: context.theme.colors.border),
              ),
            ),
            child: Column(
              children: [
                if (header != null || onClose != null)
                  SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        if (header case final header?)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: DefaultTextStyle.merge(
                              style: context.theme.typography.body.sm.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              child: header,
                            ),
                          ),
                        const Spacer(),
                        if (onClose case final onClose?)
                          DesyButton.icon(
                            key: closeKey,
                            variant: DesyButtonVariant.ghost,
                            size: DesyButtonSize.md,
                            onPress: onClose,
                            semanticsLabel: 'Collapse details sidebar',
                            semanticsTooltip: 'Collapse details sidebar',
                            child: const Icon(
                              DesyIcons.panelRightClose,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

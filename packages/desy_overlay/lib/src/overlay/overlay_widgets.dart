import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../desy_annotation.dart';

const desyInspectionSignalColor = Color(0xFFFF2D8D);
const _inspectionSignalForeground = Color(0xFF18000C);

/// Applies self-contained Desy typography to consumer-embedded chrome.
class DesyOverlayChrome extends StatelessWidget {
  const DesyOverlayChrome({
    super.key,
    required this.theme,
    required this.child,
  });

  final DesyDesignSystemTheme theme;
  final Widget child;

  @override
  Widget build(BuildContext context) => DesyDesignSystemThemeScope(
    theme: theme,
    child: Builder(
      builder: (context) => DefaultTextStyle(
        key: const ValueKey('desy-overlay-default-text-style'),
        style: context.theme.typography.body.sm.copyWith(
          color: context.theme.colors.foreground,
        ),
        child: child,
      ),
    ),
  );
}

/// Persistent launcher for entering or leaving selection mode.
class DesyOverlayControls extends StatelessWidget {
  const DesyOverlayControls({
    super.key,
    required this.selecting,
    required this.touchMode,
    required this.onToggleSelecting,
  });

  final bool selecting;
  final bool touchMode;
  final VoidCallback onToggleSelecting;

  @override
  Widget build(BuildContext context) => Row(
    key: const ValueKey('desy-overlay-controls'),
    mainAxisSize: MainAxisSize.min,
    children: [
      Semantics(
        button: true,
        label: selecting ? 'Cancel component selection' : 'Select a component',
        child: SizedBox.square(
          dimension: touchMode ? 48 : 28,
          child: DesyButton(
            key: const ValueKey('desy-overlay-select'),
            size: touchMode ? DesyButtonSize.lg : DesyButtonSize.sm,
            variant: selecting
                ? DesyButtonVariant.primary
                : DesyButtonVariant.outline,
            mainAxisSize: MainAxisSize.min,
            onPress: onToggleSelecting,
            child: Icon(DesyIcons.crosshair, size: touchMode ? 20 : 17),
          ),
        ),
      ),
    ],
  );
}

/// Compact instruction shown while the full-screen selector is active.
class DesySelectionPrompt extends StatelessWidget {
  const DesySelectionPrompt({super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const ValueKey('desy-overlay-selection-prompt'),
    decoration: BoxDecoration(
      color: context.theme.colors.background,
      border: Border.all(color: desyInspectionSignalColor),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(DesyIcons.crosshair, size: 14),
          const SizedBox(width: 6),
          Text('Select a component', style: context.theme.typography.body.xs),
        ],
      ),
    ),
  );
}

/// Draggable feedback editor for one selected consumer widget.
class DesyAnnotationCard extends StatelessWidget {
  const DesyAnnotationCard({
    super.key,
    required this.target,
    required this.comment,
    required this.error,
    required this.submitting,
    required this.touchMode,
    required this.compact,
    required this.commentFocusNode,
    required this.onClose,
    required this.onDragDelta,
    required this.onCommentChanged,
    required this.onSubmit,
  });

  final DesyWidgetTarget target;
  final String comment;
  final String? error;
  final bool submitting;
  final bool touchMode;
  final bool compact;
  final FocusNode commentFocusNode;
  final VoidCallback onClose;
  final ValueChanged<Offset> onDragDelta;
  final ValueChanged<String> onCommentChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final canSubmit = comment.trim().isNotEmpty && !submitting;
    final location = target.sourceLocation?.toString() ?? target.widgetPath;
    final buttonSize = touchMode ? DesyButtonSize.lg : DesyButtonSize.sm;
    return GestureDetector(
      key: const ValueKey('desy-overlay-drag-handle'),
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) => onDragDelta(details.delta),
      child: DesyCard(
        key: const ValueKey('desy-overlay-annotation-card'),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.all(
            compact
                ? DesyDesignSystemTokens.spaceSm
                : touchMode
                ? DesyDesignSystemTokens.spaceBase
                : DesyDesignSystemTokens.spaceMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: compact ? 4 : 10),
                child: Row(
                  children: [
                    Expanded(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.move,
                        child: Row(
                          children: [
                            const Icon(DesyIcons.messageSquare, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                target.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: typography.body.sm,
                              ),
                            ),
                            if (!compact)
                              Text(
                                '${target.identitySignals.length} signals',
                                style: typography.body.xs.copyWith(
                                  color: colors.mutedForeground,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: DesyDesignSystemTokens.spaceSm),
                    Semantics(
                      button: true,
                      label: 'Close annotation',
                      child: SizedBox.square(
                        dimension: touchMode ? 44 : 28,
                        child: DesyButton(
                          key: const ValueKey('desy-overlay-close'),
                          size: buttonSize,
                          variant: DesyButtonVariant.ghost,
                          mainAxisSize: MainAxisSize.min,
                          onPress: onClose,
                          child: const Icon(DesyIcons.x, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact)
                Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                    fontFamily: 'monospace',
                  ),
                ),
              SizedBox(
                height: compact
                    ? DesyDesignSystemTokens.spaceXs
                    : DesyDesignSystemTokens.spaceSm,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.background,
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(
                    DesyDesignSystemTokens.radiusMd,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(
                    compact
                        ? DesyDesignSystemTokens.spaceXs
                        : DesyDesignSystemTokens.spaceSm,
                  ),
                  child: DesyOverlayTextField(
                    key: const ValueKey('desy-overlay-comment'),
                    value: comment,
                    focusNode: commentFocusNode,
                    enabled: !submitting,
                    touchMode: touchMode,
                    compact: compact,
                    onChanged: onCommentChanged,
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: DesyDesignSystemTokens.spaceSm),
                Text(
                  error!,
                  style: typography.body.xs.copyWith(color: colors.destructive),
                ),
              ],
              SizedBox(
                height: compact
                    ? DesyDesignSystemTokens.spaceXs
                    : DesyDesignSystemTokens.spaceSm,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: touchMode ? 44 : 28),
                  child: DesyButton(
                    key: const ValueKey('desy-overlay-submit'),
                    size: buttonSize,
                    mainAxisSize: MainAxisSize.min,
                    onPress: canSubmit ? onSubmit : null,
                    child: Text(submitting ? 'Sending…' : 'Send feedback'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Framework-level editor that does not require Material localizations.
class DesyOverlayTextField extends StatefulWidget {
  const DesyOverlayTextField({
    super.key,
    required this.value,
    required this.focusNode,
    required this.enabled,
    required this.touchMode,
    required this.compact,
    required this.onChanged,
  });

  final String value;
  final FocusNode focusNode;
  final bool enabled;
  final bool touchMode;
  final bool compact;
  final ValueChanged<String> onChanged;

  @override
  State<DesyOverlayTextField> createState() => _DesyOverlayTextFieldState();
}

class _DesyOverlayTextFieldState extends State<DesyOverlayTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(covariant DesyOverlayTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == _controller.text) return;
    _controller.value = TextEditingValue(
      text: widget.value,
      selection: TextSelection.collapsed(offset: widget.value.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final textStyle = context.theme.typography.body.sm.copyWith(
      color: colors.foreground,
      height: 1.25,
    );

    return Semantics(
      container: true,
      textField: true,
      label: 'Design feedback',
      hint: 'What should change?',
      enabled: widget.enabled,
      child: Stack(
        children: [
          if (_controller.text.isEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: Text(
                  'What should change?',
                  style: textStyle.copyWith(color: colors.mutedForeground),
                ),
              ),
            ),
          EditableText(
            controller: _controller,
            focusNode: widget.focusNode,
            readOnly: !widget.enabled,
            maxLines: widget.compact
                ? 2
                : widget.touchMode
                ? 4
                : 6,
            minLines: widget.compact
                ? 1
                : widget.touchMode
                ? 2
                : 3,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            style: textStyle,
            cursorColor: colors.desy.signal,
            backgroundCursorColor: colors.mutedForeground,
            selectionColor: colors.desy.signal.withValues(alpha: .22),
            onChanged: widget.onChanged,
          ),
        ],
      ),
    );
  }
}

/// Label positioned next to the selected consumer widget.
class DesySelectionLabel extends StatelessWidget {
  const DesySelectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Selected widget $label',
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: desyInspectionSignalColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _inspectionSignalForeground,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    ),
  );
}

/// Framework canvas painter for the selected widget outline.
class DesySelectionOutlinePainter extends CustomPainter {
  const DesySelectionOutlinePainter({required this.bounds});

  final Rect bounds;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      bounds,
      Paint()..color = desyInspectionSignalColor.withValues(alpha: .03),
    );
    canvas.drawRect(
      bounds.deflate(.5),
      Paint()
        ..color = desyInspectionSignalColor.withValues(alpha: .45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final handles = Paint()
      ..color = desyInspectionSignalColor.withValues(alpha: .55);
    for (final point in [
      bounds.topLeft,
      bounds.topRight,
      bounds.bottomLeft,
      bounds.bottomRight,
    ]) {
      canvas.drawCircle(point, 1.75, handles);
    }
  }

  @override
  bool shouldRepaint(covariant DesySelectionOutlinePainter oldDelegate) =>
      oldDelegate.bounds != bounds;
}

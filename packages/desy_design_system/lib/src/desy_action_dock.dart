import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'desy_visual_tokens.dart';
import 'keyboard_shortcut_label.dart';

/// One command shown in a [DesyActionDock].
@immutable
class DesyActionDockAction {
  /// Creates an action-dock command.
  const DesyActionDockAction({
    required this.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.onPressed,
    this.shortcutKeys = const [],
    this.selected = false,
    this.semanticsLabel,
  });

  /// Stable widget key for this command.
  final Key key;

  /// Visual glyph for the square command button.
  final IconData icon;

  /// Short command label.
  final String label;

  /// Functional description shown in the floating label and tooltip.
  final String description;

  /// Visible shortcut keycaps. Pass only shortcuts the host implements.
  final List<String> shortcutKeys;

  /// Whether this command represents the current mode/state.
  final bool selected;

  /// Called when the command is activated.
  final VoidCallback? onPressed;

  /// Optional accessible label override.
  final String? semanticsLabel;
}

/// A visually separated command class inside [DesyActionDock].
@immutable
class DesyActionDockGroup {
  /// Creates one labelled action group.
  const DesyActionDockGroup({required this.label, required this.actions});

  /// Small descriptor shown above this group.
  final String label;

  /// Commands in reading order.
  final List<DesyActionDockAction> actions;
}

/// Compact floating command dock for Desy canvas surfaces.
class DesyActionDock extends StatefulWidget {
  /// Creates a grouped bottom action dock.
  const DesyActionDock({super.key, required this.groups, this.buttonSize = 42});

  /// Action groups separated by vertical dividers.
  final List<DesyActionDockGroup> groups;

  /// Square button side length.
  final double buttonSize;

  @override
  State<DesyActionDock> createState() => _DesyActionDockState();
}

class _DesyActionDockState extends State<DesyActionDock> {
  DesyActionDockAction? _hoveredAction;

  void _setHovered(DesyActionDockAction? action) =>
      setState(() => _hoveredAction = action);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FloatingActionDockLabel(action: _hoveredAction),
        const SizedBox(height: 8),
        _ActionDockSurface(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < widget.groups.length; index++) ...[
                _ActionDockGroupView(
                  group: widget.groups[index],
                  buttonSize: widget.buttonSize,
                  onHover: _setHovered,
                ),
                if (index != widget.groups.length - 1)
                  const _ActionDockSeparator(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Square icon command used by [DesyActionDock].
class DesyActionDockButton extends StatefulWidget {
  /// Creates an icon-first dock button.
  const DesyActionDockButton({
    super.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.onPressed,
    this.shortcutKeys = const [],
    this.selected = false,
    this.size = 42,
    this.onHoverChanged,
    this.semanticsLabel,
  });

  /// Visual glyph centered inside the square button.
  final IconData icon;

  /// Short command label.
  final String label;

  /// Functional command description.
  final String description;

  /// Visible shortcut keycaps. Pass only shortcuts the host implements.
  final List<String> shortcutKeys;

  /// Whether this command represents the current mode/state.
  final bool selected;

  /// Square button side length.
  final double size;

  /// Called when the command is activated.
  final VoidCallback? onPressed;

  /// Reports hover changes to the surrounding dock.
  final ValueChanged<bool>? onHoverChanged;

  /// Optional accessible label override.
  final String? semanticsLabel;

  @override
  State<DesyActionDockButton> createState() => _DesyActionDockButtonState();
}

class _DesyActionDockButtonState extends State<DesyActionDockButton> {
  var _hovered = false;

  void _setHovered(bool hovered) {
    setState(() => _hovered = hovered);
    widget.onHoverChanged?.call(hovered);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final tone = colors.desy.signal;
    final borderColor = widget.selected
        ? tone
        : _hovered
        ? colors.foreground.withValues(alpha: .22)
        : colors.border;
    final background = widget.selected
        ? tone.withValues(alpha: .12)
        : _hovered
        ? colors.card
        : colors.background.withValues(alpha: .92);
    final tooltip = widget.shortcutKeys.isEmpty
        ? '${widget.label} - ${widget.description}'
        : '${widget.label} - ${widget.description} (${widget.shortcutKeys.join(' + ')})';

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 250),
      child: MouseRegion(
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: AnimatedScale(
          scale: _hovered ? 1.04 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: Semantics(
            button: true,
            label: widget.semanticsLabel ?? widget.label,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(7),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOutCubic,
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: background,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(
                    child: Icon(
                      widget.icon,
                      size: 15,
                      color: widget.selected ? tone : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionDockGroupView extends StatelessWidget {
  const _ActionDockGroupView({
    required this.group,
    required this.buttonSize,
    required this.onHover,
  });

  final DesyActionDockGroup group;
  final double buttonSize;
  final ValueChanged<DesyActionDockAction?> onHover;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Text(
            group.label,
            style: context.theme.typography.body.xs.copyWith(
              color: colors.mutedForeground,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final action in group.actions)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: DesyActionDockButton(
                  key: action.key,
                  icon: action.icon,
                  label: action.label,
                  description: action.description,
                  shortcutKeys: action.shortcutKeys,
                  selected: action.selected,
                  size: buttonSize,
                  semanticsLabel: action.semanticsLabel,
                  onPressed: action.onPressed,
                  onHoverChanged: (hovered) => onHover(hovered ? action : null),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _FloatingActionDockLabel extends StatelessWidget {
  const _FloatingActionDockLabel({required this.action});

  final DesyActionDockAction? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final action = this.action;
    return AnimatedOpacity(
      opacity: action == null ? 0 : 1,
      duration: const Duration(milliseconds: 100),
      child: action == null
          ? const SizedBox(height: 28)
          : DecoratedBox(
              decoration: BoxDecoration(
                color: colors.background,
                border: Border.all(
                  color: colors.desy.signal.withValues(alpha: .38),
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: colors.desy.signal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      action.description,
                      style: context.theme.typography.body.xs,
                    ),
                    if (action.shortcutKeys.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      DesyKeyboardShortcutLabel(keys: action.shortcutKeys),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _ActionDockSurface extends StatelessWidget {
  const _ActionDockSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: .96),
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: colors.foreground.withValues(alpha: .08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: child,
      ),
    );
  }
}

class _ActionDockSeparator extends StatelessWidget {
  const _ActionDockSeparator();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 34,
    margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
    color: context.theme.colors.border,
  );
}

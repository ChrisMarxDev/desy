// PROTOTYPE - screenshot builder action bar directions.
//
// This session explores bottom-center action bars before any direction becomes
// a stable Screenshot Builder or Desy scaffold component.

import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';

/// Real Flutter directions for the Screenshot Builder action bar.
DesyPrototypeSession
buildScreenshotActionBarPrototypeSession() => DesyPrototypeSession(
  id: 'desy.prototype-session.screenshot-action-bar',
  name: 'Screenshot action bar',
  description:
      'PROTOTYPE: six bottom action bar directions comparing shortcut visibility, function recognition, and visual grouping between selection modes, insert actions, and output commands.',
  prototypes: const [
    DesyPrototype(
      id: 'desy.prototype.screenshot-action-bar.segmented-command-bar',
      name: 'Segmented command bar',
      description:
          'Groups are labelled inside one toolbar; each action keeps icon, label, and shortcut visible.',
      canvasPlacement: DesyCanvasPlacement(
        offset: Offset(72, 96),
        size: Size(1040, 260),
      ),
      builder: _segmentedCommandBar,
    ),
    DesyPrototype(
      id: 'desy.prototype.screenshot-action-bar.floating-icon-dock',
      name: 'Floating grouped dock',
      description:
          'Icon-first controls stay compact, rail-like grouping separates action classes, and the floating label explains the active action.',
      canvasPlacement: DesyCanvasPlacement(
        offset: Offset(72, 416),
        size: Size(1040, 260),
      ),
      builder: _floatingIconDock,
    ),
    DesyPrototype(
      id: 'desy.prototype.screenshot-action-bar.group-card-shelf',
      name: 'Group card shelf',
      description:
          'Each action class gets a small card-like cluster, making hierarchy very explicit.',
      canvasPlacement: DesyCanvasPlacement(
        offset: Offset(72, 736),
        size: Size(1040, 260),
      ),
      builder: _groupCardShelf,
    ),
    DesyPrototype(
      id: 'desy.prototype.screenshot-action-bar.mode-insert-rail',
      name: 'Mode and insert rail',
      description:
          'Selection modes are treated as persistent toggles; insert and output actions sit in separate rails.',
      canvasPlacement: DesyCanvasPlacement(
        offset: Offset(72, 1056),
        size: Size(1040, 260),
      ),
      builder: _modeInsertRail,
    ),
    DesyPrototype(
      id: 'desy.prototype.screenshot-action-bar.command-palette-strip',
      name: 'Command palette strip',
      description:
          'A search-like command strip gives every action a verb, icon, and shortcut in a scanning layout.',
      canvasPlacement: DesyCanvasPlacement(
        offset: Offset(72, 1376),
        size: Size(1040, 260),
      ),
      builder: _commandPaletteStrip,
    ),
    DesyPrototype(
      id: 'desy.prototype.screenshot-action-bar.dense-pro-dock',
      name: 'Dense pro dock',
      description:
          'A compact desktop dock keeps class markers and shortcuts visible without full labels on every button.',
      canvasPlacement: DesyCanvasPlacement(
        offset: Offset(72, 1696),
        size: Size(1040, 260),
      ),
      builder: _denseProDock,
    ),
  ],
);

Widget _segmentedCommandBar(BuildContext context) =>
    const _ActionBarPrototype(direction: _ActionBarDirection.segmented);

Widget _floatingIconDock(BuildContext context) =>
    const _ActionBarPrototype(direction: _ActionBarDirection.floating);

Widget _groupCardShelf(BuildContext context) =>
    const _ActionBarPrototype(direction: _ActionBarDirection.cards);

Widget _modeInsertRail(BuildContext context) =>
    const _ActionBarPrototype(direction: _ActionBarDirection.rails);

Widget _commandPaletteStrip(BuildContext context) =>
    const _ActionBarPrototype(direction: _ActionBarDirection.palette);

Widget _denseProDock(BuildContext context) =>
    const _ActionBarPrototype(direction: _ActionBarDirection.dense);

enum _ActionBarDirection { segmented, floating, cards, rails, palette, dense }

enum _ActionClass {
  selection('Mode', 'Selection mode', DesyIcons.mousePointer),
  insert('Add', 'Insert element', DesyIcons.plus),
  output('Output', 'Create result', DesyIcons.camera);

  const _ActionClass(this.shortLabel, this.longLabel, this.icon);

  final String shortLabel;
  final String longLabel;
  final IconData icon;
}

class _ActionSpec {
  const _ActionSpec({
    required this.id,
    required this.label,
    required this.description,
    required this.shortcut,
    required this.icon,
    required this.actionClass,
  });

  final String id;
  final String label;
  final String description;
  final List<String> shortcut;
  final IconData icon;
  final _ActionClass actionClass;
}

const _actions = [
  _ActionSpec(
    id: 'select',
    label: 'Select',
    description: 'Pick and resize elements',
    shortcut: ['V'],
    icon: DesyIcons.mousePointer,
    actionClass: _ActionClass.selection,
  ),
  _ActionSpec(
    id: 'frame',
    label: 'Frame',
    description: 'Edit canvas bounds',
    shortcut: ['F'],
    icon: DesyIcons.crosshair,
    actionClass: _ActionClass.selection,
  ),
  _ActionSpec(
    id: 'text',
    label: 'Text',
    description: 'Add a text layer',
    shortcut: ['T'],
    icon: DesyIcons.type,
    actionClass: _ActionClass.insert,
  ),
  _ActionSpec(
    id: 'component',
    label: 'Component',
    description: 'Open the component catalog',
    shortcut: ['C'],
    icon: DesyIcons.component,
    actionClass: _ActionClass.insert,
  ),
  _ActionSpec(
    id: 'image',
    label: 'Image',
    description: 'Add an image layer',
    shortcut: ['I'],
    icon: DesyIcons.image,
    actionClass: _ActionClass.insert,
  ),
  _ActionSpec(
    id: 'mockup',
    label: 'Mockup',
    description: 'Add status bars and bezels',
    shortcut: ['B'],
    icon: DesyIcons.smartphone,
    actionClass: _ActionClass.insert,
  ),
  _ActionSpec(
    id: 'catalog',
    label: 'Catalog',
    description: 'Search components',
    shortcut: ['Cmd', 'K'],
    icon: DesyIcons.search,
    actionClass: _ActionClass.output,
  ),
  _ActionSpec(
    id: 'shot',
    label: 'Shot',
    description: 'Export screenshot',
    shortcut: ['Cmd', 'S'],
    icon: DesyIcons.camera,
    actionClass: _ActionClass.output,
  ),
];

class _ActionBarPrototype extends StatefulWidget {
  const _ActionBarPrototype({required this.direction});

  final _ActionBarDirection direction;

  @override
  State<_ActionBarPrototype> createState() => _ActionBarPrototypeState();
}

class _ActionBarPrototypeState extends State<_ActionBarPrototype> {
  var _selectedId = 'select';
  String? _hoveredId;

  _ActionSpec get _selectedAction =>
      _actions.firstWhere((action) => action.id == _selectedId);

  _ActionSpec? get _hoveredAction {
    final id = _hoveredId;
    if (id == null) return null;
    return _actions.firstWhere((action) => action.id == id);
  }

  void _activate(_ActionSpec action) => setState(() => _selectedId = action.id);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 1040,
    height: 260,
    child: _PrototypeStage(
      selectedAction: _selectedAction,
      child: switch (widget.direction) {
        _ActionBarDirection.segmented => _SegmentedCommandBar(
          selectedId: _selectedId,
          hoveredAction: _hoveredAction,
          onHover: (id) => setState(() => _hoveredId = id),
          onActivate: _activate,
        ),
        _ActionBarDirection.floating => _FloatingIconDock(
          selectedId: _selectedId,
          onActivate: _activate,
        ),
        _ActionBarDirection.cards => _GroupCardShelf(
          selectedId: _selectedId,
          hoveredAction: _hoveredAction,
          onHover: (id) => setState(() => _hoveredId = id),
          onActivate: _activate,
        ),
        _ActionBarDirection.rails => _ModeInsertRail(
          selectedId: _selectedId,
          hoveredAction: _hoveredAction,
          onHover: (id) => setState(() => _hoveredId = id),
          onActivate: _activate,
        ),
        _ActionBarDirection.palette => _CommandPaletteStrip(
          selectedId: _selectedId,
          hoveredAction: _hoveredAction,
          onHover: (id) => setState(() => _hoveredId = id),
          onActivate: _activate,
        ),
        _ActionBarDirection.dense => _DenseProDock(
          selectedId: _selectedId,
          hoveredAction: _hoveredAction,
          onHover: (id) => setState(() => _hoveredId = id),
          onActivate: _activate,
        ),
      },
    ),
  );
}

class _PrototypeStage extends StatelessWidget {
  const _PrototypeStage({required this.selectedAction, required this.child});

  final _ActionSpec selectedAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.desy.canvas),
      child: Stack(
        children: [
          Positioned.fill(
            child: DesyCanvasGridBackground(
              backgroundColor: colors.background,
              lineColor: colors.border.withValues(alpha: .45),
            ),
          ),
          Positioned(
            left: 64,
            top: 28,
            width: 220,
            height: 132,
            child: _MockScreenshotCard(title: 'Progress trail'),
          ),
          Positioned(
            left: 316,
            top: 42,
            width: 178,
            height: 104,
            child: _MockScreenshotCard(title: 'Team roster', muted: true),
          ),
          Positioned(
            right: 58,
            top: 30,
            child: _StatusPill(action: selectedAction),
          ),
          Positioned(left: 0, right: 0, bottom: 22, child: child),
        ],
      ),
    );
  }
}

class _MockScreenshotCard extends StatelessWidget {
  const _MockScreenshotCard({required this.title, this.muted = false});

  final String title;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: colors.foreground.withValues(alpha: .05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  muted ? DesyIcons.layers : DesyIcons.shapes,
                  size: 14,
                  color: muted ? colors.mutedForeground : colors.desy.signal,
                ),
                const SizedBox(width: 8),
                Text(title, style: context.theme.typography.body.sm),
              ],
            ),
            const Spacer(),
            Container(
              width: muted ? 96 : 144,
              height: 8,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: muted ? 132 : 88,
              height: 8,
              decoration: BoxDecoration(
                color: colors.border.withValues(alpha: .72),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.action});

  final _ActionSpec action;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final tone = _toneFor(context, action.actionClass);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ClassDot(color: tone),
            const SizedBox(width: 8),
            Text(
              '${action.actionClass.longLabel}: ${action.label}',
              style: context.theme.typography.body.xs,
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedCommandBar extends StatelessWidget {
  const _SegmentedCommandBar({
    required this.selectedId,
    required this.hoveredAction,
    required this.onHover,
    required this.onActivate,
  });

  final String selectedId;
  final _ActionSpec? hoveredAction;
  final ValueChanged<String?> onHover;
  final ValueChanged<_ActionSpec> onActivate;

  @override
  Widget build(BuildContext context) => _FloatingLabelStack(
    action: hoveredAction,
    child: _BarSurface(
      padding: const EdgeInsets.all(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final actionClass in _ActionClass.values) ...[
            _InlineGroupLabel(actionClass: actionClass),
            const SizedBox(width: 4),
            for (final action in _actionsFor(actionClass))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _ActionBarButton(
                  action: action,
                  selected: action.id == selectedId,
                  style: _ActionButtonStyle.label,
                  onHover: onHover,
                  onPressed: () => onActivate(action),
                ),
              ),
            if (actionClass != _ActionClass.values.last) const _BarSeparator(),
          ],
        ],
      ),
    ),
  );
}

class _FloatingIconDock extends StatelessWidget {
  const _FloatingIconDock({required this.selectedId, required this.onActivate});

  final String selectedId;
  final ValueChanged<_ActionSpec> onActivate;

  @override
  Widget build(BuildContext context) => DesyActionDock(
    groups: [
      for (final actionClass in _ActionClass.values)
        DesyActionDockGroup(
          label: _floatingDockLabel(actionClass),
          actions: [
            for (final action in _actionsFor(actionClass))
              DesyActionDockAction(
                key: ValueKey('prototype-floating-${action.id}'),
                icon: action.icon,
                label: action.label,
                description: action.description,
                shortcutKeys: action.shortcut,
                selected: action.id == selectedId,
                onPressed: () => onActivate(action),
              ),
          ],
        ),
    ],
  );
}

class _GroupCardShelf extends StatelessWidget {
  const _GroupCardShelf({
    required this.selectedId,
    required this.hoveredAction,
    required this.onHover,
    required this.onActivate,
  });

  final String selectedId;
  final _ActionSpec? hoveredAction;
  final ValueChanged<String?> onHover;
  final ValueChanged<_ActionSpec> onActivate;

  @override
  Widget build(BuildContext context) => _FloatingLabelStack(
    action: hoveredAction,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final actionClass in _ActionClass.values)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: _GroupCard(
              actionClass: actionClass,
              selectedId: selectedId,
              onHover: onHover,
              onActivate: onActivate,
            ),
          ),
      ],
    ),
  );
}

class _ModeInsertRail extends StatelessWidget {
  const _ModeInsertRail({
    required this.selectedId,
    required this.hoveredAction,
    required this.onHover,
    required this.onActivate,
  });

  final String selectedId;
  final _ActionSpec? hoveredAction;
  final ValueChanged<String?> onHover;
  final ValueChanged<_ActionSpec> onActivate;

  @override
  Widget build(BuildContext context) => _FloatingLabelStack(
    action: hoveredAction,
    child: _BarSurface(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RailGroup(
            label: 'Selection modes',
            actions: _actionsFor(_ActionClass.selection),
            selectedId: selectedId,
            buttonStyle: _ActionButtonStyle.mode,
            onHover: onHover,
            onActivate: onActivate,
          ),
          const _BarSeparator(),
          _RailGroup(
            label: 'Add elements',
            actions: _actionsFor(_ActionClass.insert),
            selectedId: selectedId,
            buttonStyle: _ActionButtonStyle.iconWithShortcut,
            onHover: onHover,
            onActivate: onActivate,
          ),
          const _BarSeparator(),
          _RailGroup(
            label: 'Output',
            actions: _actionsFor(_ActionClass.output),
            selectedId: selectedId,
            buttonStyle: _ActionButtonStyle.iconWithShortcut,
            onHover: onHover,
            onActivate: onActivate,
          ),
        ],
      ),
    ),
  );
}

class _CommandPaletteStrip extends StatelessWidget {
  const _CommandPaletteStrip({
    required this.selectedId,
    required this.hoveredAction,
    required this.onHover,
    required this.onActivate,
  });

  final String selectedId;
  final _ActionSpec? hoveredAction;
  final ValueChanged<String?> onHover;
  final ValueChanged<_ActionSpec> onActivate;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return _FloatingLabelStack(
      action: hoveredAction,
      child: _BarSurface(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(DesyIcons.search, size: 16, color: colors.mutedForeground),
            const SizedBox(width: 8),
            Text('Add or switch...', style: context.theme.typography.body.sm),
            const SizedBox(width: 14),
            for (final actionClass in _ActionClass.values) ...[
              _PaletteGroup(
                actionClass: actionClass,
                selectedId: selectedId,
                onHover: onHover,
                onActivate: onActivate,
              ),
              if (actionClass != _ActionClass.values.last)
                const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _DenseProDock extends StatelessWidget {
  const _DenseProDock({
    required this.selectedId,
    required this.hoveredAction,
    required this.onHover,
    required this.onActivate,
  });

  final String selectedId;
  final _ActionSpec? hoveredAction;
  final ValueChanged<String?> onHover;
  final ValueChanged<_ActionSpec> onActivate;

  @override
  Widget build(BuildContext context) => _FloatingLabelStack(
    action: hoveredAction ?? _actions.firstWhere((a) => a.id == selectedId),
    child: _BarSurface(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final actionClass in _ActionClass.values) ...[
            _VerticalClassMarker(actionClass: actionClass),
            const SizedBox(width: 4),
            for (final action in _actionsFor(actionClass))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _ActionBarButton(
                  action: action,
                  selected: action.id == selectedId,
                  style: _ActionButtonStyle.dense,
                  onHover: onHover,
                  onPressed: () => onActivate(action),
                ),
              ),
            if (actionClass != _ActionClass.values.last) const _BarSeparator(),
          ],
        ],
      ),
    ),
  );
}

enum _ActionButtonStyle { label, icon, mode, iconWithShortcut, palette, dense }

class _ActionBarButton extends StatefulWidget {
  const _ActionBarButton({
    required this.action,
    required this.selected,
    required this.style,
    required this.onHover,
    required this.onPressed,
  });

  final _ActionSpec action;
  final bool selected;
  final _ActionButtonStyle style;
  final ValueChanged<String?> onHover;
  final VoidCallback onPressed;

  @override
  State<_ActionBarButton> createState() => _ActionBarButtonState();
}

class _ActionBarButtonState extends State<_ActionBarButton> {
  var _hovered = false;

  void _setHovered(bool hovered) {
    setState(() => _hovered = hovered);
    widget.onHover(hovered ? widget.action.id : null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final tone = _toneFor(context, widget.action.actionClass);
    final iconOnly = widget.style == _ActionButtonStyle.icon;
    const iconOnlySize = 42.0;
    final compact =
        widget.style == _ActionButtonStyle.icon ||
        widget.style == _ActionButtonStyle.dense;
    final showShortcut = widget.style != _ActionButtonStyle.icon;
    final showLabel = iconOnly ? false : !compact || widget.selected;
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
    final icon = Icon(
      widget.action.icon,
      size: 15,
      color: widget.selected ? tone : null,
    );

    return Tooltip(
      message: '${widget.action.label} - ${widget.action.description}',
      waitDuration: const Duration(milliseconds: 250),
      child: MouseRegion(
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: AnimatedScale(
          scale: _hovered ? 1.04 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(7),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOutCubic,
                constraints: BoxConstraints(
                  minWidth: iconOnly
                      ? iconOnlySize
                      : compact
                      ? 38
                      : 76,
                  minHeight: iconOnly
                      ? iconOnlySize
                      : widget.style == _ActionButtonStyle.dense
                      ? 38
                      : 44,
                ),
                width: iconOnly ? iconOnlySize : null,
                height: iconOnly ? iconOnlySize : null,
                padding: iconOnly
                    ? EdgeInsets.zero
                    : EdgeInsets.symmetric(
                        horizontal: compact ? 8 : 10,
                        vertical: widget.style == _ActionButtonStyle.dense
                            ? 6
                            : 8,
                      ),
                decoration: BoxDecoration(
                  color: background,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: iconOnly
                    ? Center(child: icon)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          icon,
                          if (showLabel) ...[
                            const SizedBox(width: 7),
                            Text(
                              widget.action.label,
                              style: context.theme.typography.body.xs,
                            ),
                          ],
                          if (showShortcut) ...[
                            const SizedBox(width: 8),
                            DesyKeyboardShortcutLabel(
                              keys: widget.action.shortcut,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _floatingDockLabel(_ActionClass actionClass) => switch (actionClass) {
  _ActionClass.selection => 'Selection mode',
  _ActionClass.insert => 'Add elements',
  _ActionClass.output => 'Output',
};

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.actionClass,
    required this.selectedId,
    required this.onHover,
    required this.onActivate,
  });

  final _ActionClass actionClass;
  final String selectedId;
  final ValueChanged<String?> onHover;
  final ValueChanged<_ActionSpec> onActivate;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final tone = _toneFor(context, actionClass);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(actionClass.icon, size: 13, color: tone),
                const SizedBox(width: 6),
                Text(
                  actionClass.longLabel,
                  style: context.theme.typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final action in _actionsFor(actionClass))
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _ActionBarButton(
                      action: action,
                      selected: action.id == selectedId,
                      style: _ActionButtonStyle.iconWithShortcut,
                      onHover: onHover,
                      onPressed: () => onActivate(action),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RailGroup extends StatelessWidget {
  const _RailGroup({
    required this.label,
    required this.actions,
    required this.selectedId,
    required this.buttonStyle,
    required this.onHover,
    required this.onActivate,
  });

  final String label;
  final List<_ActionSpec> actions;
  final String selectedId;
  final _ActionButtonStyle buttonStyle;
  final ValueChanged<String?> onHover;
  final ValueChanged<_ActionSpec> onActivate;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 5),
        child: Text(
          label,
          style: context.theme.typography.body.xs.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final action in actions)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _ActionBarButton(
                action: action,
                selected: action.id == selectedId,
                style: buttonStyle,
                onHover: onHover,
                onPressed: () => onActivate(action),
              ),
            ),
        ],
      ),
    ],
  );
}

class _PaletteGroup extends StatelessWidget {
  const _PaletteGroup({
    required this.actionClass,
    required this.selectedId,
    required this.onHover,
    required this.onActivate,
  });

  final _ActionClass actionClass;
  final String selectedId;
  final ValueChanged<String?> onHover;
  final ValueChanged<_ActionSpec> onActivate;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final tone = _toneFor(context, actionClass);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: tone.withValues(alpha: .28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: Text(
                actionClass.shortLabel,
                style: context.theme.typography.body.xs.copyWith(
                  color: colors.mutedForeground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final action in _actionsFor(actionClass))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _ActionBarButton(
                  action: action,
                  selected: action.id == selectedId,
                  style: _ActionButtonStyle.palette,
                  onHover: onHover,
                  onPressed: () => onActivate(action),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FloatingLabelStack extends StatelessWidget {
  const _FloatingLabelStack({required this.action, required this.child});

  final _ActionSpec? action;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AnimatedOpacity(
        opacity: action == null ? 0 : 1,
        duration: const Duration(milliseconds: 100),
        child: action == null
            ? const SizedBox(height: 28)
            : _FloatingFunctionLabel(action: action!),
      ),
      const SizedBox(height: 8),
      Center(child: child),
    ],
  );
}

class _FloatingFunctionLabel extends StatelessWidget {
  const _FloatingFunctionLabel({required this.action});

  final _ActionSpec action;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final tone = _toneFor(context, action.actionClass);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: tone.withValues(alpha: .38)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ClassDot(color: tone),
            const SizedBox(width: 7),
            Text(action.description, style: context.theme.typography.body.xs),
            const SizedBox(width: 8),
            DesyKeyboardShortcutLabel(keys: action.shortcut),
          ],
        ),
      ),
    );
  }
}

class _BarSurface extends StatelessWidget {
  const _BarSurface({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

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
      child: Padding(padding: padding, child: child),
    );
  }
}

class _InlineGroupLabel extends StatelessWidget {
  const _InlineGroupLabel({required this.actionClass});

  final _ActionClass actionClass;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ClassDot(color: _toneFor(context, actionClass)),
          const SizedBox(width: 6),
          Text(
            actionClass.shortLabel,
            style: context.theme.typography.body.xs.copyWith(
              color: colors.mutedForeground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalClassMarker extends StatelessWidget {
  const _VerticalClassMarker({required this.actionClass});

  final _ActionClass actionClass;

  @override
  Widget build(BuildContext context) {
    final tone = _toneFor(context, actionClass);
    return RotatedBox(
      quarterTurns: 3,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 3,
            decoration: BoxDecoration(
              color: tone,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            actionClass.shortLabel.toUpperCase(),
            style: context.theme.typography.body.xs.copyWith(
              color: tone,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarSeparator extends StatelessWidget {
  const _BarSeparator();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 36,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: context.theme.colors.border,
  );
}

class _ClassDot extends StatelessWidget {
  const _ClassDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

List<_ActionSpec> _actionsFor(_ActionClass actionClass) => _actions
    .where((action) => action.actionClass == actionClass)
    .toList(growable: false);

Color _toneFor(BuildContext context, _ActionClass actionClass) {
  final colors = context.theme.colors;
  return switch (actionClass) {
    _ActionClass.selection => colors.desy.signal,
    _ActionClass.insert => colors.foreground,
    _ActionClass.output => colors.desy.positive,
  };
}

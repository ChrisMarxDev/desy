// PROTOTYPE — annotation inbox directions for a local-first review flow.
//
// This is intentionally consumer-owned dogfood code. It explores the UX
// before an annotation inbox becomes a public Desy workbench contract.

import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Real Flutter directions for managing notes collected throughout the app.
DesyPrototypeSession
buildAnnotationInboxPrototypeSession() => DesyPrototypeSession(
  id: 'desy.prototype-session.annotation-inbox',
  name: 'Annotation inbox',
  description:
      'A persistent summary opens a spacious review surface, while the reviewer stays free to navigate the workbench.',
  prototypes: const [
    DesyPrototype(
      id: 'desy.prototype.annotation-inbox.review-sheet',
      name: 'Review sheet',
      description:
          'Recommended: calm rows, clear batch actions, and a compact persistent summary.',
      canvasPlacement: DesyCanvasPlacement(
        offset: Offset(72, 96),
        size: Size(1000, 640),
      ),
      builder: _reviewSheet,
    ),
    DesyPrototype(
      id: 'desy.prototype.annotation-inbox.ledger',
      name: 'Annotation ledger',
      description:
          'A denser, table-like inbox for scanning many notes at once.',
      canvasPlacement: DesyCanvasPlacement(
        offset: Offset(72, 832),
        size: Size(1000, 640),
      ),
      builder: _ledger,
    ),
    DesyPrototype(
      id: 'desy.prototype.annotation-inbox.focused',
      name: 'Focused queue',
      description:
          'One selected note gets more reading space; useful when notes are long.',
      canvasPlacement: DesyCanvasPlacement(
        offset: Offset(72, 1568),
        size: Size(1000, 640),
      ),
      builder: _focusedQueue,
    ),
  ],
);

Widget _reviewSheet(BuildContext context) =>
    const _AnnotationInboxPrototype(direction: _InboxDirection.reviewSheet);

Widget _ledger(BuildContext context) =>
    const _AnnotationInboxPrototype(direction: _InboxDirection.ledger);

Widget _focusedQueue(BuildContext context) =>
    const _AnnotationInboxPrototype(direction: _InboxDirection.focusedQueue);

enum _InboxDirection { reviewSheet, ledger, focusedQueue }

class _AnnotationNote {
  const _AnnotationNote({
    required this.id,
    required this.target,
    required this.page,
    required this.note,
    required this.when,
  });

  final String id;
  final String target;
  final String page;
  final String note;
  final String when;
}

const _initialNotes = [
  _AnnotationNote(
    id: 'button-padding',
    target: 'Button',
    page: 'Components / Actions',
    note: 'Increase the primary button tap target to 48dp.',
    when: '2 min ago',
  ),
  _AnnotationNote(
    id: 'text-field-border',
    target: 'Text field',
    page: 'Components / Inputs',
    note: 'The input border is too quiet against a white canvas.',
    when: '8 min ago',
  ),
  _AnnotationNote(
    id: 'color-contrast',
    target: 'Signal color',
    page: 'Foundations / Colors',
    note: 'Check the muted label contrast in the selected state.',
    when: 'Yesterday',
  ),
  _AnnotationNote(
    id: 'sidebar-density',
    target: 'Registry sidebar',
    page: 'Workspace / Atlas',
    note: 'The component tree could breathe a little more.',
    when: 'Yesterday',
  ),
];

class _AnnotationInboxPrototype extends StatefulWidget {
  const _AnnotationInboxPrototype({required this.direction});

  final _InboxDirection direction;

  @override
  State<_AnnotationInboxPrototype> createState() =>
      _AnnotationInboxPrototypeState();
}

class _AnnotationInboxPrototypeState extends State<_AnnotationInboxPrototype> {
  late List<_AnnotationNote> _notes;
  final Set<String> _selected = {'button-padding', 'text-field-border'};
  var _dialogOpen = true;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _notes = List.of(_initialNotes);
  }

  void _toggle(_AnnotationNote note, bool value) => setState(() {
    if (value) {
      _selected.add(note.id);
    } else {
      _selected.remove(note.id);
    }
  });

  Future<void> _copySelected() async {
    final notes = _notes.where((note) => _selected.contains(note.id)).toList();
    await Clipboard.setData(
      ClipboardData(
        text: notes
            .map((note) => '${note.target} · ${note.page}\n${note.note}')
            .join('\n\n'),
      ),
    );
    if (mounted) {
      setState(() => _feedback = '${notes.length} annotations copied');
    }
  }

  void _deleteSelected() => setState(() {
    _notes = _notes.where((note) => !_selected.contains(note.id)).toList();
    _selected.clear();
    _feedback = 'Selected annotations deleted';
  });

  void _openPage(_AnnotationNote note) =>
      setState(() => _feedback = 'Opened ${note.page}');

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 1000,
    height: 640,
    child: Stack(
      children: [
        _WorkbenchBackdrop(
          count: _notes.length,
          latest: _notes.isEmpty ? null : _notes.first,
          onOpenInbox: () => setState(() => _dialogOpen = true),
        ),
        if (_dialogOpen)
          Positioned.fill(
            child: _AnnotationReviewDialog(
              direction: widget.direction,
              notes: _notes,
              selected: _selected,
              feedback: _feedback,
              onClose: () => setState(() => _dialogOpen = false),
              onToggle: _toggle,
              onCopy: _selected.isEmpty ? null : _copySelected,
              onDelete: _selected.isEmpty ? null : _deleteSelected,
              onOpenPage: _openPage,
            ),
          ),
      ],
    ),
  );
}

class _WorkbenchBackdrop extends StatelessWidget {
  const _WorkbenchBackdrop({
    required this.count,
    required this.latest,
    required this.onOpenInbox,
  });

  final int count;
  final _AnnotationNote? latest;
  final VoidCallback onOpenInbox;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: context.theme.colors.desy.canvas),
    child: Stack(
      children: [
        const Positioned(top: 0, left: 0, right: 0, child: _PrototypeToolbar()),
        Positioned(
          top: 57,
          left: 0,
          bottom: 0,
          width: 228,
          child: const _PrototypeNavigation(),
        ),
        Positioned(
          top: 57,
          left: 229,
          right: 0,
          bottom: 0,
          child: const _PrototypeCanvas(),
        ),
        Positioned(
          left: 18,
          bottom: 18,
          child: _AnnotationSummary(
            count: count,
            latest: latest,
            onOpen: onOpenInbox,
          ),
        ),
      ],
    ),
  );
}

class _PrototypeToolbar extends StatelessWidget {
  const _PrototypeToolbar();

  @override
  Widget build(BuildContext context) => Container(
    height: 57,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      color: context.theme.colors.background,
      border: Border(
        bottom: BorderSide(color: context.theme.colors.desy.divider),
      ),
    ),
    child: Row(
      children: [
        const Icon(DesyIcons.boxes, size: 18),
        const SizedBox(width: 10),
        Text('Registry Spine', style: context.theme.typography.body.md),
        const Spacer(),
        Icon(
          DesyIcons.crosshair,
          color: context.theme.colors.desy.signal,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text('Annotate', style: context.theme.typography.body.sm),
      ],
    ),
  );
}

class _PrototypeNavigation extends StatelessWidget {
  const _PrototypeNavigation();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(
        right: BorderSide(color: context.theme.colors.desy.divider),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REGISTRY', style: context.theme.typography.body.xs),
          const SizedBox(height: 24),
          const _NavLine(label: 'Foundations', indented: false),
          const _NavLine(label: 'Colors', indented: true),
          const _NavLine(label: 'Typography', indented: true),
          const SizedBox(height: 12),
          const _NavLine(label: 'Components', indented: false),
          const _NavLine(label: 'Inputs', indented: true),
          const _NavLine(label: 'Buttons', indented: true, selected: true),
        ],
      ),
    ),
  );
}

class _NavLine extends StatelessWidget {
  const _NavLine({
    required this.label,
    required this.indented,
    this.selected = false,
  });

  final String label;
  final bool indented;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 5),
    padding: EdgeInsets.fromLTRB(indented ? 22 : 4, 7, 8, 7),
    decoration: BoxDecoration(
      color: selected ? context.theme.colors.desy.signalSurface : null,
      borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusSm),
    ),
    child: Text(label, style: context.theme.typography.body.sm),
  );
}

class _PrototypeCanvas extends StatelessWidget {
  const _PrototypeCanvas();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(34),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Button', style: context.theme.typography.display.sm),
        const SizedBox(height: 8),
        Text(
          'A real component preview stays interactive while annotations collect quietly.',
          style: context.theme.typography.body.sm.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: 336,
          child: DesyCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Primary', style: context.theme.typography.body.md),
                  const SizedBox(height: 18),
                  DesyButton(
                    onPress: () {},
                    mainAxisSize: MainAxisSize.min,
                    child: const Text('Continue'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _AnnotationSummary extends StatelessWidget {
  const _AnnotationSummary({
    required this.count,
    required this.latest,
    required this.onOpen,
  });

  final int count;
  final _AnnotationNote? latest;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final latestNote = latest;
    return SizedBox(
      width: 294,
      child: DesyCard(
        child: Semantics(
          button: true,
          label: 'Open $count annotations',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.theme.colors.desy.signalSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      DesyIcons.messageSquare,
                      size: 15,
                      color: context.theme.colors.desy.signal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: latestNote == null
                        ? Text(
                            'No annotations',
                            style: context.theme.typography.body.sm,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$count annotations',
                                style: context.theme.typography.body.sm,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${latestNote.target}: ${latestNote.note}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.theme.typography.body.xs
                                    .copyWith(
                                      color:
                                          context.theme.colors.mutedForeground,
                                    ),
                              ),
                            ],
                          ),
                  ),
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 23,
                      minHeight: 23,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.theme.colors.desy.signal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: context.theme.typography.body.xs.copyWith(
                        color: context.theme.colors.desy.onSignal,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnotationReviewDialog extends StatelessWidget {
  const _AnnotationReviewDialog({
    required this.direction,
    required this.notes,
    required this.selected,
    required this.feedback,
    required this.onClose,
    required this.onToggle,
    required this.onCopy,
    required this.onDelete,
    required this.onOpenPage,
  });

  final _InboxDirection direction;
  final List<_AnnotationNote> notes;
  final Set<String> selected;
  final String? feedback;
  final VoidCallback onClose;
  final ValueChanged<_AnnotationNote> onOpenPage;
  final void Function(_AnnotationNote note, bool value) onToggle;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {const SingleActivator(LogicalKeyboardKey.escape): onClose},
    child: Focus(
      autofocus: direction == _InboxDirection.reviewSheet,
      child: DecoratedBox(
        key: ValueKey('annotation-review-dialog-${direction.name}'),
        decoration: BoxDecoration(color: context.theme.colors.background),
        child: Column(
          children: [
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: context.theme.colors.desy.divider),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Annotations',
                    style: context.theme.typography.display.sm,
                  ),
                  const SizedBox(width: 12),
                  _CountBadge(count: notes.length),
                  const Spacer(),
                  DesyButton(
                    key: ValueKey('annotation-cancel-${direction.name}'),
                    onPress: onClose,
                    variant: DesyButtonVariant.outline,
                    size: DesyButtonSize.sm,
                    mainAxisSize: MainAxisSize.min,
                    semanticsLabel: 'Cancel annotations',
                    suffix: const DesyKeyboardShortcutLabel(
                      keys: ['Esc'],
                      semanticLabel: 'Escape cancels annotations',
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(54, 34, 54, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(switch (direction) {
                      _InboxDirection.reviewSheet =>
                        'Review what to take to your agent',
                      _InboxDirection.ledger =>
                        'Scan and batch the review inbox',
                      _InboxDirection.focusedQueue =>
                        'Work through feedback with more context',
                    }, style: context.theme.typography.body.lg),
                    const SizedBox(height: 6),
                    Text(
                      'Notes remain here as you move through the workbench. Select the ones you want to act on.',
                      style: context.theme.typography.body.sm.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                    if (feedback != null) ...[
                      const SizedBox(height: 16),
                      _FeedbackNotice(message: feedback!),
                    ],
                    const SizedBox(height: 24),
                    Expanded(child: _noteList(context)),
                    const SizedBox(height: 18),
                    _ActionBar(
                      selectedCount: selected.length,
                      onCopy: onCopy,
                      onDelete: onDelete,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _noteList(BuildContext context) => switch (direction) {
    _InboxDirection.reviewSheet => ListView.separated(
      itemCount: notes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) => _AnnotationRow(
        note: notes[index],
        selected: selected.contains(notes[index].id),
        onChanged: (value) => onToggle(notes[index], value),
        onOpenPage: () => onOpenPage(notes[index]),
      ),
    ),
    _InboxDirection.ledger => _AnnotationLedger(
      notes: notes,
      selected: selected,
      onToggle: onToggle,
      onOpenPage: onOpenPage,
    ),
    _InboxDirection.focusedQueue => _FocusedQueue(
      notes: notes,
      selected: selected,
      onToggle: onToggle,
      onOpenPage: onOpenPage,
    ),
  };
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: context.theme.colors.desy.signalSurface,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      '$count open',
      style: context.theme.typography.body.xs.copyWith(
        color: context.theme.colors.desy.signal,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _AnnotationRow extends StatelessWidget {
  const _AnnotationRow({
    required this.note,
    required this.selected,
    required this.onChanged,
    required this.onOpenPage,
  });

  final _AnnotationNote note;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenPage;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: selected
          ? context.theme.colors.desy.signalSurface
          : context.theme.colors.background,
      border: Border.all(
        color: selected
            ? context.theme.colors.desy.signalBorder
            : context.theme.colors.desy.divider,
      ),
      borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusMd),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DesyCheckbox(
            value: selected,
            onChanged: onChanged,
            label: const SizedBox.shrink(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.target, style: context.theme.typography.body.md),
                const SizedBox(height: 3),
                Text(note.note, style: context.theme.typography.body.sm),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Text(
                      note.page,
                      style: context.theme.typography.body.xs.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      note.when,
                      style: context.theme.typography.body.xs.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          DesyButton(
            onPress: onOpenPage,
            variant: DesyButtonVariant.ghost,
            size: DesyButtonSize.sm,
            mainAxisSize: MainAxisSize.min,
            child: const Text('Open page'),
          ),
        ],
      ),
    ),
  );
}

class _AnnotationLedger extends StatelessWidget {
  const _AnnotationLedger({
    required this.notes,
    required this.selected,
    required this.onToggle,
    required this.onOpenPage,
  });
  final List<_AnnotationNote> notes;
  final Set<String> selected;
  final void Function(_AnnotationNote, bool) onToggle;
  final ValueChanged<_AnnotationNote> onOpenPage;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: context.theme.colors.desy.divider),
    ),
    child: Column(
      children: [
        const _LedgerHeader(),
        Expanded(
          child: ListView.builder(
            itemCount: notes.length,
            itemBuilder: (_, index) => _LedgerRow(
              note: notes[index],
              selected: selected.contains(notes[index].id),
              onChanged: (value) => onToggle(notes[index], value),
              onOpenPage: () => onOpenPage(notes[index]),
            ),
          ),
        ),
      ],
    ),
  );
}

class _LedgerHeader extends StatelessWidget {
  const _LedgerHeader();
  @override
  Widget build(BuildContext context) => Container(
    height: 38,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: context.theme.colors.desy.panelSubtle,
      border: Border(
        bottom: BorderSide(color: context.theme.colors.desy.divider),
      ),
    ),
    child: Row(
      children: [
        const SizedBox(width: 30),
        Expanded(
          flex: 2,
          child: Text('TARGET', style: context.theme.typography.body.xs),
        ),
        Expanded(
          flex: 4,
          child: Text('ANNOTATION', style: context.theme.typography.body.xs),
        ),
        Expanded(
          flex: 2,
          child: Text('PAGE', style: context.theme.typography.body.xs),
        ),
      ],
    ),
  );
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.note,
    required this.selected,
    required this.onChanged,
    required this.onOpenPage,
  });
  final _AnnotationNote note;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenPage;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: selected ? context.theme.colors.desy.signalSurface : null,
      border: Border(
        bottom: BorderSide(color: context.theme.colors.desy.divider),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 30,
          child: DesyCheckbox(
            value: selected,
            onChanged: onChanged,
            label: const SizedBox.shrink(),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(note.target, style: context.theme.typography.body.sm),
        ),
        Expanded(
          flex: 4,
          child: Text(note.note, style: context.theme.typography.body.sm),
        ),
        Expanded(
          flex: 2,
          child: DesyButton(
            onPress: onOpenPage,
            variant: DesyButtonVariant.ghost,
            size: DesyButtonSize.xs,
            mainAxisSize: MainAxisSize.min,
            child: const Text('Open'),
          ),
        ),
      ],
    ),
  );
}

class _FocusedQueue extends StatelessWidget {
  const _FocusedQueue({
    required this.notes,
    required this.selected,
    required this.onToggle,
    required this.onOpenPage,
  });
  final List<_AnnotationNote> notes;
  final Set<String> selected;
  final void Function(_AnnotationNote, bool) onToggle;
  final ValueChanged<_AnnotationNote> onOpenPage;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();
    final focused = notes.first;
    return Row(
      children: [
        SizedBox(
          width: 270,
          child: ListView.separated(
            itemCount: notes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (_, index) => _QueueTile(
              note: notes[index],
              selected: selected.contains(notes[index].id),
              onChanged: (value) => onToggle(notes[index], value),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _AnnotationRow(
            note: focused,
            selected: selected.contains(focused.id),
            onChanged: (value) => onToggle(focused, value),
            onOpenPage: () => onOpenPage(focused),
          ),
        ),
      ],
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({
    required this.note,
    required this.selected,
    required this.onChanged,
  });
  final _AnnotationNote note;
  final bool selected;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: selected
          ? context.theme.colors.desy.signalSurface
          : context.theme.colors.desy.panelSubtle,
      borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusSm),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: DesyCheckbox(
              value: selected,
              onChanged: onChanged,
              label: const SizedBox.shrink(),
            ),
          ),
          Expanded(
            child: Text(note.target, style: context.theme.typography.body.sm),
          ),
        ],
      ),
    ),
  );
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.selectedCount,
    required this.onCopy,
    required this.onDelete,
  });
  final int selectedCount;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.theme.colors.desy.panelSubtle,
      borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusMd),
    ),
    child: Row(
      children: [
        Text(
          '$selectedCount selected',
          style: context.theme.typography.body.sm,
        ),
        const Spacer(),
        DesyButton(
          onPress: onDelete,
          variant: DesyButtonVariant.destructive,
          size: DesyButtonSize.sm,
          mainAxisSize: MainAxisSize.min,
          child: const Text('Delete'),
        ),
        const SizedBox(width: 10),
        DesyButton(
          onPress: onCopy,
          size: DesyButtonSize.sm,
          mainAxisSize: MainAxisSize.min,
          prefix: const Icon(DesyIcons.send, size: 14),
          child: const Text('Copy'),
        ),
      ],
    ),
  );
}

class _FeedbackNotice extends StatelessWidget {
  const _FeedbackNotice({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: context.theme.colors.desy.signalSurface,
      borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusSm),
    ),
    child: Text(message, style: context.theme.typography.body.sm),
  );
}

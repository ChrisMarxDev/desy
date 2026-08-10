import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';

/// One real Flutter implementation available in the workshop.
///
/// The host owns selection and feedback while this file owns only candidate
/// metadata and the widgets themselves. Codex is constrained to this boundary.
class HotReloadCandidate {
  const HotReloadCandidate({
    required this.id,
    required this.title,
    required this.description,
    required this.builder,
  });

  /// Stable identity used to carry a selection across hot reloads.
  final String id;

  /// Short human-readable direction name.
  final String title;

  /// What makes this implementation meaningfully different.
  final String description;

  /// Builds the real Flutter widget shown by Desy's preview boundary.
  final WidgetBuilder builder;
}

/// Builds the implementation candidates currently available for feedback.
///
/// Codex may add, remove, or adapt candidates while keeping stable IDs for
/// directions that remain conceptually the same.
List<HotReloadCandidate> buildHotReloadCandidates() => [
  HotReloadCandidate(
    id: 'codex-activity.chat-transcript',
    title: 'Chat transcript',
    description:
        'A familiar conversation view with tool activity embedded between messages.',
    builder: (_) => const _ChatTranscript(),
  ),
  HotReloadCandidate(
    id: 'codex-activity.grouped-turns',
    title: 'Grouped turns',
    description:
        'Prompt-and-reply groups keep each request attached to its implementation work.',
    builder: (_) => const _GroupedTurnsLog(),
  ),
  HotReloadCandidate(
    id: 'codex-activity.live-stream',
    title: 'Live stream',
    description:
        'A small-type, timestamped chat log that keeps more of a busy session visible.',
    builder: (_) => const _LiveActivityStream(),
  ),
  HotReloadCandidate(
    id: 'codex-activity.event-ledger',
    title: 'Event ledger',
    description:
        'A table-like activity feed that trades chat bubbles for maximum information density.',
    builder: (_) => const _EventLedger(),
  ),
];

class _ChatTranscript extends StatelessWidget {
  const _ChatTranscript();

  @override
  Widget build(BuildContext context) {
    return const _ChatFrame(
      title: 'Activity chat',
      subtitle: 'Today · 4 messages',
      trailing: _StatusPill(label: 'Live', showDot: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChatBubble(
            author: 'You',
            time: '10:42',
            message: 'Turn the activity view into a chat log.',
            isUser: true,
          ),
          SizedBox(height: DesyDesignSystemTokens.spaceMd),
          _InlineActivity(
            icon: Icons.search_rounded,
            title: 'Inspected hot_reload_widget.dart',
            detail: '1 file · 486 lines',
          ),
          SizedBox(height: DesyDesignSystemTokens.spaceMd),
          _ChatBubble(
            author: 'Codex',
            time: '10:43',
            message:
                'I found three chart concepts. I’ll replace them with real chat-log candidates and preserve the hot-reload API.',
          ),
          SizedBox(height: DesyDesignSystemTokens.spaceMd),
          _InlineActivity(
            icon: Icons.check_circle_outline_rounded,
            title: 'Updated implementation candidates',
            detail: '3 chat directions · formatted',
            completed: true,
          ),
        ],
      ),
    );
  }
}

class _GroupedTurnsLog extends StatelessWidget {
  const _GroupedTurnsLog();

  @override
  Widget build(BuildContext context) {
    return const _ChatFrame(
      title: 'Session conversation',
      subtitle: 'feature/activity-chat · 12 min',
      trailing: _StatusPill(label: '2 turns'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TurnGroup(
            time: '10:38',
            prompt: 'Show recent activity in the workshop.',
            response:
                'I drafted three visual activity summaries for comparison.',
            activities: [
              _TurnActivity(
                icon: Icons.visibility_outlined,
                label: 'Read source',
              ),
              _TurnActivity(
                icon: Icons.edit_outlined,
                label: 'Added 3 candidates',
              ),
            ],
          ),
          SizedBox(height: DesyDesignSystemTokens.spaceMd),
          _TurnGroup(
            time: '10:42',
            prompt: 'I meant a chat log for the activity.',
            response:
                'Got it — the activity now reads as a conversation, with implementation events kept in context.',
            activities: [
              _TurnActivity(icon: Icons.code_rounded, label: 'Reworked widget'),
              _TurnActivity(
                icon: Icons.auto_fix_high_rounded,
                label: 'Formatted',
              ),
            ],
            current: true,
          ),
        ],
      ),
    );
  }
}

class _LiveActivityStream extends StatelessWidget {
  const _LiveActivityStream();

  @override
  Widget build(BuildContext context) {
    return const _ChatFrame(
      title: 'Live activity',
      subtitle: 'Current session',
      trailing: _StatusPill(label: 'Following', showDot: true),
      contentPadding: EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StreamEntry(
            time: '10:42',
            icon: Icons.person_outline_rounded,
            label: 'You',
            text: 'I meant a chat log for the activity.',
            emphasized: true,
          ),
          _StreamEntry(
            time: '10:42',
            icon: Icons.search_rounded,
            label: 'Activity',
            text: 'Read lib/hot_reload_widget.dart',
          ),
          _StreamEntry(
            time: '10:43',
            icon: Icons.smart_toy_outlined,
            label: 'Codex',
            text: 'Reframing the candidates as chat history.',
            emphasized: true,
          ),
          _StreamEntry(
            time: '10:43',
            icon: Icons.edit_note_rounded,
            label: 'Activity',
            text: 'Replaced 3 chart candidates with chat logs',
          ),
          _StreamEntry(
            time: '10:43',
            icon: Icons.tune_rounded,
            label: 'Codex',
            text: 'Reduced type and spacing for the small preview.',
            emphasized: true,
          ),
          _StreamEntry(
            time: '10:44',
            icon: Icons.add_rounded,
            label: 'Activity',
            text: 'Added a dense event-ledger alternative',
          ),
          _StreamEntry(
            time: '10:44',
            icon: Icons.check_rounded,
            label: 'Activity',
            text: 'dart format completed',
            completed: true,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _EventLedger extends StatelessWidget {
  const _EventLedger();

  @override
  Widget build(BuildContext context) {
    return const _ChatFrame(
      title: 'Activity ledger',
      subtitle: 'Current session · 8 events',
      trailing: _StatusPill(label: 'Live', showDot: true),
      contentPadding: EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LedgerHeader(),
          _LedgerEntry(
            time: '10:42',
            icon: Icons.person_outline_rounded,
            source: 'You',
            event: 'Requested a chat log for activity',
            state: 'input',
          ),
          _LedgerEntry(
            time: '10:42',
            icon: Icons.search_rounded,
            source: 'Read',
            event: 'lib/hot_reload_widget.dart',
            state: 'done',
          ),
          _LedgerEntry(
            time: '10:43',
            icon: Icons.smart_toy_outlined,
            source: 'Codex',
            event: 'Reframed candidates as chat history',
            state: 'note',
          ),
          _LedgerEntry(
            time: '10:43',
            icon: Icons.edit_note_rounded,
            source: 'Edit',
            event: 'Updated live-stream density',
            state: 'done',
          ),
          _LedgerEntry(
            time: '10:43',
            icon: Icons.text_fields_rounded,
            source: 'Edit',
            event: 'Reduced stream type to 10–11 px',
            state: 'done',
          ),
          _LedgerEntry(
            time: '10:44',
            icon: Icons.add_rounded,
            source: 'Edit',
            event: 'Added event-ledger candidate',
            state: 'done',
          ),
          _LedgerEntry(
            time: '10:44',
            icon: Icons.auto_fix_high_rounded,
            source: 'Format',
            event: 'dart format hot_reload_widget.dart',
            state: 'running',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _ChatFrame extends StatelessWidget {
  const _ChatFrame({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.child,
    this.contentPadding = const EdgeInsets.all(DesyDesignSystemTokens.spaceLg),
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final Widget child;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return SizedBox(
      width: 600,
      height: 440,
      child: FCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesyDesignSystemTokens.spaceLg,
                DesyDesignSystemTokens.spaceLg,
                DesyDesignSystemTokens.spaceLg,
                DesyDesignSystemTokens.spaceMd,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.forum_outlined,
                      size: 18,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: DesyDesignSystemTokens.spaceSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: typography.body.lg.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: typography.body.xs.copyWith(
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing,
                ],
              ),
            ),
            Container(height: 1, color: colors.border),
            Expanded(
              child: SingleChildScrollView(
                padding: contentPadding,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.author,
    required this.time,
    required this.message,
    this.isUser = false,
  });

  final String author;
  final String time;
  final String message;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Semantics(
      label: '$author at $time: $message',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isUser
                  ? colors.primary
                  : colors.primary.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUser
                  ? Icons.person_outline_rounded
                  : Icons.auto_awesome_rounded,
              size: 15,
              color: isUser ? colors.primaryForeground : colors.primary,
            ),
          ),
          const SizedBox(width: DesyDesignSystemTokens.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      author,
                      style: typography.body.xs.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      time,
                      style: typography.body.xs.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesyDesignSystemTokens.spaceMd,
                    vertical: DesyDesignSystemTokens.spaceSm,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? colors.primary.withValues(alpha: .08)
                        : colors.secondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(message, style: typography.body.sm),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineActivity extends StatelessWidget {
  const _InlineActivity({
    required this.icon,
    required this.title,
    required this.detail,
    this.completed = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Padding(
      padding: const EdgeInsets.only(left: 40),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: completed ? colors.primary : colors.mutedForeground,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: typography.body.xs.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            detail,
            style: typography.body.xs.copyWith(color: colors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _TurnGroup extends StatelessWidget {
  const _TurnGroup({
    required this.time,
    required this.prompt,
    required this.response,
    required this.activities,
    this.current = false,
  });

  final String time;
  final String prompt;
  final String response;
  final List<_TurnActivity> activities;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Container(
      padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
      decoration: BoxDecoration(
        color: current ? colors.primary.withValues(alpha: .045) : null,
        border: Border.all(
          color: current
              ? colors.primary.withValues(alpha: .25)
              : colors.border,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You',
                style: typography.body.xs.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  prompt,
                  style: typography.body.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                time,
                style: typography.body.xs.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesyDesignSystemTokens.spaceSm),
          Wrap(spacing: 7, runSpacing: 7, children: activities),
          const SizedBox(height: DesyDesignSystemTokens.spaceSm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 15, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(response, style: typography.body.sm)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TurnActivity extends StatelessWidget {
  const _TurnActivity({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.mutedForeground),
          const SizedBox(width: 6),
          Text(
            label,
            style: typography.body.xs.copyWith(color: colors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _StreamEntry extends StatelessWidget {
  const _StreamEntry({
    required this.time,
    required this.icon,
    required this.label,
    required this.text,
    this.emphasized = false,
    this.completed = false,
    this.isLast = false,
  });

  final String time;
  final IconData icon;
  final String label;
  final String text;
  final bool emphasized;
  final bool completed;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 39,
            child: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                time,
                style: typography.body.xs.copyWith(
                  color: colors.mutedForeground,
                  fontSize: 10,
                  height: 1.15,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 24,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 22,
                    bottom: 0,
                    child: Container(width: 1, color: colors.border),
                  ),
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    color: completed
                        ? colors.primary
                        : emphasized
                        ? colors.primary.withValues(alpha: .12)
                        : colors.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border),
                  ),
                  child: Icon(
                    icon,
                    size: 12,
                    color: completed
                        ? colors.primaryForeground
                        : emphasized
                        ? colors.primary
                        : colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: emphasized ? colors.secondary : null,
                borderRadius: BorderRadius.circular(7),
                border: emphasized ? Border.all(color: colors.border) : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(
                      label,
                      style: typography.body.xs.copyWith(
                        color: completed
                            ? colors.primary
                            : colors.mutedForeground,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        height: 1.2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      text,
                      style: typography.body.xs.copyWith(
                        fontSize: 11,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerHeader extends StatelessWidget {
  const _LedgerHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final style = typography.body.xs.copyWith(
      color: colors.mutedForeground,
      fontSize: 9,
      fontWeight: FontWeight.w700,
      letterSpacing: .5,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 5),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          SizedBox(width: 42, child: Text('TIME', style: style)),
          const SizedBox(width: 26),
          SizedBox(width: 54, child: Text('SOURCE', style: style)),
          Expanded(child: Text('EVENT', style: style)),
          SizedBox(width: 44, child: Text('STATE', style: style)),
        ],
      ),
    );
  }
}

class _LedgerEntry extends StatelessWidget {
  const _LedgerEntry({
    required this.time,
    required this.icon,
    required this.source,
    required this.event,
    required this.state,
    this.isLast = false,
  });

  final String time;
  final IconData icon;
  final String source;
  final String event;
  final String state;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final stateColor = state == 'running' || state == 'done'
        ? colors.primary
        : colors.mutedForeground;
    final textStyle = typography.body.xs.copyWith(fontSize: 10.5, height: 1.2);

    return Semantics(
      label: '$time, $source, $event, $state',
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: colors.border)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              child: Text(
                time,
                style: textStyle.copyWith(color: colors.mutedForeground),
              ),
            ),
            SizedBox(
              width: 26,
              child: Icon(icon, size: 12, color: colors.mutedForeground),
            ),
            SizedBox(
              width: 54,
              child: Text(
                source,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: Text(
                event,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                state,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle.copyWith(
                  color: stateColor,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, this.showDot = false});

  final String label;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
          ],
          Text(
            label,
            style: typography.body.xs.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

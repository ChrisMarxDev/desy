import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'desy_design_system_scope.dart';
import 'desy_visual_tokens.dart';

/// The progress state communicated by one [DesyProgressTrailItem].
enum DesyProgressTrailItemState {
  /// Work that finished successfully.
  complete,

  /// Work that is happening now.
  current,

  /// Work that has not started.
  pending,

  /// Work that stopped with an error.
  failed,
}

/// A typed step rendered by [DesyProgressTrail].
@immutable
class DesyProgressTrailItem {
  /// Creates a progress-trail step.
  const DesyProgressTrailItem({
    required this.title,
    required this.state,
    this.detail,
    this.metadata,
    this.icon,
  });

  /// The concise action or outcome.
  final String title;

  /// Supporting context for the step.
  final String? detail;

  /// A short duration, count, or status label.
  final String? metadata;

  /// An optional domain-specific glyph. The state remains exposed separately.
  final IconData? icon;

  /// The step's current progress state.
  final DesyProgressTrailItemState state;
}

/// A quiet connected list for completed, current, and upcoming work.
class DesyProgressTrail extends StatelessWidget {
  /// Creates a progress trail.
  const DesyProgressTrail({super.key, required this.items});

  /// Ordered progress steps.
  final List<DesyProgressTrailItem> items;

  @override
  Widget build(BuildContext context) {
    final completed = items
        .where((item) => item.state == DesyProgressTrailItemState.complete)
        .length;
    return Semantics(
      container: true,
      label: items.isEmpty
          ? 'No activity yet'
          : '$completed of ${items.length} steps complete',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, item) in items.indexed)
            _ProgressTrailItem(item: item, isLast: index == items.length - 1),
        ],
      ),
    );
  }
}

class _ProgressTrailItem extends StatelessWidget {
  const _ProgressTrailItem({required this.item, required this.isLast});

  final DesyProgressTrailItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final emphasized = item.state == DesyProgressTrailItemState.current;
    final failed = item.state == DesyProgressTrailItemState.failed;
    final signal = failed ? colors.destructive : colors.desy.signal;
    final background = emphasized || failed
        ? signal.withValues(alpha: .05)
        : Colors.transparent;
    final border = emphasized || failed
        ? signal.withValues(alpha: .28)
        : Colors.transparent;

    return Semantics(
      container: true,
      label: '${_stateLabel(item.state)}: ${item.title}',
      child: ExcludeSemantics(
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 18,
                child: Column(
                  children: [
                    _ProgressTrailGlyph(item: item),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 1,
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          color:
                              item.state ==
                                      DesyProgressTrailItemState.complete ||
                                  item.state ==
                                      DesyProgressTrailItemState.failed
                              ? signal.withValues(alpha: .5)
                              : colors.border,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: DesyDesignSystemTokens.spaceSm),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: isLast ? 0 : DesyDesignSystemTokens.spaceMd,
                  ),
                  child: AnimatedContainer(
                    duration: DesyDesignSystemTokens.feedbackMotion,
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.all(
                      DesyDesignSystemTokens.spaceSm,
                    ),
                    decoration: BoxDecoration(
                      color: background,
                      border: Border.all(color: border),
                      borderRadius: BorderRadius.circular(
                        DesyDesignSystemTokens.radiusSm,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: typography.body.sm.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (item.metadata case final metadata?) ...[
                              const SizedBox(
                                width: DesyDesignSystemTokens.spaceSm,
                              ),
                              Text(
                                metadata,
                                style: typography.body.xs.copyWith(
                                  color: emphasized || failed
                                      ? signal
                                      : colors.mutedForeground,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (item.detail case final detail?) ...[
                          const SizedBox(
                            height: DesyDesignSystemTokens.spaceXs,
                          ),
                          Text(
                            detail,
                            style: typography.body.xs.copyWith(
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ],
                    ),
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

class _ProgressTrailGlyph extends StatelessWidget {
  const _ProgressTrailGlyph({required this.item});

  final DesyProgressTrailItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final failed = item.state == DesyProgressTrailItemState.failed;
    final pending = item.state == DesyProgressTrailItemState.pending;
    final signal = failed
        ? colors.destructive
        : pending
        ? colors.mutedForeground
        : colors.desy.signal;
    final icon =
        item.icon ??
        switch (item.state) {
          DesyProgressTrailItemState.complete => Icons.check_rounded,
          DesyProgressTrailItemState.current => Icons.more_horiz_rounded,
          DesyProgressTrailItemState.pending => Icons.circle_outlined,
          DesyProgressTrailItemState.failed => Icons.close_rounded,
        };
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: signal.withValues(alpha: pending ? .04 : .1),
        border: Border.all(color: signal.withValues(alpha: pending ? .35 : .7)),
      ),
      child: Icon(icon, size: 9, color: signal),
    );
  }
}

String _stateLabel(DesyProgressTrailItemState state) => switch (state) {
  DesyProgressTrailItemState.complete => 'Complete',
  DesyProgressTrailItemState.current => 'Current',
  DesyProgressTrailItemState.pending => 'Pending',
  DesyProgressTrailItemState.failed => 'Failed',
};

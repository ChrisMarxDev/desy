import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:desy_bench/desy_bench.dart';

/// The sample system's primary action component.
class SampleButton extends StatelessWidget {
  /// Creates a primary sample button.
  const SampleButton({super.key, required this.label, this.onPressed});

  /// Visible action label.
  final String label;

  /// Callback when enabled.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FButton(
    onPress: onPressed,
    mainAxisSize: MainAxisSize.min,
    prefix: const Icon(FLucideIcons.arrowRight),
    child: Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
  );
}

/// A compact secondary action that does not compete with the main task.
class SampleSecondaryButton extends StatelessWidget {
  /// Creates a secondary sample button.
  const SampleSecondaryButton({super.key, required this.label, this.onPressed});

  /// Visible action label.
  final String label;

  /// Callback when enabled.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FButton(
    variant: FButtonVariant.outline,
    onPress: onPressed,
    mainAxisSize: MainAxisSize.min,
    prefix: const Icon(FLucideIcons.slidersHorizontal),
    child: Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
  );
}

/// A sample content container component.
class SampleCard extends StatelessWidget {
  /// Creates a card with a title and supporting copy.
  const SampleCard({
    super.key,
    required this.title,
    required this.body,
    this.trailing,
  });

  /// Card heading.
  final String title;

  /// Supporting content.
  final String body;

  /// Optional action or status aligned with the title.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => FCard(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 8),
          Text(body),
        ],
      ),
    ),
  );
}

/// A status badge for concise, non-interactive state communication.
class SampleStatusBadge extends StatelessWidget {
  /// Creates a status badge.
  const SampleStatusBadge({super.key, required this.label, required this.tone});

  /// Text announced with the badge.
  final String label;

  /// Visual severity of the state.
  final SampleStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = switch (tone) {
      SampleStatusTone.success => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      SampleStatusTone.warning => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      SampleStatusTone.critical => (
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
    };
    return Semantics(
      label: '$label status',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colors.$1,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: colors.$2),
        ),
      ),
    );
  }
}

/// Severity variants for [SampleStatusBadge].
enum SampleStatusTone {
  /// The intended state is confirmed or proceeding normally.
  success,

  /// The state needs attention before the next decision.
  warning,

  /// The state blocks progress or records a serious failure.
  critical,
}

/// An informative callout with a clear hierarchy and optional action.
class SampleNotice extends StatelessWidget {
  /// Creates a notice.
  const SampleNotice({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
  });

  /// Short notice heading.
  final String title;

  /// Guidance presented to the person using the interface.
  final String message;

  /// Optional visible action label.
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(FLucideIcons.info, color: scheme.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(message),
                if (actionLabel != null) ...[
                  const SizedBox(height: 8),
                  FButton(
                    variant: FButtonVariant.ghost,
                    size: FButtonSizeVariant.sm,
                    mainAxisSize: MainAxisSize.min,
                    onPress: () {},
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A labeled text input for collecting a single short value.
class SampleTextField extends StatelessWidget {
  /// Creates a text field.
  const SampleTextField({
    super.key,
    required this.label,
    this.hint,
    this.errorText,
  });

  /// Persistent accessible input label.
  final String label;

  /// Optional example value.
  final String? hint;

  /// Validation guidance when input cannot be accepted.
  final String? errorText;

  @override
  Widget build(BuildContext context) =>
      DesyTextField(label: label, hintText: hint, errorText: errorText);
}

/// A row used to represent a navigable setting or destination.
class SampleNavigationRow extends StatelessWidget {
  /// Creates a navigation row.
  const SampleNavigationRow({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
  });

  /// Recognizable visual label for the destination.
  final IconData icon;

  /// Destination name.
  final String title;

  /// Supporting context for the destination.
  final String detail;

  @override
  Widget build(BuildContext context) => FTile(
    title: Text(title),
    subtitle: Text(detail),
    prefix: Icon(icon),
    suffix: const Icon(FLucideIcons.chevronRight),
    onPress: () {},
  );
}

/// A compact operational metric with supporting context.
class SampleMetricTile extends StatelessWidget {
  /// Creates a metric tile.
  const SampleMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
  });

  /// Short name for the measured value.
  final String label;

  /// Prominent formatted value.
  final String value;

  /// Supporting context for interpreting the value.
  final String detail;

  /// Symbol that identifies the metric at a glance.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 2),
                  Text(value, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 2),
                  Text(detail, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A labeled capacity reading that keeps its value available as text.
class SampleCapacityIndicator extends StatelessWidget {
  /// Creates a capacity indicator.
  const SampleCapacityIndicator({
    super.key,
    required this.label,
    required this.used,
    required this.total,
  });

  /// Name of the constrained resource.
  final String label;

  /// Currently used amount.
  final int used;

  /// Total available amount.
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0 ? 0.0 : (used / total).clamp(0.0, 1.0);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '$label, $used of $total used',
      child: FCard(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    '$used / $total',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 10,
                  child: ColoredBox(
                    color: scheme.surfaceContainerHighest,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        heightFactor: 1,
                        child: ColoredBox(color: scheme.primary),
                      ),
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

/// A scheduled operational event with its current status.
class SampleScheduleItem extends StatelessWidget {
  /// Creates a schedule item.
  const SampleScheduleItem({
    super.key,
    required this.time,
    required this.title,
    required this.detail,
    required this.status,
    required this.tone,
  });

  /// Local display time for the event.
  final String time;

  /// Event name.
  final String title;

  /// Supporting schedule information.
  final String detail;

  /// Concise visible state.
  final String status;

  /// Severity used by the status badge.
  final SampleStatusTone tone;

  @override
  Widget build(BuildContext context) => FCard(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 58,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(time, style: Theme.of(context).textTheme.labelLarge),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SampleStatusBadge(label: status, tone: tone),
        ],
      ),
    ),
  );
}

/// A calm blank state with one optional recovery action.
class SampleEmptyState extends StatelessWidget {
  /// Creates an empty state.
  const SampleEmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.actionLabel,
  });

  /// Short explanation of what is absent.
  final String title;

  /// Guidance that helps someone continue.
  final String message;

  /// Symbol for the empty collection or result.
  final IconData icon;

  /// Optional recovery action label.
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: scheme.primary),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            FButton(
              variant: FButtonVariant.outline,
              mainAxisSize: MainAxisSize.min,
              onPress: () {},
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// A small specimen driven by Desy's shared motion preview timeline.
class SampleMotionSpecimen extends StatelessWidget {
  /// Creates a motion specimen.
  const SampleMotionSpecimen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress =
        DesyMotionPlaybackScope.maybeOf(context) ?? kAlwaysDismissedAnimation;
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        return Align(
          alignment: Alignment.lerp(
            Alignment.centerLeft,
            Alignment.centerRight,
            progress.value,
          )!,
          child: child,
        );
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(9),
        ),
      ),
    );
  }
}

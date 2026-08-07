import 'package:flutter/material.dart';

/// The same consumer-owned production widget used by every prototype.
final class ActivityCard extends StatelessWidget {
  const ActivityCard({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.trailing,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool enabled;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Card(
    color: enabled
        ? Theme.of(context).colorScheme.surfaceContainer
        : Theme.of(context).colorScheme.surfaceContainerLowest,
    child: ListTile(
      enabled: enabled,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
    ),
  );
}

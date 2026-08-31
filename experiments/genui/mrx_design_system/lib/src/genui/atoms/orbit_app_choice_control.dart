// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppChoiceControl extends StatelessWidget {
  const OrbitAppChoiceControl({
    super.key,
    required this.options,
    required this.values,
    required this.onChanged,
    this.mode = OrbitSelectionMode.single,
    this.enabled = true,
  });
  final List<OrbitChoiceOption> options;
  final Set<String> values;
  final ValueChanged<Set<String>>? onChanged;
  final OrbitSelectionMode mode;
  final bool enabled;
  @override
  Widget build(BuildContext context) => OrbitAppWrap(
    children: [
      for (final option in options)
        _ChoiceChip(
          option: option,
          selected: values.contains(option.id),
          enabled: enabled && onChanged != null,
          onPressed: () {
            final next = {...values};
            if (mode == OrbitSelectionMode.boolean ||
                mode == OrbitSelectionMode.single) {
              if (next.contains(option.id)) {
                next.clear();
              } else {
                next
                  ..clear()
                  ..add(option.id);
              }
            } else {
              next.contains(option.id)
                  ? next.remove(option.id)
                  : next.add(option.id);
            }
            onChanged?.call(next);
          },
        ),
    ],
  );
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });
  final OrbitChoiceOption option;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Pressable(
    enabled: enabled,
    semanticButtonLabel: option.label,
    onPress: onPressed,
    child: Box(
      style: BoxStyler()
          .color(
            selected
                ? OrbitTheme.of(context).colors.accent
                : OrbitTheme.of(context).colors.card,
          )
          .borderRounded(OrbitTokens.radiusMd)
          .borderAll(
            color: selected
                ? OrbitTheme.of(context).colors.ring
                : OrbitTheme.of(context).colors.border,
          )
          .onFocused(
            BoxStyler().borderAll(
              color: OrbitTheme.of(context).colors.ring,
              width: 1,
            ),
          )
          .animate(AnimationConfig.ease(OrbitMotion.quick(context))),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OrbitTokens.spaceMd,
          vertical: OrbitTokens.spaceSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: OrbitAppText(option.label, role: OrbitTextRole.label),
            ),
            if (option.shortcut case final shortcut?) ...[
              const SizedBox(width: OrbitTokens.spaceSm),
              OrbitShortcutLabel(
                keys: [shortcut],
                semanticLabel:
                    'Keyboard shortcut: $shortcut selects ${option.label}',
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

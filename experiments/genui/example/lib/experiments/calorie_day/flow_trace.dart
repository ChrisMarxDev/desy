// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';

import '../../orbit/orbit_theme.dart';
import 'meal_interpreter.dart';

/// Local developer observability for the Calorie Day provider handoff.
class FlowTrace extends StatelessWidget {
  const FlowTrace({super.key, required this.events});

  final List<MealFlowEvent> events;

  @override
  Widget build(BuildContext context) => OrbitSurface(
    padding: const EdgeInsets.all(OrbitTokens.spaceMd),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const OrbitGlyph(OrbitGlyphs.activity, size: 15),
            const SizedBox(width: OrbitTokens.spaceXs),
            Text('FLOW TRACE', style: OrbitType.overline(context)),
            const Spacer(),
            Text('${events.length} events', style: OrbitType.small(context)),
          ],
        ),
        const SizedBox(height: OrbitTokens.spaceSm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final event = events[index];
              return Text(
                '${event.time}  ${event.source}.${event.name}\n${event.detail}',
                style: OrbitType.small(context).copyWith(
                  color: OrbitTheme.of(context).colors.mutedForeground,
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

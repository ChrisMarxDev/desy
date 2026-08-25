// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:a2ui_core/a2ui_core.dart' as a2ui;
import 'package:desy_bench/desy_bench.dart';
import 'package:desy_genui/desy_genui.dart';
import 'package:flutter/widgets.dart';
import 'package:genui/genui.dart';

import '../../orbit/orbit_theme.dart';
import 'flow_trace.dart';
import 'meal_interpreter.dart';

/// A chat-first daily food-log experiment with one stable generated surface.
class CalorieDayWorkbench extends StatefulWidget {
  const CalorieDayWorkbench({
    super.key,
    required this.catalog,
    required this.theme,
    this.mealInterpreterFactory,
  });

  final DesyGenUiCatalog catalog;
  final DesyTheme theme;
  final MealInterpreterFactory? mealInterpreterFactory;

  @override
  State<CalorieDayWorkbench> createState() => _CalorieDayWorkbenchState();
}

class _CalorieDayWorkbenchState extends State<CalorieDayWorkbench> {
  static const _surfaceId = 'calorie-day';

  late final SurfaceController _controller;
  late final MealInterpreter _interpreter;
  late final StreamSubscription<MealFlowEvent> _flowSubscription;
  late final TextEditingController _composer;
  late final FocusNode _composerFocus;
  final _entries = <CalorieMeal>[];
  final _messages = <_DayMessage>[
    const _DayMessage.assistant(
      'Start with something you ate. Local Codex will turn it into an estimated meal entry for this day.',
    ),
  ];
  final _flow = <MealFlowEvent>[];
  var _logging = false;
  var _traceReady = false;

  @override
  void initState() {
    super.initState();
    _interpreter =
        widget.mealInterpreterFactory?.call() ??
        const UnavailableMealInterpreter();
    _flowSubscription = _interpreter.events.listen(_recordFlow);
    _composer = TextEditingController();
    _composerFocus = FocusNode(debugLabel: 'calorie-day-composer');
    _controller = SurfaceController(catalogs: [widget.catalog.catalog]);
    _controller.handleMessage(
      a2ui.CreateSurfaceMessage(
        surfaceId: _surfaceId,
        catalogId: widget.catalog.catalog.catalogId!,
      ),
    );
    _record('a2ui', 'createSurface', 'surface=$_surfaceId');
    _publishDay();
    _controller.handleMessage(
      a2ui.UpdateComponentsMessage(
        surfaceId: _surfaceId,
        components: [
          for (final component in _calorieDayComponents)
            Map<String, dynamic>.from(component),
        ],
      ),
    );
    _record(
      'a2ui',
      'updateComponents',
      'surface=$_surfaceId · components=${_calorieDayComponents.length}',
    );
    _traceReady = true;
  }

  @override
  void dispose() {
    _composer.dispose();
    _composerFocus.dispose();
    unawaited(_flowSubscription.cancel());
    _controller.dispose();
    unawaited(_interpreter.close());
    super.dispose();
  }

  Future<void> _logMeal(String value) async {
    final text = value.trim();
    if (text.isEmpty || _logging) return;
    setState(() {
      _logging = true;
      _messages.add(_DayMessage.user(text));
    });
    _record('ui', 'meal.submitted', text);
    _composer.clear();
    try {
      final result = await _interpreter.interpret(
        message: text,
        daySoFar: List.unmodifiable(_entries),
      );
      if (!mounted) return;
      final meal = result.meal;
      if (result.logged && meal != null) {
        _entries.add(meal);
        _publishDay();
        _record(
          'app',
          'day.appended',
          '${meal.label} · ${meal.calories.round()} kcal · entries=${_entries.length}',
        );
      }
      setState(() {
        _messages.add(_DayMessage.assistant(result.reply));
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _DayMessage.assistant('Codex could not log that meal: $error'),
        );
      });
      _record('app', 'meal.failed', '$error');
    } finally {
      if (mounted) setState(() => _logging = false);
    }
  }

  void _clearDay() {
    if (_logging) return;
    setState(() {
      _entries.clear();
      _messages
        ..clear()
        ..add(
          const _DayMessage.assistant(
            'Day cleared. Add a meal and local Codex will estimate it again.',
          ),
        );
    });
    _record('ui', 'day.cleared', 'entries=0');
    _publishDay();
  }

  void _useSuggestion(String value) {
    _composer.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _composerFocus.requestFocus();
  }

  void _publishDay() {
    final calories = _entries.fold<double>(
      0,
      (sum, entry) => sum + entry.calories,
    );
    final protein = _entries.fold<double>(
      0,
      (sum, entry) => sum + entry.protein,
    );
    final carbs = _entries.fold<double>(0, (sum, entry) => sum + entry.carbs);
    final fat = _entries.fold<double>(0, (sum, entry) => sum + entry.fat);
    _controller.handleMessage(
      a2ui.UpdateDataModelMessage(
        surfaceId: _surfaceId,
        path: '/calorieDay',
        value: <String, Object?>{
          'summaryTitle': entriesTitle(_entries.length),
          'summaryDetail': _entries.isEmpty
              ? 'Ask local Codex to log a meal to begin your day.'
              : 'P ${protein.round()}g · C ${carbs.round()}g · F ${fat.round()}g',
          'calories': '${calories.round()} kcal',
          'entryCount': _entries.isEmpty
              ? 'No entries yet'
              : '${_entries.length} meal${_entries.length == 1 ? '' : 's'} logged',
          'macroLabels': const ['Protein', 'Carbs', 'Fat'],
          'macroValues': [protein, carbs, fat],
          'meals': [for (final entry in _entries) entry.toJson()],
        },
      ),
    );
    _record(
      'a2ui',
      'updateDataModel',
      'surface=$_surfaceId · path=/calorieDay · entries=${_entries.length} · ${calories.round()} kcal',
    );
  }

  void _record(String source, String name, String detail) =>
      _recordFlow(MealFlowEvent(source: source, name: name, detail: detail));

  void _recordFlow(MealFlowEvent event) {
    debugPrint('CALORIE_DAY_FLOW $event');
    void append() {
      if (_flow.length == 30) _flow.removeAt(0);
      _flow.add(event);
    }

    if (_traceReady && mounted) {
      setState(append);
    } else {
      append();
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _CalorieDayIntroduction(),
                    const SizedBox(height: OrbitTokens.spaceXl),
                    Row(
                      children: [
                        const OrbitBadge(
                          label: 'LOCAL DAY',
                          tone: OrbitBadgeTone.info,
                          glyph: OrbitGlyphs.activity,
                        ),
                        const SizedBox(width: OrbitTokens.spaceSm),
                        Expanded(
                          child: Text(
                            'AI estimates only · not nutrition or medical advice',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: OrbitType.small(context),
                          ),
                        ),
                        OrbitButton(
                          label: 'Clear day',
                          onPressed: _logging ? null : _clearDay,
                          compact: true,
                          variant: OrbitButtonVariant.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: OrbitTokens.spaceMd),
                    DesyGenUiSurface(
                      controller: _controller,
                      surfaceId: _surfaceId,
                      theme: widget.theme,
                    ),
                    const SizedBox(height: OrbitTokens.spaceXl),
                    FlowTrace(events: _flow),
                    const SizedBox(height: OrbitTokens.space2xl),
                    Text('DAY CHAT', style: OrbitType.overline(context)),
                    const SizedBox(height: OrbitTokens.spaceSm),
                    for (final message in _messages) ...[
                      _DayChatBubble(message: message),
                      const SizedBox(height: OrbitTokens.spaceSm),
                    ],
                    if (_logging) const _LoggingMeal(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      _CalorieComposer(
        controller: _composer,
        focusNode: _composerFocus,
        logging: _logging,
        onSubmit: _logMeal,
        onSuggestion: _useSuggestion,
      ),
    ],
  );
}

String entriesTitle(int count) =>
    count == 0 ? "Today's calories" : 'Today so far';

class _CalorieDayIntroduction extends StatelessWidget {
  const _CalorieDayIntroduction();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const OrbitBadge(
        label: 'GENUI DAY LOG',
        tone: OrbitBadgeTone.info,
        glyph: OrbitGlyphs.sparkle,
      ),
      const SizedBox(height: OrbitTokens.spaceLg),
      Text('Your chat is the day.', style: OrbitType.display(context)),
      const SizedBox(height: OrbitTokens.spaceSm),
      Text(
        'Log meals in plain language. Local Codex estimates each entry; the chart and meal list remain stable as your day grows.',
        style: OrbitType.body(
          context,
        ).copyWith(color: OrbitTheme.of(context).colors.mutedForeground),
      ),
    ],
  );
}

class _DayChatBubble extends StatelessWidget {
  const _DayChatBubble({required this.message});

  final _DayMessage message;

  @override
  Widget build(BuildContext context) => Align(
    alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: OrbitSurface(
        tone: message.isUser ? OrbitSurfaceTone.muted : OrbitSurfaceTone.raised,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OrbitBadge(
              label: message.isUser ? 'YOU' : 'DAY LOG',
              tone: message.isUser
                  ? OrbitBadgeTone.neutral
                  : OrbitBadgeTone.info,
            ),
            const SizedBox(height: OrbitTokens.spaceSm),
            Text(message.text, style: OrbitType.body(context)),
          ],
        ),
      ),
    ),
  );
}

class _LoggingMeal extends StatelessWidget {
  const _LoggingMeal();

  @override
  Widget build(BuildContext context) => OrbitSurface(
    padding: const EdgeInsets.symmetric(
      horizontal: OrbitTokens.spaceMd,
      vertical: OrbitTokens.spaceSm,
    ),
    child: Row(
      children: [
        OrbitSpinner(size: 16, color: OrbitTheme.of(context).colors.info),
        const SizedBox(width: OrbitTokens.spaceSm),
        Text(
          'Local Codex is estimating this meal…',
          style: OrbitType.small(context),
        ),
      ],
    ),
  );
}

class _CalorieComposer extends StatelessWidget {
  const _CalorieComposer({
    required this.controller,
    required this.focusNode,
    required this.logging,
    required this.onSubmit,
    required this.onSuggestion,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool logging;
  final ValueChanged<String> onSubmit;
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: OrbitTheme.of(context).colors.background,
      border: Border(
        top: BorderSide(color: OrbitTheme.of(context).colors.border),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _MealSuggestion(
                      label: 'Oatmeal and berries',
                      onTap: onSuggestion,
                    ),
                    const SizedBox(width: OrbitTokens.spaceSm),
                    _MealSuggestion(
                      label: 'Chicken rice bowl',
                      onTap: onSuggestion,
                    ),
                    const SizedBox(width: OrbitTokens.spaceSm),
                    _MealSuggestion(
                      label: '650 kcal, 30g protein, 80g carbs, 15g fat',
                      onTap: onSuggestion,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: OrbitTokens.spaceSm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: OrbitTextArea(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: !logging,
                      hint: 'What did you eat?',
                      onSubmitted: onSubmit,
                    ),
                  ),
                  const SizedBox(width: OrbitTokens.spaceSm),
                  OrbitButton(
                    label: logging ? 'Logging' : 'Log meal',
                    onPressed: logging ? null : () => onSubmit(controller.text),
                    leading: logging
                        ? OrbitSpinner(
                            size: 14,
                            color: OrbitTheme.of(
                              context,
                            ).colors.mutedForeground,
                          )
                        : const OrbitGlyph(OrbitGlyphs.send, size: 17),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _MealSuggestion extends StatelessWidget {
  const _MealSuggestion({required this.label, required this.onTap});

  final String label;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => OrbitButton(
    label: label,
    onPressed: () => onTap(label),
    compact: true,
    variant: OrbitButtonVariant.secondary,
    leading: const OrbitGlyph(OrbitGlyphs.add, size: 14),
  );
}

final class _DayMessage {
  const _DayMessage.user(this.text) : isUser = true;
  const _DayMessage.assistant(this.text) : isUser = false;

  final String text;
  final bool isUser;
}

const _calorieDayComponents = <Map<String, Object?>>[
  {
    'id': 'root',
    'component': 'orbit.component.stack',
    'children': ['summary', 'macros', 'meals', 'source'],
  },
  {
    'id': 'summary',
    'component': 'orbit.component.insight',
    'eyebrow': 'DAILY TOTAL · AI ESTIMATES',
    'title': {'path': '/calorieDay/summaryTitle'},
    'detail': {'path': '/calorieDay/summaryDetail'},
    'metric': {'path': '/calorieDay/calories'},
    'change': {'path': '/calorieDay/entryCount'},
    'tone': 'info',
  },
  {
    'id': 'macros',
    'component': 'orbit.component.bar-chart',
    'title': 'Macros logged (g)',
    'labels': {'path': '/calorieDay/macroLabels'},
    'values': {'path': '/calorieDay/macroValues'},
  },
  {
    'id': 'meals',
    'component': 'orbit.component.meal-list',
    'title': "Today's meal log",
    'meals': {'path': '/calorieDay/meals'},
  },
  {
    'id': 'source',
    'component': 'orbit.component.source',
    'title': 'How this sample works',
    'detail':
        'Local Codex interprets each chat message. The stable GenUI surface updates from one local day snapshot after each accepted response.',
    'meta': 'AI estimates · no health advice · no external nutrition database',
  },
];

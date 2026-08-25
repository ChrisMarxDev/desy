import 'dart:convert';
import 'dart:io';

import 'package:desy_genui_example/experiments/calorie_day/meal_interpreter.dart';

/// Performs one manual smoke test against the authenticated local Codex agent.
Future<void> main() async {
  final interpreter = CodexMealInterpreter();
  try {
    final result = await interpreter.interpret(
      message: 'Lunch was a medium chicken rice bowl with vegetables.',
      daySoFar: const [],
    );
    stdout.writeln(
      jsonEncode({
        'logged': result.logged,
        'reply': result.reply,
        if (result.meal case final meal?) ...{
          'label': meal.label,
          'calories': meal.calories,
          'protein': meal.protein,
          'carbs': meal.carbs,
          'fat': meal.fat,
        },
      }),
    );
  } finally {
    await interpreter.close();
  }
}

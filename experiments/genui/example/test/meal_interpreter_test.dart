import 'package:desy_genui_example/experiments/calorie_day/meal_interpreter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts one schema-constrained Codex meal interpretation', () {
    final interpretation = MealInterpretation.fromJson({
      'logged': true,
      'reply': 'Estimated from your description.',
      'label': 'Oatmeal with berries',
      'calories': 320,
      'protein': 9,
      'carbs': 58,
      'fat': 6,
    });

    expect(interpretation.logged, isTrue);
    expect(interpretation.meal?.label, 'Oatmeal with berries');
    expect(interpretation.meal?.calories, 320);
    expect(interpretation.meal?.protein, 9);
  });

  test('keeps an unlogged Codex reply out of the day data', () {
    final interpretation = MealInterpretation.fromJson({
      'logged': false,
      'reply': 'What food and approximate portion would you like to log?',
      'label': '',
      'calories': 0,
      'protein': 0,
      'carbs': 0,
      'fat': 0,
    });

    expect(interpretation.logged, isFalse);
    expect(interpretation.meal, isNull);
    expect(interpretation.reply, contains('portion'));
  });
}

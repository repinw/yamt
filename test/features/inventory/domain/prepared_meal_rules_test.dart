import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_rules.dart';

PreparedMeal _meal({
  num remaining = 3,
  bool inPot = false,
  List<String> openRows = const [],
}) {
  return PreparedMeal(
    id: 'chili',
    name: 'Chili',
    totalPortions: 4,
    remainingPortions: remaining,
    totalKcal: 2000,
    totalProtein: 100,
    totalCarbs: 200,
    totalFat: 80,
    createdAt: DateTime(2026, 10, 7),
    updatedAt: DateTime(2026, 10, 7),
    components: const <PreparedMealComponent>[],
    pendingRecipeIngredients: openRows,
    inPot: inPot ? true : null,
  );
}

void main() {
  const eat = PreparedMealAction.eat;
  const plan = PreparedMealAction.plan;
  const edit = PreparedMealAction.editIngredients;

  // state → (eat, plan, edit ingredients, open)
  final table = <String, (PreparedMeal, bool, bool, bool, bool)>{
    'ready': (_meal(), true, true, false, false),
    'untouched': (_meal(remaining: 4), true, true, true, false),
    'in the pot': (_meal(remaining: 4, inPot: true), false, true, true, true),
    'open rows': (_meal(openRows: ['Salz']), false, false, false, true),
    'eaten up': (_meal(remaining: 0), false, false, false, false),
  };

  for (final MapEntry(key: state, value: (meal, eats, plans, edits, open))
      in table.entries) {
    test('a meal $state allows eat=$eats plan=$plans edit=$edits', () {
      expect(meal.allows(eat), eats);
      expect(meal.allows(plan), plans);
      expect(meal.allows(edit), edits);
      expect(meal.isOpen, open);
    });
  }

  test('allowsPortions needs positive portions within what is left', () {
    final meal = _meal();

    expect(meal.allowsPortions(eat, 1), isTrue);
    expect(meal.allowsPortions(eat, 3), isTrue);
    expect(meal.allowsPortions(eat, 3.5), isFalse);
    expect(meal.allowsPortions(eat, 0), isFalse);
    expect(_meal(openRows: ['Salz']).allowsPortions(eat, 1), isFalse);
    final inPot = _meal(remaining: 4, inPot: true);
    expect(inPot.allowsPortions(eat, 1), isFalse);
    expect(inPot.allowsPortions(plan, 1), isTrue);
  });

  test('withPortionsTaken never goes below zero and takes portions back', () {
    final at = DateTime(2026, 10, 8);

    expect(_meal().withPortionsTaken(1, at).remainingPortions, 2);
    expect(_meal().withPortionsTaken(5, at).remainingPortions, 0);
    expect(_meal().withPortionsTaken(-1, at).remainingPortions, 4);
    expect(_meal().withPortionsTaken(1, at).updatedAt, at);
  });
}

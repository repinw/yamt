import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/prepared_meal_diary_entry.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_eat_calculator.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_rules.dart';

PreparedMeal _meal({
  num remaining = 3,
  bool inPot = false,
  bool inPieces = false,
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
    servedInPieces: inPieces ? true : null,
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
    // Planned only as a reminder without kcal.
    'open rows': (_meal(openRows: ['Salz']), false, true, false, true),
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

  test('a new weight needs a cooked meal in portions with food left', () {
    const weight = PreparedMealAction.changeWeight;
    bool allows(PreparedMeal meal) =>
        meal.copyWith(finalNetWeight: 2000).allows(weight);

    expect(allows(_meal()), isTrue);
    expect(allows(_meal(remaining: 4)), isTrue);
    expect(allows(_meal(openRows: ['Salz'])), isTrue);
    expect(allows(_meal(remaining: 4, inPot: true)), isFalse);
    expect(allows(_meal(inPieces: true)), isFalse);
    expect(allows(_meal(remaining: 0)), isFalse);
    // A meal that never got a weight, such as one put together from the
    // Vorrat, has none to change.
    expect(_meal().allows(weight), isFalse);
  });

  group('withWeightLeft', () {
    final at = DateTime(2026, 10, 8, 7);

    test('before the first portion is the weight of the whole meal', () {
      // Cooked hot at 2000 g, weighed cold at 1800 g the next morning.
      final cooked = _meal(remaining: 4).copyWith(finalNetWeight: 2000);

      final weighed = cooked.withWeightLeft(1800, cooked.remainingPortions, at);

      expect(weighed.finalNetWeight, 1800);
      expect(weighed.remainingNetWeight, 1800);
      expect(weighed.potWeighing?.netWeight, 1800);
      expect(weighed.potWeighing?.remainingPortions, 4);
      expect(weighed.potWeighing?.weighedAt, at);
      expect(weighed.updatedAt, at);
      // A portion is a quarter of the meal: 450 g with 500 kcal now, so
      // 100 g hold about 111 kcal instead of 100.
      final calculator = PreparedMealEatCalculator(weighed);
      expect(calculator.portionsToGrams(1), 450);
      expect(weighed.totalKcal / weighed.totalPortions, 500);
      expect(weighed.totalKcal * 100 / weighed.remainingNetWeight!, 2000 / 18);
    });

    test('after portions is what is left, and the whole meal follows', () {
      // 2000 g cooked; 3 of 4 portions left that weigh 1200 g now.
      final eaten = _meal().copyWith(finalNetWeight: 2000);
      expect(eaten.remainingNetWeight, 1500);

      final weighed = eaten.withWeightLeft(1200, eaten.remainingPortions, at);

      expect(weighed.remainingNetWeight, 1200);
      expect(weighed.finalNetWeight, 1600);
      expect(weighed.remainingPortions, 3);
      expect(PreparedMealEatCalculator(weighed).portionsToGrams(1), 400);
      // The next portion leaves two that weigh 800 g.
      expect(weighed.withPortionsTaken(1, at).remainingNetWeight, 800);
    });

    test('gives a meal without a weight one', () {
      final weighed = _meal().withWeightLeft(900, 3, at);

      expect(weighed.finalNetWeight, 1200);
      expect(weighed.remainingNetWeight, 900);
      expect(PreparedMealEatCalculator(weighed).canUseGrams, isTrue);
    });

    test('keeps the nutrients, so diary entries stay as they are', () {
      final eaten = _meal().copyWith(finalNetWeight: 2000);
      CalorieEntry entryOf(PreparedMeal meal) =>
          buildConsumedPreparedMealCalorieEntry(
            meal: meal,
            consumedPortions: 1,
            mealType: MealType.lunch,
            now: () => at,
            nextEntryId: () => 'entry',
          )!;

      final weighed = eaten.withWeightLeft(1200, eaten.remainingPortions, at);

      expect(weighed.totalKcal, eaten.totalKcal);
      expect(weighed.totalProtein, eaten.totalProtein);
      expect(entryOf(weighed).toJson(), entryOf(eaten).toJson());
    });
  });

  group('plan portions', () {
    // A plan of 1 of 4 portions.
    final mealPlan = buildConsumedPreparedMealCalorieEntry(
      meal: _meal(),
      consumedPortions: 1,
      mealType: MealType.dinner,
      now: () => DateTime(2026, 10, 7, 12),
      nextEntryId: () => 'plan',
    )!;

    PreparedMeal portioned(int total) => PreparedMeal(
      id: 'chili',
      name: 'Chili',
      totalPortions: total,
      remainingPortions: total,
      totalKcal: 2000,
      totalProtein: 100,
      totalCarbs: 200,
      totalFat: 80,
      createdAt: DateTime(2026, 10, 7),
      updatedAt: DateTime(2026, 10, 7),
      components: const <PreparedMealComponent>[],
    );

    test('count in portions of the meal as it is now', () {
      expect(preparedMealPlanPortions(mealPlan, _meal()), 1);
      expect(preparedMealPlanPortions(mealPlan, portioned(8)), 2);
    });

    test('are unknown when the share is no whole portion', () {
      // 1 of 4 is half of 2 portions.
      expect(preparedMealPlanPortions(mealPlan, portioned(2)), isNull);
      expect(preparedMealPlanPortions(mealPlan, portioned(1)), isNull);
    });

    test('go up to what is left, never below the plan', () {
      expect(preparedMealPlanMaxPortions(_meal(remaining: 2.5), 1), 2);
      expect(preparedMealPlanMaxPortions(_meal(remaining: 0), 3), 3);
    });
  });
}

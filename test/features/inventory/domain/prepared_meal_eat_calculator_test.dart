import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_eat_calculator.dart';

import '../../../support/prepared_meal_test_data.dart';

PreparedMeal _meal({num remainingPortions = 2, int? finalNetWeight}) {
  return preparedMealTestData(
    totalPortions: 4,
    remainingPortions: remainingPortions,
  ).copyWith(finalNetWeight: finalNetWeight);
}

void main() {
  test('grams need a known cooked weight', () {
    expect(PreparedMealEatCalculator(_meal()).canUseGrams, isFalse);
    expect(
      PreparedMealEatCalculator(_meal(finalNetWeight: 800)).canUseGrams,
      isTrue,
    );
  });

  test('default portions are one, or what is left when less', () {
    expect(PreparedMealEatCalculator(_meal()).defaultPortions, 1);
    expect(
      PreparedMealEatCalculator(_meal(remainingPortions: 0.5)).defaultPortions,
      0.5,
    );
  });

  test('converts grams and portions through the cooked weight', () {
    final calculator = PreparedMealEatCalculator(_meal(finalNetWeight: 800));

    expect(calculator.gramsToPortions(100), 0.5);
    expect(calculator.portionsToGrams(1), 200);
    expect(
      calculator.convertAmount(
        200,
        from: PreparedMealEatAmountMode.grams,
        to: PreparedMealEatAmountMode.portions,
      ),
      1,
    );
  });

  test('remaining grams map to all remaining portions', () {
    final calculator = PreparedMealEatCalculator(
      _meal(remainingPortions: 1.5, finalNetWeight: 800),
    );

    expect(calculator.gramsToPortions(300), 1.5);
  });

  test('validPortions rejects amounts outside the remaining stock', () {
    final calculator = PreparedMealEatCalculator(_meal(finalNetWeight: 800));

    expect(calculator.validPortions(2, PreparedMealEatAmountMode.portions), 2);
    expect(
      calculator.validPortions(2.5, PreparedMealEatAmountMode.portions),
      isNull,
    );
    expect(
      calculator.validPortions(null, PreparedMealEatAmountMode.portions),
      isNull,
    );
    expect(calculator.validPortions(200, PreparedMealEatAmountMode.grams), 1);
    expect(
      calculator.validPortions(500, PreparedMealEatAmountMode.grams),
      isNull,
    );
  });

  test('quick values start with everything left and skip larger steps', () {
    final calculator = PreparedMealEatCalculator(_meal(finalNetWeight: 800));

    expect(calculator.quickValues(PreparedMealEatAmountMode.portions), <num>[
      2,
      0.5,
      1,
    ]);
    expect(calculator.quickValues(PreparedMealEatAmountMode.grams), <num>[
      400,
      100,
      250,
    ]);
    expect(
      PreparedMealEatCalculator(_meal())
          .quickValues(PreparedMealEatAmountMode.grams),
      isEmpty,
    );
  });

  test('parses entered amounts and keeps whole numbers as int', () {
    expect(parsePreparedMealAmountInput('2'), isA<int>());
    expect(parsePreparedMealAmountInput('0,5'), 0.5);
    expect(parsePreparedMealAmountInput('0'), isNull);
    expect(parsePreparedMealAmountInput('abc'), isNull);
  });

  test('scales bound ingredients to the eaten portions', () {
    final components = PreparedMealEatCalculator(_meal()).scaledComponents(2);

    expect(components.single.component.name, 'Rice');
    expect(components.single.amount, 50);
  });
}

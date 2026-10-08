import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_eat_calculator.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_pot_weighing.dart';

import '../../../support/prepared_meal_test_data.dart';

PreparedMeal _meal({num remainingPortions = 2, int? finalNetWeight}) {
  return preparedMealTestData(
    totalPortions: 4,
    remainingPortions: remainingPortions,
  ).copyWith(finalNetWeight: finalNetWeight);
}

final _cookedAt = DateTime(2026, 10, 8, 12);

/// Linsensuppe: 4 portions, 1400 g at "Gekocht" in a 1180 g pot, 3 left.
PreparedMeal _soup({PreparedMealPotWeighing? weighing}) {
  return preparedMealTestData(totalPortions: 4, remainingPortions: 3).copyWith(
    finalNetWeight: 1400,
    potTareWeight: 1180,
    updatedAt: _cookedAt,
    potWeighing: weighing,
  );
}

void main() {
  group('pot weighing', () {
    test('a fresh weighing sets what a gram is worth', () {
      final calculator = PreparedMealEatCalculator(
        _soup(
          weighing: PreparedMealPotWeighing(
            netWeight: 990,
            weighedAt: _cookedAt,
            remainingPortions: 3,
          ),
        ),
      );

      expect(calculator.currentNetWeight, 990);
      expect(calculator.gramsToPortions(330), 1);
      expect(calculator.portionsToGrams(1), 330);
      expect(calculator.remainingAmount(PreparedMealEatAmountMode.grams), 990);
    });

    test('an older weighing scales to the portions left now', () {
      final calculator = PreparedMealEatCalculator(
        _soup(
          weighing: PreparedMealPotWeighing(
            netWeight: 1200,
            weighedAt: _cookedAt,
            remainingPortions: 4,
          ),
        ),
      );

      expect(calculator.currentNetWeight, 900);
    });

    test('without a weighing the weight at Gekocht counts', () {
      expect(PreparedMealEatCalculator(_soup()).currentNetWeight, 1050);
    });

    test('asks to weigh again when old or eaten from since', () {
      final fresh = PreparedMealPotWeighing(
        netWeight: 990,
        weighedAt: _cookedAt,
        remainingPortions: 3,
      );
      final soon = _cookedAt.add(const Duration(hours: 1));
      final later = _cookedAt.add(const Duration(hours: 4));

      expect(
        PreparedMealEatCalculator(_soup(weighing: fresh))
            .needsPotWeighing(soon),
        isFalse,
      );
      expect(
        PreparedMealEatCalculator(_soup(weighing: fresh))
            .needsPotWeighing(later),
        isTrue,
      );
      // One portion was eaten since "Gekocht".
      expect(PreparedMealEatCalculator(_soup()).needsPotWeighing(soon), isTrue);
      // A meal not weighed in its pot never asks.
      expect(
        PreparedMealEatCalculator(_meal(finalNetWeight: 800))
            .needsPotWeighing(later),
        isFalse,
      );
    });
  });

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

  test(
    'scales a piece component down from its fractional-piece storage scale',
    () {
      final eggs = InventoryItem.create(
        id: 'eggs',
        name: 'Eggs',
        entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
        storeName: 'Store',
        quantity: 8,
        initialAmount: 8000,
        currentAmount: 8000,
        amountScale: inventoryPieceAmountScale,
        amountUnit: InventoryAmountUnit.piece,
      );
      final meal = PreparedMeal(
        id: 'meal-eggs',
        name: 'Omelette',
        totalPortions: 2,
        remainingPortions: 2,
        totalKcal: 620,
        totalProtein: 52,
        totalCarbs: 4,
        totalFat: 44,
        createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
        updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
        components: [
          PreparedMealComponent(
            inventoryItemId: eggs.id,
            name: eggs.name,
            brand: eggs.brand,
            imageUrl: eggs.imageUrl,
            usedAmount: 8000,
            usedUnit: InventoryAmountUnit.piece,
            totalKcal: 620,
            totalProtein: 52,
            totalCarbs: 4,
            totalFat: 44,
            sourceItemSnapshot: eggs,
          ),
        ],
      );

      final components = PreparedMealEatCalculator(meal).scaledComponents(1);

      expect(components.single.amount, 4);
    },
  );
}

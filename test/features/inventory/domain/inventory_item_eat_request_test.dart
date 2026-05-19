import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';

InventoryItemEatRequest _eatRequest({
  double? calorieAmount,
  ConsumedUnit? calorieUnit,
  double? portionBaseAmount,
  ConsumedUnit? portionBaseUnit,
  double? portionCount,
  String? portionLabel,
}) {
  return InventoryItemEatRequest(
    inventoryAmount: 1,
    loggedAt: DateTime.parse('2026-04-06T12:30:00Z'),
    mealType: MealType.lunch,
    calorieAmount: calorieAmount,
    calorieUnit: calorieUnit,
    portionBaseAmount: portionBaseAmount,
    portionBaseUnit: portionBaseUnit,
    portionCount: portionCount,
    portionLabel: portionLabel,
  );
}

void main() {
  group('InventoryItemEatRequest', () {
    test('tracks manual calorie portions and portion learning metadata', () {
      final plainRequest = _eatRequest();
      final portionRequest = _eatRequest(
        calorieAmount: 250,
        calorieUnit: ConsumedUnit.grams,
        portionBaseAmount: 125,
        portionBaseUnit: ConsumedUnit.grams,
        portionCount: 2,
        portionLabel: '2 servings',
      );

      expect(plainRequest.hasManualCaloriePortion, isFalse);
      expect(plainRequest.hasPortionLearning, isFalse);
      expect(portionRequest.hasManualCaloriePortion, isTrue);
      expect(portionRequest.hasPortionLearning, isTrue);
      expect(portionRequest.portionLabel, '2 servings');
    });

    test('requires calorie amount and unit to be provided together', () {
      expect(
        () => _eatRequest(calorieAmount: 250),
        throwsA(isA<AssertionError>()),
      );
    });

    test('requires complete portion learning metadata', () {
      expect(
        () => _eatRequest(
          portionBaseAmount: 125,
          portionBaseUnit: ConsumedUnit.grams,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}

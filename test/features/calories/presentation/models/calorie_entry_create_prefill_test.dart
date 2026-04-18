import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_prefill.dart';

CalorieProductProfile _profile() {
  return CalorieProductProfile(
    barcode: '4061458029995',
    name: 'Waffelhorn',
    brand: 'Mucci',
    per100Kcal: 215,
    per100Protein: 4.2,
    per100Carbs: 24.8,
    per100Fat: 9.6,
    source: CalorieProductSource.userOverride,
    offProductId: 'off-4061458029995',
    imageUrl: 'https://example.com/waffel.png',
    createdAt: DateTime.parse('2026-04-01T09:00:00Z'),
    updatedAt: DateTime.parse('2026-04-01T09:00:00Z'),
  );
}

CalorieInventoryCreateContext _inventoryContext({
  double consumedAmount = 250,
  ConsumedUnit consumedUnit = ConsumedUnit.grams,
  String pendingConsumptionId = 'pending-1',
}) {
  return CalorieInventoryCreateContext(
    inventoryItemId: 'inventory-1',
    foodFingerprint: 'milk-1l',
    globalFoodItemId: 'off-milk',
    pendingConsumptionId: pendingConsumptionId,
    inventoryAmountToRestore: 250,
    itemName: 'Milk',
    itemBrand: 'Brand',
    consumedAmount: consumedAmount,
    consumedUnit: consumedUnit,
  );
}

void main() {
  test('uses provided args to build the create prefill', () {
    final loggedAt = DateTime.parse('2026-04-06T12:30:00Z');

    final prefill = CalorieEntryCreatePrefill.fromArgs(
      prefilledProfile: _profile(),
      inventoryContext: _inventoryContext(),
      preselectedMealType: MealType.lunch,
      preselectedLoggedAt: loggedAt,
    );

    expect(prefill.name, 'Waffelhorn');
    expect(prefill.brand, 'Mucci');
    expect(prefill.consumedAmount, 250);
    expect(prefill.consumedUnit, ConsumedUnit.grams);
    expect(prefill.per100Kcal, 215);
    expect(prefill.mealType, MealType.lunch);
    expect(prefill.loggedAt, loggedAt);
  });

  test('falls back to now, 100 grams, and empty text values', () {
    final before = DateTime.now();
    final prefill = CalorieEntryCreatePrefill.fromArgs(
      prefilledProfile: null,
      inventoryContext: null,
      preselectedMealType: null,
      preselectedLoggedAt: null,
    );
    final after = DateTime.now();

    expect(prefill.name, '');
    expect(prefill.brand, '');
    expect(prefill.consumedAmount, 100);
    expect(prefill.consumedUnit, ConsumedUnit.grams);
    expect(prefill.loggedAt.isBefore(before), isFalse);
    expect(prefill.loggedAt.isAfter(after), isFalse);
    expect(prefill.mealType, MealType.defaultForDateTime(prefill.loggedAt));
  });

  test('initialization key stays stable for identical args', () {
    final loggedAt = DateTime.parse('2026-04-06T07:15:00Z');

    final first = CalorieEntryCreatePrefill.fromArgs(
      prefilledProfile: _profile(),
      inventoryContext: _inventoryContext(),
      preselectedMealType: MealType.breakfast,
      preselectedLoggedAt: loggedAt,
    );
    final second = CalorieEntryCreatePrefill.fromArgs(
      prefilledProfile: _profile(),
      inventoryContext: _inventoryContext(),
      preselectedMealType: MealType.breakfast,
      preselectedLoggedAt: loggedAt,
    );

    expect(first.initializationKey, second.initializationKey);
  });

  test('initialization key changes when meal type changes', () {
    final loggedAt = DateTime.parse('2026-04-06T12:30:00Z');

    final lunch = CalorieEntryCreatePrefill.fromArgs(
      prefilledProfile: _profile(),
      inventoryContext: _inventoryContext(),
      preselectedMealType: MealType.lunch,
      preselectedLoggedAt: loggedAt,
    );
    final dinner = CalorieEntryCreatePrefill.fromArgs(
      prefilledProfile: _profile(),
      inventoryContext: _inventoryContext(),
      preselectedMealType: MealType.dinner,
      preselectedLoggedAt: loggedAt,
    );

    expect(lunch.initializationKey, isNot(dinner.initializationKey));
  });

  test('initialization key changes when loggedAt changes', () {
    final first = CalorieEntryCreatePrefill.fromArgs(
      prefilledProfile: _profile(),
      inventoryContext: _inventoryContext(),
      preselectedMealType: MealType.lunch,
      preselectedLoggedAt: DateTime.parse('2026-04-06T12:30:00Z'),
    );
    final second = CalorieEntryCreatePrefill.fromArgs(
      prefilledProfile: _profile(),
      inventoryContext: _inventoryContext(),
      preselectedMealType: MealType.lunch,
      preselectedLoggedAt: DateTime.parse('2026-04-06T18:45:00Z'),
    );

    expect(first.initializationKey, isNot(second.initializationKey));
  });

  test(
    'initialization key changes with inventory context '
    'even without a profile',
    () {
      final loggedAt = DateTime.parse('2026-04-06T12:30:00Z');

      final first = CalorieEntryCreatePrefill.fromArgs(
        prefilledProfile: null,
        inventoryContext: _inventoryContext(),
        preselectedMealType: MealType.lunch,
        preselectedLoggedAt: loggedAt,
      );
      final second = CalorieEntryCreatePrefill.fromArgs(
        prefilledProfile: null,
        inventoryContext: _inventoryContext(pendingConsumptionId: 'pending-2'),
        preselectedMealType: MealType.lunch,
        preselectedLoggedAt: loggedAt,
      );

      expect(first.initializationKey, isNot(second.initializationKey));
    },
  );
}

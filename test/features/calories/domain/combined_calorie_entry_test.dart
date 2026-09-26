import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_bundle_component.dart';
import 'package:yamt/features/calories/domain/calorie_nutrient_details.dart';
import 'package:yamt/features/calories/domain/combined_calorie_entry.dart';

final DateTime _now = DateTime.parse('2026-09-26T12:00:00Z');

CalorieEntryBundleComponent _component(
  String name, {
  double kcal = 100,
  String? itemId,
  int? amountToRestore,
}) {
  return CalorieEntryBundleComponent(
    name: name,
    amountLabel: '50 g',
    totalKcal: kcal,
    totalProtein: 4,
    totalCarbs: 10,
    totalFat: 2,
    sourceInventoryItemId: itemId,
    sourceInventoryAmountToRestore: amountToRestore,
  );
}

CalorieEntry _combined(List<CalorieEntryBundleComponent> components) {
  return buildCombinedCalorieEntry(
    id: 'entry-1',
    userId: 'user-1',
    mealType: MealType.lunch,
    loggedAt: _now,
    now: _now,
    components: components,
  );
}

void main() {
  _nutrientTests();

  test('names the entry after its foods and sums their values', () {
    final entry = _combined([
      _component('Bread', kcal: 190),
      _component('Gouda', kcal: 217),
    ]);

    expect(entry.name, 'Bread + Gouda');
    expect(entry.totalKcal, 407);
    expect(entry.per100Kcal, 407);
    expect(entry.totalProtein, 8);
    expect(entry.consumedAmount, 100);
    expect(entry.createdAt, _now);
  });

  test('is a combined bundle, not a prepared meal', () {
    final entry = _combined([_component('Bread'), _component('Gouda')]);

    expect(entry.isBundle, isTrue);
    expect(entry.isCombined, isTrue);
    expect(entry.canReturnPreparedMealToInventory, isFalse);
  });

  test('can return stock when a food has a stock source', () {
    final withoutStock = _combined([_component('Bread'), _component('Gouda')]);
    final withStock = _combined([
      _component('Bread'),
      _component('Gouda', itemId: 'gouda', amountToRestore: 60),
    ]);

    expect(withoutStock.canReturnCombinedToInventory, isFalse);
    expect(withStock.canReturnCombinedToInventory, isTrue);
  });

  test('keeps the stock source of each food through JSON', () {
    final entry = _combined([
      _component('Bread', itemId: 'bread', amountToRestore: 1),
      _component('Gouda', itemId: 'gouda', amountToRestore: 60),
    ]);

    final roundtrip = CalorieEntry.fromJson(entry.toJson());

    expect(roundtrip.isCombined, isTrue);
    expect(roundtrip.bundleComponents.last.sourceInventoryItemId, 'gouda');
    expect(roundtrip.bundleComponents.last.sourceInventoryAmountToRestore, 60);
  });

  test('a prepared meal bundle is not combined', () {
    final entry = CalorieEntry.bundle(
      id: 'bundle-1',
      userId: 'user-1',
      name: 'Chili',
      mealType: MealType.dinner,
      totalKcal: 420,
      totalProtein: 28,
      totalCarbs: 35,
      totalFat: 18,
      bundleSourcePreparedMealId: 'prepared-1',
      bundleConsumedPortions: 2,
      bundleTotalPortions: 4,
      bundleComponents: [_component('Beans')],
    );

    expect(entry.isBundle, isTrue);
    expect(entry.isCombined, isFalse);
  });

  test('counts a food that appears several times in the name', () {
    expect(combinedFoodName(['Apfel', 'Apfel']), '2× Apfel');
    expect(combinedFoodName(['Apfel', 'Brot', 'Apfel']), '2× Apfel + Brot');
    expect(combinedFoodName(['Brot', 'Gouda']), 'Brot + Gouda');
  });

  test('needs at least two foods', () {
    expect(() => _combined([_component('Bread')]), throwsArgumentError);
  });
}

void _nutrientTests() {
  test('sums label nutrients of the eaten amounts', () {
    final details = combineCalorieNutrientDetails([
      (
        details: const CalorieNutrientDetails(per100Sugar: 10, per100Salt: 1),
        amount: 50,
      ),
      (
        details: const CalorieNutrientDetails(per100Sugar: 4, per100Salt: 2),
        amount: 200,
      ),
    ]);

    expect(details?.per100Sugar, 13);
    expect(details?.per100Salt, 4.5);
  });

  test('leaves a nutrient unknown when one food lacks it', () {
    final details = combineCalorieNutrientDetails([
      (
        details: const CalorieNutrientDetails(per100Sugar: 10, per100Salt: 1),
        amount: 50,
      ),
      (details: const CalorieNutrientDetails(per100Salt: 2), amount: 100),
    ]);

    expect(details?.per100Sugar, isNull);
    expect(details?.per100Salt, 2.5);
  });

  test('is null when no food lists nutrients', () {
    expect(
      combineCalorieNutrientDetails([(details: null, amount: 50)]),
      isNull,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_edits.dart';

void main() {
  final loggedAt = DateTime(2026, 2, 25, 8);

  CalorieEntry entry({String? sourceInventoryItemId}) {
    return CalorieEntry.create(
      id: 'entry-1',
      userId: 'user-1',
      name: 'Skyr',
      imageAssetId: 'asset-1',
      mealType: MealType.breakfast,
      consumedAmount: 200,
      consumedUnit: ConsumedUnit.grams,
      per100Kcal: 100,
      per100Protein: 10,
      per100Carbs: 5,
      per100Fat: 1,
      sourceInventoryItemId: sourceInventoryItemId,
      sourceInventoryAmountToRestore: sourceInventoryItemId == null ? null : 2,
      loggedAt: loggedAt,
      createdAt: loggedAt,
      updatedAt: loggedAt,
    );
  }

  CalorieEntry bundle() {
    return CalorieEntry.bundle(
      id: 'bundle-1',
      userId: 'user-1',
      name: 'Chili',
      mealType: MealType.lunch,
      totalKcal: 420,
      totalProtein: 28,
      totalCarbs: 35,
      totalFat: 18,
      bundleSourcePreparedMealId: 'prepared-1',
      bundleConsumedPortions: 1,
      bundleTotalPortions: 4,
      bundleComponents: const [
        CalorieEntryBundleComponent(
          name: 'Beans',
          amountLabel: '150 g',
          totalKcal: 120,
          totalProtein: 8,
          totalCarbs: 18,
          totalFat: 1,
        ),
      ],
      loggedAt: loggedAt,
      createdAt: loggedAt,
      updatedAt: loggedAt,
    );
  }

  test('amount is editable only for plain entries', () {
    expect(canEditCalorieEntryAmount(entry()), isTrue);
    expect(
      canEditCalorieEntryAmount(entry(sourceInventoryItemId: 'inventory-1')),
      isFalse,
    );
    expect(canEditCalorieEntryAmount(bundle()), isFalse);
  });

  test('rescale scales totals to the new amount', () {
    final now = DateTime(2026, 2, 25, 12);

    final rescaled = rescaleCalorieEntry(entry(), amount: 50, now: now);

    expect(rescaled.consumedAmount, 50);
    expect(rescaled.totalKcal, 50);
    expect(rescaled.totalProtein, 5);
    expect(rescaled.updatedAt, now);
  });

  test('repeat logs the same food now without the inventory link', () {
    final now = DateTime(2026, 2, 26, 19, 30);

    final repeated = repeatCalorieEntry(
      entry(sourceInventoryItemId: 'inventory-1'),
      id: 'entry-2',
      now: now,
    );

    expect(repeated.id, 'entry-2');
    expect(repeated.name, 'Skyr');
    expect(repeated.consumedAmount, 200);
    expect(repeated.imageAssetId, 'asset-1');
    expect(repeated.loggedAt, now);
    expect(repeated.mealType, MealType.defaultForDateTime(now));
    expect(repeated.sourceInventoryItemId, isNull);
    expect(repeated.canRestoreToInventory, isFalse);
  });

  test('bundles cannot be repeated', () {
    expect(canRepeatCalorieEntry(entry()), isTrue);
    expect(canRepeatCalorieEntry(bundle()), isFalse);
  });

  test('nutrient details survive JSON and edits', () {
    final withDetails = CalorieEntry.fromJson(<String, dynamic>{
      ...entry().toJson(),
      'nutrient_details': <String, Object?>{
        'per_100_sugar': 4,
        'per_100_salt': 0.1,
      },
    });

    final decoded = CalorieEntry.fromJson(withDetails.toJson());
    final rescaled = rescaleCalorieEntry(decoded, amount: 50, now: loggedAt);

    expect(decoded.nutrientDetails?.per100Sugar, 4);
    expect(decoded.nutrientDetails?.per100Fiber, isNull);
    expect(rescaled.nutrientDetails?.per100Salt, 0.1);
  });
}

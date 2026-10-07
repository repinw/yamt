import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_bundle_component.dart';
import 'package:yamt/features/calories/domain/calorie_entry_edits.dart';
import 'package:yamt/features/calories/domain/combined_calorie_entry.dart';
import 'package:yamt/features/calories/domain/quick_calorie_entry.dart';

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

  test('amount is editable for every entry except bundles and quick '
      'entries', () {
    expect(canEditCalorieEntryAmount(entry()), isTrue);
    expect(
      canEditCalorieEntryAmount(entry(sourceInventoryItemId: 'inventory-1')),
      isTrue,
    );
    expect(canEditCalorieEntryAmount(bundle()), isFalse);
    expect(
      canEditCalorieEntryAmount(
        buildQuickCalorieEntry(
          id: 'quick-1',
          userId: 'user-1',
          name: 'Quick entry',
          mealType: MealType.snack,
          loggedAt: loggedAt,
          now: loggedAt,
          kcal: 300,
        ),
      ),
      isFalse,
    );
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
    expect(canRepeatCalorieEntry(_combined()), isTrue);
  });

  test('a repeated combined entry keeps its foods without stock sources', () {
    final repeated = repeatCalorieEntry(
      _combined(),
      id: 'copy',
      now: DateTime(2026, 9, 27, 12),
    );

    expect(repeated.isCombined, isTrue);
    expect(repeated.bundleComponents.map((c) => c.name), ['Bread', 'Gouda']);
    expect(repeated.canReturnCombinedToInventory, isFalse);
  });

  test('a plan again keeps meal, time of day, and the Vorrat item', () {
    final now = DateTime(2026, 2, 25, 19, 30);
    final plan = planCalorieEntryAgain(
      entry(sourceInventoryItemId: 'skyr'),
      id: 'plan-1',
      day: DateTime(2026, 2, 27),
      now: now,
    );

    expect(plan.id, 'plan-1');
    expect(plan.mealType, MealType.breakfast);
    expect(plan.loggedAt, DateTime(2026, 2, 27, 8));
    expect(plan.createdAt, now);
    expect(plan.consumedAmount, 200);
    expect(plan.sourceInventoryItemId, 'skyr');
    expect(plan.sourceInventoryAmountToRestore, 2);
  });

  test('a plan again of a combined entry has no stock source', () {
    final plan = planCalorieEntryAgain(
      _combined(),
      id: 'plan-1',
      day: DateTime(2026, 9, 28),
      now: DateTime(2026, 9, 27, 12),
    );

    expect(plan.sourceInventoryItemId, isNull);
    expect(plan.canReturnCombinedToInventory, isFalse);
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

CalorieEntry _combined() {
  CalorieEntryBundleComponent food(String name) => CalorieEntryBundleComponent(
    name: name,
    amountLabel: '80 g',
    totalKcal: 190,
    totalProtein: 6,
    totalCarbs: 36,
    totalFat: 2,
    sourceInventoryItemId: name.toLowerCase(),
    sourceInventoryAmountToRestore: 80,
  );
  return buildCombinedCalorieEntry(
    id: 'combined',
    userId: 'user',
    mealType: MealType.lunch,
    loggedAt: DateTime(2026, 9, 27, 8),
    now: DateTime(2026, 9, 27, 8),
    components: [food('Bread'), food('Gouda')],
  );
}

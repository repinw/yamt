import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_item_patch.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

GlobalFoodItem _item({
  required String id,
  String? brand,
  String? packageWeight,
  GlobalFoodNutrition? nutrition,
  DateTime? now,
}) {
  final resolvedNow = now ?? DateTime.parse('2026-04-13T10:00:00Z');
  return GlobalFoodItem.create(
    id: id,
    name: 'Milk',
    now: resolvedNow,
    brand: brand,
    barcode: '4006381333931',
    packageWeight: packageWeight,
    nutrition: nutrition,
  );
}

void main() {
  test('mergeGlobalFoodItemPatch fills missing fields from patch item', () {
    final now = DateTime.parse('2026-04-13T10:00:00Z');
    final updatedAt = now.add(const Duration(minutes: 5));
    final merged = mergeGlobalFoodItemPatch(
      currentItem: _item(id: 'milk', now: now),
      patchItem: _item(
        id: 'milk',
        now: now,
        brand: 'Acme',
        packageWeight: '1 l',
        nutrition: const GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.verified,
          per100Kcal: 100,
        ),
      ),
      updatedAt: updatedAt,
    );

    expect(merged.brand, 'Acme');
    expect(merged.packageWeight, '1 l');
    expect(merged.nutrition?.per100Kcal, 100);
    expect(merged.updatedAt, updatedAt);
  });

  test('mergeGlobalFoodItemPatch keeps populated fields unchanged', () {
    final now = DateTime.parse('2026-04-13T10:00:00Z');
    final merged = mergeGlobalFoodItemPatch(
      currentItem: _item(
        id: 'milk',
        now: now,
        brand: 'Acme',
        packageWeight: '1 l',
        nutrition: const GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.verified,
          per100Kcal: 100,
        ),
      ),
      patchItem: _item(
        id: 'milk',
        now: now,
        brand: 'Spam',
        packageWeight: '500 ml',
        nutrition: const GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.verified,
          per100Kcal: 250,
        ),
      ),
      updatedAt: now.add(const Duration(minutes: 5)),
    );

    expect(merged.brand, 'Acme');
    expect(merged.packageWeight, '1 l');
    expect(merged.nutrition?.per100Kcal, 100);
  });

  test(
    'mergeGlobalFoodNutritionPatch returns present side when other null',
    () {
      const nutrition = GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
        per100Kcal: 120,
      );

      expect(mergeGlobalFoodNutritionPatch(null, nutrition), nutrition);
      expect(mergeGlobalFoodNutritionPatch(nutrition, null), nutrition);
    },
  );

  test('mergeGlobalFoodNutritionPatch keeps higher quality status regardless '
      'of source order', () {
    const verified = GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 100,
    );
    const unverified = GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
      per100Protein: 10,
    );

    final upgraded = mergeGlobalFoodNutritionPatch(unverified, verified);
    final preserved = mergeGlobalFoodNutritionPatch(verified, unverified);

    expect(upgraded?.qualityStatus, GlobalFoodNutritionQualityStatus.verified);
    expect(preserved?.qualityStatus, GlobalFoodNutritionQualityStatus.verified);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/'
    'global_food_item_edit_policy.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

void main() {
  final now = DateTime.parse('2026-04-13T10:00:00Z');

  test('classify returns unchanged when product fields stay the same', () {
    final item = GlobalFoodItem.create(
      id: 'milk',
      name: 'Milk',
      now: now,
      brand: 'Acme',
      barcode: '4006381333931',
    );

    final kind = classifyGlobalFoodItemEdit(
      currentItem: item,
      name: 'Milk',
      brand: 'Acme',
      barcode: '4006381333931',
    );

    expect(kind, GlobalFoodItemEditKind.unchanged);
  });

  test('classify patches existing item when only missing data is filled', () {
    final item = GlobalFoodItem.create(
      id: 'milk',
      name: 'Milk',
      now: now,
      barcode: '4006381333931',
    );

    final kind = classifyGlobalFoodItemEdit(
      currentItem: item,
      name: 'Milk',
      brand: 'Acme',
      barcode: '4006381333931',
      nutrition: const GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.verified,
        per100Kcal: 100,
        per100Protein: 10,
        per100Carbs: 20,
        per100Fat: 3,
      ),
    );

    expect(kind, GlobalFoodItemEditKind.patchExisting);
  });

  test('classify creates new candidate when existing value changes', () {
    final item = GlobalFoodItem.create(
      id: 'milk',
      name: 'Milk',
      now: now,
      brand: 'Acme',
      barcode: '4006381333931',
      nutrition: const GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.verified,
        per100Kcal: 100,
        per100Protein: 10,
        per100Carbs: 20,
        per100Fat: 3,
      ),
    );

    final kind = classifyGlobalFoodItemEdit(
      currentItem: item,
      name: 'Oat Milk',
      brand: 'Acme',
      barcode: '4006381333931',
      nutrition: const GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.verified,
        per100Kcal: 100,
        per100Protein: 10,
        per100Carbs: 20,
        per100Fat: 3,
      ),
    );

    expect(kind, GlobalFoodItemEditKind.createNewCandidate);
  });

  test('classify keeps equivalent package weight on same candidate', () {
    final item = GlobalFoodItem.create(
      id: 'milk',
      name: 'Milk',
      now: now,
      brand: 'Acme',
      barcode: '4006381333931',
      packageWeight: '1 l',
    );

    final kind = classifyGlobalFoodItemEdit(
      currentItem: item,
      name: 'Milk',
      brand: 'Acme',
      barcode: '4006381333931',
      packageWeight: '1000 ml',
    );

    expect(kind, GlobalFoodItemEditKind.unchanged);
  });
}

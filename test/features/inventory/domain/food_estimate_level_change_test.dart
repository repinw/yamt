import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/food_estimate.dart';
import 'package:yamt/features/inventory/domain/food_estimate_level_change.dart';
import 'package:yamt/features/inventory/domain/food_fingerprint.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

const _old = FoodEstimate(
  name: 'Rice bowl',
  portionGrams: 400,
  kcalLean: 300,
  kcalRich: 600,
  per100: GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
    per100Kcal: 100,
  ),
  ingredients: [],
);

const _new = FoodEstimate(
  name: 'Fried rice',
  portionGrams: 350,
  kcalLean: 500,
  kcalRich: 800,
  per100: GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
    per100Kcal: 180,
  ),
  ingredients: [FoodEstimateIngredient(name: 'Rice', grams: 300, kcal: 500)],
);

const _oldPhoto = 'gs://yamt/users/u1/food_photos/old.jpg';

InventoryItem _withEstimate(
  InventoryItem item,
  FoodEstimate estimate, {
  List<String> photoUrls = const [],
}) {
  return item.copyWith(
    nutrition: estimate.per100,
    productSnapshot: item.productSnapshot.copyWith(
      aiEstimate: SavedFoodEstimate(
        estimate: estimate,
        level: FoodEstimateLevel.normal,
        description: 'with egg',
        photoUrls: photoUrls,
      ),
    ),
  );
}

void main() {
  // Half of the bowl is eaten.
  final stored = _withEstimate(
    InventoryItem.create(
      id: 'bowl',
      name: 'Rice bowl',
      entryDate: DateTime.utc(2026, 10, 2),
      storeName: 'Store',
      quantity: 1,
      initialAmount: 400,
      currentAmount: 200,
      amountUnit: InventoryAmountUnit.gram,
      weight: '400 g',
      aiEstimated: true,
    ).copyWith(imageUrl: _oldPhoto),
    _old,
    photoUrls: [_oldPhoto],
  );

  test('a new estimate replaces the food and keeps the stock (#763)', () {
    final estimated = _withEstimate(
      stored.copyWith(
        name: 'Fried rice',
        weight: '350 g',
        currentAmount: 350,
        imageUrl: null,
      ),
      _new,
    );

    final next = stored.withNewEstimate(estimated);

    expect(next.name, 'Fried rice');
    expect(next.nutrition, _new.per100);
    expect(next.productSnapshot.aiEstimate?.estimate, _new);
    expect(next.currentAmount, 200);
    expect(next.weight, '400 g');
    expect(next.entryDate, stored.entryDate);
    // Photos the user removed on the AI page go.
    expect(next.imageUrl, isNull);
    expect(next.productSnapshot.aiEstimate?.photoUrls, isEmpty);
    // The food is found under its new name.
    final fingerprint = computeFoodFingerprint(name: 'Fried rice');
    expect(next.resolvedFoodFingerprint, fingerprint);
    expect(next.globalFoodItemId, buildPendingGlobalFoodItemId(fingerprint));
  });

  test('the old food comes back exactly, also without photos (#763)', () {
    const photo = 'gs://yamt/users/u1/food_photos/new.jpg';
    final plain = _withEstimate(stored.copyWith(imageUrl: null), _old);
    final next = plain.withNewEstimate(
      _withEstimate(stored.copyWith(imageUrl: photo), _new, photoUrls: [photo]),
    );

    final back = next.withAiFoodOf(
      plain,
      foodFingerprint: plain.resolvedFoodFingerprint,
    );

    expect(back.name, 'Rice bowl');
    expect(back.imageUrl, isNull);
    expect(back.productSnapshot.aiEstimate, plain.productSnapshot.aiEstimate);
    expect(back.resolvedFoodFingerprint, plain.resolvedFoodFingerprint);
  });

  test('new photos replace the old ones (#763)', () {
    const photo = 'gs://yamt/users/u1/food_photos/new.jpg';
    final estimated = _withEstimate(
      stored.copyWith(imageUrl: photo),
      _new,
      photoUrls: [photo],
    );

    final next = stored.withNewEstimate(estimated);

    expect(next.imageUrl, photo);
    expect(next.productSnapshot.aiEstimate?.photoUrls, [photo]);
  });
}

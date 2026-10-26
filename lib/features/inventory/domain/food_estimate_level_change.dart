import 'package:yamt/features/inventory/domain/food_estimate.dart';
import 'package:yamt/features/inventory/domain/food_fingerprint.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Changes how an AI food was prepared or estimated.
extension FoodEstimateLevelChange on InventoryItem {
  /// The item prepared at [level]: its nutrition follows its AI estimate
  /// from now on, while diary entries already eaten keep theirs (#763).
  /// Unchanged without an estimate.
  InventoryItem withFoodEstimateLevel(FoodEstimateLevel level) {
    final saved = productSnapshot.aiEstimate;
    if (saved == null) return this;
    return copyWith(
      nutrition: saved.estimate.per100At(level),
      productSnapshot: productSnapshot.copyWith(
        aiEstimate: saved.copyWith(level: level),
      ),
    );
  }

  /// The item with the AI estimate of [estimated], the same food estimated
  /// again: its name, nutrition, portion, estimate and photos. The AI page
  /// starts from the stored photos, so only those the user removed go.
  /// Stock and dates stay (#763). Unchanged without an estimate.
  InventoryItem withNewEstimate(InventoryItem estimated) {
    if (estimated.productSnapshot.aiEstimate == null) return this;
    return withAiFoodOf(
      estimated,
      foodFingerprint: computeFoodFingerprint(
        name: estimated.name,
        brand: brand,
      ),
    );
  }

  /// The item showing exactly the AI food of [other], with
  /// [foodFingerprint] for its name; its stock and dates stay (#763).
  InventoryItem withAiFoodOf(
    InventoryItem other, {
    required String foodFingerprint,
  }) {
    return copyWith(
      name: other.name,
      nutrition: other.nutrition,
      servingSize: other.servingSize,
      servingQuantity: other.servingQuantity,
      servingQuantityUnit: other.servingQuantityUnit,
      imageUrl: other.imageUrl,
      foodFingerprint: foodFingerprint,
      // An AI food stays off the catalog under its pending id (#701).
      globalFoodItemId: isPendingGlobalFoodItemId(globalFoodItemId)
          ? buildPendingGlobalFoodItemId(foodFingerprint)
          : globalFoodItemId,
      productSnapshot: productSnapshot.copyWith(
        aiEstimate: other.productSnapshot.aiEstimate,
      ),
    );
  }
}

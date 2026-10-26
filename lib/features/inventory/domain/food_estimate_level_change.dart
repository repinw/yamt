import 'package:yamt/features/inventory/domain/food_estimate.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Changes how an AI food was prepared.
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
}

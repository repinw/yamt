import 'package:yamt/features/inventory/domain/food_estimate.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Builds the inventory item for [estimate] at [level], with [grams] as its
/// amount and the estimated portion as its serving.
///
/// [baseItem] carries the household and store context of the caller. The
/// item keeps the estimate, [level] and the user's [description] (#763).
InventoryItem buildFoodEstimateItem({
  required InventoryItem baseItem,
  required FoodEstimate estimate,
  required FoodEstimateLevel level,
  required int grams,
  required String description,
}) {
  final weight = '$grams g';
  final portion = '${estimate.portionGrams.round()} g';
  return baseItem
      .copyWith(
        productSnapshot: baseItem.productSnapshot.copyWith(
          aiEstimate: SavedFoodEstimate(
            estimate: estimate,
            level: level,
            description: description,
          ),
        ),
        name: estimate.name,
        brand: null,
        barcode: '',
        weight: weight,
        servingSize: portion,
        servingQuantity: estimate.portionGrams,
        servingQuantityUnit: InventoryAmountUnit.gram.code,
        nutrition: estimate.per100At(level),
        imageUrl: null,
        // It stays the user's own on every later save (#701).
        aiEstimated: true,
      )
      .withResolvedAmount(
        weight: weight,
        parsedAmount: InventoryAmountParseResult(
          amount: grams,
          unit: InventoryAmountUnit.gram,
        ),
        quantity: baseItem.quantity,
      );
}

/// Drops the AI estimate of an item's own food.
extension FoodEstimateItemPick on InventoryItem {
  /// The item for a food the user picked instead: the estimate described
  /// the item's own food (#763).
  InventoryItem get withoutAiEstimate =>
      copyWith(productSnapshot: productSnapshot.copyWith(aiEstimate: null));

  /// The item with the first of [photoUrls] as its image and all of them on
  /// its AI estimate (#763); unchanged without a photo.
  InventoryItem withFoodPhotos(List<String> photoUrls) {
    if (photoUrls.isEmpty) return this;
    return copyWith(
      imageUrl: photoUrls.first,
      productSnapshot: productSnapshot.copyWith(
        aiEstimate: productSnapshot.aiEstimate?.withPhotoUrls(photoUrls),
      ),
    );
  }
}

import 'package:yamt/features/inventory/domain/food_estimate.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Builds the inventory item for [estimate] at [level], with [grams] as its
/// amount and the estimated portion as its serving.
///
/// [baseItem] carries the household and store context of the caller.
InventoryItem buildFoodEstimateItem({
  required InventoryItem baseItem,
  required FoodEstimate estimate,
  required FoodEstimateLevel level,
  required int grams,
}) {
  final weight = '$grams g';
  final portion = '${estimate.portionGrams.round()} g';
  return baseItem
      .copyWith(
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

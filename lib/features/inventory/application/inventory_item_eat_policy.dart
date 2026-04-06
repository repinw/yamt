import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_eat_request.dart';

bool inventoryItemUsesFixedCalorieUnit(InventoryItem item) {
  if (!item.usesAmountProgress) {
    return false;
  }

  return item.amountUnit == InventoryAmountUnit.gram ||
      item.amountUnit == InventoryAmountUnit.milliliter;
}

bool inventoryItemRequiresManualCaloriePortion(InventoryItem item) {
  return !inventoryItemUsesFixedCalorieUnit(item);
}

ConsumedUnit? inventoryItemConsumedUnit(InventoryItem item) {
  return switch (item.amountUnit) {
    InventoryAmountUnit.gram => ConsumedUnit.grams,
    InventoryAmountUnit.milliliter => ConsumedUnit.milliliters,
    _ => null,
  };
}

bool canDirectlySaveInventoryItemEatRequest(
  InventoryItem item,
  InventoryItemEatRequest request,
) {
  if (request.hasManualCaloriePortion) {
    return false;
  }

  return inventoryItemUsesFixedCalorieUnit(item) &&
      item.nutrition?.hasAnyNutritionValue == true;
}

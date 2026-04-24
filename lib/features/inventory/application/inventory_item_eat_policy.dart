import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_eat_request.dart';

/// Inventory item uses fixed calorie unit.
bool inventoryItemUsesFixedCalorieUnit(InventoryItem item) {
  if (!item.usesAmountProgress) {
    return false;
  }

  return item.amountUnit == InventoryAmountUnit.gram ||
      item.amountUnit == InventoryAmountUnit.milliliter;
}

/// Inventory item requires manual calorie portion.
bool inventoryItemRequiresManualCaloriePortion(InventoryItem item) {
  return !inventoryItemUsesFixedCalorieUnit(item);
}

/// Inventory item consumed unit.
ConsumedUnit? inventoryItemConsumedUnit(InventoryItem item) {
  return switch (item.amountUnit) {
    InventoryAmountUnit.gram => ConsumedUnit.grams,
    InventoryAmountUnit.milliliter => ConsumedUnit.milliliters,
    _ => null,
  };
}

/// Can directly save inventory item eat request.
bool canDirectlySaveInventoryItemEatRequest(
  InventoryItem item,
  InventoryItemEatRequest request,
) {
  if (item.nutrition?.hasAnyNutritionValue != true) {
    return false;
  }

  if (inventoryItemUsesFixedCalorieUnit(item)) {
    if (!request.hasManualCaloriePortion) {
      return true;
    }
    return request.calorieUnit == inventoryItemConsumedUnit(item);
  }

  return request.hasManualCaloriePortion;
}

import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Normalizes optional image ids so empty strings are stored as null.
String? normalizeOptionalImageAssetId(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

/// Builds a prepared meal component from an inventory item snapshot.
PreparedMealComponent buildPreparedMealComponent({
  required InventoryItem item,
  required int usedAmount,
  required InventoryAmountUnit usedUnit,
  required GlobalFoodNutrition nutrition,
}) {
  final multiplier = _nutritionMultiplier(amount: usedAmount, unit: usedUnit);
  return PreparedMealComponent(
    inventoryItemId: item.id,
    name: item.name,
    brand: item.brand,
    imageUrl: item.imageUrl,
    usedAmount: usedAmount,
    usedUnit: usedUnit,
    totalKcal: (nutrition.per100Kcal ?? 0) * multiplier,
    totalProtein: (nutrition.per100Protein ?? 0) * multiplier,
    totalCarbs: (nutrition.per100Carbs ?? 0) * multiplier,
    totalFat: (nutrition.per100Fat ?? 0) * multiplier,
    sourceItemSnapshot: item,
  );
}

/// Resolves used unit for direct inventory consumption.
InventoryAmountUnit resolveUsedUnit(InventoryItem item) {
  if (item.usesAmountProgress) {
    return item.amountUnit ?? InventoryAmountUnit.piece;
  }
  return InventoryAmountUnit.piece;
}

/// Returns whether nutrition has all required macro values.
bool hasCompleteNutrition(GlobalFoodNutrition? nutrition) {
  if (nutrition == null) {
    return false;
  }
  return nutrition.per100Kcal != null &&
      nutrition.per100Protein != null &&
      nutrition.per100Carbs != null &&
      nutrition.per100Fat != null;
}

/// Returns available consumable amount for an inventory item.
int availableAmount(InventoryItem item) {
  if (item.usesAmountProgress) {
    return item.currentAmount > 0 ? item.currentAmount : 0;
  }
  return item.quantity > 0 ? item.quantity : 0;
}

/// Reduces an inventory item by a requested amount.
InventoryItem? reduceInventoryItem({
  required InventoryItem item,
  required int amount,
}) {
  if (amount < 1) {
    return null;
  }
  if (item.usesAmountProgress) {
    final nextCurrentAmount = item.currentAmount - amount;
    if (nextCurrentAmount < 0) {
      return null;
    }
    return item.copyWith(
      currentAmount: nextCurrentAmount,
      quantity: _quantityForCurrentAmount(
        item: item,
        currentAmount: nextCurrentAmount,
      ),
    );
  }

  final nextQuantity = item.quantity - amount;
  if (nextQuantity < 0) {
    return null;
  }
  return item.copyWith(quantity: nextQuantity);
}

/// Returns whether inventory item uses required amount unit directly.
bool hasCompatibleAmountUnit({
  required InventoryItem item,
  required InventoryAmountUnit requiredUnit,
}) {
  if (requiredUnit == InventoryAmountUnit.piece) {
    return !item.usesAmountProgress;
  }
  return item.usesAmountProgress && item.amountUnit == requiredUnit;
}

/// Returns whether item can satisfy a parsed template requirement.
bool hasCompatibleTemplateRequirement({
  required InventoryItem item,
  required InventoryAmountUnit requiredUnit,
}) {
  if (requiredUnit == InventoryAmountUnit.piece) {
    return availableAmount(item) > 0;
  }
  return hasCompatibleAmountUnit(item: item, requiredUnit: requiredUnit);
}

/// Resolves maximum amount consumable for a template requirement.
int consumableAmountForRequirement({
  required InventoryItem item,
  required InventoryAmountUnit requiredUnit,
  required int remainingAmount,
}) {
  if (remainingAmount < 1) {
    return 0;
  }

  final available = availableAmount(item);
  if (available < 1) {
    return 0;
  }

  if (requiredUnit == InventoryAmountUnit.piece && item.usesAmountProgress) {
    return available;
  }
  if (requiredUnit != InventoryAmountUnit.piece &&
      item.amountUnit != requiredUnit) {
    return 0;
  }
  return remainingAmount < available ? remainingAmount : available;
}

/// Resolves used unit when consuming from template assignment.
InventoryAmountUnit resolveTemplateUsedUnit({
  required InventoryItem item,
  required InventoryAmountUnit requiredUnit,
}) {
  if (requiredUnit == InventoryAmountUnit.piece && item.usesAmountProgress) {
    return item.amountUnit ?? InventoryAmountUnit.piece;
  }
  return requiredUnit;
}

/// Computes remaining parsed requirement after one item consumption.
int remainingRequirementAfterConsumption({
  required InventoryItem item,
  required InventoryAmountUnit requiredUnit,
  required int remainingAmount,
  required int consumedAmount,
}) {
  if (requiredUnit == InventoryAmountUnit.piece && item.usesAmountProgress) {
    return remainingAmount - 1;
  }
  return remainingAmount - consumedAmount;
}

/// Applies a portion reduction to a prepared meal list.
List<PreparedMeal> applyPreparedMealPortionReduction({
  required List<PreparedMeal> currentMeals,
  required int mealIndex,
  required num removedPortions,
  required DateTime updatedAt,
  bool keepDepletedMeal = false,
}) {
  final currentMeal = currentMeals[mealIndex];
  final nextRemainingPortions = currentMeal.remainingPortions - removedPortions;
  final nextMeals = List<PreparedMeal>.from(currentMeals);
  if (nextRemainingPortions <= 0 && !keepDepletedMeal) {
    nextMeals.removeAt(mealIndex);
    return nextMeals;
  }

  nextMeals[mealIndex] = currentMeal.copyWith(
    remainingPortions: nextRemainingPortions < 0 ? 0 : nextRemainingPortions,
    updatedAt: updatedAt,
  );
  return nextMeals;
}

/// Restores inventory items represented by a prepared meal's components.
List<InventoryItem> restoreItemsFromPreparedMeal({
  required List<InventoryItem> currentItems,
  required PreparedMeal meal,
}) {
  final nextItems = List<InventoryItem>.from(currentItems);
  for (final component in meal.components) {
    final amountToRestore = _restoreAmountForComponent(
      component: component,
      meal: meal,
    );
    if (amountToRestore < 1) {
      continue;
    }

    final itemIndex = nextItems.indexWhere(
      (item) => item.id == component.inventoryItemId,
    );
    if (itemIndex < 0) {
      nextItems.add(
        _buildRestoredSnapshotItem(
          sourceItem: component.sourceItemSnapshot,
          amountToRestore: amountToRestore,
        ),
      );
      continue;
    }

    nextItems[itemIndex] = _restoreInventoryItemAmount(
      item: nextItems[itemIndex],
      sourceItem: component.sourceItemSnapshot,
      amountToRestore: amountToRestore,
    );
  }
  return nextItems;
}

/// Computes the inventory amount represented by remaining prepared portions.
int remainingPreparedMealShareAmount({
  required int usedAmount,
  required int totalPortions,
  required num remainingPortions,
}) {
  if (totalPortions < 1 || remainingPortions <= 0) {
    return 0;
  }
  return ((usedAmount * remainingPortions) / totalPortions).round();
}

double _nutritionMultiplier({
  required int amount,
  required InventoryAmountUnit unit,
}) {
  if (unit == InventoryAmountUnit.piece) {
    return amount.toDouble();
  }
  return amount / 100;
}

int _restoreAmountForComponent({
  required PreparedMealComponent component,
  required PreparedMeal meal,
}) {
  return remainingPreparedMealShareAmount(
    usedAmount: component.usedAmount,
    totalPortions: meal.totalPortions,
    remainingPortions: meal.remainingPortions,
  );
}

InventoryItem _buildRestoredSnapshotItem({
  required InventoryItem sourceItem,
  required int amountToRestore,
}) {
  if (sourceItem.usesAmountProgress) {
    return sourceItem.copyWith(
      currentAmount: amountToRestore,
      quantity: _quantityForCurrentAmount(
        item: sourceItem,
        currentAmount: amountToRestore,
      ),
    );
  }
  return sourceItem.copyWith(quantity: amountToRestore);
}

InventoryItem _restoreInventoryItemAmount({
  required InventoryItem item,
  required InventoryItem sourceItem,
  required int amountToRestore,
}) {
  if (sourceItem.usesAmountProgress) {
    final nextCurrentAmount = item.currentAmount + amountToRestore;
    return item.copyWith(
      currentAmount: nextCurrentAmount,
      quantity: _quantityForCurrentAmount(
        item: sourceItem,
        currentAmount: nextCurrentAmount,
      ),
      nutrition: sourceItem.nutrition,
    );
  }
  return item.copyWith(
    quantity: item.quantity + amountToRestore,
    nutrition: sourceItem.nutrition,
  );
}

int _quantityForCurrentAmount({
  required InventoryItem item,
  required int currentAmount,
}) {
  final initialAmount = item.initialAmount;
  final initialQuantity = item.initialQuantity;
  if (initialAmount < 1 || initialQuantity < 1) {
    return item.quantity;
  }

  final ratio = currentAmount / initialAmount;
  final projectedQuantity = (initialQuantity * ratio).ceil();
  if (projectedQuantity < 0) {
    return 0;
  }
  if (projectedQuantity > initialQuantity) {
    return initialQuantity;
  }
  return projectedQuantity;
}

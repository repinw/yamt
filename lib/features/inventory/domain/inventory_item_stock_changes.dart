import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';

/// Caps [requestedAmount] at what [item] holds.
///
/// Returns null when the item is missing or empty, or [requestedAmount] is
/// below 1.
int? clampedRemovalAmount(InventoryItem? item, int requestedAmount) {
  if (item == null || requestedAmount < 1) {
    return null;
  }
  final available = item.availableAmount;
  if (available < 1) {
    return null;
  }
  return requestedAmount > available ? available : requestedAmount;
}

/// Takes [amount] out of the item [itemId], capped at what the item holds.
///
/// Returns null when the item is missing, empty, or [amount] is below 1.
List<InventoryItem>? buildReducedItems({
  required List<InventoryItem> currentItems,
  required String itemId,
  required int amount,
  required DateTime consumedAt,
}) {
  final itemIndex = currentItems.indexWhere((item) => item.id == itemId);
  if (itemIndex < 0) {
    return null;
  }

  final item = currentItems[itemIndex];
  final available = item.availableAmount;
  final reducedItem = item.reducedBy(
    amount > available ? available : amount,
    consumedAt: consumedAt,
  );
  if (reducedItem == null) {
    return null;
  }
  return List<InventoryItem>.from(currentItems)..[itemIndex] = reducedItem;
}

/// Returns [amount] to the item [itemId].
///
/// Returns null when the item is missing or [amount] is below 1.
List<InventoryItem>? buildRestoredItems({
  required List<InventoryItem> currentItems,
  required String itemId,
  required int amount,
}) {
  if (amount < 1) {
    return null;
  }

  final itemIndex = currentItems.indexWhere((item) => item.id == itemId);
  if (itemIndex < 0) {
    return null;
  }

  final restored = currentItems[itemIndex].restoredBy(amount);
  if (restored == null) {
    return null;
  }
  return List<InventoryItem>.from(currentItems)..[itemIndex] = restored;
}

/// Builds an edited item while preserving remaining stock for metadata edits.
InventoryItem buildInventoryItemEditSaveItem({
  required InventoryItem currentItem,
  required InventoryItem editedItem,
}) {
  final sameStockDefinition =
      editedItem.quantity == currentItem.quantity &&
      editedItem.initialAmount == currentItem.initialAmount &&
      editedItem.amountScale == currentItem.amountScale &&
      editedItem.amountUnit == currentItem.amountUnit;
  if (!sameStockDefinition) {
    return editedItem;
  }

  return editedItem.copyWith(
    quantity: currentItem.quantity,
    initialQuantity: currentItem.initialQuantity,
    initialAmount: currentItem.initialAmount,
    currentAmount: currentItem.currentAmount,
    amountScale: currentItem.amountScale,
    amountUnit: currentItem.amountUnit,
    lastConsumedAt: currentItem.lastConsumedAt,
  );
}

/// Points [sourceItem] at [resolvedProduct], or at its pending id when the
/// product is not in the catalog.
InventoryItem buildSwappedItem({
  required InventoryItem sourceItem,
  required GlobalFoodItem resolvedProduct,
  required String? weight,
  required bool canReferenceGlobalItem,
}) {
  final updatedItem = sourceItem.copyWith(
    globalFoodItemId: canReferenceGlobalItem
        ? resolvedProduct.id
        : buildPendingGlobalFoodItemId(resolvedProduct.resolvedFoodFingerprint),
    name: resolvedProduct.name,
    brand: resolvedProduct.brand,
    category: resolvedProduct.category,
    barcode: resolvedProduct.barcode,
    imageUrl: resolvedProduct.imageUrl,
    weight: weight,
    foodFingerprint: resolvedProduct.resolvedFoodFingerprint,
    servingSize: resolvedProduct.servingSize,
    servingQuantity: resolvedProduct.servingQuantity,
    servingQuantityUnit: resolvedProduct.servingQuantityUnit,
    nutrition: resolvedProduct.nutrition,
  );
  return updatedItem.withDerivedAmount(
    weight: updatedItem.weight,
    quantity: updatedItem.quantity,
    fallbackUnit: sourceItem.amountUnit,
  );
}

/// The item with [itemId] in [items], or null.
InventoryItem? findInventoryItem(List<InventoryItem> items, String itemId) {
  for (final item in items) {
    if (item.id == itemId) {
      return item;
    }
  }
  return null;
}

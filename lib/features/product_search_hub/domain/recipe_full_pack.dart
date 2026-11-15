import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_stock_count.dart';

/// The stock of one full pack of [item], picked for a recipe line measured
/// in [lineUnit], or null when the app cannot know it and must ask: the
/// item has no package size, or the line counts grams or ml and the item
/// is kept in pieces without the weight of one.
int? recipeFullPackAmount(InventoryItem item, InventoryAmountUnit? lineUnit) {
  if (!item.usesAmountProgress) return null;
  final byWeight =
      lineUnit == InventoryAmountUnit.gram ||
      lineUnit == InventoryAmountUnit.milliliter;
  if (byWeight &&
      item.amountUnit == InventoryAmountUnit.piece &&
      !hasPieceWeight(item)) {
    return null;
  }
  return item.initialAmount;
}

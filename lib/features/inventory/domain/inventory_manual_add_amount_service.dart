import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Resizes newly saved inventory stock to match immediate consumed amount.
InventoryItem resizeInventoryManualAddItemToConsumedAmount({
  required InventoryItem item,
  required int inventoryAmount,
}) {
  if (inventoryAmount < 1) {
    return item;
  }

  final unit = item.amountUnit;
  if (unit == null) {
    if (item.quantity == inventoryAmount &&
        item.initialQuantity == inventoryAmount) {
      return item;
    }
    return item.copyWith(
      quantity: inventoryAmount,
      initialQuantity: inventoryAmount,
    );
  }
  if (item.usesAmountProgress && item.currentAmount == inventoryAmount) {
    return item;
  }

  final amountScale = safeInventoryManualAddAmountScale(
    unit: unit,
    scale: item.amountScale,
  );
  final amountText = formatInventoryAmountValue(
    amount: inventoryAmount,
    unit: unit,
    scale: amountScale,
  );
  return item.withResolvedAmount(
    weight: '$amountText ${unit.code}',
    parsedAmount: InventoryAmountParseResult(
      amount: inventoryAmount,
      unit: unit,
      scale: amountScale,
    ),
    quantity: item.quantity < 1 ? 1 : item.quantity,
  );
}

/// What stays of a newly picked product's package when [inventoryAmount]
/// of it is eaten, in its inventory unit, or null without a package size or
/// when nothing stays.
int? inventoryManualAddRestAmount({
  required InventoryItem item,
  required int inventoryAmount,
}) {
  if (!item.usesAmountProgress || inventoryAmount < 1) {
    return null;
  }
  final rest = item.currentAmount - inventoryAmount;
  return rest > 0 ? rest : null;
}

/// Safe amount scale for a unit.
int safeInventoryManualAddAmountScale({
  required InventoryAmountUnit unit,
  required int scale,
}) {
  if (scale > 0) {
    return scale;
  }
  return unit == InventoryAmountUnit.piece ? inventoryPieceAmountScale : 1;
}

import 'dart:math' as math;

import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Pack sizes in g or ml that the amount page offers for a pack whose weight
/// the cook types.
const stockCommonPackSizes = [250, 500, 1000, 2000];

/// Shares of the package size that the amount page offers.
const stockPackShares = [0.25, 0.5, 1.0, 2.0];

/// The one question the amount page asks about a food for a recipe line.
enum StockAmountQuestion {
  /// "Wie viel hast du davon zu Hause?": the amount in the food's unit.
  howMuch,

  /// "Wie schwer ist die Packung?": the app cannot tell the weight.
  packWeight,

  /// "Wie viele hast du?": a count of pieces.
  howMany,
}

/// The question for [item], taken for a recipe line measured in [lineUnit]:
/// a food kept in pieces is counted, unless the line needs grams or ml and
/// a piece has no weight; a food without a package size is weighed, unless
/// the line counts pieces.
StockAmountQuestion stockAmountQuestion(
  InventoryItem item,
  InventoryAmountUnit? lineUnit,
) {
  final byWeight =
      lineUnit == InventoryAmountUnit.gram ||
      lineUnit == InventoryAmountUnit.milliliter;
  if (item.amountUnit == InventoryAmountUnit.piece) {
    return byWeight && !hasPieceWeight(item)
        ? StockAmountQuestion.packWeight
        : StockAmountQuestion.howMany;
  }
  if (!item.usesAmountProgress) {
    return lineUnit == InventoryAmountUnit.piece
        ? StockAmountQuestion.howMany
        : StockAmountQuestion.packWeight;
  }
  return StockAmountQuestion.howMuch;
}

/// Whether a piece of [item] has a weight in g or ml.
bool hasPieceWeight(InventoryItem item) =>
    (item.servingQuantity ?? 0) > 0 &&
    (item.servingQuantityUnit == InventoryAmountUnit.gram.code ||
        item.servingQuantityUnit == InventoryAmountUnit.milliliter.code);

/// [item] as one pack of [amount] in [unit], g or ml: the weight the cook
/// typed for a pack whose weight the app did not know.
InventoryItem stockItemWithPackWeight(
  InventoryItem item,
  int amount,
  InventoryAmountUnit unit,
) => item
    .withResolvedAmount(
      weight: '$amount ${unit.code}',
      parsedAmount: InventoryAmountParseResult(amount: amount, unit: unit),
      quantity: 1,
    )
    .copyWith(initialQuantity: 1);

/// [item] as [count] pieces, each weighing [pieceGrams] when the cook gave
/// it and the item has no piece weight yet.
InventoryItem stockItemWithPieces(
  InventoryItem item,
  int count,
  int? pieceGrams,
) {
  final pieces = item
      .withResolvedAmount(
        weight: '$count ${InventoryAmountUnit.piece.code}',
        parsedAmount: InventoryAmountParseResult(
          amount: count * inventoryPieceAmountScale,
          unit: InventoryAmountUnit.piece,
          scale: inventoryPieceAmountScale,
        ),
        quantity: 1,
      )
      .copyWith(initialQuantity: 1);
  return pieceGrams == null || hasPieceWeight(item)
      ? pieces
      : pieces.copyWith(
          servingQuantity: pieceGrams.toDouble(),
          servingQuantityUnit: InventoryAmountUnit.gram.code,
        );
}

/// What a recipe line that needs [need] leaves of [amount], both in the
/// same unit: `rest` when there is enough, else `missing`.
({int rest, int missing}) stockRestOf(int amount, int need) =>
    (rest: math.max(0, amount - need), missing: math.max(0, need - amount));

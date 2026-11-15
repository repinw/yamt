import 'package:yamt/features/inventory/domain/food_estimate.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/domain/food_estimate_item.dart';

/// The estimated food for a recipe line whose cook does not want to pick
/// one ("Egal, irgendeins"): exactly what the line needs, [need] in [unit],
/// with the typical values of [estimate]. Pieces weigh [pieceWeight], else
/// the estimated portion.
///
/// Returns the item and its stock in stored units.
({InventoryItem item, int amount}) recipeGuessItem({
  required InventoryItem baseItem,
  required FoodEstimate estimate,
  required String description,
  required InventoryAmountUnit unit,
  required int need,
  int? pieceWeight,
}) {
  final piece = pieceWeight ?? estimate.portionGrams.round();
  final grams = unit == InventoryAmountUnit.piece ? need * piece : need;
  final item = buildFoodEstimateItem(
    baseItem: baseItem,
    estimate: estimate,
    level: FoodEstimateLevel.normal,
    grams: grams,
    description: description,
  );
  switch (unit) {
    case InventoryAmountUnit.gram:
      return (item: item, amount: need);
    case InventoryAmountUnit.milliliter:
      // The estimate counts per 100 g; for a liquid that is near per 100 ml.
      return (
        item: item.withResolvedAmount(
          weight: '$need ${unit.code}',
          parsedAmount: InventoryAmountParseResult(amount: need, unit: unit),
          quantity: item.quantity,
        ),
        amount: need,
      );
    case InventoryAmountUnit.piece:
      final amount = need * inventoryPieceAmountScale;
      return (
        item: item
            .withResolvedAmount(
              weight: '$need ${unit.code}',
              parsedAmount: InventoryAmountParseResult(
                amount: amount,
                unit: unit,
                scale: inventoryPieceAmountScale,
              ),
              quantity: item.quantity,
            )
            .copyWith(
              servingQuantity: piece.toDouble(),
              servingQuantityUnit: InventoryAmountUnit.gram.code,
            ),
        amount: amount,
      );
  }
}

/// What "Egal, irgendeins" asks the estimate for: [food], the name the pick
/// asks for, with the addition in brackets of the recipe line [ingredient]
/// ("Frischkäse (Doppelrahmstufe)"). Without it when [food] has brackets of
/// its own or the addition is empty or names an amount ("(à 400 g)").
String recipeGuessDescription(String food, String? ingredient) {
  final addition = _addition.firstMatch(ingredient ?? '')?[1]?.trim() ?? '';
  return addition.isEmpty || food.contains('(') || addition.contains(_digit)
      ? food
      : '$food ($addition)';
}

final _addition = RegExp(r'\(([^)]*)\)');
final _digit = RegExp(r'\d');

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/food_estimate.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_pack.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/inventory_stock_amount_flow.dart';
import 'package:yamt/features/inventory/presentation/models/recipe_food_pick.dart';
import 'package:yamt/features/product_search_hub/domain/recipe_full_pack.dart';
import 'package:yamt/features/product_search_hub/domain/recipe_guess_item.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_editor_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _recipeFoodIds = Uuid();

/// The packs of the Vorrat that hold the product with [barcode] and have
/// something left for the line (not `ProductSearchHubRouteArgs.heldItemIds`),
/// opened ones first, when the recipe pick of [args] takes Vorrat foods; else
/// none.
List<InventoryItem> productSearchHubStockPacks(
  BuildContext context,
  ProductSearchHubRouteArgs args,
  String? barcode,
) {
  if (!args.takesFromStock) return const [];
  // The recipe page watches the Vorrat, so its items are here.
  final items = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(inventoryQuickEatItemsProvider).value;
  return [
    for (final pack in inventoryPacksWithBarcode(barcode, items ?? const []))
      if (!args.heldItemIds.contains(pack.id)) pack,
  ];
}

/// Completes a food picked for the recipe line of [args], the way the diary
/// takes a found product: a product that the Vorrat holds already (same
/// barcode) comes back as those Vorrat packs while they have something left
/// for the line ([productSearchHubStockPacks]). Any other product is a new
/// pack: with a package size one full pack without a page; only without one
/// the amount page asks how much is at home.
///
/// Returns the pick, null when the cook closed the page; `result` then holds
/// the last edit.
Future<({RecipeFoodPick? pick, InventoryReceiptManualProductResult result})>
pickProductSearchHubRecipeFood({
  required BuildContext context,
  required ProductSearchHubRouteArgs args,
  required InventoryReceiptManualProductResult result,
}) async {
  final packs = productSearchHubStockPacks(context, args, result.item.barcode);
  if (packs.isNotEmpty) return (pick: RecipeFoodInStock(packs), result: result);
  final full = recipeFullPackAmount(result.item, args.ingredientUnit);
  final counted = full != null
      ? (item: result.item, amount: full)
      : await countInventoryStockForRecipe(
          context,
          item: result.item,
          lineUnit: args.ingredientUnit,
          need: args.ingredientNeed,
          pieceWeight: args.pieceWeight,
        );
  if (counted == null) return (pick: null, result: result);
  // A recent item keeps the id of its stock item; the pack is a new one.
  final item = counted.item.copyWith(id: _recipeFoodIds.v4());
  final RecipeFoodPick pick = RecipeFoodNew((
    result: result.withItem(item),
    // A stock count has no day and meal; only the amount counts.
    request: InventoryItemEatRequest(
      inventoryAmount: counted.amount,
      loggedAt: DateTime.now(),
      mealType: MealType.snack,
    ),
  ));
  return (pick: pick, result: result);
}

/// The pick of the food [estimate] for the recipe line of [args], which
/// needs [need] in [unit]: exactly that amount, as the cook's own food that
/// never goes into the shared catalog.
RecipeFoodPick productSearchHubRecipeGuessPick({
  required AppLocalizations l10n,
  required ProductSearchHubRouteArgs args,
  required FoodEstimate estimate,
  required String description,
  required InventoryAmountUnit unit,
  required int need,
}) {
  final guessed = recipeGuessItem(
    baseItem: buildProductSearchHubDraftItem(l10n: l10n, sourceItem: args.item),
    estimate: estimate,
    description: description,
    unit: unit,
    need: need,
    pieceWeight: args.pieceWeight,
  );
  return RecipeFoodNew((
    result: InventoryReceiptManualProductResult(
      item: guessed.item,
      action: args.initialManualProductAction,
      // An estimate is the cook's own food, not a product to buy (#655).
      requiresGlobalPersistence: false,
      skipMissingBarcodePrompt: true,
      confirmed: true,
    ),
    request: InventoryItemEatRequest(
      inventoryAmount: guessed.amount,
      loggedAt: DateTime.now(),
      mealType: MealType.snack,
    ),
  ));
}

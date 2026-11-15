import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/models/recipe_food_pick.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';

/// A Vorrat item named [name] in grams.
InventoryItem namedStock(String id, String name, int amount) =>
    stockItem(id, amount).copyWith(name: name);

/// Another cooking "Pfannkuchen" of the household that takes [takes] from
/// the Vorrat.
CookRun otherRun(Map<String, int> takes) => CookRun.fromJson({
  ...buildCookRun(
    id: 'recipe-t2',
    recipeId: 't2',
    pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
    lines: [textLine('x', 'Reis', amount: 1, settlement: assigned(takes))],
  ).toJson(),
  'name': 'Pfannkuchen',
});

/// What the food search answers when it found a new pack of [item].
RecipeFoodNew newPackFood(InventoryItem item, {required int amount}) =>
    RecipeFoodNew((
      result: InventoryReceiptManualProductResult(
        item: item,
        action: InventoryReceiptManualProductAction.addToInventory,
        requiresGlobalPersistence: false,
        skipMissingBarcodePrompt: true,
      ),
      request: InventoryItemEatRequest(
        inventoryAmount: amount,
        loggedAt: DateTime(2026, 11, 12),
        mealType: MealType.lunch,
      ),
    ));

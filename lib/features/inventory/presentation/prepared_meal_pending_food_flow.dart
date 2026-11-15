import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/application/template_ingredient_unit_mapper.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/inventory_manual_add_amount_service.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_product_save_flow.dart';
import 'package:yamt/features/inventory/presentation/inventory_stock_amount_flow.dart';
import 'package:yamt/features/inventory/presentation/models/food_pick_route_args.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_manual_product_save_outcome.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_meal_food_pick.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'prepared_meal_food_source.dart';
import 'package:yamt/features/inventory/presentation/models/recipe_food_pick.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Fills an open row of a meal with a food found by search, barcode, or AI.
abstract final class PreparedMealPendingFoodFlow {
  const new _();

  /// Opens the food pick at [source], the search for [query]. The found food
  /// is added to the Vorrat with exactly the entered amount, and [onFill]
  /// uses that amount for the row.
  ///
  /// For the recipe [ingredient], such as "250 g Mehl", the pick asks which
  /// food it is, scanning first; a food in pieces without a piece weight
  /// starts with [pieceWeight]. [need] is what the line needs: its unit
  /// decides whether a full pack can go in without a question, and its
  /// amount is what "Egal, irgendeins" takes. With [onTake] the pick also
  /// offers the Vorrat, and a food that is in the Vorrat already goes to
  /// [onTake] instead: nothing is added, so nothing is removed either. The
  /// Vorrat items [heldItemIds] have nothing left for the line: the pick does
  /// not offer them, and their product goes in as a new pack.
  ///
  /// Returns null when the cook cancels, otherwise whether it worked. When
  /// [onFill] fails, the added food is removed again.
  static Future<bool?> fill({
    required BuildContext context,
    required PreparedMealFoodSource source,
    required Future<bool> Function(InventoryItem item, int usedAmount) onFill,
    Future<bool> Function(List<InventoryItem> items)? onTake,
    String? query,
    String? ingredient,
    int? pieceWeight,
    TemplateIngredientRequirement? need,
    Set<String> heldItemIds = const {},
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final container = ProviderScope.containerOf(context, listen: false);
    final args = FoodPickRouteArgs(
      source: source,
      query: query,
      ingredient: ingredient,
      pieceWeight: pieceWeight,
      ingredientUnit: need?.unit.toInventoryAmountUnit(),
      ingredientNeed: need?.amount,
      takesFromStock: onTake != null,
      heldItemIds: heldItemIds,
    );
    final InventoryMealFoodPick? pick;
    if (ingredient == null) {
      pick = await context.push<InventoryMealFoodPick>(
        AppRoutes.homeFoodPick,
        extra: args,
      );
    } else {
      final answer = await context.push<RecipeFoodPick>(
        AppRoutes.homeFoodPick,
        extra: args,
      );
      if (!context.mounted) return null;
      switch (answer) {
        case RecipeFoodInStock(:final items) when onTake != null:
          return await onTake(items);
        case RecipeFoodNew(:final food):
          pick = food;
        case RecipeFoodInStock() || null:
          pick = null;
      }
    }
    if (pick == null || !context.mounted) {
      return null;
    }
    final request = pick.request;
    // Pieces are kept in thousandths; a food without a package size counts
    // whole ones.
    final amount =
        request.inventoryAmount *
        (_countedWithWeight(pick.result.item, request)
            ? inventoryPieceAmountScale
            : 1);
    final outcome = await saveManualProductResultToInventory(
      context: context,
      container: container,
      l10n: l10n,
      result: pick.result,
      adjustItem: (item) => resizeInventoryManualAddItemToConsumedAmount(
        item: _withTypedPieceWeight(item, request),
        inventoryAmount: amount,
      ),
    );
    final item = outcome.item;
    switch (outcome.status) {
      case InventoryManualProductSaveStatus.canceled:
        return null;
      case InventoryManualProductSaveStatus.saved when item != null:
        final filled = await onFill(item, amount);
        if (!filled) await remove(container, item.id);
        return filled;
      case InventoryManualProductSaveStatus.saved:
      case InventoryManualProductSaveStatus.failed:
      // Only the diary eat flow plans.
      case InventoryManualProductSaveStatus.planned:
        return false;
    }
  }

  /// "Ändern" of [item], which [fill] just added for a recipe line that needs
  /// [need]: asks on the amount page how much of it is at home (a piece
  /// without a weight starts with [pieceWeight]) and saves that as its
  /// stock, the way [fill] entered it. Returns the saved food, `null` when the
  /// cook closes the page or the save failed, which a snack bar says.
  static Future<InventoryItem?> recount({
    required BuildContext context,
    required InventoryItem item,
    TemplateIngredientRequirement? need,
    int? pieceWeight,
  }) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context)!.inventoryItemActionFailed;
    final counted = await countInventoryStockForRecipe(
      context,
      item: item,
      lineUnit: need?.unit.toInventoryAmountUnit(),
      need: need?.amount,
      pieceWeight: pieceWeight,
    );
    if (counted == null) return null;
    final saved = resizeInventoryManualAddItemToConsumedAmount(
      item: counted.item,
      inventoryAmount: counted.amount,
    );
    // Without a listener the controller is gone before the save is written.
    final keep = container.listen(inventoryItemsControllerProvider, (_, _) {});
    try {
      final updated = await container
          .read(inventoryItemsControllerProvider.notifier)
          .updateItem(saved);
      if (updated) return saved;
      messenger.showAppSnackBar(failed, tone: AppSnackBarTone.error);
      return null;
    } finally {
      keep.close();
    }
  }

  /// Takes a food that [fill] added out of the Vorrat again, for a caller
  /// that uses it only later and then does not.
  static Future<void> remove(ProviderContainer container, String itemId) async {
    // Without a listener the controller is gone before the delete is written.
    final keep = container.listen(inventoryItemsControllerProvider, (_, _) {});
    try {
      final removed = await container
          .read(inventoryItemsControllerProvider.notifier)
          .deleteItem(itemId);
      if (!removed) {
        log(
          'The food added for a row stayed in the Vorrat.',
          name: 'PreparedMealPendingFoodFlow',
        );
      }
    } finally {
      keep.close();
    }
  }

  // [item] kept in pieces without a piece weight takes the one the cook
  // typed on its page ([request]), so the meal counts the pieces by it. A
  // food without a package size that the cook counted with such a weight is
  // kept in pieces of it, so the meal and the cooking count its grams.
  static InventoryItem _withTypedPieceWeight(
    InventoryItem item,
    InventoryItemEatRequest request,
  ) {
    final (grams, unit) = (request.portionBaseAmount, request.portionBaseUnit);
    if (grams == null ||
        unit == null ||
        (item.amountUnit != InventoryAmountUnit.piece &&
            !_countedWithWeight(item, request))) {
      return item;
    }
    final pieces = _countedWithWeight(item, request)
        ? item.copyWith(
            amountUnit: InventoryAmountUnit.piece,
            amountScale: inventoryPieceAmountScale,
          )
        : item;
    return (item.servingQuantity ?? 0) > 0
        ? pieces
        : pieces.copyWith(
            servingQuantity: grams,
            servingQuantityUnit: unit.jsonValue,
          );
  }

  // Whether [item] has no package size and [request] counts it with the
  // weight of one piece.
  static bool _countedWithWeight(
    InventoryItem item,
    InventoryItemEatRequest request,
  ) => item.amountUnit == null && request.portionBaseAmount != null;
}

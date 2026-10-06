import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/calories/domain/combined_calorie_entry.dart';
import 'package:yamt/features/inventory/application/inventory_combined_eat_service.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/inventory_manual_add_amount_service.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/inventory_manual_product_save_flow.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_hub_result.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_manual_product_save_outcome.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _logName = 'InventoryCombinedEatFlow';

/// Logs a stock item together with other foods as one diary entry, or keeps
/// them in stock as one prepared meal.
///
/// Foods found by search are added to the inventory first, sized to their
/// eaten amount. They are deleted again when the save fails, when the user
/// cancels, and on undo.
abstract final class InventoryCombinedEatFlow {
  /// Saves one combined entry for [picks], with [item] unless it left the
  /// meal, and reports on [context]'s page with an undo. [request] carries
  /// [item]'s amount and the log time and meal of the entry.
  static Future<void> eat({
    required BuildContext context,
    required WidgetRef ref,
    required InventoryItem item,
    required InventoryItemEatRequest request,
    required List<InventoryCombinePick> picks,
    bool includesItem = true,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final container = ref.container;
    final inventory = container.read(inventoryItemsControllerProvider.notifier);
    // Read before the awaits: releasing the stock still works when the page
    // is gone after them.
    final eating = container.read(inventoryItemEatControllerProvider.notifier);
    final foods = <InventoryCombinedFood>[];
    final added = <InventoryItem>[];
    try {
      final prepared = await _prepare(
        context,
        container,
        includesItem ? (item, request) : null,
        picks,
        added,
      );
      if (prepared == null) {
        return;
      }
      for (final (item, request) in prepared) {
        final pending = await inventory.stagePendingConsumption(
          item.id,
          request.inventoryAmount,
        );
        if (pending == null) {
          throw StateError('No stock to stage for ${item.id}.');
        }
        foods.add((item: item, request: request, pending: pending));
      }
      // Read again: the controller may have been disposed while the user
      // added found foods.
      final entry = await container
          .read(inventoryItemEatControllerProvider.notifier)
          .logCombined(
            foods: foods,
            loggedAt: request.loggedAt,
            mealType: request.mealType,
          );
      if (entry == null) {
        throw StateError('The combined entry was not saved.');
      }
      messenger.showAppSnackBar(
        l10n.eatPageCombineSaved,
        onUndo: () async {
          final undone = await InventoryItemEatFlow.undoEat(
            container: container,
            entry: entry,
          );
          if (undone) {
            await _deleteAll(inventory, added);
          }
          return undone;
        },
      );
    } on Object catch (error, stackTrace) {
      developer.log(
        'Logging the combined entry failed.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      for (final food in foods) {
        await eating.discard(food.pending.id);
      }
      await _deleteAll(inventory, added);
      messenger.showAppSnackBar(
        l10n.eatPageCombineFailed,
        tone: AppSnackBarTone.error,
      );
    }
  }

  /// Keeps [item] and [picks] in stock as one prepared meal of [portions]
  /// portions, made of the entered amounts.
  static Future<void> storeAsMeal({
    required BuildContext context,
    required WidgetRef ref,
    required InventoryItem item,
    required InventoryItemEatRequest request,
    required List<InventoryCombinePick> picks,
    required int portions,
    bool includesItem = true,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final container = ref.container;
    final inventory = container.read(inventoryItemsControllerProvider.notifier);
    final mealsSubscription = container.listen(
      preparedMealsControllerProvider,
      (_, _) {},
    );
    final meals = container.read(preparedMealsControllerProvider.notifier);
    final added = <InventoryItem>[];
    try {
      final prepared = await _prepare(
        context,
        container,
        includesItem ? (item, request) : null,
        picks,
        added,
      );
      if (prepared == null) {
        return;
      }
      final result = await meals.createPreparedMeal(
        name: combinedFoodName(prepared.map((part) => part.$1.name)),
        totalPortions: portions,
        items: [
          for (final (item, request) in prepared)
            PreparedMealItemInput(
              itemId: item.id,
              usedAmount: request.inventoryAmount,
            ),
        ],
      );
      final mealId = result.preparedMealId;
      if (!result.isSuccess || mealId == null) {
        throw StateError('The prepared meal was not saved.');
      }
      messenger.showAppSnackBar(
        l10n.preparedMealCreatedMessage,
        onUndo: () async {
          final undone = await meals.unbundlePreparedMeal(mealId);
          if (undone) {
            await _deleteAll(inventory, added);
          }
          return undone;
        },
      );
    } on Object catch (error, stackTrace) {
      developer.log(
        'Keeping the meal in stock failed.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      await _deleteAll(inventory, added);
      messenger.showAppSnackBar(
        l10n.preparedMealActionFailed,
        tone: AppSnackBarTone.error,
      );
    } finally {
      mealsSubscription.close();
    }
  }

  /// The stock item and amount of every food, starting with [hubFood] when
  /// the hub's item is part of the meal. Search finds are added to the
  /// inventory and collected in [added]. Returns null when the user cancels
  /// adding a find; the finds added so far are deleted again.
  static Future<List<(InventoryItem, InventoryItemEatRequest)>?> _prepare(
    BuildContext context,
    ProviderContainer container,
    (InventoryItem, InventoryItemEatRequest)? hubFood,
    List<InventoryCombinePick> picks,
    List<InventoryItem> added,
  ) async {
    final parts = <(InventoryItem, InventoryItemEatRequest)>[?hubFood];
    for (final pick in picks) {
      final searchResult = pick.searchResult;
      if (searchResult == null) {
        parts.add((pick.item, pick.request));
        continue;
      }
      if (!context.mounted) {
        throw StateError('The page closed while adding a found food.');
      }
      final outcome = await saveManualProductResultToInventory(
        context: context,
        container: container,
        l10n: AppLocalizations.of(context)!,
        result: searchResult,
        adjustItem: (item) => resizeInventoryManualAddItemToConsumedAmount(
          item: item,
          inventoryAmount: pick.request.inventoryAmount,
        ),
      );
      final stockItem = outcome.item;
      switch (outcome.status) {
        case InventoryManualProductSaveStatus.canceled:
          await _deleteAll(
            container.read(inventoryItemsControllerProvider.notifier),
            added,
          );
          return null;
        case InventoryManualProductSaveStatus.saved when stockItem != null:
          added.add(stockItem);
          parts.add((stockItem, pick.request));
        case InventoryManualProductSaveStatus.saved:
        case InventoryManualProductSaveStatus.failed:
        // Only the diary eat flow plans.
        case InventoryManualProductSaveStatus.planned:
          throw StateError('Adding ${pick.item.name} to the stock failed.');
      }
    }
    return parts;
  }

  static Future<void> _deleteAll(
    InventoryItemsController inventory,
    List<InventoryItem> items,
  ) async {
    for (final item in items) {
      await inventory.deleteItem(item.id);
    }
  }
}

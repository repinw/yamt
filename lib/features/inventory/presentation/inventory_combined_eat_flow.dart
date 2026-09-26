import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/application/inventory_calorie_bridge_flow.dart';
import 'package:yamt/features/inventory/application/inventory_combined_eat_service.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/inventory_manual_add_amount_service.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/inventory_manual_product_save_flow.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_hub_result.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Logs a stock item together with other foods as one diary entry.
abstract final class InventoryCombinedEatFlow {
  /// Adds foods found by search to the inventory, sized to their eaten
  /// amount, stages the stock of [item] and every pick, and saves one
  /// combined entry. Reports on [context]'s page with an undo. On failure
  /// the added foods are deleted again.
  static Future<void> eat({
    required BuildContext context,
    required WidgetRef ref,
    required InventoryItem item,
    required InventoryItemEatRequest request,
    required List<InventoryCombinePick> picks,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final container = ref.container;
    final inventory = container.read(inventoryItemsControllerProvider.notifier);
    final serviceSubscription = container.listen(
      inventoryCombinedEatServiceProvider,
      (_, _) {},
    );
    final added = <InventoryItem>[];
    final foods = <InventoryCombinedFood>[];
    try {
      final stockFoods = <(InventoryItem, InventoryItemEatRequest)>[
        (item, request),
      ];
      for (final pick in picks) {
        final stockItem = await _stockItemFor(context, container, pick);
        if (stockItem == null) {
          break;
        }
        if (pick.searchResult != null) {
          added.add(stockItem);
        }
        stockFoods.add((stockItem, pick.request));
      }
      for (final (item, request) in stockFoods) {
        final pending = await inventory.stagePendingConsumption(
          item.id,
          request.inventoryAmount,
        );
        if (pending == null) {
          break;
        }
        foods.add((item: item, request: request, pending: pending));
      }
      final entry = foods.length == picks.length + 1
          ? await serviceSubscription.read().save(
              foods: foods,
              loggedAt: request.loggedAt,
              mealType: request.mealType,
            )
          : null;
      if (entry == null) {
        for (final food in foods) {
          await inventory.discardPendingConsumption(food.pending.id);
        }
        for (final item in added) {
          await inventory.deleteItem(item.id);
        }
        messenger.showAppSnackBar(
          l10n.inventoryItemActionFailed,
          tone: AppSnackBarTone.error,
        );
        return;
      }
      messenger.showAppSnackBar(
        l10n.eatPageCombineSaved,
        onUndo: () => InventoryCalorieBridgeFlow.undoEat(
          container: container,
          entry: entry,
        ),
      );
    } finally {
      serviceSubscription.close();
    }
  }

  /// The stock item of [pick]. A food found by search is added to the
  /// inventory first, sized to the eaten amount. Returns null when that
  /// fails or the user cancels it.
  static Future<InventoryItem?> _stockItemFor(
    BuildContext context,
    ProviderContainer container,
    InventoryCombinePick pick,
  ) async {
    final searchResult = pick.searchResult;
    if (searchResult == null) {
      return pick.item;
    }
    if (!context.mounted) {
      return null;
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
    return outcome.status == InventoryManualProductSaveStatus.saved
        ? outcome.item
        : null;
  }
}

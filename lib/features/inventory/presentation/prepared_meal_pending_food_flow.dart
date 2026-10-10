import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/domain/inventory_manual_add_amount_service.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_product_save_flow.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_manual_product_save_outcome.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_meal_food_pick.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'prepared_meal_food_source.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Fills an open row of a meal with a food found by search, barcode, or AI.
abstract final class PreparedMealPendingFoodFlow {
  const new _();

  /// Opens the food pick at [source]. The found food is added to the Vorrat
  /// with exactly the entered amount, and [onFill] uses that amount for the
  /// row. Returns null when the cook cancels, otherwise whether it worked.
  /// When [onFill] fails, the added food is removed again.
  static Future<bool?> fill({
    required BuildContext context,
    required PreparedMealFoodSource source,
    required Future<bool> Function(String itemId, int usedAmount) onFill,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final container = ProviderScope.containerOf(context, listen: false);
    final pick = await context.push<InventoryMealFoodPick>(
      AppRoutes.homeFoodPickPath(start: _start(source)),
    );
    if (pick == null || !context.mounted) {
      return null;
    }
    final amount = pick.request.inventoryAmount;
    final outcome = await saveManualProductResultToInventory(
      context: context,
      container: container,
      l10n: l10n,
      result: pick.result,
      adjustItem: (item) => resizeInventoryManualAddItemToConsumedAmount(
        item: item,
        inventoryAmount: amount,
      ),
    );
    final item = outcome.item;
    switch (outcome.status) {
      case InventoryManualProductSaveStatus.canceled:
        return null;
      case InventoryManualProductSaveStatus.saved when item != null:
        final filled = await onFill(item.id, amount);
        if (!filled) {
          await container
              .read(inventoryItemsControllerProvider.notifier)
              .deleteItem(item.id);
        }
        return filled;
      case InventoryManualProductSaveStatus.saved:
      case InventoryManualProductSaveStatus.failed:
      // Only the diary eat flow plans.
      case InventoryManualProductSaveStatus.planned:
        return false;
    }
  }

  static String? _start(PreparedMealFoodSource source) {
    return switch (source) {
      PreparedMealFoodSource.search => null,
      PreparedMealFoodSource.barcode => AppRoutes.homeFoodPickStartBarcode,
      PreparedMealFoodSource.ai => AppRoutes.homeFoodPickStartAi,
    };
  }
}

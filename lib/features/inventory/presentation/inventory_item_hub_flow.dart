import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_stock_changes.dart';
import 'package:yamt/features/inventory/domain/inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meal_selection_controller.dart';
import 'package:yamt/features/inventory/presentation/inventory_combined_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_hub_page.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_reanalyze_flow.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_remove_flow.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_hub_action.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_hub_result.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_meal_food_pick.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/inventory_item_row/inventory_item_candidate_swap_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the item hub of a stock item and runs what the user picks there.
///
/// Action dialogs and sheets open on top of the hub, so cancelling one
/// returns to the hub. A finished edit, replace or remove closes the hub and
/// reports on the inventory page, which then shows the changed item. Adding
/// to the shopping list keeps the hub open.
abstract final class InventoryItemHubFlow {
  /// Opens the hub for [item]. [initialPicks] and the catalog foods
  /// [initialFoods] join the meal right away. [onDismissed] runs when the
  /// user closes the hub without eating, combining, or a finished action.
  static Future<void> open({
    required BuildContext context,
    required WidgetRef ref,
    required InventoryItem item,
    List<InventoryItem> initialPicks = const <InventoryItem>[],
    List<InventoryMealFoodPick> initialFoods = const <InventoryMealFoodPick>[],
    VoidCallback? onDismissed,
  }) async {
    final pageMessenger = ScaffoldMessenger.of(context);
    // An edit, replace, or remove closes the hub without a result too.
    var closedByAction = false;
    final result = await Navigator.of(context, rootNavigator: true)
        .push<InventoryItemHubResult>(
          MaterialPageRoute<InventoryItemHubResult>(
            fullscreenDialog: true,
            builder: (_) => InventoryItemHubPage(
              item: item,
              initialPicks: initialPicks,
              initialFoods: initialFoods,
              onAction: (hubContext, action) async {
                final changed = await _run(
                  hubContext,
                  ref,
                  _current(ref, item),
                  action,
                  pageMessenger,
                );
                closedByAction |=
                    changed &&
                    action != InventoryItemHubAction.addToShoppingList;
                return changed;
              },
            ),
          ),
        );
    if (!context.mounted) {
      return;
    }
    final current = _current(ref, item);
    switch (result) {
      case null:
        if (!closedByAction) onDismissed?.call();
      case InventoryItemHubCombine(:final picks, :final includesItem):
        ref
            .read(preparedMealSelectionControllerProvider.notifier)
            .startFrom(
              anchorItemId: item.id,
              itemIds: {
                if (includesItem) item.id,
                for (final pick in picks)
                  if (pick.searchResult == null) pick.item.id,
              },
              catalogFoods: [
                for (final pick in picks)
                  if (pick.searchResult case final result?)
                    (result: result, request: pick.request),
              ],
            );
      case InventoryItemHubEat(:final request):
        final started = await InventoryItemEatFlow.stageAndComplete(
          context: context,
          container: ref.container,
          item: current,
          request: request,
        );
        if (!started && context.mounted) {
          _showFailure(context);
        }
      case InventoryItemHubMeal(
        :final request,
        :final picks,
        :final keepInStock,
        :final includesItem,
      ):
        if (keepInStock) {
          await InventoryCombinedEatFlow.storeAsMeal(
            context: context,
            ref: ref,
            item: current,
            request: request,
            picks: picks,
            includesItem: includesItem,
          );
        } else {
          await InventoryCombinedEatFlow.eat(
            context: context,
            ref: ref,
            item: current,
            request: request,
            picks: picks,
            includesItem: includesItem,
          );
        }
    }
  }

  // An AI level chip saves the item while the hub stays open (#763); other
  // items stay as the hub showed them.
  static InventoryItem _current(WidgetRef ref, InventoryItem item) {
    if (item.productSnapshot.aiEstimate == null) return item;
    final items = ref.read(inventoryItemsControllerProvider).value;
    return findInventoryItem(items ?? const [], item.id) ?? item;
  }

  static Future<bool> _run(
    BuildContext hubContext,
    WidgetRef ref,
    InventoryItem item,
    InventoryItemHubAction action,
    ScaffoldMessengerState pageMessenger,
  ) {
    return switch (action) {
      InventoryItemHubAction.remove => InventoryItemRemoveFlow.run(
        context: hubContext,
        ref: ref,
        item: item,
        messenger: pageMessenger,
      ),
      InventoryItemHubAction.addToShoppingList => _addToShoppingList(
        hubContext,
        ref,
        item,
      ),
      InventoryItemHubAction.edit => _edit(
        hubContext,
        ref,
        item,
        pageMessenger,
      ),
      InventoryItemHubAction.replace => _replace(hubContext, ref, item),
      InventoryItemHubAction.reanalyze => InventoryItemReanalyzeFlow.run(
        context: hubContext,
        ref: ref,
        item: item,
        messenger: pageMessenger,
      ),
    };
  }

  /// Adds [item] to the shopping list and reports it on the hub, which stays
  /// open.
  static Future<bool> _addToShoppingList(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(inventoryItemsControllerProvider.notifier);
    final revert = await _guard(() => controller.buyAgainItem(item));
    if (!context.mounted) {
      return false;
    }
    if (revert == null) {
      _showFailure(context);
      return false;
    }
    ScaffoldMessenger.of(context).showAppSnackBar(
      l10n.inventoryItemBuyAgainSucceeded,
      onUndo: () => controller.undoBuyAgainItem(revert),
    );
    return true;
  }

  static Future<bool> _edit(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
    ScaffoldMessengerState pageMessenger,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (!item.isFullyAvailable) {
      _showFailure(context, l10n.inventoryItemEditRequiresFullItem);
      return false;
    }
    final result = await GoRouter.of(context)
        .push<InventoryReceiptManualProductResult>(
          AppRoutes.homeInventoryItemEditPath(item.id),
        );
    final edited = result?.item;
    if (edited == null || edited == item || !context.mounted) {
      return false;
    }

    final controller = ref.read(inventoryItemsControllerProvider.notifier);
    final saved = await _guard(() => controller.updateItem(edited)) ?? false;
    if (!context.mounted) {
      return false;
    }
    if (!saved) {
      _showFailure(context);
      return false;
    }
    pageMessenger.showAppSnackBar(
      l10n.inventoryItemUpdatedMessage,
      onUndo: () => controller.updateItem(item),
    );
    return true;
  }

  static Future<bool> _replace(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
  ) async {
    if (!item.isFullyAvailable) {
      _showFailure(
        context,
        AppLocalizations.of(context)!
            .inventoryItemSwapCandidateRequiresFullItem,
      );
      return false;
    }
    final request = await showInventoryItemCandidateSwapFlow(
      context: context,
      ref: ref,
      item: item,
    );
    if (request == null || !context.mounted) {
      return false;
    }

    final saved =
        await _guard(
          () => ref
              .read(inventoryItemsControllerProvider.notifier)
              .swapItemCandidate(
                itemId: item.id,
                resolvedProduct: request.resolvedProduct,
                requiresGlobalPersistence: request.requiresGlobalPersistence,
                weight: request.weight,
                aiEstimated: request.aiEstimated,
                aiEstimate: request.aiEstimate,
              ),
        ) ??
        false;
    if (!saved && context.mounted) {
      _showFailure(context);
    }
    return saved;
  }

  static void _showFailure(BuildContext context, [String? message]) {
    ScaffoldMessenger.of(context).showAppSnackBar(
      message ?? AppLocalizations.of(context)!.inventoryItemActionFailed,
      tone: AppSnackBarTone.error,
    );
  }

  static Future<T?> _guard<T>(Future<T?> Function() action) async {
    try {
      return await action();
    } on Object catch (error, stackTrace) {
      developer.log(
        'Item hub action failed.',
        name: 'InventoryItemHubFlow',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}

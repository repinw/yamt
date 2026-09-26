import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/application/inventory_calorie_bridge_flow.dart';
import 'package:yamt/features/inventory/application/inventory_combined_eat_service.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_hub_result.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Logs a stock item together with other stock items as one diary entry.
abstract final class InventoryCombinedEatFlow {
  /// Stages the stock of [item] and every pick, saves one combined entry,
  /// and reports on [context]'s page with an undo.
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
    final foods = <InventoryCombinedFood>[];
    try {
      for (final (item, request) in [
        (item, request),
        for (final pick in picks) (pick.item, pick.request),
      ]) {
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
}

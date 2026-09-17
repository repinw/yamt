import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_manual_product_eat_flow_contract.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_product_eat_completion_flow.dart'
    as internal_eat_flow;
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_product_save_flow.dart'
    as internal_save_flow;
import 'package:yamt/l10n/app_localizations.dart';

part 'inventory_manual_product_eat_coordinator.g.dart';

/// Provides the Inventory presentation boundary for Diary's manual eat flow.
@Riverpod(keepAlive: true)
InventoryManualProductEatCoordinator inventoryManualProductEatCoordinator(
  Ref ref,
) {
  return const _InventoryManualProductEatCoordinator();
}

class _InventoryManualProductEatCoordinator
    implements InventoryManualProductEatCoordinator {
  const new();

  @override
  Future<InventoryManualProductEatOutcome> complete({
    required BuildContext context,
    required ProviderContainer container,
    required AppLocalizations l10n,
    required InventoryReceiptManualProductResult result,
    MealType? preselectedMealType,
    DateTime? preselectedLoggedAt,
    bool continueBatchOnConfirm = false,
  }) async {
    final outcome = await internal_eat_flow.saveManualProductResultForEatFlow(
      context: context,
      container: container,
      l10n: l10n,
      result: result,
      preselectedMealType: preselectedMealType,
      preselectedLoggedAt: preselectedLoggedAt,
      continueBatchOnConfirm: continueBatchOnConfirm,
    );
    return _toEatOutcome(outcome);
  }

  InventoryManualProductEatOutcome _toEatOutcome(
    internal_save_flow.InventoryManualProductSaveOutcome outcome,
  ) {
    return InventoryManualProductEatOutcome(
      status: switch (outcome.status) {
        internal_save_flow.InventoryManualProductSaveStatus.saved =>
          InventoryManualProductEatStatus.saved,
        internal_save_flow.InventoryManualProductSaveStatus.canceled =>
          InventoryManualProductEatStatus.canceled,
        internal_save_flow.InventoryManualProductSaveStatus.failed =>
          InventoryManualProductEatStatus.failed,
      },
      item: outcome.item,
      calorieEntryId: outcome.calorieEntryId,
      addMoreRequested: outcome.addMoreRequested,
    );
  }

  @override
  Future<bool> deleteItem({
    required ProviderContainer container,
    required String itemId,
  }) {
    return container
        .read(inventoryItemsControllerProvider.notifier)
        .deleteItem(itemId);
  }
}

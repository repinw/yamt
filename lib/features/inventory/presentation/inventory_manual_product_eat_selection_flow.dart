import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_sheet_result.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_manual_add_amount_service.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_quick_eat_sheet_picker.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Resolves the inventory request used by the manual-product eat flow.
abstract final class InventoryManualProductEatSelectionFlow {
  const new _();

  /// Uses an existing selection or opens the inventory eat sheet.
  static Future<InventoryItemEatSheetResult?> resolve({
    required BuildContext context,
    required AppLocalizations l10n,
    required InventoryItem item,
    required InventoryItemEatRequest? selectedRequest,
    required MealType? preselectedMealType,
    required DateTime? preselectedLoggedAt,
    required bool continueBatchOnConfirm,
  }) {
    final intent = _confirmIntent(continueBatchOnConfirm);
    if (selectedRequest != null) {
      return Future.value(selectedRequest.asSheetResult(intent));
    }
    return _showEatSheet(
      context: context,
      l10n: l10n,
      item: item,
      preselectedMealType: preselectedMealType,
      preselectedLoggedAt: preselectedLoggedAt,
      continueBatchOnConfirm: continueBatchOnConfirm,
    );
  }

  static Future<InventoryItemEatSheetResult?> _showEatSheet({
    required BuildContext context,
    required AppLocalizations l10n,
    required InventoryItem item,
    required MealType? preselectedMealType,
    required DateTime? preselectedLoggedAt,
    required bool continueBatchOnConfirm,
  }) async {
    final maxAmount = resolveInventoryManualAddConsumableAmount(item);
    if (maxAmount == null) {
      showInventoryManualAddSnackBar(
        context: context,
        message: l10n.inventoryItemActionFailed,
      );
      return null;
    }
    return await const InventoryQuickEatSheetPicker().pickItemResult(
      context: context,
      item: item,
      maxAmount: maxAmount,
      invalidAmountMessage: l10n.inventoryReceiptReviewInvalidNumber,
      confirmIntent: _confirmIntent(continueBatchOnConfirm),
      initialInventoryAmount: resolveInventoryManualAddInitialConsumedAmount(
        item: item,
        rawWeight: item.weight,
      ),
      initialLoggedAt: preselectedLoggedAt,
      initialMealType: preselectedMealType,
      addMoreActionText: continueBatchOnConfirm
          ? null
          : l10n.inventoryItemEatSheetAddMoreAction,
    );
  }

  static InventoryItemEatSheetIntent _confirmIntent(
    bool continueBatchOnConfirm,
  ) {
    return continueBatchOnConfirm
        ? InventoryItemEatSheetIntent.addMore
        : InventoryItemEatSheetIntent.logOnly;
  }
}

extension on InventoryItemEatRequest {
  InventoryItemEatSheetResult asSheetResult(
    InventoryItemEatSheetIntent intent,
  ) {
    return InventoryItemEatSheetResult(request: this, intent: intent);
  }
}

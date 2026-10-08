import 'dart:developer' show log;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_eat_sheet_result.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet.dart';
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
  }) {
    if (selectedRequest != null) {
      return Future.value(
        selectedRequest.asSheetResult(InventoryItemEatSheetIntent.logOnly),
      );
    }
    return _showEatSheet(
      context: context,
      l10n: l10n,
      item: item,
      preselectedMealType: preselectedMealType,
      preselectedLoggedAt: preselectedLoggedAt,
    );
  }

  static Future<InventoryItemEatSheetResult?> _showEatSheet({
    required BuildContext context,
    required AppLocalizations l10n,
    required InventoryItem item,
    required MealType? preselectedMealType,
    required DateTime? preselectedLoggedAt,
  }) async {
    if (consumableInventoryAmount(item) == null) {
      log(
        'Item ${item.id} has nothing left to eat '
        '(quantity=${item.quantity}, currentAmount=${item.currentAmount}).',
        name: 'InventoryManualProductEatSelectionFlow',
      );
      showInventoryManualAddSnackBar(
        context: context,
        message: l10n.inventoryItemActionFailed,
      );
      return null;
    }
    return await showInventoryItemEatSheetResult(
      context: context,
      item: item,
      initialLoggedAt: preselectedLoggedAt,
      initialMealType: preselectedMealType,
      hasOpenStock: true,
    );
  }
}

extension on InventoryItemEatRequest {
  InventoryItemEatSheetResult asSheetResult(
    InventoryItemEatSheetIntent intent,
  ) {
    return InventoryItemEatSheetResult(request: this, intent: intent);
  }
}

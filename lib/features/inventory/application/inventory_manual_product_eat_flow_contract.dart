import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Coordinates the inventory-side work needed by Diary's manual eat flow.
abstract interface class InventoryManualProductEatCoordinator {
  /// Saves the product, logs the selected consumption, and returns the result.
  Future<InventoryManualProductEatOutcome> complete({
    required BuildContext context,
    required ProviderContainer container,
    required AppLocalizations l10n,
    required InventoryReceiptManualProductResult result,
    MealType? preselectedMealType,
    DateTime? preselectedLoggedAt,
    bool continueBatchOnConfirm,
  });

  /// Deletes an inventory item created by the flow.
  Future<bool> deleteItem({
    required ProviderContainer container,
    required String itemId,
  });
}

/// Result returned by the manual product eat presentation flow.
class InventoryManualProductEatOutcome {
  /// Creates an outcome.
  const new({
    required this.status,
    this.item,
    this.calorieEntryId,
    this.addMoreRequested = false,
  });

  /// Outcome status.
  final InventoryManualProductEatStatus status;

  /// The saved inventory item, when saving succeeded.
  final InventoryItem? item;

  /// The directly saved calorie entry id, when one was created.
  final String? calorieEntryId;

  /// Whether another product should be added after this one.
  final bool addMoreRequested;
}

/// Status of the manual product eat flow.
enum InventoryManualProductEatStatus {
  /// The product and consumption were saved.
  saved,

  /// The user canceled the flow.
  canceled,

  /// Persistence or completion failed.
  failed,
}

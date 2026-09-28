import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Manual product inventory save status.
enum InventoryManualProductSaveStatus {
  /// Product was saved.
  saved,

  /// User canceled a required save step.
  canceled,

  /// Save failed.
  failed,
}

/// Manual product inventory save outcome.
class InventoryManualProductSaveOutcome {
  const new _({
    required this.status,
    this.item,
    this.calorieEntryId,
    this.addMoreRequested = false,
  });

  /// Saved outcome.
  factory saved(
    InventoryItem item, {
    String? calorieEntryId,
    bool addMoreRequested = false,
  }) {
    return InventoryManualProductSaveOutcome._(
      status: InventoryManualProductSaveStatus.saved,
      item: item,
      calorieEntryId: calorieEntryId,
      addMoreRequested: addMoreRequested,
    );
  }

  /// Canceled outcome.
  const new canceled()
    : this._(status: InventoryManualProductSaveStatus.canceled);

  /// Failed outcome.
  const new failed() : this._(status: InventoryManualProductSaveStatus.failed);

  /// Outcome status.
  final InventoryManualProductSaveStatus status;

  /// Saved inventory item.
  final InventoryItem? item;

  /// Calorie entry id created by an immediate diary eat flow.
  final String? calorieEntryId;

  /// Whether user asked to add another food after this save.
  final bool addMoreRequested;
}

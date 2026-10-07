import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/inventory_eat_outcome.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Manual product inventory save status.
enum InventoryManualProductSaveStatus {
  /// Product was saved.
  saved,

  /// The day lies after today: a plan was saved, and no product.
  planned,

  /// User canceled a required save step.
  canceled,

  /// Save failed.
  failed,
}

/// Manual product inventory save outcome.
class InventoryManualProductSaveOutcome {
  const new _({required this.status, this.item, this.plan, this.planFailure});

  /// Saved outcome.
  factory saved(InventoryItem item) {
    return InventoryManualProductSaveOutcome._(
      status: InventoryManualProductSaveStatus.saved,
      item: item,
    );
  }

  /// Planned outcome: [plan] was saved instead of the product.
  factory planned(CalorieEntry plan) {
    return InventoryManualProductSaveOutcome._(
      status: InventoryManualProductSaveStatus.planned,
      plan: plan,
    );
  }

  /// Failed outcome of a plan, for [planFailure].
  const new planFailed(InventoryEatFailure planFailure)
    : this._(
        status: InventoryManualProductSaveStatus.failed,
        planFailure: planFailure,
      );

  /// Canceled outcome.
  const new canceled()
    : this._(status: InventoryManualProductSaveStatus.canceled);

  /// Failed outcome.
  const new failed() : this._(status: InventoryManualProductSaveStatus.failed);

  /// Outcome status.
  final InventoryManualProductSaveStatus status;

  /// Saved inventory item.
  final InventoryItem? item;

  /// The saved plan, when the day lies after today.
  final CalorieEntry? plan;

  /// Why the plan failed, when a plan failed.
  final InventoryEatFailure? planFailure;
}

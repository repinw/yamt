import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_create_context.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

/// Why an eat from the Vorrat was not logged.
enum InventoryEatFailure {
  /// The item has no nutrition values to log.
  noNutrition,

  /// The diary entry and the stock change were not saved.
  notSaved,

  /// The amount needs the calorie editor, which saves eaten food, not plans.
  cannotPlan,
}

/// What happened to an eat from the Vorrat.
sealed class InventoryEatOutcome {
  const new();
}

/// The diary entry and the stock change were saved together.
final class InventoryEatLogged extends InventoryEatOutcome {
  /// Creates the outcome.
  const new(this.entry);

  /// The saved diary entry.
  final CalorieEntry entry;
}

/// The day lies after today, so [entry] was saved as a plan. A plan takes
/// no stock; the reserved stock was released.
final class InventoryEatPlanned extends InventoryEatOutcome {
  /// Creates the outcome.
  const new(this.entry);

  /// The saved plan.
  final CalorieEntry entry;
}

/// The amount cannot be logged without the calorie editor. The stock stays
/// reserved: the eat flow opens the editor and logs the entry it returns,
/// or releases the stock when the editor closes without one.
final class InventoryEatNeedsEditor extends InventoryEatOutcome {
  /// Creates the outcome.
  const new({
    required this.profile,
    required this.scannedSourceRef,
    required this.inventoryContext,
  });

  /// The item's nutrition as a calorie product.
  final CalorieProductProfile profile;

  /// The barcode source of the item, if it has one.
  final CalorieScannedSourceRef? scannedSourceRef;

  /// The amounts and the reserved stock for the editor.
  final CalorieInventoryCreateContext inventoryContext;
}

/// Nothing was saved and the reserved stock was released.
final class InventoryEatFailed extends InventoryEatOutcome {
  /// Creates the outcome.
  const new(this.failure);

  /// Why it failed.
  final InventoryEatFailure failure;
}

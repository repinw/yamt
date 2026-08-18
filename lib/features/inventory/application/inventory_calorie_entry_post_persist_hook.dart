import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_create_context.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_entry_post_persist_hook.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_serving_suggestion_service.dart';

part 'inventory_calorie_entry_post_persist_hook.g.dart';

/// The inventory calorie entry post persist hook provider.
@riverpod
CalorieEntryPostPersistHook inventoryCalorieEntryPostPersistHook(Ref ref) {
  ref.keepAlive();
  final service = ref.read(inventoryServingSuggestionServiceProvider);

  return ({
    required CalorieEntry entry,
    CalorieInventoryCreateContext? inventoryContext,
    CalorieScannedSourceRef? scannedSourceRef,
  }) async {
    if (inventoryContext == null || entry.consumedAmount <= 0) {
      return;
    }
    final learnedServing = _resolveLearnedServing(
      entry: entry,
      inventoryContext: inventoryContext,
    );
    await service.recordSelection(
      foodFingerprint: inventoryContext.foodFingerprint,
      globalFoodItemId: inventoryContext.globalFoodItemId,
      amount: learnedServing.amount,
      unit: learnedServing.unit,
      label: learnedServing.label,
      selectedAt: entry.updatedAt,
    );
  };
}

({double amount, ConsumedUnit unit, String? label}) _resolveLearnedServing({
  required CalorieEntry entry,
  required CalorieInventoryCreateContext inventoryContext,
}) {
  final baseAmount = inventoryContext.portionBaseAmount;
  final baseUnit = inventoryContext.portionBaseUnit;
  final count = inventoryContext.portionCount;
  if (baseAmount == null || baseUnit == null || count == null) {
    return (
      amount: entry.consumedAmount,
      unit: entry.consumedUnit,
      label: null,
    );
  }

  final expectedAmount = baseAmount * count;
  final amountChanged = (entry.consumedAmount - expectedAmount).abs() > 0.001;
  if (entry.consumedUnit != baseUnit || amountChanged) {
    return (
      amount: entry.consumedAmount,
      unit: entry.consumedUnit,
      label: null,
    );
  }

  return (
    amount: baseAmount,
    unit: baseUnit,
    label: inventoryContext.portionLabel,
  );
}

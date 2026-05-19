import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_create_context.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

part 'calorie_entry_post_persist_hook.g.dart';

/// Defines calorie entry post persist hook typedef.
typedef CalorieEntryPostPersistHook =
    Future<void> Function({
      required CalorieEntry entry,
      CalorieInventoryCreateContext? inventoryContext,
      CalorieScannedSourceRef? scannedSourceRef,
    });

/// The calorie entry post persist hook provider.
@riverpod
CalorieEntryPostPersistHook calorieEntryPostPersistHook(Ref ref) {
  ref.keepAlive();
  return ({
    required CalorieEntry entry,
    CalorieInventoryCreateContext? inventoryContext,
    CalorieScannedSourceRef? scannedSourceRef,
  }) async {};
}

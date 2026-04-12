import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_entry_post_persist_hook.dart';
import 'package:yamt/features/inventory/application/'
    'global_food_serving_suggestion_repository.dart';

final inventoryCalorieEntryPostPersistHookProvider =
    Provider<CalorieEntryPostPersistHook>((ref) {
      final repository = ref.read(
        globalFoodServingSuggestionRepositoryProvider,
      );

      return ({
        required CalorieEntry entry,
        CalorieInventoryCreateContext? inventoryContext,
        CalorieScannedSourceRef? scannedSourceRef,
      }) async {
        if (inventoryContext == null || entry.consumedAmount <= 0) {
          return;
        }
        await repository.recordSelection(
          foodFingerprint: inventoryContext.foodFingerprint,
          globalFoodItemId: inventoryContext.globalFoodItemId,
          amount: entry.consumedAmount,
          unit: entry.consumedUnit,
          selectedAt: entry.updatedAt,
        );
      };
    });

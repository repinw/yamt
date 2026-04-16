import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';

/// Defines calorie entry post persist hook typedef.
typedef CalorieEntryPostPersistHook =
    Future<void> Function({
      required CalorieEntry entry,
      CalorieInventoryCreateContext? inventoryContext,
      CalorieScannedSourceRef? scannedSourceRef,
    });

/// The calorie entry post persist hook provider.
final calorieEntryPostPersistHookProvider =
    Provider<CalorieEntryPostPersistHook>((ref) {
      return ({
        required CalorieEntry entry,
        CalorieInventoryCreateContext? inventoryContext,
        CalorieScannedSourceRef? scannedSourceRef,
      }) async {};
    });

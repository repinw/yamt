import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';

typedef CalorieEntryPostPersistHook =
    Future<void> Function({
      required CalorieEntry entry,
      CalorieInventoryCreateContext? inventoryContext,
      CalorieScannedSourceRef? scannedSourceRef,
    });

final calorieEntryPostPersistHookProvider =
    Provider<CalorieEntryPostPersistHook>((ref) {
      return ({
        required CalorieEntry entry,
        CalorieInventoryCreateContext? inventoryContext,
        CalorieScannedSourceRef? scannedSourceRef,
      }) async {};
    });

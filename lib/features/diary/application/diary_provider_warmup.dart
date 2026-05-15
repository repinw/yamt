import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_entry_delete_flow.dart';
import 'package:yamt/features/calories/application/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';

part 'diary_provider_warmup.g.dart';

/// Keeps expensive providers warm while the diary page is open.
@Riverpod(
  dependencies: [
    InventoryItemsController,
    PreparedMealsController,
    calorieEntryDeleteFlow,
    inventoryBackedCalorieEntrySaveFlow,
  ],
)
void diaryProviderWarmup(Ref ref) {
  ref
    ..watch(inventoryItemsControllerProvider)
    ..watch(preparedMealsControllerProvider)
    ..watch(calorieEntryDeleteFlowProvider)
    ..watch(inventoryBackedCalorieEntrySaveFlowProvider);
}

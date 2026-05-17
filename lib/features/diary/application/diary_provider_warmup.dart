import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_entry_delete_flow.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';

part 'diary_provider_warmup.g.dart';

/// Keeps expensive providers warm while the diary page is open.
@Riverpod(
  dependencies: [
    InventoryItemsController,
    PreparedMealsController,
  ],
)
void diaryProviderWarmup(Ref ref) {
  ref
    ..watch(inventoryItemsControllerProvider)
    ..watch(preparedMealsControllerProvider)
    ..watch(calorieEntryDeleteFlowProvider);
}

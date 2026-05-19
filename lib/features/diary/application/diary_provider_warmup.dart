import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/'
    'calorie_entry_delete_flow.dart';
import 'package:yamt/features/calories/provider/'
    'burn_week_run_controller.dart';
import 'package:yamt/features/diary/application/'
    'diary_balance_provider.dart';
import 'package:yamt/features/diary/application/'
    'diary_meal_sections_provider.dart';
import 'package:yamt/features/diary/presentation/'
    'diary_calendar_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meals_controller.dart';

part 'diary_provider_warmup.g.dart';

/// Keeps expensive providers warm while the diary page is open.
@Riverpod(
  dependencies: [
    InventoryItemsController,
    PreparedMealsController,
  ],
)
void diaryProviderWarmup(Ref ref) {
  final calendarState = ref.watch(diaryCalendarControllerProvider);
  final today = calendarState.today;

  ref
    ..watch(inventoryItemsControllerProvider)
    ..watch(preparedMealsControllerProvider)
    ..watch(calorieEntryDeleteFlowProvider)
    ..watch(burnWeekRunControllerProvider)
    ..watch(diaryBalanceSourceProvider(today))
    ..watch(diaryMealSectionsProvider(today));
}

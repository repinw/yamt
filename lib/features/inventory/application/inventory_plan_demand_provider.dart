import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_demand.dart';

part 'inventory_plan_demand_provider.g.dart';

/// The open plans from today to the last day that can be planned. Overdue
/// plans do not count.
@riverpod
Future<List<CalorieEntry>> openPlans(Ref ref) {
  // Plan writes bump the revision.
  ref.watch(calorieOverviewRevisionProvider);
  final today = dateOnly(ref.watch(clockProvider)());
  return ref
      .watch(plannedEntryRepositoryProvider)
      .loadPlannedEntries(today, addLocalDays(today, diaryPlanAheadDayCount));
}

/// What the open plans take from the Vorrat, foods and cooked meals:
/// "verplant" on Vorrat rows and "fehlt" on plan rows.
@riverpod
Future<InventoryPlanDemand> openPlanDemand(Ref ref) async {
  // Start all three loads before awaiting one, so they run side by side.
  final items = ref.watch(inventoryQuickEatItemsProvider.future)..ignore();
  final meals = ref.watch(inventoryQuickEatMealsProvider.future)..ignore();
  final plans = ref.watch(openPlansProvider.future)..ignore();
  return inventoryPlanDemand(await plans, await items, await meals);
}

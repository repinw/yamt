import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_demand.dart';

part 'inventory_plan_demand_provider.g.dart';

/// What the open plans from today on take from the Vorrat: "verplant" on
/// Vorrat rows and "fehlt" on plan rows.
@riverpod
Future<InventoryPlanDemand> openPlanDemand(Ref ref) async {
  // Plan writes bump the revision.
  ref.watch(calorieOverviewRevisionProvider);
  final today = dateOnly(ref.watch(clockProvider)());
  final items = await ref.watch(inventoryQuickEatItemsProvider.future);
  final plans = await ref
      .watch(plannedEntryRepositoryProvider)
      .loadPlannedEntries(today, addLocalDays(today, diaryPlanAheadDayCount));
  return inventoryPlanDemand(plans, items);
}

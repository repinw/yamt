import 'dart:developer';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/application/template_plan_entry.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_demand.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

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

/// The Kochbuch recipes and Vorlagen that recipe plans come from.
@riverpod
Stream<List<PreparedMeal>> planTemplates(Ref ref) =>
    ref.watch(preparedMealTemplateRepositoryProvider).watchAll();

/// What the open plans take from the Vorrat, foods and cooked meals:
/// "verplant" on Vorrat rows and "fehlt" on plan rows.
@riverpod
Future<InventoryPlanDemand> openPlanDemand(Ref ref) async {
  // Start the loads before awaiting one, so they run side by side.
  final items = ref.watch(inventoryQuickEatItemsProvider.future)..ignore();
  final meals = ref.watch(inventoryQuickEatMealsProvider.future)..ignore();
  final plans = ref.watch(openPlansProvider.future)..ignore();
  final templates = ref.watch(planTemplatesProvider.future)..ignore();
  final parser = ref.watch(templateIngredientParserProvider);
  final now = ref.watch(clockProvider)();
  final stock = await items;
  final templatesById = {
    for (final template in await _orNone(templates)) template.id: template,
  };
  final open = await plans;
  return inventoryPlanDemand(
    open,
    stock,
    await meals,
    ingredientNeedsByPlanId: {
      for (final plan in open)
        if (templatesById[plan.bundleSourceTemplateId] case final template?)
          plan.id: templatePlanIngredientNeeds(
            plan: plan,
            template: template,
            items: stock,
            parser: parser,
            now: now,
          ),
    },
    unstockedIngredientsByPlanId: {
      for (final plan in open)
        if (templatesById[plan.bundleSourceTemplateId] case final template?)
          plan.id: templatePlanUnstockedIngredients(
            plan: plan,
            template: template,
            items: stock,
            parser: parser,
          ),
    },
  );
}

// Without the recipes, the other plans still count.
Future<List<PreparedMeal>> _orNone(Future<List<PreparedMeal>> templates) async {
  try {
    return await templates;
  } on Object catch (error, stackTrace) {
    log(
      'Failed to read the recipes of the plans.',
      name: 'openPlanDemand',
      error: error,
      stackTrace: stackTrace,
    );
    return const [];
  }
}

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'diary_plan_meals_controller.g.dart';

/// The Vorrat meal of each meal plan on [day], by plan id, as the meal is
/// now. Loads the meals only when the day has a meal plan.
@riverpod
Map<String, PreparedMeal> diaryPlanMeals(Ref ref, DateTime day) {
  final plans =
      ref
          .watch(diaryDayDashboardControllerProvider(day))
          .data
          ?.plannedEntries ??
      const [];
  if (!plans.any((plan) => plan.bundleSourcePreparedMealId != null)) {
    return const {};
  }
  final meals = {
    for (final meal
        in ref.watch(inventoryQuickEatMealsProvider).value ??
            const <PreparedMeal>[])
      meal.id: meal,
  };
  return {
    for (final plan in plans)
      if (plan.bundleSourcePreparedMealId case final mealId?)
        plan.id: ?meals[mealId],
  };
}

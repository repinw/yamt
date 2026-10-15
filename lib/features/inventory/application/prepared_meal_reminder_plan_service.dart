import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/inventory/application/prepared_meal_diary_entry.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_rules.dart';

part 'prepared_meal_reminder_plan_service.g.dart';

/// The reminder plans service.
@riverpod
PreparedMealReminderPlanService preparedMealReminderPlanService(Ref ref) {
  return PreparedMealReminderPlanService(
    plans: ref.watch(plannedEntryRepositoryProvider),
    meals: ref.watch(preparedMealRepositoryProvider),
    overviewRevision: ref.watch(calorieOverviewRevisionProvider.notifier),
    clock: ref.watch(clockProvider),
  );
}

/// Keeps the plans of a cooked meal in step with its rows: a reminder
/// without kcal while a row is open, a plan with the meal's values once
/// none is.
///
/// shortcut: only the device that changes the rows rewrites its own plans;
/// a plan of a meal changed elsewhere keeps its kind until it is accepted,
/// which eats the meal as it is then.
class PreparedMealReminderPlanService {
  /// Creates the service.
  const new({
    required this._plans,
    required this._meals,
    required this._overviewRevision,
    required this._clock,
  });

  final PlannedEntryRepository _plans;
  final PreparedMealRepository _meals;
  final CalorieOverviewRevision _overviewRevision;
  final DateTime Function() _clock;

  /// Rewrites each plan of the meal [mealId] whose kind no longer fits the
  /// meal: reminders get its values once no row is open, and plans turn
  /// back into reminders when a row opens again. Throws when a read or
  /// write fails.
  Future<void> refresh(String mealId) async {
    // The cache holds the rows that were just saved, also offline.
    final meal = (await _meals.readAllForChange()).firstWhereOrNull(
      (meal) => meal.id == mealId,
    );
    if (meal == null) {
      return;
    }
    final pending = meal.hasPendingRecipeIngredients;
    final today = dateOnly(_clock());
    Future<List<CalorieEntry>> load() => _plans.loadPlannedEntries(
      addLocalDays(today, -diaryOverduePlanLookbackDays),
      addLocalDays(today, diaryPlanAheadDayCount),
    );
    final rewritten = [
      for (final plan in await load())
        if (plan.bundleSourcePreparedMealId == mealId &&
            plan.nutritionPending != pending)
          ?preparedMealPlanWithPortions(
            plan,
            meal,
            preparedMealPlanShare(plan, meal),
            now: _clock,
          ),
    ];
    if (rewritten.isEmpty) {
      return;
    }
    // An accept or a delete since the read must not bring a plan back.
    final stillPlanned = {for (final plan in await load()) plan.id};
    for (final plan in rewritten) {
      if (stillPlanned.contains(plan.id)) {
        await _plans.savePlannedEntry(plan);
      }
    }
    _overviewRevision.markChanged();
  }
}

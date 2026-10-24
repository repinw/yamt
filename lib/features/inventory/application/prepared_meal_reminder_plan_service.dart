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
import 'package:yamt/features/inventory/application/template_plan_entry.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_rules.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

part 'prepared_meal_reminder_plan_service.g.dart';

/// The reminder plans service.
@riverpod
PreparedMealReminderPlanService preparedMealReminderPlanService(Ref ref) {
  return PreparedMealReminderPlanService(
    plans: ref.watch(plannedEntryRepositoryProvider),
    meals: ref.watch(preparedMealRepositoryProvider),
    overviewRevision: ref.watch(calorieOverviewRevisionProvider.notifier),
    parser: ref.watch(templateIngredientParserProvider),
    clock: ref.watch(clockProvider),
  );
}

/// Keeps the plans of a cooked meal in step with its rows: a reminder
/// without kcal while a row is open, a plan with the meal's values once
/// none is. A reminder of a Kochbuch recipe gets the recipe's values once
/// each ingredient has a Vorrat item or is ignored.
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
    required this._parser,
    required this._clock,
  });

  final PlannedEntryRepository _plans;
  final PreparedMealRepository _meals;
  final CalorieOverviewRevision _overviewRevision;
  final TemplateIngredientParser _parser;
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
    await _rewrite(
      (plan) =>
          plan.bundleSourcePreparedMealId == mealId &&
              plan.nutritionPending != pending
          ? preparedMealPlanWithPortions(
              plan,
              meal,
              preparedMealPlanShare(plan, meal),
              now: _clock,
            )
          : null,
    );
  }

  /// Gives each reminder of a recipe in [templates] the recipe's values,
  /// cooked on paper from the Vorrat [items], once none of its ingredients
  /// lacks an item. Throws when a read or write fails.
  ///
  /// shortcut: a recipe plan with kcal stays one when an ingredient loses
  /// its item; it is planned anew from the recipe page then.
  Future<void> refreshRecipes(
    List<PreparedMeal> templates,
    List<InventoryItem> items,
  ) {
    final byId = {for (final template in templates) template.id: template};
    return _rewrite((plan) {
      final template = byId[plan.bundleSourceTemplateId];
      if (!plan.nutritionPending || template == null) {
        return null;
      }
      final counted = replanTemplatePlan(
        plan,
        template,
        items: items,
        parser: _parser,
      );
      return counted == null || counted.nutritionPending ? null : counted;
    });
  }

  /// Saves the plans that [rewrite] gives for the open and overdue plans; a
  /// plan it gives null for stays.
  Future<void> _rewrite(
    CalorieEntry? Function(CalorieEntry plan) rewrite,
  ) async {
    final today = dateOnly(_clock());
    Future<List<CalorieEntry>> load() => _plans.loadPlannedEntries(
      addLocalDays(today, -diaryOverduePlanLookbackDays),
      addLocalDays(today, diaryPlanAheadDayCount),
    );
    final rewritten = [
      for (final plan in await load())
        if (rewrite(plan) case final next?) (before: plan, next: next),
    ];
    if (rewritten.isEmpty) {
      return;
    }
    // An accept, a delete, or a change since the read must not be undone.
    final unchanged = {
      for (final plan in await load()) plan.id: plan.updatedAt,
    };
    for (final (:before, :next) in rewritten) {
      if (unchanged[before.id] == before.updatedAt) {
        await _plans.savePlannedEntry(next);
      }
    }
    _overviewRevision.markChanged();
  }
}

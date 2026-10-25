import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/domain/daily_nutrition_target.dart';
import 'package:yamt/features/calories/domain/daily_nutrition_target_resolver.dart';

/// Grams of carbs, protein and fat.
typedef MacroGrams = ({double carbs, double protein, double fat});

/// The budget of one diary day: what the day is measured against.
class DayBudget {
  /// Creates a day budget.
  const new({
    required this.goalKcal,
    required this.target,
    required this.carryoverMacroDelta,
  });

  /// The goal the day is measured against. A practice day borrows the goal
  /// that starts later.
  final double goalKcal;

  /// The nutrition target of the day, with the carryover from the days
  /// before, the same carryover the day's kcal goal shows.
  final DailyNutritionTarget target;

  /// How much the carryover changes the macro targets.
  final MacroGrams carryoverMacroDelta;
}

/// Resolves the budget of the last day of [week].
///
/// The macro targets take the week's carryover, which the week overview
/// already leaves out for a planned day, so they match the kcal goal.
DayBudget resolveDayBudget({
  required CalorieWeekOverview week,
  required DailyNutritionTargetResolver nutrition,
}) {
  final day = normalizeLocalDay(week.days.last.date);
  final goalKcal = dayGoalKcal(week);
  final target = nutrition.resolveTarget(
    day: day,
    goalKcal: goalKcal,
    carryoverKcal: week.carryoverBeforeTodayKcal,
  );
  final base = nutrition.resolveBaseTarget(day: day, goalKcal: goalKcal);
  return DayBudget(
    goalKcal: goalKcal,
    target: target,
    carryoverMacroDelta: (
      carbs: target.carbsGrams - base.carbsGrams,
      protein: target.proteinGrams - base.proteinGrams,
      fat: target.fatGrams - base.fatGrams,
    ),
  );
}

/// Whether [day] lies before the goal of [week] that starts later, so it
/// is a practice day where nothing counts yet.
bool isPracticeDay({required CalorieWeekOverview week, required DateTime day}) {
  final startDate = week.nextGoalStartDate;
  if (!week.goalStartsInFuture || startDate == null) {
    return false;
  }
  return normalizeLocalDay(day).isBefore(normalizeLocalDay(startDate));
}

/// The goal the last day of [week] is measured against.
///
/// A practice day before a future goal start has no goal of its own, so it
/// borrows the goal that starts later. This keeps the kcal bar and the macro
/// targets visible while nothing counts yet.
double dayGoalKcal(CalorieWeekOverview week) {
  final dayOverview = week.days.last;
  if (!isPracticeDay(week: week, day: dayOverview.date)) {
    return dayOverview.goalKcal;
  }
  return week.futureGoalKcal ?? dayOverview.goalKcal;
}

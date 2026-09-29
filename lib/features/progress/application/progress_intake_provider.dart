import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/application/daily_nutrition_target_resolver_service.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/calorie_carryover_history.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_extensions.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/daily_nutrition_target_resolver.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/progress/domain/progress_day.dart';
import 'package:yamt/features/progress/domain/progress_intake.dart';

part 'progress_intake_provider.g.dart';

/// Intake of the current 7-day run and of the last four weeks.
///
/// Logging, editing, or removing an entry refreshes it through the calorie
/// overview revision.
@riverpod
Future<ProgressIntake> progressIntake(Ref ref) async {
  ref.watch(calorieOverviewRevisionProvider);
  final today = normalizeDiaryDay(ref.watch(clockProvider)());
  final repository = ref.watch(calorieLogRepositoryProvider);
  final targetResolver = ref.watch(dailyNutritionTargetResolverProvider);
  final settings = await ref.watch(calorieGoalControllerProvider.future);
  if (!ref.mounted) {
    throw StateError('Progress intake provider disposed.');
  }

  final weekStart = resolveCalorieGoalRunStartDate(
    settings: settings,
    day: today,
  );
  final weekEnd = resolveCalorieGoalRunEndDate(settings: settings, day: today);
  final firstDay = addDiaryDays(today, -progressComparisonDayCount);
  final start = weekStart.isBefore(firstDay) ? weekStart : firstDay;
  final entries = await repository.readEntriesInRange(
    startInclusive: start,
    endExclusive: nextDiaryDay(weekEnd),
  );
  if (!ref.mounted) {
    throw StateError('Progress intake provider disposed.');
  }

  final entriesByDay = entries.groupByDiaryDayKey();
  final days = [
    for (final day in buildCalorieCarryoverDateRange(
      startInclusive: start,
      endExclusive: nextDiaryDay(weekEnd),
    ))
      _progressDay(
        day: day,
        today: today,
        entries: entriesByDay[diaryDayKey(day)] ?? const <CalorieEntry>[],
        goalKcal: settings.goalKcalForDay(day),
        isTrainingDay: settings.isTrainingDay(day),
        isPauseDay: settings.isPauseDay(day),
        targetResolver: targetResolver,
      ),
  ];
  return ProgressIntake.fromDays(
    days: days,
    weekStart: weekStart,
    weekEnd: weekEnd,
    today: today,
  );
}

ProgressDay _progressDay({
  required DateTime day,
  required DateTime today,
  required List<CalorieEntry> entries,
  required double goalKcal,
  required bool isTrainingDay,
  required bool isPauseDay,
  required DailyNutritionTargetResolver targetResolver,
}) {
  double sum(double Function(CalorieEntry entry) value) =>
      entries.fold<double>(0, (total, entry) => total + value(entry));
  final target = targetResolver.resolveBaseTarget(day: day, goalKcal: goalKcal);
  return ProgressDay(
    day: day,
    eatenKcal: sum((entry) => entry.totalKcal),
    proteinGrams: sum((entry) => entry.totalProtein),
    carbsGrams: sum((entry) => entry.totalCarbs),
    fatGrams: sum((entry) => entry.totalFat),
    goalKcal: goalKcal,
    proteinGoalGrams: target.proteinGrams,
    carbsGoalGrams: target.carbsGrams,
    fatGoalGrams: target.fatGrams,
    isTrainingDay: isTrainingDay,
    isPauseDay: isPauseDay,
    hasEntries: entries.isNotEmpty,
    isFuture: day.isAfter(today),
  );
}

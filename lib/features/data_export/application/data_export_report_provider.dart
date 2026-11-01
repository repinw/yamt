import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_budget_settings_provider.dart';
import 'package:yamt/features/calories/application/calorie_goal_archive_provider.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/application/daily_nutrition_target_resolver_service.dart';
import 'package:yamt/features/calories/application/tdee_analytics_provider.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_carryover_history.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_extensions.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/daily_nutrition_target_resolver.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';
import 'package:yamt/features/data_export/domain/data_export_range.dart';
import 'package:yamt/features/data_export/domain/data_export_report.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';
import 'package:yamt/features/health/application/weight_series_provider.dart';

part 'data_export_report_provider.g.dart';

/// The report of the days of [range], read on the device because the diary
/// and the weights are end-to-end encrypted.
@riverpod
Future<DataExportReport> dataExportReport(
  Ref ref,
  DataExportRange range,
) async {
  ref.watch(calorieOverviewRevisionProvider);
  final today = normalizeLocalDay(ref.watch(clockProvider)());
  final repository = ref.watch(calorieLogRepositoryProvider);
  final targetResolver = ref.watch(dailyNutritionTargetResolverProvider);
  final storedShares = ref
      .watch(appPreferencesProvider)
      .getStringSync(DiaryMealShares.preferenceKey);
  final settingsFuture = ref.watch(calorieBudgetSettingsProvider.future);
  final cyclesFuture = ref.watch(calorieGoalArchiveProvider.future);
  final weightsFuture = ref.watch(weightSeriesProvider.future);
  final tdeeFuture = ref.watch(
    tdeeAnalyticsProvider(const TdeeAnalyticsQuery(cycleIds: {'all'})).future,
  );
  final settings = await settingsFuture;
  final cycles = await cyclesFuture;
  final weights = await weightsFuture;
  final tdee = await tdeeFuture;
  if (!ref.mounted) {
    throw StateError('Data export report provider disposed.');
  }

  final days = _fromFirstGoal(
    range.resolve(settings: settings, today: today),
    cycles,
  );
  final end = nextLocalDay(days.to);
  final entries = await repository.readEntriesInRange(
    startInclusive: days.from,
    endExclusive: end,
  );
  if (!ref.mounted) {
    throw StateError('Data export report provider disposed.');
  }

  final entriesByDay = entries.groupByDiaryDayKey();
  final tdeeByDay = {
    for (final point in tdee.points)
      localDayKey(point.day): ?point.totalTdeeKcal,
  };
  final shares =
      (storedShares == null ? null : DiaryMealShares.decode(storedShares)) ??
      DiaryMealShares.standard;
  return DataExportReport(
    from: days.from,
    to: days.to,
    goals: _goalsBetween(cycles, settings, days),
    mealSharePercents: shares.percents,
    days: [
      for (final day in buildCalorieCarryoverDateRange(
        startInclusive: days.from,
        endExclusive: end,
      ))
        _exportDay(
          day: day,
          settings: settings,
          entries: entriesByDay[localDayKey(day)] ?? const <CalorieEntry>[],
          targetResolver: targetResolver,
          weightKg: weights.rawByDay[localDayKey(day)],
          trendWeightKg: weights.trendFor(day),
          tdeeKcal: tdeeByDay[localDayKey(day)],
        ),
    ],
  );
}

DataExportDay _exportDay({
  required DateTime day,
  required CalorieGoalSettings settings,
  required List<CalorieEntry> entries,
  required DailyNutritionTargetResolver targetResolver,
  required double? weightKg,
  required double? trendWeightKg,
  required double? tdeeKcal,
}) {
  final goalKcal = settings.goalKcalForDay(day);
  final target = targetResolver.resolveBaseTarget(day: day, goalKcal: goalKcal);
  return DataExportDay(
    day: day,
    dayType: DiaryDayTypeStatus.fromSettings(settings, day).type,
    goalKcal: goalKcal,
    proteinGoalGrams: target.proteinGrams,
    carbsGoalGrams: target.carbsGrams,
    fatGoalGrams: target.fatGrams,
    meals: [
      for (final meal in MealType.sectionOrder)
        if (entries.where((entry) => entry.mealType == meal).toList()
            case final foods when foods.isNotEmpty)
          DataExportMeal(mealType: meal, foods: foods),
    ],
    weightKg: weightKg,
    trendWeightKg: trendWeightKg,
    tdeeKcal: tdeeKcal,
  );
}

/// [days] without the days before the first goal of [cycles] (newest
/// first): nothing before it is offered.
DataExportDays _fromFirstGoal(
  DataExportDays days,
  List<TdeeAnalyticsGoalCycle> cycles,
) {
  if (cycles.isEmpty) return days;
  final first = normalizeLocalDay(cycles.last.startDate);
  if (!days.from.isBefore(first) || first.isAfter(days.to)) return days;
  return (from: first, to: days.to);
}

/// Last day of the goal at [index] in [cycles] (newest first); null while
/// it runs. A goal ended on the day the next one starts leaves that day to
/// it, as in Fortschritt.
DateTime? _lastDayOf(List<TdeeAnalyticsGoalCycle> cycles, int index) {
  final endDate = cycles[index].endDate;
  if (endDate == null) return null;
  final start = normalizeLocalDay(cycles[index].startDate);
  var end = normalizeLocalDay(endDate);
  if (index > 0) {
    final beforeNext = previousLocalDay(
      normalizeLocalDay(cycles[index - 1].startDate),
    );
    if (end.isAfter(beforeNext)) end = beforeNext;
  }
  return end.isBefore(start) ? start : end;
}

/// The goals of [cycles] (newest first) that overlap [days], oldest first.
List<DataExportGoal> _goalsBetween(
  List<TdeeAnalyticsGoalCycle> cycles,
  CalorieGoalSettings settings,
  DataExportDays days,
) {
  return [
    for (final (index, cycle) in cycles.indexed.toList().reversed)
      if (_lastDayOf(cycles, index) case final end
          when !normalizeLocalDay(cycle.startDate).isAfter(days.to) &&
              (end == null || !end.isBefore(days.from)))
        DataExportGoal(
          number: cycles.length - index,
          startDay: normalizeLocalDay(cycle.startDate),
          endDay: end,
          goalMode: cycle.goalMode,
          startWeightKg: cycle.startWeightKg,
          targetWeightKg: cycle.targetWeightKg,
          speedKgPerWeek: cycle.goalSpeedKgPerWeek,
          baseKcal: settings.baseGoalKcalForDay(cycle.startDate),
        ),
  ];
}

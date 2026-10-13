import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/daily_tdee_series.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_extensions.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_tdee_offsets.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/application/health_connection_controller.dart';
import 'package:yamt/features/health/application/manual_health_weight_entries_controller.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/weight_trend_calculator.dart';

part 'calorie_budget_settings_provider.g.dart';

/// The goal settings that budgets read.
///
/// The stored settings, whose goals follow the daily TDEE once it is
/// computed; until then the stored goals stand, so a budget never waits.
@riverpod
Future<CalorieGoalSettings> calorieBudgetSettings(Ref ref) async {
  // Only a changed offset rebuilds the budget, and offsets of older settings
  // never reach newer ones.
  final offsets = ref.watch(
    goalTdeeOffsetsByDayProvider.select((state) => state.value),
  );
  final settings = await ref.watch(calorieGoalControllerProvider.future);
  return offsets == null ||
          offsets.byDay.isEmpty ||
          !identical(offsets.settings, settings)
      ? settings
      : settings.withGoalOffsets(offsets.byDay);
}

/// The daily TDEE goal offsets and the settings they belong to.
@immutable
class GoalTdeeOffsets {
  /// Creates the offsets [byDay] computed for [settings].
  const new({required this.settings, required this.byDay});

  /// The stored settings the offsets were computed for.
  final CalorieGoalSettings settings;

  /// Offset in kcal by diary day key.
  final Map<String, double> byDay;

  @override
  bool operator ==(Object other) =>
      other is GoalTdeeOffsets &&
      identical(other.settings, settings) &&
      mapEquals(other.byDay, byDay);

  @override
  int get hashCode => Object.hash(
    identityHashCode(settings),
    Object.hashAllUnordered(
      byDay.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );
}

/// How far each goal moves with the daily TDEE, through the running week.
@riverpod
Future<GoalTdeeOffsets> goalTdeeOffsetsByDay(Ref ref) async {
  final today = ref.watch(diaryTodayProvider);
  final settings = await ref.watch(calorieGoalControllerProvider.future);
  if (!ref.mounted) {
    throw StateError('Goal TDEE offsets provider was disposed.');
  }
  final startDay = DailyTdeeSeries.startDay(settings, today);
  if (startDay == null) {
    return GoalTdeeOffsets(settings: settings, byDay: const {});
  }
  final (entries, manualEntries, healthSamples) = await (
    ref.watch(calorieEntriesFromProvider(startDay).future),
    ref.watch(manualHealthWeightEntriesControllerProvider.future),
    ref.watch(healthWeightSamplesFromProvider(startDay).future),
  ).wait;
  return GoalTdeeOffsets(
    settings: settings,
    byDay: goalTdeeOffsets(
      settings: settings,
      startDate: startDay,
      today: today,
      tdeeByDay: DailyTdeeSeries.estimate(
        startDate: startDay,
        endDate: today,
        today: today,
        settings: settings,
        entriesByDay: entries.groupByDiaryDayKey(),
        weights: WeightTrendCalculator.fromSources(
          manualEntries: manualEntries,
          healthSamples: healthSamples,
        ),
      ),
    ),
  );
}

/// The diary entries from [startDay] on, from the local cache first.
@riverpod
Stream<List<CalorieEntry>> calorieEntriesFrom(Ref ref, DateTime startDay) {
  return ref.watch(calorieLogRepositoryProvider).watchEntriesFrom(startDay);
}

/// Health weights from before [startDay] on, loaded once, so an entry
/// change only recomputes.
///
/// shortcut: a weight synced later in the day counts from the next day on;
/// reload on a Health change event when one exists.
@riverpod
Future<List<HealthWeightSample>> healthWeightSamplesFrom(
  Ref ref,
  DateTime startDay,
) async {
  final today = ref.watch(diaryTodayProvider);
  final healthWeightService = ref.watch(healthWeightServiceProvider);
  final status = await ref.watch(healthConnectionControllerProvider.future);
  if (status.accessState != HealthDataAccessState.ready) {
    return const <HealthWeightSample>[];
  }
  return await healthWeightService.loadWeightSamples(
    startInclusive: addDiaryDays(startDay, -WeightTrendCalculator.warmUpDays),
    endExclusive: nextDiaryDay(today),
  );
}

import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/activity/domain/diary_activity_weight_models.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/domain/diary_activity_summary.dart';
import 'package:yamt/features/health/domain/diary_health_activity_trend_day.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/health_workout_session.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

part 'diary_activity_weight_service.g.dart';

const _logName = 'DiaryActivityWeightService';
const _emptyDiaryHealthDayData = DiaryHealthDayData(
  totalSteps: 0,
  workouts: <HealthWorkoutSession>[],
);

/// Aggregates activity and weight inputs for the diary card.
class DiaryActivityWeightService {
  /// Creates a diary activity weight service.
  const DiaryActivityWeightService();

  /// Loads activity and weight data for the selected day window.
  Future<DiaryActivityWeightData> load({
    required DateTime day,
    required DiaryActivityWeightProfile? profile,
    required HealthConnectionStatus healthStatus,
    required List<ManualHealthWeightEntry> manualEntries,
    required DiaryHealthService diaryHealthService,
    required HealthWeightService healthWeightService,
    bool Function()? isCancelled,
  }) async {
    final selectedDay = normalizeDiaryDay(day);
    final days = List<DateTime>.generate(
      7,
      (index) => selectedDay.subtract(Duration(days: 6 - index)),
    );
    final profileWeightKg = profile?.weightKg;
    final userHeightCm = profile?.heightCm;
    final healthAccessState = healthStatus.accessState;

    final activityTrend = List<double?>.filled(7, null);
    int? selectedActivityKcal;
    int? selectedActiveMinutes;

    if (healthAccessState == HealthDataAccessState.ready) {
      final selectedDayData = await _loadDayDataSafely(
        diaryHealthService: diaryHealthService,
        day: selectedDay,
        userHeightCm: userHeightCm,
      );
      _throwIfCancelled(isCancelled);
      final selectedSummary = buildDiaryActivitySummary(
        day: selectedDay,
        dayData: selectedDayData,
      );
      selectedActivityKcal = _resolveBurnedKcal(selectedSummary);
      selectedActiveMinutes = _resolveActiveMinutes(selectedDayData);

      final trendDays = await _loadActivityTrendDaysSafely(
        diaryHealthService: diaryHealthService,
        startInclusive: days.first,
        endExclusive: nextDiaryDay(days.last),
      );
      _throwIfCancelled(isCancelled);
      if (trendDays == null) {
        await _fillActivityTrendFromDayData(
          activityTrend: activityTrend,
          days: days,
          selectedDay: selectedDay,
          selectedActivityKcal: selectedActivityKcal,
          diaryHealthService: diaryHealthService,
          userHeightCm: userHeightCm,
          isCancelled: isCancelled,
        );
      } else {
        _fillActivityTrendFromAggregate(
          activityTrend: activityTrend,
          days: days,
          selectedDay: selectedDay,
          selectedActivityKcal: selectedActivityKcal,
          trendDays: trendDays,
        );
      }
    }

    final healthWeightByDay = <String, HealthWeightSample>{};
    if (healthAccessState == HealthDataAccessState.ready && days.isNotEmpty) {
      _throwIfCancelled(isCancelled);
      final healthSamples = await _loadWeightSamplesSafely(
        healthWeightService: healthWeightService,
        startInclusive: days.first,
        endExclusive: nextDiaryDay(days.last),
      );
      _throwIfCancelled(isCancelled);
      healthWeightByDay.addAll(_latestWeightByDay(healthSamples));
    }

    final manualWeightByDay = <String, double>{};
    for (final entry in manualEntries) {
      manualWeightByDay[diaryDayKey(entry.day)] = entry.weightKg;
    }

    final weightByDay = <String, double>{
      for (final entry in healthWeightByDay.entries)
        entry.key: entry.value.weightKg,
      ...manualWeightByDay,
    };
    final selectedDayKey = diaryDayKey(selectedDay);
    final weightDays = days
        .map((trendDay) {
          final dayKey = diaryDayKey(trendDay);
          return DiaryWeightDayData(
            day: trendDay,
            weightKg: weightByDay[dayKey],
            hasManualWeight: manualWeightByDay.containsKey(dayKey),
            hasAppOwnedHealthWeight:
                healthWeightByDay[dayKey]?.isFromThisApp == true,
            healthSample: healthWeightByDay[dayKey],
          );
        })
        .toList(growable: false);
    final weightTrend = weightDays
        .map((weightDay) => weightDay.weightKg)
        .toList(growable: false);
    final selectedWeightKg = weightByDay[selectedDayKey] ?? profileWeightKg;

    return DiaryActivityWeightData(
      healthAccessState: healthAccessState,
      activityKcal: selectedActivityKcal,
      activeMinutes: selectedActiveMinutes,
      profileWeightKg: profileWeightKg,
      selectedWeightKg: selectedWeightKg,
      hasSelectedDayWeight: weightByDay.containsKey(selectedDayKey),
      activityTrend: activityTrend,
      weightTrend: weightTrend,
      weightDays: weightDays,
    );
  }

  int? _resolveBurnedKcal(DiaryActivitySummary summary) {
    return calculateDiaryBurnedCalories(
      stepsOutsideWorkouts: summary.stepsOutsideWorkouts,
      workoutCalories: summary.workouts.map(
        (workout) => workout.totalCalories,
      ),
      unassignedActiveEnergySegments: summary.unassignedActiveEnergySegments,
    );
  }

  Future<List<DiaryHealthActivityTrendDay>?> _loadActivityTrendDaysSafely({
    required DiaryHealthService diaryHealthService,
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    final trendService = diaryHealthService is DiaryHealthActivityTrendService
        ? diaryHealthService as DiaryHealthActivityTrendService
        : null;
    if (trendService == null) {
      return null;
    }
    try {
      return await trendService.loadActivityTrendDays(
        startInclusive: startInclusive,
        endExclusive: endExclusive,
      );
    } on Exception catch (error, stackTrace) {
      log(
        'Failed to load diary health activity trend.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> _fillActivityTrendFromDayData({
    required List<double?> activityTrend,
    required List<DateTime> days,
    required DateTime selectedDay,
    required int? selectedActivityKcal,
    required DiaryHealthService diaryHealthService,
    required double? userHeightCm,
    required bool Function()? isCancelled,
  }) async {
    for (var index = 0; index < days.length; index += 1) {
      final trendDay = days[index];
      if (isSameDiaryDay(trendDay, selectedDay)) {
        activityTrend[index] = selectedActivityKcal?.toDouble();
        continue;
      }
      final trendDayData = await _loadDayDataSafely(
        diaryHealthService: diaryHealthService,
        day: trendDay,
        userHeightCm: userHeightCm,
      );
      _throwIfCancelled(isCancelled);
      final summary = buildDiaryActivitySummary(
        day: trendDay,
        dayData: trendDayData,
      );
      activityTrend[index] = _resolveBurnedKcal(summary)?.toDouble();
    }
  }

  void _fillActivityTrendFromAggregate({
    required List<double?> activityTrend,
    required List<DateTime> days,
    required DateTime selectedDay,
    required int? selectedActivityKcal,
    required List<DiaryHealthActivityTrendDay> trendDays,
  }) {
    final trendByDay = {
      for (final trendDay in trendDays) diaryDayKey(trendDay.day): trendDay,
    };
    for (var index = 0; index < days.length; index += 1) {
      final day = days[index];
      if (isSameDiaryDay(day, selectedDay)) {
        activityTrend[index] = selectedActivityKcal?.toDouble();
        continue;
      }
      final trendDay = trendByDay[diaryDayKey(day)];
      activityTrend[index] = trendDay == null
          ? null
          : calculateAggregateDiaryBurnedCalories(
              totalSteps: trendDay.totalSteps,
              activeEnergyKcal: trendDay.activeEnergyKcal,
            ).toDouble();
    }
  }

  void _throwIfCancelled(bool Function()? isCancelled) {
    if (isCancelled?.call() ?? false) {
      throw StateError('Diary activity weight load cancelled.');
    }
  }

  Future<DiaryHealthDayData> _loadDayDataSafely({
    required DiaryHealthService diaryHealthService,
    required DateTime day,
    required double? userHeightCm,
  }) async {
    try {
      return await diaryHealthService.loadDayData(
        day: day,
        userHeightCm: userHeightCm,
      );
    } on Exception catch (error, stackTrace) {
      log(
        'Failed to load diary health day data.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return _emptyDiaryHealthDayData;
    }
  }

  Future<List<HealthWeightSample>> _loadWeightSamplesSafely({
    required HealthWeightService healthWeightService,
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    try {
      return await healthWeightService.loadWeightSamples(
        startInclusive: startInclusive,
        endExclusive: endExclusive,
      );
    } on Exception catch (error, stackTrace) {
      log(
        'Failed to load diary weight samples.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <HealthWeightSample>[];
    }
  }

  int _resolveActiveMinutes(DiaryHealthDayData dayData) {
    final workoutMinutes = dayData.workouts.fold<int>(
      0,
      (sum, workout) => sum + workout.durationMinutes.round(),
    );
    final unassignedMinutes = dayData.unassignedActiveEnergySegments.fold<int>(
      0,
      (sum, segment) => sum + segment.durationMinutes.round(),
    );
    return workoutMinutes + unassignedMinutes;
  }

  Map<String, HealthWeightSample> _latestWeightByDay(
    List<HealthWeightSample> samples,
  ) {
    final latestSampleByDay = <String, HealthWeightSample>{};
    for (final sample in samples) {
      final key = diaryDayKey(sample.recordedAt);
      final previous = latestSampleByDay[key];
      if (previous == null || sample.recordedAt.isAfter(previous.recordedAt)) {
        latestSampleByDay[key] = sample;
      }
    }
    return Map<String, HealthWeightSample>.unmodifiable(latestSampleByDay);
  }
}

/// Provides the diary activity weight aggregation service.
@riverpod
DiaryActivityWeightService diaryActivityWeightService(Ref ref) {
  return const DiaryActivityWeightService();
}

import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_activity_summary.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/health_workout_session.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

const _logName = 'DiaryActivityWeightService';
const _emptyDiaryHealthDayData = DiaryHealthDayData(
  totalSteps: 0,
  workouts: <HealthWorkoutSession>[],
);

/// Data for the diary activity and weight cards.
class DiaryActivityWeightData {
  /// Creates diary activity and weight data.
  const DiaryActivityWeightData({
    required this.healthAccessState,
    required this.activityKcal,
    required this.activeMinutes,
    required this.profileWeightKg,
    required this.selectedWeightKg,
    required this.hasSelectedDayWeight,
    required this.activityTrend,
    required this.weightTrend,
    required this.weightDays,
  });

  /// Health access state for activity tracking.
  final HealthDataAccessState healthAccessState;

  /// Burned kcal for the selected day.
  final int? activityKcal;

  /// Active workout minutes for the selected day.
  final int? activeMinutes;

  /// Profile weight from the calorie calculator.
  final double? profileWeightKg;

  /// Weight for the selected day, falling back to profile weight.
  final double? selectedWeightKg;

  /// Whether the selected day has a real saved weight point.
  final bool hasSelectedDayWeight;

  /// Seven day burned kcal trend.
  final List<double?> activityTrend;

  /// Seven day weight trend.
  final List<double?> weightTrend;

  /// Seven day weight entries.
  final List<DiaryWeightDayData> weightDays;
}

/// One day of weight data for the selected diary window.
class DiaryWeightDayData {
  /// Creates one weight day.
  const DiaryWeightDayData({
    required this.day,
    required this.weightKg,
    required this.hasManualWeight,
    required this.hasAppOwnedHealthWeight,
    required this.healthSample,
  });

  /// The diary day.
  final DateTime day;

  /// The weight for the day.
  final double? weightKg;

  /// Whether the app owns this day as a manual fallback entry.
  final bool hasManualWeight;

  /// Whether this day has a Health Connect entry from this app.
  final bool hasAppOwnedHealthWeight;

  /// Health sample for the day, when available.
  final HealthWeightSample? healthSample;

  /// Whether this weight can be removed by this app.
  bool get canDeleteWeight => hasManualWeight || hasAppOwnedHealthWeight;
}

/// Aggregates activity and weight inputs for the diary card.
class DiaryActivityWeightService {
  /// Creates a diary activity weight service.
  const DiaryActivityWeightService();

  /// Loads activity and weight data for the selected day window.
  Future<DiaryActivityWeightData> load({
    required DateTime day,
    required CalorieGoalSettings? goalSettings,
    required HealthConnectionStatus healthStatus,
    required List<ManualHealthWeightEntry> manualEntries,
    required DiaryHealthService diaryHealthService,
    required HealthWeightService healthWeightService,
  }) async {
    final selectedDay = normalizeDiaryDay(day);
    final days = List<DateTime>.generate(
      7,
      (index) => selectedDay.subtract(Duration(days: 6 - index)),
    );
    final calculatorProfile = goalSettings?.calculatorProfile;
    final profileWeightKg = calculatorProfile?.weightKg;
    final userHeightCm = calculatorProfile?.heightCm;
    final healthAccessState = healthStatus.accessState;

    final activityTrend = List<double?>.filled(7, null);
    int? selectedActivityKcal;
    int? selectedActiveMinutes;

    if (healthAccessState == HealthDataAccessState.ready) {
      final dayDataList = await Future.wait(
        days.map(
          (trendDay) => _loadDayDataSafely(
            diaryHealthService: diaryHealthService,
            day: trendDay,
            userHeightCm: userHeightCm,
          ),
        ),
      );

      for (var index = 0; index < days.length; index += 1) {
        final summary = buildDiaryActivitySummary(
          day: days[index],
          dayData: dayDataList[index],
        );
        final burnedKcal = _resolveBurnedKcal(summary);
        activityTrend[index] = burnedKcal?.toDouble();

        if (isSameDiaryDay(days[index], selectedDay)) {
          selectedActivityKcal = burnedKcal;
          selectedActiveMinutes = _resolveActiveMinutes(dayDataList[index]);
        }
      }
    }

    final healthWeightByDay = <String, HealthWeightSample>{};
    if (healthAccessState == HealthDataAccessState.ready && days.isNotEmpty) {
      final healthSamples = await _loadWeightSamplesSafely(
        healthWeightService: healthWeightService,
        startInclusive: days.first,
        endExclusive: nextDiaryDay(days.last),
      );
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
    );
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
    } on Object catch (error, stackTrace) {
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
    } on Object catch (error, stackTrace) {
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
    return dayData.workouts.fold<int>(
      0,
      (sum, workout) => sum + workout.durationMinutes.round(),
    );
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
final diaryActivityWeightServiceProvider = Provider<DiaryActivityWeightService>(
  (ref) {
    return const DiaryActivityWeightService();
  },
);

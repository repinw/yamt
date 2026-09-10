import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/activity/domain/diary_activity_weight_models.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

part 'diary_activity_weight_service.g.dart';

const _logName = 'DiaryActivityWeightService';

/// Aggregates weight inputs for the diary card.
class DiaryActivityWeightService {
  /// Creates a diary weight service.
  const DiaryActivityWeightService();

  /// Loads weight data for the selected seven-day window.
  Future<DiaryActivityWeightData> load({
    required DateTime day,
    required DiaryActivityWeightProfile? profile,
    required HealthConnectionStatus healthStatus,
    required List<ManualHealthWeightEntry> manualEntries,
    required HealthWeightService healthWeightService,
    bool Function()? isCancelled,
  }) async {
    final selectedDay = normalizeDiaryDay(day);
    final days = List<DateTime>.generate(
      7,
      (index) => selectedDay.subtract(Duration(days: 6 - index)),
    );
    final healthWeightByDay = <String, HealthWeightSample>{};
    if (healthStatus.accessState == HealthDataAccessState.ready) {
      _throwIfCancelled(isCancelled);
      final healthSamples = await _loadWeightSamplesSafely(
        healthWeightService: healthWeightService,
        startInclusive: days.first,
        endExclusive: nextDiaryDay(days.last),
      );
      _throwIfCancelled(isCancelled);
      healthWeightByDay.addAll(_latestWeightByDay(healthSamples));
    }

    final manualWeightByDay = <String, double>{
      for (final entry in manualEntries) diaryDayKey(entry.day): entry.weightKg,
    };
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

    return DiaryActivityWeightData(
      profileWeightKg: profile?.weightKg,
      selectedWeightKg: weightByDay[selectedDayKey] ?? profile?.weightKg,
      hasSelectedDayWeight: weightByDay.containsKey(selectedDayKey),
      weightTrend: weightDays
          .map((weightDay) => weightDay.weightKg)
          .toList(growable: false),
      weightDays: weightDays,
    );
  }

  void _throwIfCancelled(bool Function()? isCancelled) {
    if (isCancelled?.call() ?? false) {
      throw StateError('Diary weight load cancelled.');
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

/// Provides the diary weight aggregation service.
@riverpod
DiaryActivityWeightService diaryActivityWeightService(Ref ref) {
  return const DiaryActivityWeightService();
}

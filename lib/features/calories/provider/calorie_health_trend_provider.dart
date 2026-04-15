import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_health_trend_snapshot.dart';
import 'package:yamt/features/calories/domain/diary_activity_summary.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_health_trends_window_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_visible_window_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/provider/diary_health_service_provider.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/features/health/provider/health_weight_service_provider.dart';
import 'package:yamt/features/health/provider/'
    'manual_health_weight_entries_controller.dart';

part 'calorie_health_trend_provider.g.dart';

@riverpod
Future<CalorieHealthTrendSnapshot> calorieHealthTrendSnapshot(Ref ref) async {
  final trendsWindowEnd = ref.watch(
    calorieHealthTrendsWindowControllerProvider,
  );
  final DateTime visibleWindowEnd =
      trendsWindowEnd ?? ref.watch(calorieVisibleWindowControllerProvider);
  final intakeSnapshot = await ref.watch(
    calorieWeekConsumptionSnapshotForWindowProvider(visibleWindowEnd).future,
  );
  final status = await ref.watch(healthConnectionControllerProvider.future);
  final manualEntries = await ref.watch(
    manualHealthWeightEntriesControllerProvider.future,
  );
  final days = intakeSnapshot.days
      .map((day) => day.date)
      .toList(growable: false);

  var burnedByDay = <String, int?>{};
  var weightByDay = <String, double>{};
  final weightSourceByDay = <String, CalorieHealthTrendWeightSource>{
    for (final entry in manualEntries)
      diaryDayKey(entry.day): CalorieHealthTrendWeightSource.manual,
  };

  if (status.accessState == HealthDataAccessState.ready && days.isNotEmpty) {
    final diaryHealthService = ref.watch(diaryHealthServiceProvider);
    final dayDataList = await Future.wait(
      days.map((day) => diaryHealthService.loadDayData(day: day)),
    );
    burnedByDay = {
      for (var index = 0; index < days.length; index += 1)
        diaryDayKey(days[index]): _resolveBurnedKcal(
          day: days[index],
          dayData: dayDataList[index],
        ),
    };

    final startInclusive = days.first;
    final endExclusive = days.last.add(const Duration(days: 1));
    final weightSamples = await ref
        .watch(healthWeightServiceProvider)
        .loadWeightSamples(
          startInclusive: startInclusive,
          endExclusive: endExclusive,
        );
    weightByDay = _latestWeightByDay(weightSamples);
    for (final key in weightByDay.keys) {
      weightSourceByDay.putIfAbsent(
        key,
        () => CalorieHealthTrendWeightSource.health,
      );
    }
  }

  for (final entry in manualEntries) {
    weightByDay[diaryDayKey(entry.day)] = entry.weightKg;
  }

  return CalorieHealthTrendSnapshot(
    points: List<CalorieHealthTrendPoint>.unmodifiable(
      intakeSnapshot.days.map((day) {
        final key = diaryDayKey(day.date);
        return CalorieHealthTrendPoint(
          day: day.date,
          intakeKcal: day.totalKcal,
          burnedKcal: burnedByDay[key],
          weightKg: weightByDay[key],
          weightSource:
              weightSourceByDay[key] ?? CalorieHealthTrendWeightSource.none,
        );
      }),
    ),
    healthAccessState: status.accessState,
    healthPlatform: status.platform,
  );
}

int? _resolveBurnedKcal({
  required DateTime day,
  required DiaryHealthDayData dayData,
}) {
  final summary = buildDiaryActivitySummary(day: day, dayData: dayData);
  return calculateDiaryBurnedCalories(
    stepsOutsideWorkouts: summary.stepsOutsideWorkouts,
    workoutCalories: summary.workouts.map((workout) => workout.totalCalories),
  );
}

Map<String, double> _latestWeightByDay(List<HealthWeightSample> samples) {
  final latestSampleByDay = <String, HealthWeightSample>{};
  for (final sample in samples) {
    final key = diaryDayKey(sample.recordedAt);
    final previous = latestSampleByDay[key];
    if (previous == null || sample.recordedAt.isAfter(previous.recordedAt)) {
      latestSampleByDay[key] = sample;
    }
  }
  return {
    for (final entry in latestSampleByDay.entries)
      entry.key: entry.value.weightKg,
  };
}

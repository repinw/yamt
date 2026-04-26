import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_carryover_history.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_extensions.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_overview_revision_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/features/health/provider/health_weight_service_provider.dart';
import 'package:yamt/features/health/provider/'
    'manual_health_weight_entries_controller.dart';

part 'daily_learned_tdee_provider.g.dart';

/// Daily learned TDEE override for the current day.
class DailyLearnedTdeeGoalData {
  /// Creates daily learned TDEE goal data.
  const DailyLearnedTdeeGoalData({
    required this.measured,
    required this.calculatedTrueTdeeKcal,
    required this.newGoalKcal,
  });

  /// The measured TDEE before EMA smoothing.
  final CalorieMeasuredTdeeCalculation measured;

  /// The smoothed learned maintenance TDEE.
  final double calculatedTrueTdeeKcal;

  /// The capped target goal for today.
  final double newGoalKcal;
}

/// Resolve optional daily learned TDEE override for [day].
@riverpod
Future<DailyLearnedTdeeGoalData?> dailyLearnedTdeeGoalForDay(
  Ref ref, {
  required DateTime day,
  required DateTime today,
  required double storedGoalKcal,
}) async {
  ref.watch(calorieOverviewRevisionProvider);

  final normalizedDay = normalizeDiaryDay(day);
  if (!isSameDiaryDay(normalizedDay, today)) {
    return null;
  }

  final settings = await ref.watch(calorieGoalControllerProvider.future);
  if (!ref.mounted) {
    throw StateError('Daily learned TDEE disposed.');
  }
  final learnedEntry = settings.learnedTdeeEntryForDay(normalizedDay);
  final snapshot = learnedEntry?.weeklyCheckInSnapshot;
  if (snapshot == null) {
    return null;
  }

  final lastCompleteDay = previousDiaryDay(normalizedDay);
  if (!lastCompleteDay.isAfter(normalizeDiaryDay(snapshot.windowEndDate))) {
    return null;
  }

  final startDate = _dailyLearnedStartDate(
    settings: settings,
    snapshot: snapshot,
    today: normalizedDay,
  );
  final intakeDays = buildCalorieCarryoverDateRange(
    startInclusive: startDate,
    endExclusive: normalizedDay,
  );
  if (intakeDays.length < dailyLearnedTdeeMinimumCompleteDays) {
    return null;
  }

  final entries = await ref
      .watch(calorieLogRepositoryProvider)
      .readEntriesInRange(
        startInclusive: startDate,
        endExclusive: normalizedDay,
      );
  if (!ref.mounted) {
    throw StateError('Daily learned TDEE disposed.');
  }
  final intakeKcalByDay = _resolveDailyLearnedIntake(
    days: intakeDays,
    entriesByDay: entries.groupByDiaryDayKey(),
    settings: settings,
  );
  if (intakeKcalByDay == null) {
    return null;
  }

  final healthStatus = await ref.watch(
    healthConnectionControllerProvider.future,
  );
  if (!ref.mounted) {
    throw StateError('Daily learned TDEE disposed.');
  }
  final weightPoints = await _loadDailyLearnedWeightPoints(
    ref,
    startDate: startDate,
    endDateInclusive: normalizedDay,
    healthStatus: healthStatus,
  );
  if (!ref.mounted) {
    throw StateError('Daily learned TDEE disposed.');
  }
  if (weightPoints.length < 2) {
    return null;
  }

  final goalMode = _goalModeForDay(settings: settings, day: normalizedDay);
  final goalSpeedKgPerWeek = goalMode == CalorieGoalMode.maintain
      ? 0.0
      : _goalSpeedForDay(settings: settings, day: normalizedDay);
  final calculation = CalorieWeeklyCheckInCalculator.calculateLearnedGoal(
    previousGoalKcal: storedGoalKcal,
    previousLearnedTdeeKcal: snapshot.calculatedTrueTdeeKcal,
    goalSpeedKgPerWeek: goalSpeedKgPerWeek,
    isLosing: goalMode == CalorieGoalMode.lose,
    isGaining: goalMode == CalorieGoalMode.gain,
    intakeKcalByDay: intakeKcalByDay,
    weightPoints: weightPoints,
    maxGoalAdjustmentKcal: dailyLearnedTdeeMaxGoalAdjustmentKcal,
  );
  return DailyLearnedTdeeGoalData(
    measured: calculation.measured,
    calculatedTrueTdeeKcal: calculation.calculatedTrueTdeeKcal,
    newGoalKcal: calculation.newGoalKcal,
  );
}

DateTime _dailyLearnedStartDate({
  required CalorieGoalSettings settings,
  required CalorieGoalWeeklyCheckInSnapshot snapshot,
  required DateTime today,
}) {
  CalorieGoalHistoryEntry? firstLearnedEntry;
  for (final entry in settings.sortedGoalHistory) {
    if (entry.weeklyCheckInSnapshot != null) {
      firstLearnedEntry = entry;
      break;
    }
  }
  var startDate = normalizeDiaryDay(
    firstLearnedEntry?.weeklyCheckInSnapshot?.windowStartDate ??
        snapshot.windowStartDate,
  );
  final oldestAllowed = today.subtract(
    const Duration(days: dailyLearnedTdeeMaximumLookbackDays),
  );
  if (startDate.isBefore(oldestAllowed)) {
    startDate = normalizeDiaryDay(oldestAllowed);
  }
  return startDate;
}

List<double>? _resolveDailyLearnedIntake({
  required List<DateTime> days,
  required Map<String, List<CalorieEntry>> entriesByDay,
  required CalorieGoalSettings settings,
}) {
  final intakeKcalByDay = <double>[];
  for (final day in days) {
    final dayEntries = entriesByDay[diaryDayKey(day)] ?? const <CalorieEntry>[];
    if (dayEntries.isNotEmpty) {
      intakeKcalByDay.add(
        dayEntries.fold<double>(
          0,
          (sum, entry) => sum + entry.totalKcal,
        ),
      );
      continue;
    }
    if (!settings.isSkippedIntakeDay(day) || intakeKcalByDay.isEmpty) {
      return null;
    }
    intakeKcalByDay.add(
      intakeKcalByDay.fold<double>(0, (sum, value) => sum + value) /
          intakeKcalByDay.length,
    );
  }
  return intakeKcalByDay;
}

Future<List<CalorieWeeklyCheckInWeightPoint>> _loadDailyLearnedWeightPoints(
  Ref ref, {
  required DateTime startDate,
  required DateTime endDateInclusive,
  required HealthConnectionStatus healthStatus,
}) async {
  final manualEntries = await ref.watch(
    manualHealthWeightEntriesControllerProvider.future,
  );
  if (!ref.mounted) {
    throw StateError('Daily learned TDEE disposed.');
  }
  final healthWeights = healthStatus.accessState == HealthDataAccessState.ready
      ? await ref
            .watch(healthWeightServiceProvider)
            .loadWeightSamples(
              startInclusive: startDate,
              endExclusive: nextDiaryDay(endDateInclusive),
            )
      : const <HealthWeightSample>[];
  if (!ref.mounted) {
    throw StateError('Daily learned TDEE disposed.');
  }

  final manualWeightByDay = _manualWeightByDay(manualEntries);
  final healthWeightByDay = _representativeWeightByDay(healthWeights);
  final weightPoints = <CalorieWeeklyCheckInWeightPoint>[];
  for (
    var day = startDate;
    !day.isAfter(endDateInclusive);
    day = nextDiaryDay(day)
  ) {
    final key = diaryDayKey(day);
    final weightKg = manualWeightByDay[key] ?? healthWeightByDay[key];
    if (weightKg == null) {
      continue;
    }
    weightPoints.add(
      CalorieWeeklyCheckInWeightPoint(
        dayIndex: day.difference(startDate).inDays,
        weightKg: weightKg,
      ),
    );
  }
  return weightPoints;
}

Map<String, double> _manualWeightByDay(
  List<ManualHealthWeightEntry> manualEntries,
) {
  return <String, double>{
    for (final entry in manualEntries) diaryDayKey(entry.day): entry.weightKg,
  };
}

Map<String, double> _representativeWeightByDay(
  List<HealthWeightSample> samples,
) {
  final samplesByDay = <String, List<double>>{};
  for (final sample in samples) {
    final key = diaryDayKey(sample.recordedAt);
    samplesByDay.putIfAbsent(key, () => <double>[]).add(sample.weightKg);
  }
  return {
    for (final entry in samplesByDay.entries)
      entry.key: _medianWeight(entry.value),
  };
}

double _medianWeight(List<double> values) {
  if (values.isEmpty) {
    return 0;
  }
  final sorted = List<double>.from(values)..sort();
  final middleIndex = sorted.length ~/ 2;
  if (sorted.length.isOdd) {
    return sorted[middleIndex];
  }
  return (sorted[middleIndex - 1] + sorted[middleIndex]) / 2;
}

CalorieGoalMode _goalModeForDay({
  required CalorieGoalSettings settings,
  required DateTime day,
}) {
  return settings.goalEntryForDay(day)?.calculatorProfile?.goalMode ??
      settings.calculatorProfile?.goalMode ??
      CalorieGoalMode.maintain;
}

double _goalSpeedForDay({
  required CalorieGoalSettings settings,
  required DateTime day,
}) {
  return settings.goalEntryForDay(day)?.calculatorProfile?.goalSpeedKgPerWeek ??
      settings.calculatorProfile?.goalSpeedKgPerWeek ??
      0.0;
}

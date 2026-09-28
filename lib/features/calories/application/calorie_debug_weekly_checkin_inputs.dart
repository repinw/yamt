import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_build_models.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_window_resolver.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/pending_calorie_goal_weekly_check_in.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';

/// The completed check-in windows of the goal active on [today].
List<PendingCalorieGoalWeeklyCheckIn> resolveCalorieDebugWeeklyCheckInWindows({
  required CalorieGoalSettings settings,
  required DateTime today,
}) {
  final countingGoalEntry = settings.countingGoalEntryForDay(today);
  if (countingGoalEntry == null) {
    return const <PendingCalorieGoalWeeklyCheckIn>[];
  }
  final anchorEntry =
      settings.cycleAnchorEntryForDay(today) ?? countingGoalEntry;
  if (!anchorEntry.hasGoal) {
    return const <PendingCalorieGoalWeeklyCheckIn>[];
  }

  final windows = <PendingCalorieGoalWeeklyCheckIn>[];
  var windowStartDate = CalorieWeeklyWindowResolver.firstWindowStartDate(
    anchorEntry,
  );
  while (true) {
    final windowLengthDays =
        CalorieWeeklyWindowResolver.windowLengthDaysForStart(
          anchorEntry: anchorEntry,
          windowStartDate: windowStartDate,
        );
    final dueDate = addDiaryDays(windowStartDate, windowLengthDays);
    if (dueDate.isAfter(today)) {
      break;
    }
    final windowEndDate = addDiaryDays(windowStartDate, windowLengthDays - 1);
    windows.add(
      PendingCalorieGoalWeeklyCheckIn(
        windowStartDate: windowStartDate,
        windowEndDate: windowEndDate,
        dueDate: dueDate,
      ),
    );
    windowStartDate = nextDiaryDay(windowEndDate);
  }
  return List<PendingCalorieGoalWeeklyCheckIn>.unmodifiable(windows);
}

/// Loads the Health weights of all windows when Health access is ready.
Future<List<HealthWeightSample>> loadCalorieDebugWeeklyHealthWeights({
  required CalorieGoalSettings settings,
  required Iterable<CalorieWeeklyCheckInWindowDates> datesByWindow,
  required List<PendingCalorieGoalWeeklyCheckIn> windows,
  required HealthConnectionStatus healthStatus,
  required HealthWeightService healthWeightService,
}) async {
  if (healthStatus.accessState != HealthDataAccessState.ready) {
    return const <HealthWeightSample>[];
  }

  final dates = datesByWindow.toList(growable: false);
  final weightStartCandidates = [
    for (final date in dates) ...date.healthWeightStartCandidates,
  ];
  final weightEndDay = _latestDay([
    for (final date in dates) date.nextBoundaryDay,
  ]);
  return await healthWeightService.loadWeightSamples(
    startInclusive: _earliestDate(weightStartCandidates),
    endExclusive: nextDiaryDay(weightEndDay),
  );
}

/// The missing weight that blocks a window, or `null`.
CalorieDebugMissingWeightData? validateCalorieDebugWeeklyWeightData({
  required CalorieWeeklyCheckInWindowDates dates,
  required CalorieWeeklyCheckInWeightData weightData,
}) {
  final hasLearningStartWeight =
      weightData.weightByDay[diaryDayKey(dates.learningStartDate)] != null;
  final hasWindowEndWeight =
      weightData.weightByDay[diaryDayKey(
        dates.pendingWeeklyCheckIn.windowEndDate,
      )] !=
      null;
  if (weightData.weightPoints.length < 2 && !hasLearningStartWeight) {
    return CalorieDebugMissingWeightData(
      reason: 'missing_window_start_weight',
      missingWeightDays: [dates.learningStartDate],
    );
  }
  if (weightData.weightPoints.length < 2 && !hasWindowEndWeight) {
    return CalorieDebugMissingWeightData(
      reason: 'missing_window_end_weight',
      missingWeightDays: [dates.pendingWeeklyCheckIn.windowEndDate],
    );
  }
  return null;
}

/// Why a window lacks weight data and which days are missing.
class CalorieDebugMissingWeightData {
  /// Creates missing weight data.
  const new({required this.reason, required this.missingWeightDays});

  /// The blocked reason name.
  final String reason;

  /// The days without weight.
  final List<DateTime> missingWeightDays;
}

/// The snake-case name of a blocked reason.
String calorieDebugBlockedReasonName(CalorieWeeklyCheckInBlockedReason reason) {
  return switch (reason) {
    CalorieWeeklyCheckInBlockedReason.missingIntakeDays =>
      'missing_intake_days',
    CalorieWeeklyCheckInBlockedReason.tooManyMissingIntakeDays =>
      'too_many_missing_intake_days',
    CalorieWeeklyCheckInBlockedReason.skippedDayWithoutPriorAverage =>
      'skipped_day_without_prior_average',
    CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight =>
      'missing_window_start_weight',
    CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight =>
      'missing_window_end_weight',
    CalorieWeeklyCheckInBlockedReason.unstableWeightData =>
      'unstable_weight_data',
  };
}

/// The learned TDEE before [day], or the calculated or goal TDEE.
double calorieDebugPreviousLearnedTdeeKcal({
  required CalorieGoalSettings settings,
  required DateTime day,
  required DateTime fallbackDay,
}) {
  final normalizedDay = normalizeDiaryDay(day);
  CalorieGoalHistoryEntry? learnedEntry;
  for (final entry in settings.sortedGoalHistory) {
    if (!entry.effectiveDate.isBefore(normalizedDay)) {
      break;
    }
    if (entry.hasLearnedTdee) {
      learnedEntry = entry;
    }
  }
  final learnedTdeeKcal =
      learnedEntry?.weeklyCheckInSnapshot?.calculatedTdeeKcal;
  if (learnedTdeeKcal != null) {
    return learnedTdeeKcal;
  }
  final calculatorProfile = CalorieWeeklyWindowResolver.calculatorProfileForDay(
    settings: settings,
    day: fallbackDay,
  );
  if (calculatorProfile != null) {
    final result = CalorieGoalCalculator.calculate(calculatorProfile);
    return result.tdeeKcal;
  }
  return settings.baseGoalKcalForDay(fallbackDay);
}

/// Groups [entries] by diary day key.
Map<String, List<CalorieEntry>> calorieDebugEntriesByDay(
  List<CalorieEntry> entries,
) {
  final entriesByDay = <String, List<CalorieEntry>>{};
  for (final entry in entries) {
    final key = diaryDayKey(entry.loggedAt);
    entriesByDay.putIfAbsent(key, () => <CalorieEntry>[]).add(entry);
  }
  return entriesByDay;
}

DateTime _latestDay(List<DateTime> days) {
  assert(days.isNotEmpty, 'At least one day is required.');
  var latest = normalizeDiaryDay(days.first);
  for (final day in days.skip(1)) {
    final normalizedDay = normalizeDiaryDay(day);
    if (normalizedDay.isAfter(latest)) {
      latest = normalizedDay;
    }
  }
  return latest;
}

DateTime _earliestDate(List<DateTime> dates) {
  return dates.reduce((left, right) => left.isBefore(right) ? left : right);
}

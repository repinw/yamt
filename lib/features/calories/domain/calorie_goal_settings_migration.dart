import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Hard-migrates legacy calorie math settings into the current model.
CalorieGoalSettings migrateCalorieGoalSettingsToCurrentMath({
  required CalorieGoalSettings settings,
  required DateTime now,
}) {
  if (settings.calorieMathVersion >= currentCalorieMathVersion) {
    return settings;
  }

  final migrationDay = _resolveMigrationCountingStart(
    settings: settings,
    now: now,
  );
  final migrationTimestamp = _resolveMigrationTimestamp(
    migrationDay: migrationDay,
    now: now,
  );
  final goalEntry = _resolveMigrationGoalEntry(
    settings: settings,
    migrationDay: migrationDay,
  );
  if (goalEntry?.hasGoal != true) {
    return const CalorieGoalSettings.empty().copyWith(updatedAt: now);
  }

  final calculatorProfile =
      goalEntry!.calculatorProfile ?? settings.calculatorProfile;
  return CalorieGoalSettings.single(
    dailyKcalGoal: goalEntry.dailyKcalGoal,
    calculatorProfile: calculatorProfile,
    expectedActivityKcal: _resolveExpectedActivityKcal(
      settings: settings,
      goalEntry: goalEntry,
      calculatorProfile: calculatorProfile,
    ),
    effectiveDate: migrationTimestamp,
    countingStartDate: migrationDay,
    updatedAt: now,
    source: goalEntry.source,
    weeklyCheckInSnapshot: goalEntry.learnedTdeeSnapshot,
  );
}

DateTime _resolveMigrationCountingStart({
  required CalorieGoalSettings settings,
  required DateTime now,
}) {
  final today = normalizeDiaryDay(now);
  final countedGoalEntry = settings.countingGoalEntryForDay(today);
  if (countedGoalEntry != null) {
    return _resolveActiveRunStartDate(
      today: today,
      countingStartDate: countedGoalEntry.effectiveCountingStartDate,
    );
  }

  return settings.nextGoalStartAfterDay(today) ?? today;
}

DateTime _resolveActiveRunStartDate({
  required DateTime today,
  required DateTime countingStartDate,
}) {
  final normalizedStartDate = normalizeDiaryDay(countingStartDate);
  final elapsedDays = today.difference(normalizedStartDate).inDays;
  if (elapsedDays <= 0) {
    return normalizedStartDate;
  }
  final runOffset = elapsedDays % calorieGoalRunLengthDays;
  return today.subtract(Duration(days: runOffset));
}

DateTime _resolveMigrationTimestamp({
  required DateTime migrationDay,
  required DateTime now,
}) {
  if (isSameDiaryDay(migrationDay, now)) {
    return now;
  }
  return migrationDay;
}

CalorieGoalHistoryEntry? _resolveMigrationGoalEntry({
  required CalorieGoalSettings settings,
  required DateTime migrationDay,
}) {
  return settings.goalEntryForDay(migrationDay) ?? settings.latestGoalEntry;
}

double? _resolveExpectedActivityKcal({
  required CalorieGoalSettings settings,
  required CalorieGoalHistoryEntry goalEntry,
  required CalorieCalculatorProfile? calculatorProfile,
}) {
  final learnedActivityKcal =
      goalEntry.learnedTdeeSnapshot?.averageActiveKcal ??
      settings.latestLearnedTdeeEntry?.learnedTdeeSnapshot?.averageActiveKcal;
  if (learnedActivityKcal != null) {
    return learnedActivityKcal;
  }
  final storedExpectedActivityKcal =
      goalEntry.expectedActivityKcal ?? settings.expectedActivityKcal;
  if (storedExpectedActivityKcal != null) {
    return storedExpectedActivityKcal;
  }
  if (calculatorProfile == null) {
    return null;
  }
  return CalorieGoalCalculator.calculate(
    calculatorProfile,
  ).expectedActivityKcal;
}

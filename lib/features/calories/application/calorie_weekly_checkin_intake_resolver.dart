import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_build_models.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_domain_math.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';

/// Reads calorie entries grouped by diary day for a check-in range.
Future<Map<String, List<CalorieEntry>>> readCheckInCalorieEntriesByDay({
  required CalorieLogRepositoryContract calorieLogRepository,
  required DateTime startInclusive,
  required DateTime endExclusive,
}) async {
  final calorieEntries = await calorieLogRepository.readEntriesInRange(
    startInclusive: startInclusive,
    endExclusive: endExclusive,
  );
  final calorieEntriesByDay = <String, List<CalorieEntry>>{};
  for (final entry in calorieEntries) {
    final key = localDayKey(entry.loggedAt);
    calorieEntriesByDay.putIfAbsent(key, () => <CalorieEntry>[]).add(entry);
  }
  return calorieEntriesByDay;
}

/// Resolves logged and skipped intake for visible weekly window days.
CalorieWeeklyWindowIntakeData resolveWeeklyWindowIntakeData({
  required List<DateTime> days,
  required Map<String, List<CalorieEntry>> calorieEntriesByDay,
  required CalorieGoalSettings settings,
  required Map<String, double> weightByDay,
}) {
  final missingIntakeDays = <DateTime>[];
  final windowDays = <CalorieWeeklyCheckInWindowDay>[];
  for (final day in days) {
    final dayKey = localDayKey(day);
    final dayEntries = calorieEntriesByDay[dayKey] ?? const <CalorieEntry>[];
    final isExplicitPause = settings.isPauseDay(day);
    final hasEntries = dayEntries.isNotEmpty && !isExplicitPause;
    if (!hasEntries) {
      missingIntakeDays.add(day);
    }
    windowDays.add(
      CalorieWeeklyCheckInWindowDay(
        day: day,
        hasEntries: hasEntries,
        loggedIntakeKcal: sumCalorieEntryKcal(dayEntries),
        resolvedIntakeKcal: null,
        isSkippedIntakeDay: !hasEntries,
        isPauseDay: isExplicitPause,
        weightKg: weightByDay[dayKey],
      ),
    );
  }

  if (missingIntakeDays.length >= weeklyCheckInMissingIntakeBlockThreshold) {
    return CalorieWeeklyWindowIntakeData.blocked(
      days: windowDays,
      blockedReason: CalorieWeeklyCheckInBlockedReason.tooManyMissingIntakeDays,
      missingIntakeDays: missingIntakeDays,
    );
  }

  return _resolveSkippedWindowIntake(
    windowDays: windowDays,
    missingIntakeDays: missingIntakeDays,
  );
}

/// Sum entry calories.
double sumCalorieEntryKcal(List<CalorieEntry> entries) {
  return entries.fold<double>(0, (sum, entry) => sum + entry.totalKcal);
}

CalorieWeeklyWindowIntakeData _resolveSkippedWindowIntake({
  required List<CalorieWeeklyCheckInWindowDay> windowDays,
  required List<DateTime> missingIntakeDays,
}) {
  final loggedVals = <double>[];
  for (final day in windowDays) {
    if (day.hasEntries) {
      loggedVals.add(day.loggedIntakeKcal);
    }
  }

  if (loggedVals.isEmpty && missingIntakeDays.isNotEmpty) {
    return CalorieWeeklyWindowIntakeData.blocked(
      days: windowDays,
      blockedReason: CalorieWeeklyCheckInBlockedReason.missingIntakeDays,
      missingIntakeDays: missingIntakeDays,
    );
  }

  final averageLogged = loggedVals.isEmpty
      ? 0.0
      : CalorieDomainMath.average(loggedVals);

  for (var index = 0; index < windowDays.length; index += 1) {
    final day = windowDays[index];
    if (day.hasEntries) {
      windowDays[index] = _copyWindowDayWithResolvedIntake(
        day: day,
        hasEntries: true,
        loggedIntakeKcal: day.loggedIntakeKcal,
        resolvedIntakeKcal: day.loggedIntakeKcal,
      );
    } else {
      windowDays[index] = _copyWindowDayWithResolvedIntake(
        day: day,
        hasEntries: false,
        loggedIntakeKcal: 0,
        resolvedIntakeKcal: averageLogged,
      );
    }
  }

  return CalorieWeeklyWindowIntakeData.ready(
    days: windowDays,
    missingIntakeDays: missingIntakeDays,
  );
}

CalorieWeeklyCheckInWindowDay _copyWindowDayWithResolvedIntake({
  required CalorieWeeklyCheckInWindowDay day,
  required bool hasEntries,
  required double loggedIntakeKcal,
  required double resolvedIntakeKcal,
}) {
  return CalorieWeeklyCheckInWindowDay(
    day: day.day,
    hasEntries: hasEntries,
    loggedIntakeKcal: loggedIntakeKcal,
    resolvedIntakeKcal: resolvedIntakeKcal,
    isSkippedIntakeDay: day.isSkippedIntakeDay,
    isPauseDay: day.isPauseDay,
    weightKg: day.weightKg,
  );
}

import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_build_models.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_domain_math.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

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
    final key = diaryDayKey(entry.loggedAt);
    calorieEntriesByDay.putIfAbsent(key, () => <CalorieEntry>[]).add(entry);
  }
  return calorieEntriesByDay;
}

/// Resolves logged and skipped intake for visible weekly window days.
CalorieWeeklyWindowIntakeData resolveWeeklyWindowIntakeData({
  required List<DateTime> days,
  required Map<String, List<CalorieEntry>> calorieEntriesByDay,
  required CalorieGoalSettings settings,
  required Map<String, int> activeKcalByDay,
  required Map<String, double> weightByDay,
  required Set<String> heartDayKeys,
}) {
  final missingIntakeDays = <DateTime>[];
  final windowDays = <CalorieWeeklyCheckInWindowDay>[];
  for (final day in days) {
    final dayKey = diaryDayKey(day);
    final dayEntries = calorieEntriesByDay[dayKey] ?? const <CalorieEntry>[];
    final isHeartDay = heartDayKeys.contains(dayKey);
    if (dayEntries.isEmpty && !isHeartDay) {
      missingIntakeDays.add(day);
    }
    windowDays.add(
      CalorieWeeklyCheckInWindowDay(
        day: day,
        hasEntries: dayEntries.isNotEmpty && !isHeartDay,
        loggedIntakeKcal: sumCalorieEntryKcal(dayEntries),
        resolvedIntakeKcal: null,
        isSkippedIntakeDay: settings.isSkippedIntakeDay(day),
        isHeartDay: isHeartDay,
        activeKcal: activeKcalByDay[dayKey] ?? 0,
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

/// Resolves learning intake, including skipped-day interpolation.
///
/// Heart days count as perfect days: learning uses the target kcal for that
/// day and ignores any logged intake.
CalorieWeeklyLearningIntakeData resolveWeeklyLearningIntakeData({
  required List<DateTime> days,
  required Map<String, List<CalorieEntry>> calorieEntriesByDay,
  required CalorieGoalSettings settings,
  required Set<String> heartDayKeys,
}) {
  final loggedVals = <double>[];
  final missingIntakeDays = <DateTime>[];

  for (final day in days) {
    final dayKey = diaryDayKey(day);
    if (heartDayKeys.contains(dayKey)) {
      loggedVals.add(settings.goalKcalForDay(day));
      continue;
    }
    final dayEntries = calorieEntriesByDay[dayKey] ?? const <CalorieEntry>[];
    if (dayEntries.isNotEmpty) {
      loggedVals.add(sumCalorieEntryKcal(dayEntries));
    } else {
      missingIntakeDays.add(day);
    }
  }

  if (missingIntakeDays.length >= weeklyCheckInMissingIntakeBlockThreshold) {
    return CalorieWeeklyLearningIntakeData.blocked(
      blockedReason: CalorieWeeklyCheckInBlockedReason.tooManyMissingIntakeDays,
      missingIntakeDays: missingIntakeDays,
    );
  }

  if (loggedVals.isEmpty && missingIntakeDays.isNotEmpty) {
    return CalorieWeeklyLearningIntakeData.blocked(
      blockedReason: CalorieWeeklyCheckInBlockedReason.missingIntakeDays,
      missingIntakeDays: missingIntakeDays,
    );
  }

  final averageLogged = loggedVals.isEmpty
      ? 0.0
      : CalorieDomainMath.average(loggedVals);
  final intakeKcalByDay = <double>[];

  for (final day in days) {
    final dayKey = diaryDayKey(day);
    if (heartDayKeys.contains(dayKey)) {
      intakeKcalByDay.add(settings.goalKcalForDay(day));
      continue;
    }
    final dayEntries = calorieEntriesByDay[dayKey] ?? const <CalorieEntry>[];
    if (dayEntries.isNotEmpty) {
      intakeKcalByDay.add(sumCalorieEntryKcal(dayEntries));
    } else {
      if (!settings.isSkippedIntakeDay(day)) {
        return CalorieWeeklyLearningIntakeData.blocked(
          blockedReason: CalorieWeeklyCheckInBlockedReason.missingIntakeDays,
          missingIntakeDays: missingIntakeDays,
        );
      }
      intakeKcalByDay.add(averageLogged);
    }
  }

  return CalorieWeeklyLearningIntakeData.ready(
    intakeKcalByDay: intakeKcalByDay,
    missingIntakeDays: missingIntakeDays,
  );
}

/// Sum entry calories.
double sumCalorieEntryKcal(List<CalorieEntry> entries) {
  return entries.fold<double>(0, (sum, entry) => sum + entry.totalKcal);
}

/// Returns activity values matching [days].
List<int> activityKcalByDay({
  required List<DateTime> days,
  required Map<String, int> activeKcalByDay,
}) {
  return days
      .map((day) => activeKcalByDay[diaryDayKey(day)] ?? 0)
      .toList(growable: false);
}

CalorieWeeklyWindowIntakeData _resolveSkippedWindowIntake({
  required List<CalorieWeeklyCheckInWindowDay> windowDays,
  required List<DateTime> missingIntakeDays,
}) {
  final loggedVals = <double>[];
  for (final day in windowDays) {
    if (day.isHeartDay) {
      continue;
    }
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
    if (day.isHeartDay) {
      continue;
    }
    if (day.hasEntries) {
      windowDays[index] = _copyWindowDayWithResolvedIntake(
        day: day,
        hasEntries: true,
        loggedIntakeKcal: day.loggedIntakeKcal,
        resolvedIntakeKcal: day.loggedIntakeKcal,
      );
    } else {
      if (!day.isSkippedIntakeDay) {
        return CalorieWeeklyWindowIntakeData.blocked(
          days: windowDays,
          blockedReason: CalorieWeeklyCheckInBlockedReason.missingIntakeDays,
          missingIntakeDays: missingIntakeDays,
        );
      }
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
    isHeartDay: day.isHeartDay,
    activeKcal: day.activeKcal,
    weightKg: day.weightKg,
  );
}

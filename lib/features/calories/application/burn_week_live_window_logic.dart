import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';

/// Day compare helper for Burn Week date math.
bool isBeforeBurnWeekDay(DateTime left, DateTime right) {
  return normalizeDiaryDay(left).isBefore(normalizeDiaryDay(right));
}

/// Parses persisted Burn Week day key into a normalized day.
DateTime? tryParseBurnWeekDayKey(String? dayKey) {
  final normalizedDayKey = dayKey?.trim();
  if (normalizedDayKey == null || normalizedDayKey.isEmpty) {
    return null;
  }
  final parts = normalizedDayKey.split('-');
  if (parts.length != 3) {
    return null;
  }
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    return null;
  }
  return normalizeDiaryDay(DateTime(year, month, day));
}

/// Whether a persisted week start still belongs to the active cycle.
bool shouldUseStoredBurnWeekStartDate({
  required DateTime storedWeekStartDate,
  required DateTime currentDay,
  required DateTime balanceStartDate,
}) {
  final normalizedStoredWeekStart = normalizeDiaryDay(storedWeekStartDate);
  final normalizedCurrentDay = normalizeDiaryDay(currentDay);
  final normalizedBalanceStartDate = normalizeDiaryDay(balanceStartDate);
  final storedWeekEnd = normalizedStoredWeekStart.add(
    const Duration(days: burnWeekDaysPerWeek),
  );
  return !normalizedStoredWeekStart.isAfter(normalizedCurrentDay) &&
      !normalizedStoredWeekStart.isBefore(normalizedBalanceStartDate) &&
      normalizedCurrentDay.isBefore(storedWeekEnd);
}

/// Resolves live current Burn Week start date.
DateTime resolveBurnWeekLiveWeekStartDate({
  required DateTime currentDay,
  required DateTime balanceStartDate,
  required String? storedWeekStartDayKey,
}) {
  final storedWeekStartDate = tryParseBurnWeekDayKey(storedWeekStartDayKey);
  if (storedWeekStartDate != null &&
      shouldUseStoredBurnWeekStartDate(
        storedWeekStartDate: storedWeekStartDate,
        currentDay: currentDay,
        balanceStartDate: balanceStartDate,
      )) {
    return storedWeekStartDate;
  }
  final normalizedCurrentDay = normalizeDiaryDay(currentDay);
  final elapsedDays = resolveBurnWeekLiveElapsedDays(
    currentDay: normalizedCurrentDay,
    balanceStartDate: balanceStartDate,
  );
  final dayOffset = elapsedDays % burnWeekDaysPerWeek;
  return normalizedCurrentDay.subtract(Duration(days: dayOffset));
}

/// Resolves sync anchor for current live Burn Week.
DateTime resolveBurnWeekLiveSyncWeekStartDate({
  required DateTime currentDay,
  required DateTime currentWeekStartDate,
}) {
  var syncWeekStartDate = normalizeDiaryDay(currentWeekStartDate);
  final normalizedCurrentDay = normalizeDiaryDay(currentDay);
  while (!normalizedCurrentDay.isBefore(
    syncWeekStartDate.add(const Duration(days: burnWeekDaysPerWeek)),
  )) {
    syncWeekStartDate = syncWeekStartDate.add(
      const Duration(days: burnWeekDaysPerWeek),
    );
  }
  return syncWeekStartDate;
}

/// Resolves elapsed days from original balance start.
int resolveBurnWeekLiveElapsedDays({
  required DateTime currentDay,
  required DateTime balanceStartDate,
}) {
  return normalizeDiaryDay(currentDay)
      .difference(normalizeDiaryDay(balanceStartDate))
      .inDays
      .clamp(0, 1000000);
}

/// Resolves whether tracking miss already happened this week.
bool resolveBurnWeekLiveMissedTrackingThisWeek({
  required CalorieWeekOverview weekOverview,
  required DateTime currentWeekStartDate,
  required DateTime today,
  required CalorieGoalSettings settings,
}) {
  return weekOverview.days.any((day) {
    final normalizedDay = normalizeDiaryDay(day.date);
    if (normalizedDay.isBefore(normalizeDiaryDay(currentWeekStartDate))) {
      return false;
    }
    if (!normalizedDay.isBefore(normalizeDiaryDay(today))) {
      return false;
    }
    if (settings.isSkippedIntakeDay(normalizedDay) ||
        settings.isPauseDay(normalizedDay)) {
      return false;
    }
    return day.entryCount == 0;
  });
}

/// Resolves whether tracking was missed in a stored Burn Week window.
bool resolveBurnWeekLiveMissedTrackingForStoredWeek({
  required CalorieWeekConsumptionSnapshot storedWeekSnapshot,
  required DateTime storedWeekStartDate,
  required DateTime today,
  required CalorieGoalSettings settings,
}) {
  return storedWeekSnapshot.days.any((day) {
    final normalizedDay = normalizeDiaryDay(day.date);
    if (normalizedDay.isBefore(normalizeDiaryDay(storedWeekStartDate))) {
      return false;
    }
    if (!normalizedDay.isBefore(normalizeDiaryDay(today))) {
      return false;
    }
    if (settings.isSkippedIntakeDay(normalizedDay) ||
        settings.isPauseDay(normalizedDay)) {
      return false;
    }
    return day.entryCount == 0;
  });
}

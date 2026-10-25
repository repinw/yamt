import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';

/// Resolves weekly calorie learning windows from goal history.
abstract final class CalorieWeeklyWindowResolver {
  /// Returns the first weekly check-in window start for [anchorEntry].
  static DateTime firstWindowStartDate(CalorieGoalHistoryEntry anchorEntry) {
    final anchorStartDate = normalizeLocalDay(
      anchorEntry.effectiveCountingStartDate,
    );
    if (!isSameLocalDay(anchorEntry.effectiveDate, anchorStartDate)) {
      return anchorStartDate;
    }
    if (!hasStarterDay(anchorEntry)) {
      return anchorStartDate;
    }
    return nextLocalDay(anchorStartDate);
  }

  /// Whether [anchorEntry] has a partial starter day before learning starts.
  static bool hasStarterDay(CalorieGoalHistoryEntry anchorEntry) {
    return isSameLocalDay(
          anchorEntry.effectiveDate,
          anchorEntry.effectiveCountingStartDate,
        ) &&
        startsOnPartialDiaryDay(anchorEntry.effectiveChangedAt);
  }

  /// Whether [changedAt] starts after midnight on its diary day.
  static bool startsOnPartialDiaryDay(DateTime changedAt) {
    return changedAt.hour != 0 ||
        changedAt.minute != 0 ||
        changedAt.second != 0 ||
        changedAt.millisecond != 0 ||
        changedAt.microsecond != 0;
  }

  /// Returns learning-window length for [windowStartDate].
  static int windowLengthDaysForStart({
    required CalorieGoalHistoryEntry anchorEntry,
    required DateTime windowStartDate,
  }) {
    if (hasStarterDay(anchorEntry) &&
        isFirstWindowStart(
          anchorEntry: anchorEntry,
          windowStartDate: windowStartDate,
        )) {
      return weeklyCheckInWindowLengthDays - 1;
    }
    return weeklyCheckInWindowLengthDays;
  }

  /// Whether [windowStartDate] is the first learning window start.
  static bool isFirstWindowStart({
    required CalorieGoalHistoryEntry anchorEntry,
    required DateTime windowStartDate,
  }) {
    return isSameLocalDay(firstWindowStartDate(anchorEntry), windowStartDate);
  }

  /// Returns starter-day weight source day for first partial-day window.
  static DateTime? anchorWeightSourceDayForWindow({
    required CalorieGoalHistoryEntry anchorEntry,
    required DateTime windowStartDate,
  }) {
    if (!isFirstWindowStart(
      anchorEntry: anchorEntry,
      windowStartDate: windowStartDate,
    )) {
      return null;
    }
    if (!hasStarterDay(anchorEntry)) {
      return null;
    }
    return normalizeLocalDay(anchorEntry.effectiveDate);
  }

  /// Returns calculator profile active for [day].
  static CalorieCalculatorProfile? calculatorProfileForDay({
    required CalorieGoalSettings settings,
    required DateTime day,
  }) {
    return settings.activeGoalEntryForDay(day)?.calculatorProfile ??
        settings.calculatorProfile;
  }
}

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_provider.dart'
    as week_overview;
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';

part 'diary_weekly_checkin_provider.g.dart';

/// Whether the active calorie goal had already been reached on [day].
bool diaryActiveCalorieGoalWasReached(
  CalorieGoalSettings settings,
  DateTime day,
) {
  return settings.cycleAnchorEntryForDay(day)?.reachedAt != null;
}

/// Most recent recorded weight inside a weekly check-in window.
double? latestDiaryCheckInWeightKg(CalorieWeeklyCheckInData data) {
  for (final day in data.days.reversed) {
    if (day.weightKg != null) {
      return day.weightKg;
    }
  }
  return null;
}

/// Whether the check-in waits for a weight that the user can still track.
bool diaryCheckInCanTrackMissingWeight(CalorieWeeklyCheckInData data) {
  if (data.missingWeightDays.isEmpty) {
    return false;
  }

  return switch (data.blockedReason) {
    CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight ||
    CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight => true,
    _ => false,
  };
}

/// Whether [selectedDay] currently has calorie entries in the weekly window.
@riverpod
Future<bool> diaryWeeklyCheckInSelectedDayHasEntries(
  Ref ref,
  DateTime selectedDay,
) async {
  final overview = await ref.watch(
    week_overview.calorieWeekDayOverviewForDateProvider(selectedDay).future,
  );
  return overview.entryCount > 0;
}

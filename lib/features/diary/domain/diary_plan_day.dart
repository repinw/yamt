import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Whether the plans of [day] count toward it: a future day whose day before
/// is not closed. Once the day before is closed, [day] counts like a started
/// day, and only eaten food counts.
bool diaryDayCountsPlans({
  required DateTime day,
  required DateTime today,
  required bool isPreviousDayClosed,
}) => isDiaryFutureDay(day: day, today: today) && !isPreviousDayClosed;

/// Whether [day] shows as a plan: a future day whose day before is not
/// closed with its carryover. Otherwise it counts like a started day.
bool diaryDayIsPlanned({
  required DateTime day,
  required DateTime today,
  required bool isPreviousDayClosed,
  required double? previousDayCarryoverKcal,
}) =>
    isDiaryFutureDay(day: day, today: today) &&
    !(isPreviousDayClosed && previousDayCarryoverKcal != null);

import 'package:yamt/core/domain/local_day_window.dart';

/// Rolling day count used by the calorie diary window.
const int diaryVisibleDayCount = localVisibleDayCount;

/// Normalizes a timestamp to its local diary day.
DateTime normalizeDiaryDay(DateTime day) {
  return normalizeLocalDay(day);
}

/// Adds whole diary days without relying on 24-hour durations.
DateTime addDiaryDays(DateTime day, int dayOffset) {
  return addLocalDays(day, dayOffset);
}

/// Whole diary days from [from] to [to], also across a clock change.
int diaryDaysBetween(DateTime from, DateTime to) {
  return DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
}

/// Returns the next local diary day.
DateTime nextDiaryDay(DateTime day) {
  return nextLocalDay(day);
}

/// Returns the previous local diary day.
DateTime previousDiaryDay(DateTime day) {
  return previousLocalDay(day);
}

/// Builds the visible diary days from oldest to newest.
List<DateTime> buildDiaryVisibleDays({DateTime? anchorDay}) {
  return buildRollingLocalDays(anchorDay: anchorDay);
}

/// Number of days after today that can be planned.
const int diaryPlanAheadDayCount = 14;

/// Whether [day] lies after [today], so food added to it is a plan.
bool isDiaryFutureDay({required DateTime day, required DateTime today}) =>
    normalizeDiaryDay(day).isAfter(normalizeDiaryDay(today));

/// Returns whether two timestamps belong to the same diary day.
bool isSameDiaryDay(DateTime left, DateTime right) {
  return isSameLocalDay(left, right);
}

/// Returns a stable string key for one diary day.
String diaryDayKey(DateTime day) {
  return localDayKey(day);
}

/// Returns the local diary day window (start inclusive, end exclusive).
({DateTime startInclusive, DateTime endExclusive}) diaryDayBounds(
  DateTime day,
) {
  final start = normalizeDiaryDay(day);
  return (startInclusive: start, endExclusive: nextDiaryDay(start));
}

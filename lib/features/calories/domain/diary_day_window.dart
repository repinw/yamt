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

/// Returns the next local diary day.
DateTime nextDiaryDay(DateTime day) {
  return nextLocalDay(day);
}

/// Returns the previous local diary day.
DateTime previousDiaryDay(DateTime day) {
  return previousLocalDay(day);
}

/// Returns the last visible diary day.
DateTime resolveDiaryWindowEnd({DateTime? anchorDay}) {
  return resolveRollingLocalWindowEnd(anchorDay: anchorDay);
}

/// Returns the first visible diary day in the rolling window.
DateTime resolveDiaryWindowStart({DateTime? anchorDay}) {
  return resolveRollingLocalWindowStart(anchorDay: anchorDay);
}

/// Builds the visible diary days from oldest to newest.
List<DateTime> buildDiaryVisibleDays({DateTime? anchorDay}) {
  return buildRollingLocalDays(anchorDay: anchorDay);
}

/// Returns whether two timestamps belong to the same diary day.
bool isSameDiaryDay(DateTime left, DateTime right) {
  return isSameLocalDay(left, right);
}

/// Returns a stable string key for one diary day.
String diaryDayKey(DateTime day) {
  return localDayKey(day);
}

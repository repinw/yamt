/// Shared rolling 7-day window helpers for the diary UI and aggregates.
const int diaryVisibleDayCount = 7;

/// Normalizes a timestamp to its local calendar day.
DateTime normalizeDiaryDay(DateTime day) {
  return DateTime(day.year, day.month, day.day);
}

/// Adds whole local calendar days without relying on 24-hour durations.
DateTime addDiaryDays(DateTime day, int dayOffset) {
  final normalizedDay = normalizeDiaryDay(day);
  return DateTime(
    normalizedDay.year,
    normalizedDay.month,
    normalizedDay.day + dayOffset,
  );
}

/// Returns the next local calendar day.
DateTime nextDiaryDay(DateTime day) {
  return addDiaryDays(day, 1);
}

/// Returns the previous local calendar day.
DateTime previousDiaryDay(DateTime day) {
  return addDiaryDays(day, -1);
}

/// Returns the last visible diary day, which is always the current day.
DateTime resolveDiaryWindowEnd({DateTime? anchorDay}) {
  return normalizeDiaryDay(anchorDay ?? DateTime.now());
}

/// Returns the first visible diary day in the rolling 7-day window.
DateTime resolveDiaryWindowStart({DateTime? anchorDay}) {
  return addDiaryDays(
    resolveDiaryWindowEnd(anchorDay: anchorDay),
    -(diaryVisibleDayCount - 1),
  );
}

/// Builds the visible diary days from oldest to newest.
List<DateTime> buildDiaryVisibleDays({DateTime? anchorDay}) {
  final start = resolveDiaryWindowStart(anchorDay: anchorDay);
  return List<DateTime>.unmodifiable([
    for (var index = 0; index < diaryVisibleDayCount; index += 1)
      addDiaryDays(start, index),
  ]);
}

/// Returns whether two timestamps belong to same local calendar day.
bool isSameDiaryDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

/// Returns stable string key for one local calendar day.
String diaryDayKey(DateTime day) {
  final normalizedDay = normalizeDiaryDay(day);
  return '${normalizedDay.year}-'
      '${normalizedDay.month}-'
      '${normalizedDay.day}';
}

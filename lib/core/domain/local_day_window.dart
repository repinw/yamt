/// Shared rolling local-day window helpers.
const int localVisibleDayCount = 7;

/// Normalizes a timestamp to its local calendar day.
DateTime normalizeLocalDay(DateTime day) {
  return DateTime(day.year, day.month, day.day);
}

/// Adds whole local calendar days without relying on 24-hour durations.
DateTime addLocalDays(DateTime day, int dayOffset) {
  final normalizedDay = normalizeLocalDay(day);
  return DateTime(
    normalizedDay.year,
    normalizedDay.month,
    normalizedDay.day + dayOffset,
  );
}

/// Returns the next local calendar day.
DateTime nextLocalDay(DateTime day) {
  return addLocalDays(day, 1);
}

/// Returns the previous local calendar day.
DateTime previousLocalDay(DateTime day) {
  return addLocalDays(day, -1);
}

/// Returns the last visible local day, which defaults to the current day.
DateTime resolveRollingLocalWindowEnd({DateTime? anchorDay}) {
  return normalizeLocalDay(anchorDay ?? DateTime.now());
}

/// Returns the first visible local day in the rolling window.
DateTime resolveRollingLocalWindowStart({DateTime? anchorDay}) {
  return addLocalDays(
    resolveRollingLocalWindowEnd(anchorDay: anchorDay),
    -(localVisibleDayCount - 1),
  );
}

/// Builds visible local days from oldest to newest.
List<DateTime> buildRollingLocalDays({DateTime? anchorDay}) {
  final start = resolveRollingLocalWindowStart(anchorDay: anchorDay);
  return List<DateTime>.unmodifiable([
    for (var index = 0; index < localVisibleDayCount; index += 1)
      addLocalDays(start, index),
  ]);
}

/// Returns whether two timestamps belong to same local calendar day.
bool isSameLocalDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

/// Returns stable string key for one local calendar day.
String localDayKey(DateTime day) {
  final normalizedDay = normalizeLocalDay(day);
  return '${normalizedDay.year}-'
      '${normalizedDay.month}-'
      '${normalizedDay.day}';
}

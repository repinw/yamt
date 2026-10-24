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

/// Whole local calendar days from [from] to [to], also across a clock
/// change.
int localDaysBetween(DateTime from, DateTime to) {
  return DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
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

/// Returns the local day window of [day] (start inclusive, end exclusive).
({DateTime startInclusive, DateTime endExclusive}) localDayBounds(
  DateTime day,
) {
  final start = normalizeLocalDay(day);
  return (startInclusive: start, endExclusive: nextLocalDay(start));
}

/// Returns stable string key for one local calendar day.
String localDayKey(DateTime day) {
  final normalizedDay = normalizeLocalDay(day);
  return '${normalizedDay.year}-'
      '${normalizedDay.month}-'
      '${normalizedDay.day}';
}

/// The day a [localDayKey] names; null when [key] is not one.
DateTime? parseLocalDayKey(String key) {
  final parts = key.split('-').map(int.tryParse).toList();
  return switch (parts) {
    [final year?, final month?, final day?] => DateTime(year, month, day),
    _ => null,
  };
}

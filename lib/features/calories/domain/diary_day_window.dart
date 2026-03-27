/// Shared rolling 7-day window helpers for the diary UI and aggregates.
const int diaryVisibleDayCount = 7;

/// Normalizes a timestamp to its local calendar day.
DateTime normalizeDiaryDay(DateTime day) {
  return DateTime(day.year, day.month, day.day);
}

/// Returns the last visible diary day, which is always the current day.
DateTime resolveDiaryWindowEnd({DateTime? anchorDay}) {
  return normalizeDiaryDay(anchorDay ?? DateTime.now());
}

/// Returns the first visible diary day in the rolling 7-day window.
DateTime resolveDiaryWindowStart({DateTime? anchorDay}) {
  return resolveDiaryWindowEnd(
    anchorDay: anchorDay,
  ).subtract(const Duration(days: diaryVisibleDayCount - 1));
}

/// Builds the visible diary days from oldest to newest.
List<DateTime> buildDiaryVisibleDays({DateTime? anchorDay}) {
  final start = resolveDiaryWindowStart(anchorDay: anchorDay);
  return List<DateTime>.unmodifiable([
    for (var index = 0; index < diaryVisibleDayCount; index += 1)
      start.add(Duration(days: index)),
  ]);
}

/// Moves the selected day one step left inside the visible diary window.
DateTime previousDiaryVisibleDay(DateTime selectedDay, {DateTime? anchorDay}) {
  final previousDay = normalizeDiaryDay(
    selectedDay.subtract(const Duration(days: 1)),
  );
  final earliestVisibleDay = resolveDiaryWindowStart(anchorDay: anchorDay);
  if (previousDay.isBefore(earliestVisibleDay)) {
    return earliestVisibleDay;
  }
  return previousDay;
}

/// Moves the selected day one step right inside the visible diary window.
DateTime nextDiaryVisibleDay(DateTime selectedDay, {DateTime? anchorDay}) {
  final nextDay = normalizeDiaryDay(selectedDay.add(const Duration(days: 1)));
  final latestVisibleDay = resolveDiaryWindowEnd(anchorDay: anchorDay);
  if (nextDay.isAfter(latestVisibleDay)) {
    return latestVisibleDay;
  }
  return nextDay;
}

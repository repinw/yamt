import 'package:yamt/core/domain/local_day_window.dart';

/// Number of future days selectable for meal prep.
const int diaryCalendarFutureDayCount = 14;

/// Selectable day range of the diary calendar.
class DiaryCalendarBounds {
  /// Creates calendar bounds.
  const DiaryCalendarBounds({
    required this.earliestDay,
    required this.latestDay,
  });

  /// Resolves bounds from [today] and the optional [planStartDay].
  ///
  /// Users cannot go back before their plan started, and never before today
  /// when no plan exists yet. The future is limited for meal prep.
  factory DiaryCalendarBounds.resolve({
    required DateTime today,
    DateTime? planStartDay,
  }) {
    final normalizedToday = normalizeLocalDay(today);
    final planStart = planStartDay == null
        ? null
        : normalizeLocalDay(planStartDay);
    return DiaryCalendarBounds(
      earliestDay: planStart == null || planStart.isAfter(normalizedToday)
          ? normalizedToday
          : planStart,
      latestDay: addLocalDays(normalizedToday, diaryCalendarFutureDayCount),
    );
  }

  /// Earliest selectable day.
  final DateTime earliestDay;

  /// Latest selectable day.
  final DateTime latestDay;

  /// Whether [day] is selectable.
  bool contains(DateTime day) {
    final normalizedDay = normalizeLocalDay(day);
    return !normalizedDay.isBefore(earliestDay) &&
        !normalizedDay.isAfter(latestDay);
  }

  /// Whether the day before [day] is selectable.
  bool canGoBack(DateTime day) => normalizeLocalDay(day).isAfter(earliestDay);

  /// Whether the day after [day] is selectable.
  bool canGoForward(DateTime day) => normalizeLocalDay(day).isBefore(latestDay);

  /// Clamps [day] into the selectable range.
  DateTime clamp(DateTime day) {
    final normalizedDay = normalizeLocalDay(day);
    if (normalizedDay.isBefore(earliestDay)) {
      return earliestDay;
    }
    if (normalizedDay.isAfter(latestDay)) {
      return latestDay;
    }
    return normalizedDay;
  }
}

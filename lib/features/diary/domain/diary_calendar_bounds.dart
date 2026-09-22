import 'package:meta/meta.dart';
import 'package:yamt/core/domain/local_day_window.dart';

/// Number of future days selectable for meal prep.
const int diaryCalendarFutureDayCount = 14;

/// Selectable day range of the diary calendar.
@immutable
class DiaryCalendarBounds {
  /// Creates calendar bounds.
  const new({required this.earliestDay, required this.latestDay});

  /// Resolves bounds from [today] and the optional [planStartDay].
  ///
  /// Users cannot go back before their plan started, and never before today
  /// when no plan exists yet. The future is limited for meal prep.
  factory resolve({required DateTime today, DateTime? planStartDay}) {
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

  /// Number of selectable days.
  int get dayCount => indexOf(latestDay) + 1;

  /// Position of [day] counted in days from [earliestDay].
  int indexOf(DateTime day) {
    final normalizedDay = normalizeLocalDay(day);
    // UTC days are always 24 hours long, so daylight saving time cannot
    // shorten or stretch the difference.
    return DateTime.utc(
          normalizedDay.year,
          normalizedDay.month,
          normalizedDay.day,
        )
        .difference(
          DateTime.utc(earliestDay.year, earliestDay.month, earliestDay.day),
        )
        .inDays;
  }

  /// Day at [index] days after [earliestDay].
  DateTime dayAt(int index) => addLocalDays(earliestDay, index);

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

  @override
  bool operator ==(Object other) =>
      other is DiaryCalendarBounds &&
      other.earliestDay == earliestDay &&
      other.latestDay == latestDay;

  @override
  int get hashCode => Object.hash(earliestDay, latestDay);

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

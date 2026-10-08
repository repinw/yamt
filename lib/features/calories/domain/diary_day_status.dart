import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Where a diary day stands relative to today.
enum DiaryDayStatus {
  /// A day before today.
  past,

  /// Today.
  today,

  /// A future day whose day before is still open: its food is a plan, and
  /// its plans count toward it.
  planned,

  /// Tomorrow after today was closed with its carryover: it counts like a
  /// started day, and only eaten food counts.
  afterClosedDay;

  /// The status of [day] when the day before it is closed or not.
  ///
  /// The week overview only reports a closed day for tomorrow, and only when
  /// today hands tomorrow a carryover.
  factory of({
    required DateTime day,
    required DateTime today,
    bool isPreviousDayClosed = false,
  }) {
    final normalizedDay = normalizeDiaryDay(day);
    final normalizedToday = normalizeDiaryDay(today);
    if (normalizedDay.isBefore(normalizedToday)) {
      return past;
    }
    if (!normalizedDay.isAfter(normalizedToday)) {
      return DiaryDayStatus.today;
    }
    return isPreviousDayClosed ? afterClosedDay : planned;
  }

  /// Whether the day lies after today, so food added to it is a plan.
  bool get isFuture => this == planned || this == afterClosedDay;

  /// Whether the day shows as a plan, and its plans count toward it.
  bool get isPlanned => this == planned;
}

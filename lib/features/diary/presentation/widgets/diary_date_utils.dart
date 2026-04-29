const _weekdaysShort = <String>['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
const _weekdaysFull = <String>[
  'Montag',
  'Dienstag',
  'Mittwoch',
  'Donnerstag',
  'Freitag',
  'Samstag',
  'Sonntag',
];
const _months = <String>[
  'Januar',
  'Februar',
  'März',
  'April',
  'Mai',
  'Juni',
  'Juli',
  'August',
  'September',
  'Oktober',
  'November',
  'Dezember',
];

/// Formats the diary header date.
String formatDiaryHeaderDate(DateTime day) {
  return '${diaryWeekdayLabel(day)}, ${day.day}. '
      '${_months[day.month - 1]}';
}

/// Returns the short German weekday label for [day].
String diaryWeekdayLabel(DateTime day) {
  return _weekdaysShort[day.weekday - 1];
}

/// Returns the full German weekday label for [day].
String diaryWeekdayFullLabel(DateTime day) {
  return _weekdaysFull[day.weekday - 1];
}

/// Normalizes [day] to date-only precision.
DateTime diaryDayOnly(DateTime day) {
  return DateTime(day.year, day.month, day.day);
}

/// Returns the Monday that starts the calendar week for [day].
DateTime startOfDiaryCalendarWeek(DateTime day) {
  final normalized = diaryDayOnly(day);
  return normalized.subtract(Duration(days: normalized.weekday - 1));
}

/// Compares two days at date-only precision.
bool isSameDiaryCalendarDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

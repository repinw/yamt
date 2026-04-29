import 'package:intl/intl.dart';

/// Formats the diary header date.
String formatDiaryHeaderDate(DateTime day, String localeName) {
  return '${diaryWeekdayLabel(day, localeName)}, '
      '${DateFormat.MMMMd(localeName).format(day)}';
}

/// Returns the localized short weekday label for [day].
String diaryWeekdayLabel(DateTime day, String localeName) {
  return DateFormat.E(localeName)
      .format(day)
      .replaceFirst(
        RegExp(r'\.$'),
        '',
      );
}

/// Returns the localized full weekday label for [day].
String diaryWeekdayFullLabel(DateTime day, String localeName) {
  return DateFormat.EEEE(localeName).format(day);
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
